# NutriWise: Food Availability Prediction

## Mission and problem
NutriWise aims to improve nutrition in African farming communities.
Field officers often cannot tell quickly which farm households are short of food.
This project predicts the food energy available to a household (kcal per adult per day)
from simple facts, so that officers can decide which households to visit first.

## Dataset
The Rural Household Multiple Indicator Survey (RHoMIS) is a real survey of farm households, released under a CC0 public-domain licence. This project uses its 11,010 households from 11 African countries, surveyed from 2015 to 2018, with 10 input features (6 numeric and 4 categorical). The target is `Food_Availability_kCal_MAE_day`. After cleaning, 9,479 households are used.

Source: [RHoMIS on Harvard Dataverse](https://doi.org/10.7910/DVN/9M6EHS)

## Public API (Swagger UI)
https://nutriwise-africa-api.onrender.com/docs

The free Render service sleeps when idle, so the first request can take up to a minute.

## Video demo
TODO: paste the YouTube link here

## Run the mobile app
You need [Flutter](https://docs.flutter.dev/get-started/install), Git, and an Android emulator or phone. The app calls the public API, so no local server is needed.

1. Clone the repository and open the app folder:
   ```bash
   git clone https://github.com/M-Kwizera/Summative---Regression-Analysis.git
   cd Summative---Regression-Analysis/summative/FlutterApp/nutriwise
   ```
2. Install the packages:
   ```bash
   flutter pub get
   ```
3. Start an emulator, or connect a phone with USB debugging on. To list your emulators and start one:
   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```
4. Find the device ID, then run the app on it:
   ```bash
   flutter devices
   flutter run -d <device_id>
   ```
5. Fill in the 10 fields and press **Predict**. Example values:

   | Field | Value |
   |---|---|
   | Household size | 6 |
   | Land cultivated | 2 |
   | Livestock holdings | 1.5 |
   | Food-insecure months | 2 |
   | Months eating wild foods | 0 |
   | Share controlled by women | 0.3 |
   | Country | Kenya |
   | Household type | couple |
   | Education of household head | primary |
   | Food insecurity (FI) status | ModeratelyFI |

   The prediction, or an error message for a missing or invalid value, appears under the button.
