"""Shared model code and the POST /retrain route."""
from pathlib import Path
from threading import Lock

import joblib
import pandas as pd
from fastapi import APIRouter, File, HTTPException, UploadFile
from sklearn.base import clone

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "best_model.pkl"
DATA_PATH = BASE_DIR / "rhomis_africa.csv"

TARGET = "Food_Availability_kCal_MAE_day"
NUMERIC_FEATURES = [
    "HHsizemembers", "LandCultivated", "LivestockHoldings",
    "NrofMonthsFoodInsecure", "NrofMonthsWildFoodCons", "Gender_FemaleControl",
]
CATEGORICAL_FEATURES = ["Country", "HouseholdType", "Head_EducationLevel", "HFIAS_status"]
FEATURES = NUMERIC_FEATURES + CATEGORICAL_FEATURES

MIN_NEW_ROWS = 10
MAX_UPLOAD_BYTES = 20 * 1024 * 1024

router = APIRouter()
retrain_lock = Lock()


def load_and_predict(row, model_path=MODEL_PATH):
    """Load the saved pipeline and predict the target (same function as the notebook).

    The file is read on every call, so /predict uses a retrained model at once.
    """
    loaded_model = joblib.load(model_path)
    return float(loaded_model.predict(row)[0])


def clean_data(frame):
    """Apply the same cleaning rules as the notebook."""
    data = frame[FEATURES + [TARGET]].copy()
    for column in NUMERIC_FEATURES + [TARGET]:
        data[column] = pd.to_numeric(data[column])  # raises ValueError on text

    data = data.dropna(subset=[TARGET])
    data = data[data[TARGET].between(100, 50000)]
    data = data[data["HHsizemembers"].between(1, 30)]
    land = data["LandCultivated"]
    data = data[land.between(0, 50) | land.isna()]
    data = data[data["LivestockHoldings"].between(0, 50)].copy()

    for column in CATEGORICAL_FEATURES:
        data[column] = data[column].astype(object).where(data[column].notna(), float("nan"))
    return data


@router.post("/retrain")
def retrain(file: UploadFile = File(..., description="CSV with the training columns")):
    """Upload a CSV: the model is refitted on the original data plus the new rows."""
    if not (file.filename or "").lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Upload a .csv file.")
    if file.size is not None and file.size > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="The file is larger than 20 MB.")

    try:
        uploaded = pd.read_csv(file.file, low_memory=False)
    except (ValueError, UnicodeDecodeError) as exc:
        raise HTTPException(status_code=400, detail=f"Could not read the CSV: {exc}") from exc

    missing = [c for c in FEATURES + [TARGET] if c not in uploaded.columns]
    if missing:
        raise HTTPException(status_code=422, detail=f"Missing columns: {missing}")

    try:
        new_rows = clean_data(uploaded)
    except (ValueError, TypeError) as exc:
        raise HTTPException(status_code=422, detail=f"A numeric column contains text: {exc}") from exc
    if len(new_rows) < MIN_NEW_ROWS:
        raise HTTPException(
            status_code=422,
            detail=f"Only {len(new_rows)} usable rows after cleaning; at least {MIN_NEW_ROWS} are needed.",
        )

    # One retraining at a time, so two uploads cannot overwrite each other.
    with retrain_lock:
        original = clean_data(pd.read_csv(DATA_PATH, low_memory=False))
        combined = pd.concat([original, new_rows], ignore_index=True)

        # The best model is a random forest, which has no partial_fit, so it is
        # refitted from scratch with the same settings.
        new_model = clone(joblib.load(MODEL_PATH))
        new_model.fit(combined[FEATURES], combined[TARGET])

        # Write to a temporary file and swap it in, so /predict never reads a
        # half-written model.
        temporary_path = MODEL_PATH.with_suffix(".tmp")
        joblib.dump(new_model, temporary_path, compress=3)
        temporary_path.replace(MODEL_PATH)

    return {
        "message": "Model retrained and now in use.",
        "rows_uploaded": len(uploaded),
        "new_rows_used": len(new_rows),
        "total_training_rows": len(combined),
    }
