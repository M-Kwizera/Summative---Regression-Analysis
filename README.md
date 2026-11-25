# NutriWise: Food Availability Prediction

## Mission and problem
My mission is to use machine learning to educate people in Rwanda about diet, for the betterment of their lives.
Nutrition educators cannot easily tell which farm households are short of food.
This project predicts a household's available food energy (kcal per adult per day), to show whom to support first.
It is trained on 11 African countries, including Rwanda's neighbours, and needs checking with Rwandan data.

## Dataset
The Rural Household Multiple Indicator Survey (RHoMIS) is a real survey of farm households, released under a CC0 public-domain licence. This project uses its 11,010 households from 11 African countries, surveyed from 2015 to 2018. After cleaning, 9,479 households remain. The model uses 10 input features (6 numeric and 4 categorical) to predict `Food_Availability_kCal_MAE_day`.

Source: [RHoMIS on Harvard Dataverse](https://doi.org/10.7910/DVN/9M6EHS)

## Public API (Swagger UI)
https://nutriwise-africa-api.onrender.com/docs

The free Render service sleeps when idle, so the first request can take up to a minute.

## Video demo
https://www.youtube.com/watch?v=nIzCqlpHqGg

## Run the mobile app
You need [Flutter](https://docs.flutter.dev/get-started/install), Git, and an Android emulator or phone. The app calls the public API, so no local server is needed.

1. Clone the repository and open the app folder:
   ```bash
   git clone https://github.com/M-Kwizera/linear_regression_model.git
   cd linear_regression_model/summative/FlutterApp/nutriwise
   ```
2. Install the packages:
   ```bash
   flutter pub get
   ```
3. Start an emulator, or connect a phone with USB debugging on:
   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```
4. Find the device ID and run the app:
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
