# NutriWise Flutter app

A one-page Flutter app that calls the NutriWise FastAPI `/predict` endpoint.

## 1. Configure the API URL

Open `lib/api_config.dart` and replace:

```dart
https://YOUR-RENDER-SERVICE.onrender.com
```

with your actual Render service URL. Do not add `/docs` or `/predict`.

## 2. Create / run the Flutter project

Install Flutter and verify the setup:

```bash
flutter doctor
```

This download contains the app source (`lib/`) and package configuration, not the generated Android/iOS platform folders. From this folder, generate the Flutter platform scaffolding once, then fetch packages:

```bash
flutter create . --platforms=android,ios
flutter pub get
flutter run
```

On Windows, you can build and run the Android app. Building an iOS app requires macOS with Xcode.

## 3. Test

The form sends all 10 required fields to `POST /predict`. The categorical dropdowns use the NHANES codes expected by the model. A successful response should contain `predicted_day1_kcal`, `unit`, `interpretation`, and `model`.

## Input fields

- `RIDAGEYR`: age in years
- `DMDHHSIZ`: household size
- `INDFMPIR`: family income-to-poverty ratio
- `BMXHT`: height in cm
- `BMXWT`: weight in kg
- `BMXBMI`: BMI
- `BMXWAIST`: waist circumference in cm
- `RIAGENDR`: gender code 1 or 2
- `RIDRETH3`: race/ethnicity code 1, 2, 3, 4, 6 or 7
- `DMDEDUC2`: education code 1–5

## Important interpretation

`DR1TKCAL` is reported energy intake from one Day 1 24-hour dietary recall. It is not a recommended calorie target or medical advice. The training dataset is US NHANES 2021–2023; do not assume the model generalizes to Rwanda without validation on representative local data.
