from flask import render_template

from app import app


@app.route("/", methods=["GET"])
def home():
    return render_template("home.html")


@app.route("/mixes", methods=["GET"])
def mixes():
    return render_template("mixes.html")


@app.route("/movies", methods=["GET"])
def movies():
    return render_template("movies.html")
