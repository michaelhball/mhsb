from flask import redirect, render_template, request, send_from_directory, url_for

from app import app
from app.music import MIXES


@app.route("/", methods=["GET"])
def home():
    return render_template("home.html")


@app.route("/remove_tag", methods=["GET"])
def remove_tag():
    tag = request.args.get("tag")
    tags = request.args.get("tags").split(",")
    tags = [t for t in tags if t != tag]
    kwargs = {} if len(tags) == 0 else {"tags": ",".join(tags)}
    return redirect(url_for("music", **kwargs))


@app.route("/add_tag", methods=["GET"])
def add_tag():
    tag = request.args.get("tag")
    tags = [] if "tags" not in request.args else request.args.get("tags").split(",")
    tags = [t for t in tags if t != ""]
    if tag not in tags:
        tags.append(tag)
    return redirect(url_for("music", tags=",".join(tags)))


@app.route("/music", methods=["GET", "POST"])
def music():
    tags = [] if "tags" not in request.args else request.args.get("tags").split(",")
    tags = [t for t in tags if t != ""]
    mixes = [m for m in MIXES if all(tag in m["tags"] for tag in tags)]
    return render_template("music.html", mixes=mixes, tags=tags, no_more_tags=len(tags) == 2)


@app.route("/movies", methods=["GET"])
def movies():
    return render_template("movies.html")


@app.get("/cv")
def cv():
    return send_from_directory(app.static_folder, "documents/michael_ball_CV.pdf")


@app.get("/thesis")
def thesis():
    return send_from_directory(app.static_folder, "documents/michael_ball_thesis.pdf")
