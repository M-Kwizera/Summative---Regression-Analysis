"""NutriWise API: predicts household food availability (kcal per adult per day)."""
from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field

from retrain import FEATURES, MODEL_PATH, load_and_predict, router as retrain_router

app = FastAPI(title="NutriWise API")

# CORS decides which websites may call this API from a browser.
# Allowed: our own Render site (Swagger UI) and the local Flutter web debug
#   address (flutter run -d chrome --web-port 8080). No wildcard, so other
#   websites cannot read our responses in a visitor's browser.
# Methods: only GET (docs) and POST (predict, retrain), the ones we use.
# Headers: only Content-Type, needed to send JSON and file uploads.
# Credentials: off, because the API uses no cookies or logins.
# The mobile app is not a browser, so CORS does not restrict it.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://nutriwise-api-tc0r.onrender.com",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ],
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
    allow_credentials=False,
)

app.include_router(retrain_router)

# Load once at startup so a missing or broken model file fails immediately.
joblib.load(MODEL_PATH)


class PredictionInput(BaseModel):
    # strict: "5" (text) is not accepted as a number. forbid: no unknown fields.
    model_config = ConfigDict(
        strict=True,
        extra="forbid",
        json_schema_extra={
            "example": {
                "HHsizemembers": 6, "LandCultivated": 2.0, "LivestockHoldings": 1.5,
                "NrofMonthsFoodInsecure": 2, "NrofMonthsWildFoodCons": 0,
                "Gender_FemaleControl": 0.3, "Country": "Kenya",
                "HouseholdType": "couple", "Head_EducationLevel": "primary",
                "HFIAS_status": "ModeratelyFI",
            }
        },
    )

    HHsizemembers: int = Field(ge=1, le=30, description="People in the household")
    LandCultivated: float = Field(ge=0, le=50, description="Land cultivated (hectares)")
    LivestockHoldings: float = Field(ge=0, le=50, description="Livestock (tropical livestock units)")
    NrofMonthsFoodInsecure: int = Field(ge=0, le=12, description="Food-insecure months per year")
    NrofMonthsWildFoodCons: int = Field(ge=0, le=12, description="Months per year eating wild foods")
    Gender_FemaleControl: float = Field(ge=0, le=1, description="Share controlled by women (0 to 1)")
    Country: Literal[
        "Burkina_Faso", "Burundi", "DRC", "Ethiopia", "Ghana", "Kenya",
        "Malawi", "Mali", "Tanzania", "Uganda", "Zambia",
    ]
    HouseholdType: Literal[
        "couple", "couple_man_works_away", "couple_woman_works_away", "man_single",
        "woman_single", "single", "together", "polygamous", "workaway",
        "nonparenthead", "other",
    ]
    Head_EducationLevel: Literal[
        "primary", "secondary", "postsecondary", "no_school", "illiterate",
        "literate", "adult_education", "religious_school", "islamic_school", "informal",
    ]
    HFIAS_status: Literal["FoodSecure", "MildlyFI", "ModeratelyFI", "SeverelyFI"] = Field(
        description="Food insecurity (FI) status"
    )


class PredictionOutput(BaseModel):
    predicted_kcal_per_adult_per_day: float


@app.post("/predict", response_model=PredictionOutput)
def predict(payload: PredictionInput):
    """Return the predicted food availability for one household."""
    row = pd.DataFrame([payload.model_dump()])[FEATURES]
    return PredictionOutput(predicted_kcal_per_adult_per_day=round(load_and_predict(row), 1))
