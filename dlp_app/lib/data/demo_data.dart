/// OULAD-shaped demo profiles.
///
/// These stand in for the output of the Python pipeline
/// (studentInfo ⋈ studentAssessment ⋈ assessments, studentVle ⋈ vle).
/// Module codes follow the OULAD anonymized convention (AAA..GGG); the
/// pipeline will later export real per-student profiles in the same JSON
/// schema (see LearnerProfile.toJson).
library;

import '../models/models.dart';

const demoLearners = <LearnerProfile>[
  LearnerProfile(
    id: 'OU-2026-548721',
    name: 'Nadeesha Perera',
    institution: 'University of Vavuniya',
    programme: 'BSc Applied Data Science',
    finalResult: 'Distinction',
    skills: {
      'Data analysis': 0.88,
      'Programming': 0.72,
      'Maths & statistics': 0.84,
      'Communication': 0.66,
      'Domain knowledge': 0.78,
      'Engagement consistency': 0.91,
    },
    modules: [
      ModuleRecord(
        code: 'FFF',
        title: 'Statistical methods',
        presentation: '2025J',
        tmaAverage: 86,
        examScore: 89,
        result: 'Distinction',
      ),
      ModuleRecord(
        code: 'CCC',
        title: 'Computing & data fundamentals',
        presentation: '2025B',
        tmaAverage: 81,
        examScore: 84,
        result: 'Distinction',
      ),
      ModuleRecord(
        code: 'BBB',
        title: 'Business context for analytics',
        presentation: '2024J',
        tmaAverage: 74,
        result: 'Pass',
      ),
      ModuleRecord(
        code: 'GGG',
        title: 'Professional communication',
        presentation: '2024B',
        tmaAverage: 68,
        result: 'Pass',
      ),
    ],
    weeklyClicks: [
      120, 165, 158, 190, 175, 210, 198, 230, 205, 240,
      225, 260, 218, 235, 248, 270, 255, 280, 262, 290,
    ],
    certifications: ['Google Data Analytics (Coursera)', 'SQL Fundamentals'],
  ),
  LearnerProfile(
    id: 'OU-2026-661084',
    name: 'Kasun Jayasuriya',
    institution: 'University of Vavuniya',
    programme: 'BSc Information Technology',
    finalResult: 'Pass',
    skills: {
      'Data analysis': 0.54,
      'Programming': 0.81,
      'Maths & statistics': 0.49,
      'Communication': 0.71,
      'Domain knowledge': 0.62,
      'Engagement consistency': 0.58,
    },
    modules: [
      ModuleRecord(
        code: 'CCC',
        title: 'Computing & data fundamentals',
        presentation: '2025J',
        tmaAverage: 83,
        examScore: 79,
        result: 'Distinction',
      ),
      ModuleRecord(
        code: 'EEE',
        title: 'Software development practice',
        presentation: '2025B',
        tmaAverage: 77,
        examScore: 72,
        result: 'Pass',
      ),
      ModuleRecord(
        code: 'FFF',
        title: 'Statistical methods',
        presentation: '2024J',
        tmaAverage: 55,
        examScore: 51,
        result: 'Pass',
      ),
      ModuleRecord(
        code: 'DDD',
        title: 'Systems & networks',
        presentation: '2024B',
        tmaAverage: 70,
        result: 'Pass',
      ),
    ],
    weeklyClicks: [
      140, 95, 180, 60, 155, 40, 170, 85, 130, 50,
      160, 75, 145, 35, 150, 90, 120, 55, 165, 80,
    ],
    certifications: ['AWS Cloud Practitioner'],
  ),
  LearnerProfile(
    id: 'OU-2026-712359',
    name: 'Amaya Fernando',
    institution: 'University of Vavuniya',
    programme: 'BSc Business Information Systems',
    finalResult: 'Pass',
    skills: {
      'Data analysis': 0.61,
      'Programming': 0.38,
      'Maths & statistics': 0.57,
      'Communication': 0.86,
      'Domain knowledge': 0.82,
      'Engagement consistency': 0.74,
    },
    modules: [
      ModuleRecord(
        code: 'BBB',
        title: 'Business context for analytics',
        presentation: '2025J',
        tmaAverage: 84,
        examScore: 81,
        result: 'Distinction',
      ),
      ModuleRecord(
        code: 'GGG',
        title: 'Professional communication',
        presentation: '2025B',
        tmaAverage: 88,
        result: 'Distinction',
      ),
      ModuleRecord(
        code: 'AAA',
        title: 'Organisations & management',
        presentation: '2024J',
        tmaAverage: 76,
        examScore: 73,
        result: 'Pass',
      ),
      ModuleRecord(
        code: 'CCC',
        title: 'Computing & data fundamentals',
        presentation: '2024B',
        tmaAverage: 58,
        examScore: 54,
        result: 'Pass',
      ),
    ],
    weeklyClicks: [
      100, 115, 122, 108, 130, 125, 140, 118, 135, 142,
      128, 150, 138, 145, 132, 155, 148, 160, 152, 158,
    ],
    certifications: ['HubSpot Inbound Marketing'],
  ),
];

const demoRoles = <TargetRole>[
  TargetRole(
    name: 'Data analyst',
    summary: 'Entry-level analytics role: SQL, dashboards, statistics.',
    required: {
      'Data analysis': 0.85,
      'Programming': 0.55,
      'Maths & statistics': 0.75,
      'Communication': 0.65,
      'Domain knowledge': 0.55,
      'Engagement consistency': 0.60,
    },
  ),
  TargetRole(
    name: 'Software developer',
    summary: 'Junior developer role: coding, systems, collaboration.',
    required: {
      'Data analysis': 0.45,
      'Programming': 0.90,
      'Maths & statistics': 0.55,
      'Communication': 0.60,
      'Domain knowledge': 0.50,
      'Engagement consistency': 0.65,
    },
  ),
  TargetRole(
    name: 'Business analyst',
    summary: 'Bridges business and tech: requirements, stakeholders, data.',
    required: {
      'Data analysis': 0.65,
      'Programming': 0.35,
      'Maths & statistics': 0.50,
      'Communication': 0.90,
      'Domain knowledge': 0.80,
      'Engagement consistency': 0.55,
    },
  ),
];

/// Sample job description for demoing the on-device Edge LM JD analysis
/// without typing one in.
const kSampleJobDescription = '''
Junior Data Analyst — FinServe Lanka

We are looking for a junior data analyst to join our Colombo finance
analytics team. You will build dashboards in Power BI, write SQL queries
against our reporting warehouse, and apply statistics and regression
techniques for monthly forecasting.

Requirements:
- Strong SQL and Excel; Tableau or Power BI experience
- Solid grounding in statistics and quantitative analysis
- Some Python scripting for ETL is a plus
- Clear communication and presentation skills for stakeholder reviews
- Self-motivated, reliable, and able to manage deadlines independently
- Interest in the finance domain
''';

/// Learning recommendations per skill dimension, surfaced when a gap is
/// detected. In the full system these come from the campus-edge SLM.
const skillRecommendations = <String, String>{
  'Data analysis':
      'Complete the applied analytics project module and a SQL short course.',
  'Programming':
      'Take the structured programming pathway; build two portfolio projects.',
  'Maths & statistics':
      'Revise inferential statistics; retake the FFF module practice TMAs.',
  'Communication':
      'Join the presentation skills workshop; lead one group assignment.',
  'Domain knowledge':
      'Add an industry elective aligned to the target sector.',
  'Engagement consistency':
      'Set a weekly VLE study cadence; aim for steady weekly activity.',
};
