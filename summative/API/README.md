# NutriWise — Task 2: FastAPI

This service loads the fitted Task 1 pipeline (`best_model.pkl`) and exposes prediction, health-check, and retraining endpoints.

## What the prediction means

The target is **`DR1TKCAL`: Day 1 reported dietary energy intake in kcal** from one NHANES 24-hour dietary recall. It is not a recommended calorie target, daily energy expenditure, or medical advice. The training data is from the United States NHANES 2021–2023 cycle; validate on representative Rwandan data before using it for local decisions.

## Project files

- `prediction.py` — FastAPI application
- `best_model.pkl` — trained preprocessing + SGDRegressor pipeline from Task 1
- `nutriwise_dataset.csv` — source data used for non-incremental retraining fallback
- `requirements.txt` — Python dependencies
- `render.yaml` — Render deployment configuration
- `sample_request.json` — example `/predict` request

## Run locally (Kali Linux / Linux / Windows)

```bash
cd api
python3 -m venv .venv
source .venv/bin/activate       # Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
uvicorn prediction:app --reload
```

Open `http://127.0.0.1:8000/docs` for interactive Swagger documentation.

## Endpoints

- `GET /` — service information
- `GET /health` — health check
- `POST /predict` — JSON input with all 10 model features
- `POST /retrain` — multipart form upload named `file`, containing a CSV with all 10 features plus `DR1TKCAL`

### Test prediction with curl

```bash
curl -X POST "http://127.0.0.1:8000/predict" \
  -H "Content-Type: application/json" \
  --data @sample_request.json
```

### Test retraining with curl

```bash
curl -X POST "http://127.0.0.1:8000/retrain" \
  -F "file=@your_new_training_rows.csv"
```

The uploaded CSV must contain at least 10 rows with non-negative numeric `DR1TKCAL` values. The current best model is `SGDRegressor`, so the API transforms uploaded features with the existing fitted preprocessor and continues learning using `partial_fit`. If a non-incremental estimator is substituted later, the fallback refits it on the original CSV plus the uploaded rows.

## Deploy to Render

1. Push the contents of this `api` folder to a GitHub repository (or place them in a repository root).
2. In Render, choose **New + → Web Service**, connect the repository, and set the root directory to `api` if this folder is inside a larger repository.
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn prediction:app --host 0.0.0.0 --port $PORT`
5. Deploy. Open the Render URL and append `/docs` to test the API.
6. Set `ALLOWED_ORIGINS` to a comma-separated list of exact frontend origins if you later call it from Flutter Web. Native Android/iOS Flutter apps do not use browser CORS enforcement.

The Render filesystem on a free service may be ephemeral; a retrained model can revert after a restart or redeploy. The original model file is included in the repository and will be loaded at startup.

## CORS

CORS is configured using the `ALLOWED_ORIGINS` environment variable. It defaults to local development origins and does not use a wildcard. Add your deployed Flutter Web origin in Render's environment settings when applicable.
