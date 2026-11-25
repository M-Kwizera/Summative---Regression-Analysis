# Summative — Regression Analysis


## Repository structure

```
summative/
├── pyproject.toml
├── uv.lock
├── linear_regression/
│   └── multivariate.ipynb      
├── API/
│   ├── prediction.py             
│   ├── requirements.txt          
│   └── best_model.pkl           
└── FlutterApp/
    └── student_gpa_app/          
```

```
cd summative/API
uv run uvicorn prediction:app --reload
# Swagger UI → http://localhost:8000/docs
```
