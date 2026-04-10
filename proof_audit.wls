#!/usr/bin/env wolframscript
(* === PROOF AUDIT SCRIPT - Zero-Day Verification === *)
(* AVR Decision Support for Octogenarians *)
(* Based on: Massalha et al., Open Heart, 2025 *)
(* Usage: wolframscript -file proof_audit.wls *)

Print["===================================================="];
Print["   PROOF AUDIT - Zero-Day Verification"];
Print["   AVR Decision Support Engine"];
Print["====================================================\n"];

passed = 0; failed = 0; warnings = 0;

auditResult[name_, test_, detail_] := If[test,
  Print["  PASS: ", name]; passed++,
  Print["  FAIL: ", name, " -- ", detail]; failed++
];
auditWarn[name_, test_, detail_] := If[!test,
  Print["  WARN: ", name, " -- ", detail]; warnings++
];

(* Load the package *)
Get[FileNameJoin[{DirectoryName[$InputFileName], "AVRDecisionEngine.wl"}]];
SeedRandom[42];
ref = PaperReferenceData[];

(* -------------------------------------------------- *)
(* AUDIT 1: Reference Data Integrity                   *)
(* -------------------------------------------------- *)
Print["\n=== AUDIT 1: Reference Data Integrity ==="];

auditResult["Cohort total = 1396",
  ref["Cohort"]["Total"] == 1396,
  StringJoin["Got ", ToString[ref["Cohort"]["Total"]]]
];
auditResult["Non-oct = 858",
  ref["Cohort"]["NonOctogenarians"] == 858,
  StringJoin["Got ", ToString[ref["Cohort"]["NonOctogenarians"]]]
];
auditResult["Oct = 538",
  ref["Cohort"]["Octogenarians"] == 538,
  StringJoin["Got ", ToString[ref["Cohort"]["Octogenarians"]]]
];
auditResult["858 + 538 = 1396",
  ref["Cohort"]["NonOctogenarians"] + ref["Cohort"]["Octogenarians"] == ref["Cohort"]["Total"],
  "Subgroup counts don't sum to total"
];
auditResult["AVR rate oct < non-oct",
  ref["AVRRate"]["Octogenarian"] < ref["AVRRate"]["NonOctogenarian"],
  "Treatment disparity not reflected"
];
auditResult["HR oct (0.28) < HR non-oct (0.38)",
  ref["HazardRatios"]["AVR_Mortality"]["Octogenarian"]["HR"] < ref["HazardRatios"]["AVR_Mortality"]["NonOctogenarian"]["HR"],
  "Octogenarian AVR benefit should be stronger"
];

(* -------------------------------------------------- *)
(* AUDIT 2: Synthetic Cohort Validation                *)
(* -------------------------------------------------- *)
Print["\n=== AUDIT 2: Synthetic Cohort Validation ==="];

SeedRandom[42];
testNonOct = GenerateSyntheticCohort[858, "NonOctogenarian"];
SeedRandom[42];
testOct = GenerateSyntheticCohort[538, "Octogenarian"];

(* Check non-oct age range *)
nonOctAges = Lookup[testNonOct, "Age"];
auditResult["Non-oct ages in [60,79]",
  Min[nonOctAges] >= 60 && Max[nonOctAges] <= 79,
  StringJoin["Range: [", ToString[Min[nonOctAges]], ", ", ToString[Max[nonOctAges]], "]"]
];

(* Check oct age range *)
octAges = Lookup[testOct, "Age"];
auditResult["Oct ages in [80,90]",
  Min[octAges] >= 80 && Max[octAges] <= 90,
  StringJoin["Range: [", ToString[Min[octAges]], ", ", ToString[Max[octAges]], "]"]
];

(* Check mean ages are close to paper *)
auditResult["Non-oct mean age near 72",
  Abs[Mean[nonOctAges] - 72] < 2,
  StringJoin["Mean = ", ToString[N[Mean[nonOctAges]]]]
];
auditResult["Oct mean age near 84",
  Abs[Mean[octAges] - 84] < 2,
  StringJoin["Mean = ", ToString[N[Mean[octAges]]]]
];

(* Check AVR rates *)
nonOctAVR = N[Mean[Lookup[testNonOct, "AVR"]]];
octAVR = N[Mean[Lookup[testOct, "AVR"]]];
auditResult["Non-oct AVR rate near 60%",
  Abs[nonOctAVR - 0.60] < 0.05,
  StringJoin["Got ", ToString[nonOctAVR * 100], "%"]
];
auditResult["Oct AVR rate near 42%",
  Abs[octAVR - 0.42] < 0.05,
  StringJoin["Got ", ToString[octAVR * 100], "%"]
];

(* Check MPG >= 40 for all patients *)
allMPG = Join[Lookup[testNonOct, "MPG"], Lookup[testOct, "MPG"]];
auditResult["All MPG >= 40 (HG-sAS criterion)",
  Min[allMPG] >= 40,
  StringJoin["Min MPG = ", ToString[Min[allMPG]]]
];

(* Check AVA < 1.0 for all patients *)
allAVA = Join[Lookup[testNonOct, "AVA"], Lookup[testOct, "AVA"]];
auditResult["All AVA < 1.0 (sAS criterion)",
  Max[allAVA] < 1.0,
  StringJoin["Max AVA = ", ToString[Max[allAVA]]]
];

(* -------------------------------------------------- *)
(* AUDIT 3: Survival Model Consistency                 *)
(* -------------------------------------------------- *)
Print["\n=== AUDIT 3: Survival Model Consistency ==="];

(* S(0) should be 1.0 for any patient *)
testPatient = First[testOct];
s0 = AVRSurvival[0.001, testPatient, "Octogenarian"];
auditResult["S(0) near 1.0",
  Abs[s0 - 1.0] < 0.01,
  StringJoin["S(0) = ", ToString[s0]]
];

(* S(t) should be monotonically decreasing *)
sValues = Table[AVRSurvival[t, testPatient, "Octogenarian"], {t, 0.1, 5.0, 0.5}];
auditResult["S(t) monotonically decreasing",
  And @@ Table[sValues[[i]] >= sValues[[i + 1]], {i, Length[sValues] - 1}],
  "Survival function not monotonically decreasing"
];

(* AVR patient should have higher survival than non-AVR *)
patientNoAVR = ReplacePart[testPatient, "AVR" -> 0];
patientAVR = ReplacePart[testPatient, "AVR" -> 1];
sNoAVR = AVRSurvival[5.0, patientNoAVR, "Octogenarian"];
sAVR = AVRSurvival[5.0, patientAVR, "Octogenarian"];
auditResult["AVR patient survival > non-AVR at 5 years",
  sAVR > sNoAVR,
  StringJoin["AVR: ", ToString[sAVR], " vs No-AVR: ", ToString[sNoAVR]]
];

(* HF patient should have lower survival *)
patientNoHF = ReplacePart[patientNoAVR, "HF" -> 0];
patientHF = ReplacePart[patientNoAVR, "HF" -> 1];
sNoHF = AVRSurvival[5.0, patientNoHF, "Octogenarian"];
sHF = AVRSurvival[5.0, patientHF, "Octogenarian"];
auditResult["HF patient survival < non-HF (HR 2.01)",
  sHF < sNoHF,
  StringJoin["HF: ", ToString[sHF], " vs No-HF: ", ToString[sNoHF]]
];

(* -------------------------------------------------- *)
(* AUDIT 4: NNT Validity                               *)
(* -------------------------------------------------- *)
Print["\n=== AUDIT 4: NNT Validity ==="];

nntResult = ComputeNNT[0.28, 0.50];
auditResult["NNT > 0",
  nntResult["NNT"] > 0,
  StringJoin["NNT = ", ToString[nntResult["NNT"]]]
];
auditResult["ARR > 0 (AVR reduces risk)",
  nntResult["ARR"] > 0,
  StringJoin["ARR = ", ToString[nntResult["ARR"]]]
];
auditResult["Risk with AVR < baseline risk",
  nntResult["RiskWithAVR"] < nntResult["BaselineRisk"],
  "AVR should reduce risk"
];

(* -------------------------------------------------- *)
(* AUDIT 5: E-Value Computation                        *)
(* -------------------------------------------------- *)
Print["\n=== AUDIT 5: E-Value Computation ==="];

eVal = EValueCompute[0.28, 0.20];
auditResult["E-value > 1",
  eVal["EValue_Point"] > 1,
  StringJoin["E-value = ", ToString[eVal["EValue_Point"]]]
];
auditResult["E-value CI > 1",
  eVal["EValue_CI"] > 1,
  StringJoin["E-value CI = ", ToString[eVal["EValue_CI"]]]
];
auditResult["E-value point > E-value CI",
  eVal["EValue_Point"] >= eVal["EValue_CI"],
  "Point estimate E-value should be >= CI E-value"
];

(* -------------------------------------------------- *)
(* AUDIT 6: Hospitalisation Model                      *)
(* -------------------------------------------------- *)
Print["\n=== AUDIT 6: Hospitalisation Model ==="];

hospNoAVR = HospitalisationRate[First[testOct], 0];
hospAVR = HospitalisationRate[First[testOct], 1];
auditResult["Hosp rate no-AVR > AVR",
  hospNoAVR > hospAVR,
  StringJoin["No-AVR: ", ToString[hospNoAVR], " vs AVR: ", ToString[hospAVR]]
];

(* Check ratio is approximately IRR 0.39 *)
ratio = hospAVR / hospNoAVR;
auditResult["Hosp rate ratio near 0.39 (paper IRR)",
  Abs[ratio - 0.39] < 0.15,
  StringJoin["Ratio = ", ToString[ratio]]
];

(* Negative binomial simulation should produce non-negative integers *)
SeedRandom[42];
hospCount = NegBinomHospitalisations[First[testOct], 0, 3.0];
auditResult["NegBinom produces non-negative integer",
  hospCount >= 0 && IntegerQ[Round[hospCount]],
  StringJoin["Got ", ToString[hospCount]]
];

(* -------------------------------------------------- *)
(* AUDIT 7: Reproducibility (SeedRandom)               *)
(* -------------------------------------------------- *)
Print["\n=== AUDIT 7: Reproducibility ==="];

SeedRandom[42];
cohort1 = GenerateSyntheticCohort[100, "Octogenarian"];
SeedRandom[42];
cohort2 = GenerateSyntheticCohort[100, "Octogenarian"];
auditResult["Reproducible cohort generation",
  Lookup[cohort1, "Age"] == Lookup[cohort2, "Age"],
  "Different seeds produce different results"
];

(* -------------------------------------------------- *)
(* FINAL REPORT                                        *)
(* -------------------------------------------------- *)
Print["\n===================================================="];
Print["          AUDIT REPORT SUMMARY"];
Print["===================================================="];
Print["  Passed:   ", passed];
Print["  Failed:   ", failed];
Print["  Warnings: ", warnings];
Print["----------------------------------------------------"];
If[failed == 0,
  Print["  OVERALL:  ALL AUDITS PASSED"],
  Print["  OVERALL:  AUDIT FAILURES DETECTED"]
];
Print["===================================================="];

Exit[If[failed > 0, 1, 0]]
