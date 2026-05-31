"""Unit tests for the mixes content/data (app/music.py)."""

from pathlib import Path

from app.music import MIXES

APP_DIR = Path(__file__).resolve().parent.parent / "app"
REQUIRED_FIELDS = {"id", "color", "name", "date", "image_url", "tags", "url"}


def test_there_are_mixes():
    assert len(MIXES) > 0


def test_every_mix_has_required_fields():
    for mix in MIXES:
        missing = REQUIRED_FIELDS - mix.keys()
        assert not missing, f"{mix.get('name')!r} is missing {missing}"


def test_every_mix_has_nonempty_string_tags():
    for mix in MIXES:
        assert mix["tags"], f"{mix['name']!r} has no tags"
        assert all(isinstance(tag, str) and tag for tag in mix["tags"])


def test_mix_urls_are_soundcloud_embeds_for_their_id_and_color():
    for mix in MIXES:
        assert mix["url"].startswith("https://w.soundcloud.com/player/")
        assert mix["id"] in mix["url"]
        assert mix["color"] in mix["url"]


def test_mix_artwork_files_exist():
    for mix in MIXES:
        rel = mix["image_url"].lstrip("/")  # e.g. /static/images/foo.jpeg
        assert (APP_DIR / rel).is_file(), f"missing artwork for {mix['name']!r}: {rel}"
