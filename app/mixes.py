def _get_url(id: str, color: str) -> str:
    return f"https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/{id}&color=%23{color}&inverse=false&auto_play=false&show_user=false&show_artwork=false&show_playcount=false"


MIXES = [
    {"url": _get_url(m["id"], m["color"]), **m}
    for m in [
        {
            "id": "1653656613",
            "color": "36341e",
            "name": "spooky town III",
            "date": "Oct. 31 2023",
            "image_url": "/static/images/spooky_town_iii.jpeg",
            "tags": ["spooky", "halloween", "house", "techno"],
        },
        {
            "id": "1546245496",
            "color": "80902c",
            "name": "afternoon underexertion",
            "date": "Jun. 19 2023",
            "image_url": "/static/images/afternoon_under_exertion.png",
            "tags": ["autumn", "relax", "house"],
        },
        {
            "id": "1503987556",
            "color": "f7ed46",
            "name": "silly season",
            "date": "May 1 2023",
            "image_url": "/static/images/silly_season.jpeg",
            "tags": ["funk", "sunshine", "silly", "house"],
        },
        {
            "id": "1455510700",
            "color": "ff5500",
            "name": "fled's fifty",
            "date": "Feb. 24 2023",
            "image_url": "/static/images/fleds_fifty.jpeg",
            "tags": ["jazz", "hip-hop", "downtempo", "funk"],
        },
        {
            "id": "1367528887",
            "color": "847850",
            "name": "slow your circulation",
            "date": "Oct. 21 2022",
            "image_url": "/static/images/slow_your_circulation.jpeg",
            "tags": ["float", "dub", "jazz", "downtempo", "blues"],
        },
    ]
]
