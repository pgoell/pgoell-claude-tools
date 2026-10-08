# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6"]
# ///
"""Fill an edition's weather from Open-Meteo when the edition has none.

Reads `weather:` in config/topics.yaml (place, latitude, longitude) and, when
<newspaper>/<date>.json has `weather: null`, asks Open-Meteo's free forecast
API (no key) for that day and writes `{place, summary, high_c, low_c}` back
into the JSON. A weather block already in the JSON is left alone, and
`weather: null` in topics.yaml turns the box off. This is the one network
request the scripts make, and only when an edition is being built.
"""

import json
import sys
import urllib.error
import urllib.parse
import urllib.request

import yaml
from common import base_parser, newspaper_dir, today

DEFAULT = {"place": "Gelnhausen", "latitude": 50.2019, "longitude": 9.1912}
API = "https://api.open-meteo.com/v1/forecast"

# WMO weather interpretation codes, as Open-Meteo documents them, in German
# because the weather box sits in the German chrome of the page.
WMO = {
    0: "Klar und sonnig",
    1: "Überwiegend sonnig",
    2: "Wechselnd bewölkt",
    3: "Bedeckt",
    45: "Nebel",
    48: "Nebel mit Reif",
    51: "Leichter Nieselregen",
    53: "Nieselregen",
    55: "Starker Nieselregen",
    56: "Gefrierender Nieselregen",
    57: "Gefrierender Nieselregen",
    61: "Leichter Regen",
    63: "Regen",
    65: "Starker Regen",
    66: "Gefrierender Regen",
    67: "Gefrierender Regen",
    71: "Leichter Schneefall",
    73: "Schneefall",
    75: "Starker Schneefall",
    77: "Schneegriesel",
    80: "Einzelne Regenschauer",
    81: "Regenschauer",
    82: "Heftige Regenschauer",
    85: "Schneeschauer",
    86: "Starke Schneeschauer",
    95: "Gewitter",
    96: "Gewitter mit Hagel",
    99: "Schwere Gewitter mit Hagel",
}


def forecast(lat: float, lon: float, day: str) -> dict:
    query = urllib.parse.urlencode(
        {
            "latitude": lat,
            "longitude": lon,
            "daily": "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max",
            "timezone": "Europe/Berlin",
            "start_date": day,
            "end_date": day,
        }
    )
    with urllib.request.urlopen(f"{API}?{query}", timeout=20) as response:
        daily = json.load(response)["daily"]
    summary = WMO.get(daily["weather_code"][0], "Wetter unbestimmt")
    rain = daily.get("precipitation_probability_max", [None])[0]
    if rain is not None and rain >= 30:
        summary += f", Regenrisiko {rain} %"
    return {
        "summary": summary,
        "high_c": round(daily["temperature_2m_max"][0]),
        "low_c": round(daily["temperature_2m_min"][0]),
    }


def main() -> None:
    args = base_parser(__doc__.splitlines()[0]).parse_args()
    day = (args.date or today()).isoformat()
    folder = newspaper_dir(args.vault, args.periodic)
    path = folder / f"{day}.json"

    topics = yaml.safe_load((folder / "config" / "topics.yaml").read_text()) or {}
    if "weather" in topics and topics["weather"] is None:
        print("weather: off in topics.yaml")
        return
    place = {**DEFAULT, **(topics.get("weather") or {})}

    edition = json.loads(path.read_text())
    if edition.get("weather"):
        print("weather: already set, left alone")
        return
    try:
        edition["weather"] = {"place": place["place"], **forecast(place["latitude"], place["longitude"], day)}
    except (urllib.error.URLError, TimeoutError, KeyError, IndexError, TypeError) as error:
        # A morning without a weather box beats a morning without a paper.
        print(f"warning: no weather from Open-Meteo ({error}); weather stays null", file=sys.stderr)
        return
    path.write_text(json.dumps(edition, ensure_ascii=False, indent=2) + "\n")
    print(f"weather: {edition['weather']}")


if __name__ == "__main__":
    main()
