"""Unit tests for the tag-parsing helper (pure logic, no app needed)."""

from app.routes import _parse_tags


def test_parse_tags_none_returns_empty():
    assert _parse_tags(None) == []


def test_parse_tags_empty_string_returns_empty():
    assert _parse_tags("") == []


def test_parse_tags_splits_on_comma():
    assert _parse_tags("house,techno") == ["house", "techno"]


def test_parse_tags_drops_empty_segments():
    assert _parse_tags("house,,techno,") == ["house", "techno"]


def test_parse_tags_single():
    assert _parse_tags("house") == ["house"]
