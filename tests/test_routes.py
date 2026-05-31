def test_home(client):
    r = client.get("/")
    assert r.status_code == 200
    assert b"Michael Ball" in r.data


def test_music_lists_all_mixes(client):
    r = client.get("/music")
    assert r.status_code == 200
    assert b"spooky town III" in r.data


def test_music_filters_by_tag(client):
    r = client.get("/music?tags=halloween")
    assert r.status_code == 200
    assert b"spooky town III" in r.data  # has the halloween tag
    assert b"bavarian bluebird" not in r.data  # does not


def test_music_two_tags_disables_further_tags(client):
    r = client.get("/music?tags=house,techno")
    assert r.status_code == 200
    assert b"tag disabled" in r.data


def test_add_tag_redirects_to_music(client):
    r = client.get("/add_tag?tag=house")
    assert r.status_code == 302
    assert "tags=house" in r.headers["Location"]


def test_remove_tag_without_tags_param_does_not_500(client):
    # Regression: previously raised AttributeError -> 500.
    r = client.get("/remove_tag?tag=house")
    assert r.status_code == 302


def test_remove_tag_keeps_remaining_tag(client):
    r = client.get("/remove_tag?tag=house&tags=house,jazz")
    assert r.status_code == 302
    assert "tags=jazz" in r.headers["Location"]


def test_cv_is_pdf(client):
    r = client.get("/cv")
    assert r.status_code == 200
    assert r.headers["Content-Type"] == "application/pdf"


def test_thesis_is_pdf(client):
    r = client.get("/thesis")
    assert r.status_code == 200
    assert r.headers["Content-Type"] == "application/pdf"


def test_unknown_path_renders_branded_404(client):
    r = client.get("/does-not-exist")
    assert r.status_code == 404
    assert b"Head home" in r.data


def test_security_headers_present(client):
    r = client.get("/")
    assert r.headers["X-Content-Type-Options"] == "nosniff"
    assert "Referrer-Policy" in r.headers
    assert "X-Frame-Options" in r.headers
