"""OULAD pipeline for the DLP paper (Section 5).

Builds per-registration learner profiles from the seven OULAD tables and
evaluates the skill gap engine:

  (a) worked example: one learner, top-5 gaps, severities, recommendations
  (b) validation: Pearson r between aggregate gap severity and the
      held-out final_result ordering (Withdrawn=0 < Fail=1 < Pass=2 <
      Distinction=3), plus Spearman as a robustness check
  (c) at-risk classification (Fail/Withdrawn): threshold chosen on a 70%
      train split by F1, precision/recall reported on the 30% test split

Unit of analysis: one registration (id_student, code_module,
code_presentation), matching studentInfo rows. final_result is excluded
from profile construction and used only as the validation label.

Skill dimension construction (documented design choices; the paper
discloses that these are performance proxies, not competency tags):
  Data analysis           <- mean relative (z) score on CMAs
  Programming             <- mean relative score on TMAs in STEM modules
  Maths & statistics      <- relative exam score
  Communication           <- mean relative score on TMAs in social
                             science modules
  Domain knowledge        <- credit-weighted overall score percentile
  Engagement consistency  <- VLE regularity: active-week fraction and
                             inverse weekly-click variability
Missed assessments (no submission for a weighted assessment) count as
score 0 in the means: the "missed opportunity" signal of Al-Gahmi (2025).
Each dimension is converted to a [0,1] percentile within the
module-presentation cohort (relative achievement).
"""

import json
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats

DATA = Path(__file__).parent / "data"
OUT = Path(__file__).parent / "results"
OUT.mkdir(exist_ok=True)

STEM_MODULES = {"CCC", "DDD", "EEE", "FFF"}  # Kuzilek et al. 2017, Table 1
KEYS = ["code_module", "code_presentation", "id_student"]

DIMS = [
    "Data analysis",
    "Programming",
    "Maths & statistics",
    "Communication",
    "Domain knowledge",
    "Engagement consistency",
]

# Mirrors lib/data/demo_data.dart in the app.
ROLES = {
    "Data analyst": {
        "Data analysis": 0.85, "Programming": 0.55,
        "Maths & statistics": 0.75, "Communication": 0.65,
        "Domain knowledge": 0.55, "Engagement consistency": 0.60,
    },
    "Software developer": {
        "Data analysis": 0.45, "Programming": 0.90,
        "Maths & statistics": 0.55, "Communication": 0.60,
        "Domain knowledge": 0.50, "Engagement consistency": 0.65,
    },
    "Business analyst": {
        "Data analysis": 0.65, "Programming": 0.35,
        "Maths & statistics": 0.50, "Communication": 0.90,
        "Domain knowledge": 0.80, "Engagement consistency": 0.55,
    },
}

RECOMMENDATIONS = {
    "Data analysis":
        "Complete the applied analytics project module and a SQL short course.",
    "Programming":
        "Take the structured programming pathway; build two portfolio projects.",
    "Maths & statistics":
        "Revise inferential statistics; retake the FFF module practice TMAs.",
    "Communication":
        "Join the presentation skills workshop; lead one group assignment.",
    "Domain knowledge":
        "Add an industry elective aligned to the target sector.",
    "Engagement consistency":
        "Set a weekly VLE study cadence; aim for steady weekly activity.",
}

OUTCOME_ORDER = {"Withdrawn": 0, "Fail": 1, "Pass": 2, "Distinction": 3}


def pct_rank_within(df, group_cols, value_col):
    """Percentile rank of value_col within each group, in [0,1]."""
    return df.groupby(group_cols)[value_col].rank(pct=True)


def main():
    print("Loading tables ...")
    student_info = pd.read_csv(DATA / "studentInfo.csv")
    assessments = pd.read_csv(DATA / "assessments.csv")
    student_assessment = pd.read_csv(DATA / "studentAssessment.csv")
    student_vle = pd.read_csv(
        DATA / "studentVle.csv",
        usecols=["code_module", "code_presentation", "id_student",
                 "date", "sum_click"],
        dtype={"id_student": np.int64, "date": np.int32,
               "sum_click": np.int32},
    )
    courses = pd.read_csv(DATA / "courses.csv")

    n_reg = len(student_info)
    n_students = student_info["id_student"].nunique()
    print(f"Registrations: {n_reg}, unique students: {n_students}")

    # ---------------- assessment features ----------------
    print("Joining assessments ...")
    sa = student_assessment.merge(assessments, on="id_assessment", how="left")

    # Expand to the full (registration x module assessment) grid so that
    # missing submissions are visible (missed-opportunity signal).
    weighted = assessments[assessments["weight"] > 0]
    grid = student_info[KEYS].merge(
        weighted[["code_module", "code_presentation", "id_assessment",
                  "assessment_type", "weight"]],
        on=["code_module", "code_presentation"], how="left")
    grid = grid.merge(
        sa[["id_student", "id_assessment", "score"]],
        on=["id_student", "id_assessment"], how="left")

    # z-score of score within each assessment's cohort (submitters only),
    # then missing submissions get the cohort minimum z minus 1 (clamped),
    # implementing "missed counts against you" without leaking labels.
    g = grid.groupby("id_assessment")["score"]
    grid["z"] = (grid["score"] - g.transform("mean")) / g.transform("std")
    grid["z"] = grid["z"].clip(-3, 3)
    grid["missed"] = grid["score"].isna() & grid["id_assessment"].notna()
    grid.loc[grid["missed"], "z"] = -3.0

    grid["is_stem"] = grid["code_module"].isin(STEM_MODULES)
    grid["wz"] = grid["z"] * grid["weight"]

    def mean_z(mask):
        sub = grid[mask]
        return sub.groupby(KEYS)["z"].mean()

    feats = pd.DataFrame(index=pd.MultiIndex.from_frame(student_info[KEYS]))
    feats["z_cma"] = mean_z(grid["assessment_type"] == "CMA")
    feats["z_tma_stem"] = mean_z((grid["assessment_type"] == "TMA")
                                 & grid["is_stem"])
    feats["z_tma_social"] = mean_z((grid["assessment_type"] == "TMA")
                                   & ~grid["is_stem"])
    feats["z_tma_any"] = mean_z(grid["assessment_type"] == "TMA")
    feats["z_exam"] = mean_z(grid["assessment_type"] == "Exam")
    wsum = grid.groupby(KEYS).apply(
        lambda d: np.average(d["z"], weights=d["weight"])
        if d["weight"].sum() > 0 else np.nan, include_groups=False)
    feats["z_weighted"] = wsum
    feats["missed_frac"] = grid.groupby(KEYS)["missed"].mean()

    # ---------------- VLE engagement features ----------------
    print("Aggregating VLE clicks (10.6M rows) ...")
    student_vle["week"] = student_vle["date"] // 7
    weekly = (student_vle.groupby(KEYS + ["week"])["sum_click"]
              .sum().reset_index())
    length_weeks = courses.set_index(
        ["code_module", "code_presentation"])["module_presentation_length"] // 7

    agg = weekly.groupby(KEYS)["sum_click"].agg(["sum", "mean", "std", "count"])
    agg["weeks_total"] = [
        max(int(length_weeks.get((m, p), 38)), 1)
        for m, p, _ in agg.index
    ]
    agg["active_frac"] = (agg["count"] / agg["weeks_total"]).clip(0, 1)
    cv = (agg["std"] / agg["mean"]).replace([np.inf, -np.inf], np.nan).fillna(2.0)
    agg["regularity"] = (1 - (cv / 2.0).clip(0, 1))
    feats["engagement_raw"] = 0.5 * agg["active_frac"] + 0.5 * agg["regularity"]
    feats["total_clicks"] = agg["sum"]

    feats = feats.reset_index()

    # ---------------- skill dimensions (cohort percentiles) ----------------
    cohort = ["code_module", "code_presentation"]
    fallback_overall = feats["z_weighted"]

    def dim_from(col):
        v = feats[col].fillna(fallback_overall)
        tmp = feats[cohort].copy()
        tmp["v"] = v
        return tmp.groupby(cohort)["v"].rank(pct=True)

    feats["Data analysis"] = dim_from("z_cma")
    feats["Programming"] = dim_from("z_tma_stem")
    feats["Maths & statistics"] = dim_from("z_exam")
    feats["Communication"] = dim_from("z_tma_social")
    feats["Domain knowledge"] = dim_from("z_weighted")
    tmp = feats[cohort].copy()
    tmp["v"] = feats["engagement_raw"].fillna(0)
    feats["Engagement consistency"] = tmp.groupby(cohort)["v"].rank(pct=True)

    # Profiles with no assessment data at all cannot be scored on dims 1-5.
    feats["has_assessment"] = feats["z_weighted"].notna()
    feats["has_vle"] = feats["total_clicks"].notna()

    # Attach held-out label LAST; never used above.
    labeled = feats.merge(student_info[KEYS + ["final_result"]], on=KEYS)
    labeled["outcome"] = labeled["final_result"].map(OUTCOME_ORDER)

    complete = labeled[labeled["has_assessment"] & labeled["has_vle"]].copy()
    coverage = {
        "registrations_total": int(n_reg),
        "unique_students": int(n_students),
        "with_assessment_data": int(labeled["has_assessment"].sum()),
        "with_vle_data": int(labeled["has_vle"].sum()),
        "complete_profiles": int(len(complete)),
        "coverage_pct": round(100 * len(complete) / n_reg, 1),
    }
    print("Coverage:", coverage)

    # ---------------- aggregate gap severity ----------------
    # Reference requirement = mean of the three demo role vectors,
    # making the validation role-neutral.
    reference = {d: np.mean([ROLES[r][d] for r in ROLES]) for d in DIMS}
    sev = np.zeros(len(complete))
    for d in DIMS:
        sev += np.maximum(0, reference[d] - complete[d].values)
    complete["gap_severity"] = sev

    # ---------------- (b) correlation ----------------
    pear_r, pear_p = stats.pearsonr(complete["gap_severity"],
                                    complete["outcome"])
    spear_r, spear_p = stats.spearmanr(complete["gap_severity"],
                                       complete["outcome"])
    sev_by_outcome = (complete.groupby("final_result")["gap_severity"]
                      .agg(["mean", "std", "count"]).round(3))
    print(f"Pearson r = {pear_r:.3f} (p = {pear_p:.2e})")
    print(f"Spearman rho = {spear_r:.3f} (p = {spear_p:.2e})")
    print(sev_by_outcome)

    # ---------------- (c) at-risk classification ----------------
    rng = np.random.RandomState(42)
    complete["at_risk"] = complete["outcome"] <= 1
    idx = rng.permutation(len(complete))
    cut = int(0.7 * len(complete))
    train = complete.iloc[idx[:cut]]
    test = complete.iloc[idx[cut:]]

    best_f1, best_t = -1.0, None
    for t in np.quantile(train["gap_severity"], np.linspace(0.05, 0.95, 91)):
        pred = train["gap_severity"] >= t
        tp = (pred & train["at_risk"]).sum()
        if tp == 0:
            continue
        prec = tp / pred.sum()
        rec = tp / train["at_risk"].sum()
        f1 = 2 * prec * rec / (prec + rec)
        if f1 > best_f1:
            best_f1, best_t = f1, t

    pred = test["gap_severity"] >= best_t
    tp = (pred & test["at_risk"]).sum()
    precision = tp / pred.sum()
    recall = tp / test["at_risk"].sum()
    f1 = 2 * precision * recall / (precision + recall)
    base_rate = test["at_risk"].mean()
    print(f"Test precision = {precision:.3f}, recall = {recall:.3f}, "
          f"F1 = {f1:.3f}, base rate = {base_rate:.3f}, "
          f"threshold = {best_t:.3f}, n_test = {len(test)}")

    # ---------------- (a) worked example ----------------
    # A mid-band learner: Pass outcome, complete profile, in a STEM module,
    # with the median gap severity among such learners (representative,
    # not cherry-picked).
    pool = complete[(complete["final_result"] == "Pass")
                    & complete["code_module"].isin(STEM_MODULES)]
    median_sev = pool["gap_severity"].median()
    example = pool.iloc[(pool["gap_severity"] - median_sev).abs().argsort()
                        ].iloc[0]

    role = ROLES["Data analyst"]
    gaps = []
    for d in DIMS:
        severity = role[d] - example[d]
        if severity > 0.005:
            gaps.append({
                "skill": d,
                "required": round(role[d], 2),
                "actual": round(float(example[d]), 2),
                "severity_pts": int(round(severity * 100)),
                "recommendation": RECOMMENDATIONS[d],
            })
    gaps.sort(key=lambda g: -g["severity_pts"])

    a = np.array([example[d] for d in DIMS], dtype=float)
    b = np.array([role[d] for d in DIMS], dtype=float)
    match = float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b)))

    worked_example = {
        "id_student": int(example["id_student"]),
        "module": example["code_module"],
        "presentation": example["code_presentation"],
        "final_result_heldout": example["final_result"],
        "skill_vector": {d: round(float(example[d]), 2) for d in DIMS},
        "target_role": "Data analyst",
        "cosine_match": round(match, 3),
        "top_gaps": gaps[:5],
    }
    print(json.dumps(worked_example, indent=2))

    results = {
        "coverage": coverage,
        "reference_vector": {d: round(reference[d], 3) for d in DIMS},
        "correlation": {
            "pearson_r": round(float(pear_r), 3),
            "pearson_p": float(pear_p),
            "spearman_rho": round(float(spear_r), 3),
            "spearman_p": float(spear_p),
            "n": int(len(complete)),
            "severity_by_outcome": sev_by_outcome.to_dict(),
        },
        "classification": {
            "definition": "at-risk = Fail or Withdrawn",
            "split": "70/30 random (seed 42), threshold by F1 on train",
            "threshold": round(float(best_t), 3),
            "test_precision": round(float(precision), 3),
            "test_recall": round(float(recall), 3),
            "test_f1": round(float(f1), 3),
            "test_base_rate": round(float(base_rate), 3),
            "n_train": int(len(train)),
            "n_test": int(len(test)),
        },
        "worked_example": worked_example,
    }
    (OUT / "evaluation.json").write_text(json.dumps(results, indent=2))
    complete[KEYS + DIMS + ["gap_severity", "final_result"]].to_csv(
        OUT / "profiles_scored.csv", index=False)
    print(f"\nWrote {OUT/'evaluation.json'} and profiles_scored.csv "
          f"({len(complete)} rows)")


if __name__ == "__main__":
    main()
