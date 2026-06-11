/// Core domain models for the Digital Learning Passport.
///
/// Shapes mirror the OULAD schema (Kuzilek et al., 2017) so that profiles
/// exported by the Python pipeline (studentInfo + studentAssessment +
/// studentVle joins) can be served to this app without remapping.
library;

/// Canonical skill dimensions used for profile and role vectors.
/// Order matters: vectors are compared positionally.
const List<String> kSkillDimensions = [
  'Data analysis',
  'Programming',
  'Maths & statistics',
  'Communication',
  'Domain knowledge',
  'Engagement consistency',
];

class LearnerProfile {
  final String id;
  final String name;
  final String institution;
  final String programme;

  /// OULAD studentInfo.final_result: Distinction / Pass / Fail / Withdrawn.
  final String finalResult;

  /// Skill mastery per dimension in [kSkillDimensions], range 0..1.
  final Map<String, double> skills;

  final List<ModuleRecord> modules;

  /// Weekly VLE click totals (OULAD studentVle sum_click aggregated by week).
  final List<int> weeklyClicks;

  final List<String> certifications;

  const LearnerProfile({
    required this.id,
    required this.name,
    required this.institution,
    required this.programme,
    required this.finalResult,
    required this.skills,
    required this.modules,
    required this.weeklyClicks,
    required this.certifications,
  });

  List<double> get skillVector =>
      kSkillDimensions.map((d) => skills[d] ?? 0.0).toList();

  Map<String, dynamic> toJson({
    bool includeScores = true,
    bool includeEngagement = true,
  }) =>
      {
        'id': id,
        'nm': name,
        'ins': institution,
        'prg': programme,
        'res': finalResult,
        'sk': skills,
        if (includeScores)
          'mods': modules.map((m) => m.toJson()).toList(),
        if (includeEngagement) 'eng': weeklyClicks,
        'crt': certifications,
      };

  factory LearnerProfile.fromJson(Map<String, dynamic> j) => LearnerProfile(
        id: j['id'] as String,
        name: j['nm'] as String,
        institution: j['ins'] as String,
        programme: j['prg'] as String,
        finalResult: j['res'] as String,
        skills: (j['sk'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        modules: (j['mods'] as List<dynamic>? ?? [])
            .map((m) => ModuleRecord.fromJson(m as Map<String, dynamic>))
            .toList(),
        weeklyClicks: (j['eng'] as List<dynamic>? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        certifications: (j['crt'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );
}

class ModuleRecord {
  /// OULAD courses.code_module (AAA..GGG in the open dataset).
  final String code;
  final String title;

  /// OULAD code_presentation, e.g. 2026J.
  final String presentation;

  /// Mean tutor-marked assessment (TMA) score, 0..100.
  final double tmaAverage;

  /// Final exam score if the module had one.
  final double? examScore;

  /// Pass / Distinction / Fail / Withdrawn at module level.
  final String result;

  const ModuleRecord({
    required this.code,
    required this.title,
    required this.presentation,
    required this.tmaAverage,
    this.examScore,
    required this.result,
  });

  Map<String, dynamic> toJson() => {
        'c': code,
        't': title,
        'p': presentation,
        'tma': tmaAverage,
        if (examScore != null) 'ex': examScore,
        'r': result,
      };

  factory ModuleRecord.fromJson(Map<String, dynamic> j) => ModuleRecord(
        code: j['c'] as String,
        title: j['t'] as String,
        presentation: j['p'] as String,
        tmaAverage: (j['tma'] as num).toDouble(),
        examScore: (j['ex'] as num?)?.toDouble(),
        result: j['r'] as String,
      );
}

/// A target role the recruiter matches candidates against.
class TargetRole {
  final String name;
  final String summary;

  /// Required mastery per dimension in [kSkillDimensions], range 0..1.
  final Map<String, double> required;

  const TargetRole({
    required this.name,
    required this.summary,
    required this.required,
  });

  List<double> get vector =>
      kSkillDimensions.map((d) => required[d] ?? 0.0).toList();
}

/// One detected gap between a role requirement and a learner's mastery.
class SkillGap {
  final String skill;
  final double required;
  final double actual;

  const SkillGap(this.skill, this.required, this.actual);

  /// Positive when the learner is below the requirement.
  double get severity => (required - actual).clamp(0.0, 1.0);
}
