(* ::Package:: *)
(* AVRDecisionEngine.wl *)
(* Decision-support engine for AVR in octogenarians with HG-sAS *)
(* Based on: Massalha et al., Open Heart, 2025 (PMC12352216) *)

BeginPackage["AVRDecisionEngine`"]

PaperReferenceData::usage = "PaperReferenceData[] returns an Association with all reference data from the paper."
GenerateSyntheticCohort::usage = "GenerateSyntheticCohort[n, ageGroup] generates n synthetic patients. ageGroup: \"Octogenarian\" or \"NonOctogenarian\"."
BaselineHazard::usage = "BaselineHazard[t, ageGroup] returns the Weibull baseline hazard at time t (years)."
CoxPHLogHazard::usage = "CoxPHLogHazard[patient, ageGroup] computes the Cox PH linear predictor for a patient Association."
SurvivalFunction::usage = "SurvivalFunction[t, patient, ageGroup] returns S(t) for a patient using the Cox PH model."
KaplanMeierEstimate::usage = "KaplanMeierEstimate[eventTimes, censorFlags, tMax] computes KM survival curve."
ComputeNNT::usage = "ComputeNNT[hr, baselineRisk] computes Number Needed to Treat."
HospitalisationRate::usage = "HospitalisationRate[patient, avrStatus] returns expected rate per 100 patient-years."
NegBinomHospitalisations::usage = "NegBinomHospitalisations[patient, avrStatus, followUpYears] simulates hospitalisation count."
TreatmentGapAnalysis::usage = "TreatmentGapAnalysis[octCohort, nonOctCohort] quantifies lives saved if AVR rates equalised."
PatientRiskScore::usage = "PatientRiskScore[patient] returns comprehensive risk assessment Association."
EValueCompute::usage = "EValueCompute[hr, ciLower] computes E-value for unmeasured confounding sensitivity."
ValidateCohort::usage = "ValidateCohort[cohort, ageGroup] checks synthetic cohort against paper values."
SimulateEventTime::usage = "SimulateEventTime[patient, ageGroup, tMax] simulates a survival event time."

Begin["`Private`"]

(* ================================================================ *)
(* Reference Data from the Paper                                     *)
(* ================================================================ *)

PaperReferenceData[] := <|
  "Cohort" -> <|
    "Total" -> 1396,
    "NonOctogenarians" -> 858,
    "Octogenarians" -> 538
  |>,
  "Age" -> <|
    "NonOctogenarian" -> <|"Mean" -> 72.0, "SD" -> 5.0|>,
    "Octogenarian" -> <|"Mean" -> 84.0, "SD" -> 3.0|>
  |>,
  "Female" -> <|
    "NonOctogenarian" -> 0.47,
    "Octogenarian" -> 0.55
  |>,
  "AVRRate" -> <|
    "NonOctogenarian" -> 0.60,
    "Octogenarian" -> 0.42
  |>,
  "Comorbidities" -> <|
    "Hypertension" -> <|"NonOctogenarian" -> 0.78, "Octogenarian" -> 0.82|>,
    "DM" -> <|"NonOctogenarian" -> 0.42, "Octogenarian" -> 0.40|>,
    "CAD" -> <|"NonOctogenarian" -> 0.16, "Octogenarian" -> 0.15|>,
    "PriorMI" -> <|"NonOctogenarian" -> 0.085, "Octogenarian" -> 0.11|>,
    "HF" -> <|"NonOctogenarian" -> 0.10, "Octogenarian" -> 0.18|>,
    "MR" -> <|"NonOctogenarian" -> 0.11, "Octogenarian" -> 0.099|>,
    "AF" -> <|"NonOctogenarian" -> 0.15, "Octogenarian" -> 0.22|>,
    "Pacemaker" -> <|"NonOctogenarian" -> 0.022, "Octogenarian" -> 0.046|>,
    "PVD" -> <|"NonOctogenarian" -> 0.17, "Octogenarian" -> 0.18|>,
    "CVD" -> <|"NonOctogenarian" -> 0.21, "Octogenarian" -> 0.23|>,
    "COPD" -> <|"NonOctogenarian" -> 0.21, "Octogenarian" -> 0.18|>,
    "Liver" -> <|"NonOctogenarian" -> 0.092, "Octogenarian" -> 0.069|>,
    "Malignancy" -> <|"NonOctogenarian" -> 0.062, "Octogenarian" -> 0.076|>,
    "Dementia" -> <|"NonOctogenarian" -> 0.026, "Octogenarian" -> 0.11|>
  |>,
  "Symptoms" -> <|
    "NonOctogenarian" -> 0.39,
    "Octogenarian" -> 0.44
  |>,
  "Echo" -> <|
    "MPG" -> <|
      "NonOctogenarian" -> <|"Median" -> 46.0, "Q1" -> 42.0, "Q3" -> 53.0|>,
      "Octogenarian" -> <|"Median" -> 45.0, "Q1" -> 42.0, "Q3" -> 51.0|>
    |>,
    "AVA" -> <|
      "NonOctogenarian" -> <|"Median" -> 0.78, "Q1" -> 0.67, "Q3" -> 0.87|>,
      "Octogenarian" -> <|"Median" -> 0.73, "Q1" -> 0.61, "Q3" -> 0.82|>
    |>
  |>,
  "HazardRatios" -> <|
    "AVR_Mortality" -> <|
      "NonOctogenarian" -> <|"HR" -> 0.38, "Lower" -> 0.27, "Upper" -> 0.54|>,
      "Octogenarian" -> <|"HR" -> 0.28, "Lower" -> 0.20, "Upper" -> 0.38|>
    |>,
    "AVR_Mortality_Symptomatic" -> <|
      "NonOctogenarian" -> <|"HR" -> 0.29, "Lower" -> 0.18, "Upper" -> 0.45|>,
      "Octogenarian" -> <|"HR" -> 0.28, "Lower" -> 0.19, "Upper" -> 0.41|>
    |>,
    "AVR_Mortality_Asymptomatic" -> <|
      "NonOctogenarian" -> <|"HR" -> 0.60, "Lower" -> 0.32, "Upper" -> 1.10|>,
      "Octogenarian" -> <|"HR" -> 0.29, "Lower" -> 0.16, "Upper" -> 0.51|>
    |>,
    "AVR_Hospitalisation_TimeToFirst" -> <|
      "Octogenarian" -> <|"HR" -> 0.62, "Lower" -> 0.48, "Upper" -> 0.79|>
    |>,
    "AVR_Hospitalisation_Recurrent" -> <|
      "Octogenarian" -> <|"IRR" -> 0.39, "Lower" -> 0.30, "Upper" -> 0.50|>
    |>
  |>,
  "MortalityPredictors" -> <|
    "Octogenarian" -> <|
      "AVR" -> <|"HR" -> 0.32, "Lower" -> 0.19, "Upper" -> 0.53|>,
      "Symptoms" -> <|"HR" -> 1.43, "Lower" -> 1.02, "Upper" -> 2.00|>,
      "AgePerYear" -> <|"HR" -> 1.09, "Lower" -> 1.04, "Upper" -> 1.14|>,
      "PriorMI" -> <|"HR" -> 1.57, "Lower" -> 1.04, "Upper" -> 2.37|>,
      "HF" -> <|"HR" -> 2.01, "Lower" -> 1.43, "Upper" -> 2.81|>,
      "AF" -> <|"HR" -> 1.40, "Lower" -> 1.03, "Upper" -> 1.91|>,
      "Hypertension" -> <|"HR" -> 0.67, "Lower" -> 0.47, "Upper" -> 0.95|>,
      "Male" -> <|"HR" -> 0.85, "Lower" -> 0.64, "Upper" -> 1.14|>,
      "MPGPer5" -> <|"HR" -> 1.06, "Lower" -> 0.96, "Upper" -> 1.17|>,
      "CAD" -> <|"HR" -> 1.21, "Lower" -> 0.82, "Upper" -> 1.79|>,
      "DM" -> <|"HR" -> 1.18, "Lower" -> 0.89, "Upper" -> 1.57|>,
      "Dementia" -> <|"HR" -> 1.11, "Lower" -> 0.73, "Upper" -> 1.68|>,
      "COPD" -> <|"HR" -> 1.10, "Lower" -> 0.78, "Upper" -> 1.54|>,
      "Liver" -> <|"HR" -> 1.14, "Lower" -> 0.64, "Upper" -> 2.01|>,
      "Malignancy" -> <|"HR" -> 0.73, "Lower" -> 0.42, "Upper" -> 1.25|>,
      "MR" -> <|"HR" -> 1.37, "Lower" -> 0.90, "Upper" -> 2.08|>,
      "PVD" -> <|"HR" -> 1.06, "Lower" -> 0.74, "Upper" -> 1.53|>,
      "CVD" -> <|"HR" -> 0.99, "Lower" -> 0.71, "Upper" -> 1.36|>,
      "Pacemaker" -> <|"HR" -> 1.16, "Lower" -> 0.63, "Upper" -> 2.14|>
    |>,
    "NonOctogenarian" -> <|
      "AVR" -> <|"HR" -> 0.59, "Lower" -> 0.34, "Upper" -> 1.01|>,
      "Symptoms" -> <|"HR" -> 2.82, "Lower" -> 1.77, "Upper" -> 4.49|>,
      "AgePerYear" -> <|"HR" -> 1.05, "Lower" -> 1.01, "Upper" -> 1.08|>,
      "PriorMI" -> <|"HR" -> 1.51, "Lower" -> 0.91, "Upper" -> 2.50|>,
      "HF" -> <|"HR" -> 1.44, "Lower" -> 0.92, "Upper" -> 2.26|>,
      "AF" -> <|"HR" -> 1.71, "Lower" -> 1.14, "Upper" -> 2.25|>,
      "Hypertension" -> <|"HR" -> 0.92, "Lower" -> 0.60, "Upper" -> 1.42|>,
      "Male" -> <|"HR" -> 1.51, "Lower" -> 1.07, "Upper" -> 2.12|>,
      "MPGPer5" -> <|"HR" -> 1.03, "Lower" -> 0.92, "Upper" -> 1.15|>,
      "CAD" -> <|"HR" -> 0.71, "Lower" -> 0.46, "Upper" -> 1.10|>,
      "DM" -> <|"HR" -> 1.04, "Lower" -> 0.75, "Upper" -> 1.45|>,
      "Dementia" -> <|"HR" -> 2.51, "Lower" -> 1.32, "Upper" -> 4.78|>,
      "COPD" -> <|"HR" -> 1.57, "Lower" -> 1.09, "Upper" -> 2.25|>,
      "Liver" -> <|"HR" -> 0.65, "Lower" -> 0.34, "Upper" -> 1.25|>,
      "Malignancy" -> <|"HR" -> 1.71, "Lower" -> 1.03, "Upper" -> 2.83|>,
      "MR" -> <|"HR" -> 0.70, "Lower" -> 0.43, "Upper" -> 1.14|>,
      "PVD" -> <|"HR" -> 1.05, "Lower" -> 0.70, "Upper" -> 1.59|>,
      "CVD" -> <|"HR" -> 1.31, "Lower" -> 0.91, "Upper" -> 1.87|>,
      "Pacemaker" -> <|"HR" -> 0.34, "Lower" -> 0.08, "Upper" -> 1.38|>,
      "HaemoglobinPerGdL" -> <|"HR" -> 0.85, "Lower" -> 0.77, "Upper" -> 0.94|>,
      "CardiologistVisit" -> <|"HR" -> 0.71, "Lower" -> 0.52, "Upper" -> 0.97|>
    |>
  |>,
  "Hospitalisation" -> <|
    "AVR" -> <|"FollowUpYears" -> 516.0, "Events" -> 213, "RatePer100" -> 41.0|>,
    "NoAVR" -> <|"FollowUpYears" -> 749.0, "Events" -> 630, "RatePer100" -> 84.0|>
  |>
|>

(* ================================================================ *)
(* Synthetic Cohort Generation                                       *)
(* ================================================================ *)

sampleBernoulli[p_] := If[RandomReal[] < p, 1, 0]

sampleLogNormalFromIQR[median_, q1_, q3_] := Module[
  {mu, sigma},
  mu = Log[median];
  sigma = (Log[q3] - Log[q1]) / (2.0 * 1.349);
  N[Exp[RandomVariate[NormalDistribution[mu, Max[sigma, 0.01]]]]]
]

truncatedNormal[mean_, sd_, lo_, hi_] := Module[{x},
  x = RandomVariate[TruncatedDistribution[{lo, hi}, NormalDistribution[mean, sd]]];
  N[x]
]

GenerateSyntheticCohort[n_Integer, ageGroup_String] := Module[
  {ref, comorbRef, echoRef, ageMean, ageSD, femalePrev, symptomPrev, avrRate, patients},
  ref = PaperReferenceData[];
  comorbRef = ref["Comorbidities"];
  echoRef = ref["Echo"];
  ageMean = ref["Age"][ageGroup]["Mean"];
  ageSD = ref["Age"][ageGroup]["SD"];
  femalePrev = ref["Female"][ageGroup];
  symptomPrev = ref["Symptoms"][ageGroup];
  avrRate = ref["AVRRate"][ageGroup];

  patients = Table[Module[
    {age, female, mpg, ava, symptoms, avr, comorbs},
    age = If[ageGroup === "Octogenarian",
      truncatedNormal[ageMean, ageSD, 80, 90],
      truncatedNormal[ageMean, ageSD, 60, 79]
    ];
    female = sampleBernoulli[femalePrev];
    mpg = sampleLogNormalFromIQR[
      echoRef["MPG"][ageGroup]["Median"],
      echoRef["MPG"][ageGroup]["Q1"],
      echoRef["MPG"][ageGroup]["Q3"]
    ];
    mpg = Max[40.0, mpg];
    ava = sampleLogNormalFromIQR[
      echoRef["AVA"][ageGroup]["Median"],
      echoRef["AVA"][ageGroup]["Q1"],
      echoRef["AVA"][ageGroup]["Q3"]
    ];
    ava = Min[0.99, Max[0.3, ava]];
    symptoms = sampleBernoulli[symptomPrev];
    avr = sampleBernoulli[avrRate];
    comorbs = Association[
      KeyValueMap[
        Function[{k, v}, k -> sampleBernoulli[v[ageGroup]]],
        comorbRef
      ]
    ];
    <|
      "Age" -> N[Round[age, 1]],
      "Female" -> female,
      "Male" -> 1 - female,
      "AgeGroup" -> ageGroup,
      "MPG" -> N[Round[mpg, 0.1]],
      "AVA" -> N[Round[ava, 0.01]],
      "Symptoms" -> symptoms,
      "AVR" -> avr,
      "Hypertension" -> comorbs["Hypertension"],
      "DM" -> comorbs["DM"],
      "CAD" -> comorbs["CAD"],
      "PriorMI" -> comorbs["PriorMI"],
      "HF" -> comorbs["HF"],
      "MR" -> comorbs["MR"],
      "AF" -> comorbs["AF"],
      "Pacemaker" -> comorbs["Pacemaker"],
      "PVD" -> comorbs["PVD"],
      "CVD" -> comorbs["CVD"],
      "COPD" -> comorbs["COPD"],
      "Liver" -> comorbs["Liver"],
      "Malignancy" -> comorbs["Malignancy"],
      "Dementia" -> comorbs["Dementia"]
    |>
  ], {i, n}];
  patients
]

(* ================================================================ *)
(* Baseline Hazard (Weibull)                                         *)
(* ================================================================ *)

BaselineHazard[t_?NumericQ, ageGroup_String] := Module[
  {shape, scale, lambda},
  (* Calibrated so ~35-40% 5-year mortality for untreated average patient *)
  If[ageGroup === "Octogenarian",
    shape = 1.3; scale = 6.5,
    shape = 1.2; scale = 9.0
  ];
  lambda = 1.0 / scale;
  N[shape * lambda * (lambda * Max[t, 0.001])^(shape - 1)]
]

baselineCumHazard[t_?NumericQ, ageGroup_String] := Module[
  {shape, scale, lambda},
  If[ageGroup === "Octogenarian",
    shape = 1.3; scale = 6.5,
    shape = 1.2; scale = 9.0
  ];
  lambda = 1.0 / scale;
  N[(lambda * Max[t, 0.001])^shape]
]

baselineSurvival[t_?NumericQ, ageGroup_String] :=
  N[Exp[-baselineCumHazard[t, ageGroup]]]

(* ================================================================ *)
(* Cox PH Linear Predictor                                           *)
(* ================================================================ *)

CoxPHLogHazard[patient_Association, ageGroup_String] := Module[
  {ref, preds, lp, refAge, mpgRef},
  ref = PaperReferenceData[];
  preds = ref["MortalityPredictors"][ageGroup];
  refAge = ref["Age"][ageGroup]["Mean"];
  mpgRef = 46.0;
  lp = 0.0;
  lp += Log[preds["AVR"]["HR"]] * patient["AVR"];
  lp += Log[preds["Symptoms"]["HR"]] * patient["Symptoms"];
  lp += Log[preds["AgePerYear"]["HR"]] * (patient["Age"] - refAge);
  lp += Log[preds["Male"]["HR"]] * patient["Male"];
  lp += Log[preds["MPGPer5"]["HR"]] * ((patient["MPG"] - mpgRef) / 5.0);
  lp += Log[preds["HF"]["HR"]] * patient["HF"];
  lp += Log[preds["AF"]["HR"]] * patient["AF"];
  lp += Log[preds["DM"]["HR"]] * patient["DM"];
  lp += Log[preds["CAD"]["HR"]] * patient["CAD"];
  lp += Log[preds["PriorMI"]["HR"]] * patient["PriorMI"];
  lp += Log[preds["Hypertension"]["HR"]] * patient["Hypertension"];
  lp += Log[preds["COPD"]["HR"]] * patient["COPD"];
  lp += Log[preds["Dementia"]["HR"]] * patient["Dementia"];
  lp += Log[preds["Liver"]["HR"]] * patient["Liver"];
  lp += Log[preds["Malignancy"]["HR"]] * patient["Malignancy"];
  lp += Log[preds["MR"]["HR"]] * patient["MR"];
  lp += Log[preds["PVD"]["HR"]] * patient["PVD"];
  lp += Log[preds["CVD"]["HR"]] * patient["CVD"];
  lp += Log[preds["Pacemaker"]["HR"]] * patient["Pacemaker"];
  N[lp]
]

(* ================================================================ *)
(* Survival Function                                                 *)
(* ================================================================ *)

SurvivalFunction[t_?NumericQ, patient_Association, ageGroup_String] := Module[
  {lp, cumH0},
  lp = CoxPHLogHazard[patient, ageGroup];
  cumH0 = baselineCumHazard[t, ageGroup];
  N[Exp[-cumH0 * Exp[lp]]]
]

(* ================================================================ *)
(* Event Time Simulation                                             *)
(* ================================================================ *)

SimulateEventTime[patient_Association, ageGroup_String, tMax_: 5.0] := Module[
  {lp, u, shape, scale, lambda, cumH, eventTime},
  lp = CoxPHLogHazard[patient, ageGroup];
  u = RandomReal[];
  If[ageGroup === "Octogenarian",
    shape = 1.3; scale = 6.5,
    shape = 1.2; scale = 9.0
  ];
  lambda = 1.0 / scale;
  (* Solve: S(t) = exp(-H0(t)*exp(lp)) = u => H0(t) = -log(u)/exp(lp) *)
  cumH = -Log[u] / Exp[lp];
  (* H0(t) = (lambda*t)^shape => t = (cumH^(1/shape))/lambda *)
  eventTime = N[(cumH^(1.0/shape)) / lambda];
  If[eventTime > tMax,
    <|"EventTime" -> N[tMax], "Censored" -> 1|>,
    <|"EventTime" -> N[eventTime], "Censored" -> 0|>
  ]
]

(* ================================================================ *)
(* Kaplan-Meier Estimator                                            *)
(* ================================================================ *)

KaplanMeierEstimate[eventTimes_List, censorFlags_List, tMax_: 5.0] := Module[
  {data, sorted, nAtRisk, survProb, kmCurve, n},
  n = Length[eventTimes];
  data = Transpose[{eventTimes, censorFlags}];
  sorted = SortBy[data, First];
  nAtRisk = n;
  survProb = 1.0;
  kmCurve = {{0.0, 1.0}};
  Do[
    Module[{ti, ci},
      ti = sorted[[i, 1]];
      ci = sorted[[i, 2]];
      If[ci == 0, (* event occurred *)
        survProb = survProb * (1.0 - 1.0 / nAtRisk);
        AppendTo[kmCurve, {N[ti], N[survProb]}];
      ];
      nAtRisk -= 1;
    ],
    {i, Length[sorted]}
  ];
  AppendTo[kmCurve, {N[tMax], N[survProb]}];
  kmCurve
]

(* ================================================================ *)
(* Number Needed to Treat                                            *)
(* ================================================================ *)

ComputeNNT[hr_?NumericQ, baselineRisk_?NumericQ] := Module[
  {riskWithAVR, arr},
  riskWithAVR = 1.0 - (1.0 - baselineRisk)^hr;
  arr = baselineRisk - riskWithAVR;
  If[arr > 0,
    <|
      "BaselineRisk" -> N[baselineRisk],
      "RiskWithAVR" -> N[riskWithAVR],
      "ARR" -> N[arr],
      "NNT" -> N[1.0 / arr]
    |>,
    <|
      "BaselineRisk" -> N[baselineRisk],
      "RiskWithAVR" -> N[riskWithAVR],
      "ARR" -> N[arr],
      "NNT" -> N[Infinity]
    |>
  ]
]

(* ================================================================ *)
(* Hospitalisation Model                                             *)
(* ================================================================ *)

HospitalisationRate[patient_Association, avrStatus_Integer] := Module[
  {baseRate, irr},
  baseRate = 84.0; (* per 100 patient-years, no AVR *)
  irr = 0.39;
  If[avrStatus == 1,
    N[baseRate * irr * (1.0 + 0.1 * patient["HF"] + 0.05 * patient["AF"])],
    N[baseRate * (1.0 + 0.1 * patient["HF"] + 0.05 * patient["AF"])]
  ]
]

NegBinomHospitalisations[patient_Association, avrStatus_Integer, followUpYears_?NumericQ] := Module[
  {rate, mu, r, p},
  rate = HospitalisationRate[patient, avrStatus] / 100.0;
  mu = rate * followUpYears;
  r = 2.0; (* dispersion *)
  p = r / (r + mu);
  N[RandomVariate[NegativeBinomialDistribution[r, p]]]
]

(* ================================================================ *)
(* Treatment Gap Analysis                                            *)
(* ================================================================ *)

TreatmentGapAnalysis[octCohort_List, nonOctCohort_List] := Module[
  {currentAVRRate, targetAVRRate, nOct, additionalAVR, hr, baselineMortality5yr,
   livesPerAVR, livesSaved, hospRate, hospAVRRate, hospAvoided},
  nOct = Length[octCohort];
  currentAVRRate = 0.42;
  targetAVRRate = 0.60;
  additionalAVR = Round[nOct * (targetAVRRate - currentAVRRate)];
  hr = 0.28;
  baselineMortality5yr = 0.50;
  livesPerAVR = baselineMortality5yr * (1.0 - hr);
  livesSaved = N[additionalAVR * livesPerAVR];
  hospRate = 84.0;
  hospAVRRate = 41.0;
  hospAvoided = N[additionalAVR * (hospRate - hospAVRRate) / 100.0 * 3.0];
  <|
    "CurrentAVRRate" -> N[currentAVRRate],
    "TargetAVRRate" -> N[targetAVRRate],
    "OctogenarianCount" -> nOct,
    "AdditionalAVRPatients" -> additionalAVR,
    "EstimatedLivesSaved5yr" -> N[livesSaved],
    "EstimatedHospitalisationsAvoided3yr" -> N[hospAvoided],
    "CostSavings3yr_USD" -> N[hospAvoided * 15000.0],
    "HR_AVR" -> hr,
    "BaselineMortality5yr" -> baselineMortality5yr
  |>
]

(* ================================================================ *)
(* Patient Risk Scorer                                               *)
(* ================================================================ *)

PatientRiskScore[patient_Association] := Module[
  {ageGroup, survNoAVR, survAVR, patientNoAVR, patientAVR,
   arr, nnt, hospNoAVR, hospAVR, hospReduction, recommendation},
  ageGroup = patient["AgeGroup"];
  patientNoAVR = ReplacePart[patient, "AVR" -> 0];
  patientAVR = ReplacePart[patient, "AVR" -> 1];
  survNoAVR = SurvivalFunction[5.0, patientNoAVR, ageGroup];
  survAVR = SurvivalFunction[5.0, patientAVR, ageGroup];
  arr = survAVR - survNoAVR;
  nnt = If[arr > 0.001, 1.0 / arr, Infinity];
  hospNoAVR = HospitalisationRate[patientNoAVR, 0];
  hospAVR = HospitalisationRate[patientAVR, 1];
  hospReduction = (hospNoAVR - hospAVR) / hospNoAVR * 100.0;
  recommendation = Which[
    arr > 0.20, "Strong AVR benefit",
    arr > 0.10, "Moderate AVR benefit",
    arr > 0.05, "Discuss with heart team",
    True, "Marginal benefit - consider patient preferences"
  ];
  <|
    "AgeGroup" -> ageGroup,
    "Age" -> patient["Age"],
    "Survival5yr_NoAVR" -> N[survNoAVR],
    "Survival5yr_AVR" -> N[survAVR],
    "AbsoluteRiskReduction" -> N[arr],
    "NNT_5yr" -> N[nnt],
    "HospRate_NoAVR" -> N[hospNoAVR],
    "HospRate_AVR" -> N[hospAVR],
    "HospReductionPct" -> N[hospReduction],
    "Recommendation" -> recommendation
  |>
]

(* ================================================================ *)
(* E-Value for Sensitivity Analysis                                  *)
(* ================================================================ *)

EValueCompute[hr_?NumericQ, ciLower_?NumericQ] := Module[
  {eVal, eValCI, hrInv, ciInv},
  hrInv = 1.0 / hr;
  ciInv = 1.0 / ciLower;
  eVal = hrInv + Sqrt[hrInv * (hrInv - 1.0)];
  eValCI = If[ciInv > 1.0,
    ciInv + Sqrt[ciInv * (ciInv - 1.0)],
    1.0
  ];
  <|
    "HR" -> N[hr],
    "CI_Lower" -> N[ciLower],
    "EValue_Point" -> N[eVal],
    "EValue_CI" -> N[eValCI],
    "Interpretation" -> StringJoin[
      "An unmeasured confounder would need to be associated with both the treatment and outcome by a risk ratio of at least ",
      ToString[NumberForm[eVal, {4, 2}]],
      " to explain away the observed HR of ",
      ToString[NumberForm[hr, {3, 2}]]
    ]
  |>
]

(* ================================================================ *)
(* Cohort Validation                                                 *)
(* ================================================================ *)

ValidateCohort[cohort_List, ageGroup_String] := Module[
  {ref, n, results, observedFemale, observedAge, observedMPG, observedAVA,
   observedSymptoms, observedAVR, comorbRef, tolerance},
  ref = PaperReferenceData[];
  comorbRef = ref["Comorbidities"];
  n = Length[cohort];
  tolerance = 0.05;
  observedFemale = N[Mean[Lookup[cohort, "Female"]]];
  observedAge = N[Mean[Lookup[cohort, "Age"]]];
  observedMPG = N[Median[Lookup[cohort, "MPG"]]];
  observedAVA = N[Median[Lookup[cohort, "AVA"]]];
  observedSymptoms = N[Mean[Lookup[cohort, "Symptoms"]]];
  observedAVR = N[Mean[Lookup[cohort, "AVR"]]];
  results = <|
    "N" -> n,
    "AgeMean" -> <|
      "Observed" -> observedAge,
      "Expected" -> ref["Age"][ageGroup]["Mean"],
      "Pass" -> Abs[observedAge - ref["Age"][ageGroup]["Mean"]] < 2.0
    |>,
    "FemalePct" -> <|
      "Observed" -> observedFemale,
      "Expected" -> ref["Female"][ageGroup],
      "Pass" -> Abs[observedFemale - ref["Female"][ageGroup]] < tolerance
    |>,
    "MPGMedian" -> <|
      "Observed" -> observedMPG,
      "Expected" -> ref["Echo"]["MPG"][ageGroup]["Median"],
      "Pass" -> Abs[observedMPG - ref["Echo"]["MPG"][ageGroup]["Median"]] < 3.0
    |>,
    "AVAMedian" -> <|
      "Observed" -> observedAVA,
      "Expected" -> ref["Echo"]["AVA"][ageGroup]["Median"],
      "Pass" -> Abs[observedAVA - ref["Echo"]["AVA"][ageGroup]["Median"]] < 0.05
    |>,
    "SymptomPct" -> <|
      "Observed" -> observedSymptoms,
      "Expected" -> ref["Symptoms"][ageGroup],
      "Pass" -> Abs[observedSymptoms - ref["Symptoms"][ageGroup]] < tolerance
    |>,
    "AVRRate" -> <|
      "Observed" -> observedAVR,
      "Expected" -> ref["AVRRate"][ageGroup],
      "Pass" -> Abs[observedAVR - ref["AVRRate"][ageGroup]] < tolerance
    |>
  |>;
  Do[
    Module[{obs, exp},
      obs = N[Mean[Lookup[cohort, comorb]]];
      exp = comorbRef[comorb][ageGroup];
      AssociateTo[results,
        comorb -> <|
          "Observed" -> obs,
          "Expected" -> exp,
          "Pass" -> Abs[obs - exp] < tolerance
        |>
      ];
    ],
    {comorb, Keys[comorbRef]}
  ];
  results
]

End[]
EndPackage[]
