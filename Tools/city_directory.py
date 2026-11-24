"""Build the Policy Watch city directory from the .gov registry on your Mac (never in the app).
Usage: python3 city_directory.py MI      (one state, two-letter code)
       python3 city_directory.py ALL     (every state)
Optional: --csv path/to/current-full.csv to use a file you already downloaded.
Source: https://github.com/cisagov/dotgov-data (CC0 1.0, public domain)
"""
import datetime as dt
import hashlib
import io
import json
import re
import sys
from pathlib import Path
from tempfile import NamedTemporaryFile
from urllib.error import HTTPError, URLError
from urllib.request import urlopen
 
import csv
 
SOURCE = "https://raw.githubusercontent.com/cisagov/dotgov-data/main/current-full.csv"
COLUMNS = {"Domain name", "Domain type", "Organization name", "City", "State"}
DOMAIN = re.compile(r"[a-z0-9-]+\.gov")
 
 
def org_key(name):
    """'City of Detroit - ITSD' and 'City of Detroit' are the same government."""
    name = name.split(" - ")[0].lower()
    name = re.sub(r"[^a-z0-9 ]", " ", name)
    return " ".join(name.split())
 
 
def kind(name):
    """City, Village, Township or Other. Other covers libraries, police and offices."""
    key = org_key(name)
    if re.search(r"\b(library|police|marshal|court|clerk|fire|department|authority)\b", key):
        return "Other"
    if re.search(r"\btown(ship|hsip)?\b|\btwp\b", key):
        return "Township"
    if re.search(r"\bvillage\b", key):
        return "Village"
    if re.search(r"\bcity\b", key):
        return "City"
    return "Other"
 
 
def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
 
 
def build_directory(raw_csv, state, captured):
    reader = csv.DictReader(io.StringIO(raw_csv))
    if not COLUMNS.issubset(reader.fieldnames or []):
        raise ValueError("Unexpected CSV columns")
    groups = {}
    for row in reader:
        if row["Domain type"] != "City":
            continue
        where = row["State"].strip().upper()
        if state != "ALL" and where != state:
            continue
        domain = row["Domain name"].strip().lower()
        org = " ".join(row["Organization name"].split())
        if not DOMAIN.fullmatch(domain) or not org:
            continue
        mailing = row["City"].strip()
        # Same-named townships exist in different counties, so the mailing city is part of the key.
        key = (where, org_key(org), mailing.lower())
        entry = groups.setdefault(key, dict(
            id=where + "-" + slug(key[1] + " " + mailing), name=org.split(" - ")[0],
            kind=kind(org), state=where, mailingCity=mailing, domains=[]))
        # The security contact email column is deliberately never copied.
        entry["domains"].append(dict(domain=domain, org=org))
    cities = []
    for entry in groups.values():
        entry["domains"].sort(key=lambda d: (" - " in d["org"], len(d["domain"]), d["domain"]))
        entry["primary"] = entry["domains"][0]["domain"]
        cities.append(entry)
    cities.sort(key=lambda c: (c["state"], c["name"].lower()))
    return dict(source="cisagov/dotgov-data current-full.csv", state=state,
                captured=captured, count=len(cities), cities=cities)
 
 
def run(state, csv_path=None):
    state = state.upper()
    if state != "ALL" and not re.fullmatch(r"[A-Z]{2}", state):
        raise ValueError("Use a two-letter state code or ALL")
    if csv_path:
        payload = Path(csv_path).read_bytes()
    else:
        with urlopen(SOURCE, timeout=30) as response:
            payload = response.read()
    digest = hashlib.sha256(payload).hexdigest()
    archive = Path("snapshots")
    archive.mkdir(exist_ok=True)
    try:
        with (archive / ("dotgov-" + digest + ".csv")).open("xb") as output:
            output.write(payload)
    except FileExistsError:
        pass
    stamp = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    directory = build_directory(payload.decode("utf-8-sig"), state, stamp)
    if not directory["cities"]:
        raise ValueError("No cities found for " + state)
    directory["snapshot_id"] = digest
    out = Path("cities-" + state + ".json")
    with NamedTemporaryFile("w", dir=".", delete=False) as tmp:
        json.dump(directory, tmp, indent=2)
    Path(tmp.name).replace(out)
    print(out, "·", directory["count"], "governments")
 
 
if __name__ == "__main__":
    try:
        args = sys.argv[1:]
        path = None
        if "--csv" in args:
            spot = args.index("--csv")
            path = args[spot + 1]
            del args[spot:spot + 2]
        run(args[0], path)
    except HTTPError as error:
        sys.exit("GitHub HTTP " + str(error.code) + ". Keep the saved directory.")
    except (OSError, URLError, ValueError, IndexError, UnicodeDecodeError) as error:
        sys.exit("Build failed (" + type(error).__name__
                 + "). Check the state code, connection and CSV.")

