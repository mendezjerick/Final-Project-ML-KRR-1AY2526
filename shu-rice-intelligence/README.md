# Rice Price Forecasting & Advisory (MLI Guide)

This project follows the **MLI_Guide** proposal for "Rice Price Forecasting and Rule-Based Advisory System". It uses the provided dataset in `data/rice.csv` to:

- Clean and aggregate PSA/WFP/WB rice price series to monthly national and regional averages.
- Train baseline forecasting models (Linear Regression, Random Forest, HistGradientBoosting) with time-aware features.
- Persist the best-performing model (`models/best_model.joblib`) plus documented metrics.
- Interpret model outputs through a lightweight forward-chaining rule base that produces stakeholder advisories tied to SDG 2 and SDG 8.
- Surface insights, forecasts, and advisories through a Shu-themed PySide6 desktop application.

## Project layout

```
shu-rice-intelligence/
├── app.py                      # PySide6 desktop application entry point
├── backend.py                  # PyWebView bridge that loads data/models
├── build_exe.ps1               # helper script to bundle ShuRiceApp.exe (PyInstaller)
├── requirements.txt            # Python dependencies
├── data/
│   └── rice.csv                # raw dataset supplied by the user
├── documentation/
│   └── MLI_Guide.pdf           # reference proposal
│   ├── GROUP CONTRIBUTION.pdf  
│   └── RICE PRICE FORECASTING AND RULE-BASED ADVISORY SYSTEM FOR FOOD SECURITY IN THE PHILIPPINES.pdf                 
├── download_app/               # packaged binaries + PyInstaller work dirs
│   ├── build/                  # PyInstaller workpath (output)
│   └── dist/                   # packaged EXEs live here
├── forecast/                   # generated forecasts/advisories
│   ├── next_month_forecast.csv
│   ├── rule_based_advisories.csv
│   ├── next_month_forecast_test.csv
│   ├── rule_based_advisories_test.csv
│   └── archive/
├── models/                     # serialized models + metrics (gitignored)
│   ├── best_model.joblib
│   ├── metrics.json
│   └── README.md
├── notebooks/                  # reserved for exploration notebooks
├── src/                        # reusable Python package + assets
│   ├── backgrounds/            # Shu-themed assets (shu.jpg, shu2.jpg)
│   ├── backports/
│   ├── icons/                  # shu.ico used for executables
│   ├── mli_rice/               # package code (data, features, modeling, rules, CLI)
│   └── web/                    # HTML/CSS/JS for the UI
└── video/                      # placeholder for presentation assets
```

## Quick start

1. **Install dependencies** (Python 3.11 recommended):
   ```powershell
   pip install -r requirements.txt
   ```

2. **Set the module path** for CLI usage (PowerShell example):
   ```powershell
   $env:PYTHONPATH = "$PWD/src"
   ```

3. **Explore the dataset**:
   ```powershell
   python -m mli_rice.cli describe
   ```

4. **Train models & log metrics** (1-month horizon with 12-month holdout window):
   ```powershell
   python -m mli_rice.cli train --holdout-months 12 --horizon 1
   ```
   Outputs:
   - `models/best_model.joblib` – fitted sklearn pipeline
   - `models/metrics.json` – CV & holdout RMSE/R^2 for each candidate

5. **Generate forecasts + advisories** (set `--forecast-months` to look multiple months ahead even if the dataset stops earlier):
   ```powershell
   python -m mli_rice.cli forecast `
     --forecast-months 2 `
     --output-path forecast/next_month_forecast.csv `
     --advisories-path forecast/rule_based_advisories.csv
   ```

6. **Launch the desktop workspace**:
   ```powershell
   python app.py
   ```

## Desktop application (PySide6)

`app.py` launches the **Shu Rice Intelligence** desktop suite:

- **Home** (shu.jpg background) shows dataset stats, a national price chart, and a synopsis of the ML/KRR workflow.
- **Price Observatory** (shu2.jpg background) lets users pick any region + month to retrieve PSA-recorded prices while browsing the historical records.
- **Forecast Studio** (shu2.jpg background) offers multi-month simulations or a concrete target month, exposes the entire training/holdout feature tables, displays evaluation metrics, plots actual vs. projected prices, and surfaces rule-based advisories.

Retrain via the CLI whenever new data arrives—the PySide6 UI automatically picks up refreshed artifacts from `models/best_model.joblib`.

## Build a standalone EXE (Windows)

Bundle the entire project as a portable executable with the Shu icon:

1. Install PyInstaller (one-time): `pip install pyinstaller`
2. From the repo root:
   ```powershell
   python -m PyInstaller --clean --noconsole --onefile app.py `
     --name "Shu Rice Intelligence" `
     --paths src `
     --distpath download_app/dist `
     --workpath download_app/build `
     --add-data "src/web;src/web" --add-data "src/backgrounds;src/backgrounds" --add-data "src/icons;src/icons" `
     --add-data "data/rice.csv;data" --add-data "models;models" `
     --icon "src/icons/shu.ico"
   ```
3. The packaged app lives in `download_app/dist/Shu Rice Intelligence.exe`, includes `data/rice.csv`, `backgrounds/`, `icons/`, `src/`, and `models/`, and shows the Shu icon. You can also rename the EXE manually in `download_app/dist` without breaking it. Upload this single file as a GitHub release asset; users only need to download and run it (SmartScreen may require “More info” → “Run anyway”).

## Dashboard UX updates

- Home/Dashboard now has a single dim background (no double overlay), a frosted navbar matching the cards, and a global loading screen while data/chart initialize.
- Forecast Studio shows rule-based advisories in their own card; if a target date is unreachable with the chosen months ahead, the app returns an empty forecast with a clear notice instead of placeholder data.

## Modeling approach

- **Aggregation**: `mli_rice.data` creates national and region-level monthly averages with a `date` index.
- **Feature engineering** (`mli_rice.features`):
  - Lagged prices (1, 2, 3, 6 months)
  - Rolling mean/std (3- & 6-month windows)
  - Temporal encodings (`month`, sinusoidal seasonality, running `time_index`)
- **Algorithms**: Linear Regression, Random Forest Regressor, and HistGradientBoosting (scikit-learn).
- **Evaluation**: 5-fold time-series CV + 12-month holdout RMSE/R^2. Metrics are persisted to JSON for auditability.
- **Artifacts**: Best model refit on full data after selection to maximize predictive strength for operational use.

## Rule-based reasoning

`mli_rice.rules` implements forward-chaining heuristics aligned with the guide's examples:

- >5% forecasted MoM price rise or 3-month upward trend -> "Supply Risk" (import/storage) advisory.
- >3% projected decline -> "Market Opportunity" to stabilize farmer income.
- Regional forecast >1 SD above national mean -> "Consumer Protection" (monitoring/subsidies).
- Forecast well below mean with falling trend -> "Trade Optimization" (ship to deficit areas).
- Persistent uptick -> "Local Government Action" prompt for LGUs/DA.

The CLI stores the resulting advisories in `forecast/rule_based_advisories.csv`, while the desktop app renders them alongside forecasts for transparency.

## Application highlights (`app.py`)

- Exploratory overview: richly themed Home tab showing national benchmarks and workflow notes.
- Model evaluation: training/holdout previews plus stored metrics surfaced inside the Forecast Studio.
- Forecasts & advisories: multi-region predictions, percentage deltas, and SDG-tagged advisories rendered in native tables.
- SDG alignment: curated copy throughout the app to highlight SDG 2 (Zero Hunger) and SDG 8 (Decent Work & Growth).

## Extensibility

- Adjust lag windows or horizons via CLI options (`--horizon`) or by editing `FeatureConfig` defaults.
- Extend `generate_advisories` to ingest external signals (rainfall, import volumes) as data becomes available.
- Replace/augment the baseline models with deep-learning (LSTM) models by adding new estimators inside `mli_rice.modeling`.
- Connect the dashboard to a live database/API once production data pipelines exist.

## References

- `documentation/MLI_Guide.pdf` – proposal text with objectives, rules, and SDG framing.
- PSA/WFP/World Bank rice price statistics consolidated in `data/rice.csv`.
