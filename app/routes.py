from flask import Blueprint, current_app, redirect, render_template, request, send_from_directory, url_for
from flask.typing import ResponseReturnValue

from app.music import MIXES

bp = Blueprint("main", __name__)

MAX_TAGS = 2


def _parse_tags(raw: str | None) -> list[str]:
    return [tag for tag in (raw or "").split(",") if tag]


@bp.get("/")
def home() -> str:
    return render_template("home.html")


@bp.get("/music")
def music() -> str:
    tags = _parse_tags(request.args.get("tags"))
    mixes = [mix for mix in MIXES if all(tag in mix["tags"] for tag in tags)]
    return render_template("music.html", mixes=mixes, tags=tags, no_more_tags=len(tags) >= MAX_TAGS)


@bp.get("/add_tag")
def add_tag() -> ResponseReturnValue:
    tag = request.args.get("tag", "")
    tags = _parse_tags(request.args.get("tags"))
    if tag and tag not in tags:
        tags.append(tag)
    return redirect(url_for("main.music", tags=",".join(tags)))


@bp.get("/remove_tag")
def remove_tag() -> ResponseReturnValue:
    tag = request.args.get("tag", "")
    tags = [t for t in _parse_tags(request.args.get("tags")) if t != tag]
    kwargs = {"tags": ",".join(tags)} if tags else {}
    return redirect(url_for("main.music", **kwargs))


@bp.get("/cv")
def cv() -> ResponseReturnValue:
    return send_from_directory(current_app.static_folder, "documents/michael_ball_CV.pdf")


@bp.get("/thesis")
def thesis() -> ResponseReturnValue:
    return send_from_directory(current_app.static_folder, "documents/michael_ball_thesis.pdf")
