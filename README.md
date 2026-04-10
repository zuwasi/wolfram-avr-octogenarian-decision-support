# AVR Decision Support for Octogenarians with Severe Aortic Stenosis

Reproducing and extending: **Massalha et al., "Treatment disparities and prognostic implications in octogenarians versus non-octogenarians with high-gradient severe aortic stenosis"** (Open Heart, 2025; PMC12352216)

## Purpose

This notebook implements a clinical decision-support analytics engine demonstrating the survival and hospitalisation benefits of aortic valve replacement (AVR) in octogenarians with high-gradient severe aortic stenosis (HG-sAS).

## Key Findings Reproduced

- Octogenarians are 38% less likely to receive AVR (HR 0.62)
- AVR reduces 5-year mortality by ~70% in octogenarians (HR 0.28)
- Benefit is symptom-independent in octogenarians (interaction p=0.6)
- AVR reduces hospitalisations by 61% (IRR 0.39)

## Prerequisites

- **Wolfram Mathematica** 13.0+ (14.0 recommended)
- No additional paclets required

## How to Run

1. Open `AVR_Decision_Support_Octogenarians.nb` in Mathematica
2. **Evaluate → Evaluate Notebook** (or Ctrl+Shift+Enter)
3. The notebook loads `AVRDecisionEngine.wl` automatically from the same directory
4. Interactive dashboard in Section 11 allows real-time patient parameter adjustment

## File Manifest

| File | Description |
|------|-------------|
| `AVR_Decision_Support_Octogenarians.nb` | Main notebook (14 sections) |
| `AVRDecisionEngine.wl` | Reusable Wolfram Language package |
| `proof_audit.wls` | Automated validation script |
| `README.md` | This file |
| `exports/` | Directory for exported figures and data |

## Notebook Sections

1. Package Loading & Configuration
2. Synthetic Cohort Generation
3. Cohort Validation
4. Cox PH Survival Model
5. Kaplan-Meier Survival Curves
6. Number Needed to Treat (NNT)
7. Hospitalisation Model
8. Treatment Gap Analysis
9. Individual Patient Risk Scorer
10. Sensitivity Analysis (E-Value)
11. Interactive Clinical Dashboard
12. Key Findings
13. Validation Summary
14. References

## Customisation

- Modify `PaperReferenceData[]` in the `.wl` package to update reference values
- Adjust Weibull parameters in `BaselineHazard` for different baseline risk calibration
- Change cost assumption ($15,000/hospitalisation) in Section 7.2

## Source Paper

Massalha E, Shimoni O, Rapp O, et al. Treatment disparities and prognostic implications in octogenarians versus non-octogenarians with high-gradient severe aortic stenosis. *Open Heart*. 2025;12(2):e003405. doi:[10.1136/openhrt-2025-003405](https://doi.org/10.1136/openhrt-2025-003405)
