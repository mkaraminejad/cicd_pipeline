from flask import Flask, request, render_template
import requests
import os

app = Flask(__name__)

API_KEY = os.environ.get("API_KEY") or "7d1d9790927298a60291acc7abd0e847"
BASE_URL = "http://api.openweathermap.org/data/2.5/weather"

@app.route("/", methods=["GET", "POST"])
def index():
    weather = {}
    if request.method == "POST":
        city = request.form.get("city")
        params = {"q": city, "appid": API_KEY, "units": "metric"}
        response = requests.get(BASE_URL, params=params)
        if response.status_code == 200:
            data = response.json()
            weather = {
                "city": city,
                "temperature": data["main"]["temp"],
                "description": data["weather"][0]["description"].title(),
                "icon": data["weather"][0]["icon"],
            }
        else:
            weather["error"] = "City not found"
    return render_template("index.html", weather=weather)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

