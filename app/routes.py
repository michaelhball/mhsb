from flask import render_template

from app import app
from app.mixes import MIXES


@app.route("/", methods=["GET"])
def home():
    return render_template("home.html")


@app.route("/mixes", methods=["GET"])
def mixes():
    return render_template("mixes.html", mixes=MIXES)


@app.route("/movies", methods=["GET"])
def movies():
    return render_template("movies.html")
