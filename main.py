from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import os 


current_directory = os.path.dirname(__file__)
model_directory = os.path.join(current_directory, "save-model")
model_path = os.path.join(model_directory, "random-forest-ads.pkl")
# Load your model
estimator_advertising_loaded = joblib.load(model_path)

class Ads(BaseModel):
    TV: float
    Radio: float
    Newspaper: float

    class Config:
        schema_extra = {
            "example": {
                "TV": 220.4,
                "Radio": 40.3,
                "Newspaper": 66.1,
            }
        }

app = FastAPI()

@app.post("/predict/ads")
async def predict_advertising(ad: Ads):
    prediction = adv_prediction(estimator_advertising_loaded, ad.dict())
    return {"prediction": prediction}

# prediction function
def adv_prediction(model, request):
    # parse input from request
    TV = request["TV"]
    Radio = request['Radio']
    Newspaper = request['Newspaper']
    # Make an input vector
    advertising = [[TV, Radio, Newspaper]]
    # Predict
    prediction = model.predict(advertising)
    return prediction[0]
