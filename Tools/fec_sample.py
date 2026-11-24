"""Build one bounded OpenFEC Schedule A sample on your Mac (never in the app).
 
Usage: FEC_API_KEY=your_key python3 fec_sample.py C00000000 2024
Verify parameter and field names against https://api.open.fec.gov/developers/
"""
import datetime as dt
import hashlib
import json
import os
import re
import sys
from pathlib import Path
from tempfile import NamedTemporaryFile
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import urlopen
 
 
def normalize(raw, committee, cycle, captured):
     rows = {}
     for item in raw["results"]:
         if item.get("committee_id") != committee:
             raise ValueError("Unexpected committee ID")
         key = item.get("sub_id")
         if key is None:
             raise ValueError("Missing FEC row ID")
         row = dict(
             id=str(key),
             payer=item.get("contributor_name") or "Payer undisclosed",
             day=(item.get("contribution_receipt_date") or "Date undisclosed")[:10],
             filing=str(item.get("file_number") or "unavailable"),
             amount=item.get("contribution_receipt_amount"),
             link=item.get("pdf_url"),
         )
         if key in rows and row != rows[key]:
             raise ValueError("Conflicting duplicate row")
         rows[key] = row
     return dict(committee=committee, cycle=cycle, captured=captured,
                 rows=list(rows.values()))
 
 
def build(committee, cycle):
     if not re.fullmatch(r"C[0-9]{8}", committee) or cycle % 2:
         raise ValueError("Use an FEC committee ID and an even cycle year")
     query = urlencode(dict(
         api_key=os.environ["FEC_API_KEY"],
         committee_id=committee,
         two_year_transaction_period=cycle,
         per_page=20,
         sort="-contribution_receipt_date",
     ))
     url = "https://api.open.fec.gov/v1/schedules/schedule_a/?" + query
     with urlopen(url, timeout=25) as response:
         payload = response.read()
     digest = hashlib.sha256(payload).hexdigest()
     archive = Path("snapshots")
     archive.mkdir(exist_ok=True)
     target = archive / (digest + ".json")
     try:
         with target.open("xb") as output:
             output.write(payload)
     except FileExistsError:
         pass
     stamp = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
     sample = normalize(json.loads(payload), committee, cycle, stamp)
     sample["snapshot_id"] = digest
     out = Path("sample-" + committee + "-" + str(cycle) + ".json")
     with NamedTemporaryFile("w", dir=".", delete=False) as tmp:
         json.dump(sample, tmp, indent=2)
     Path(tmp.name).replace(out)
     print(out)
 
 
if __name__ == "__main__":
     try:
         build(sys.argv[1], int(sys.argv[2]))
     except HTTPError as error:
         hint = error.headers.get("Retry-After", "later")
         if error.code == 429:
             sys.exit("Rate limit. Retry " + hint + ". Keep the saved sample.")
         sys.exit("FEC HTTP " + str(error.code) + ". Keep the saved sample.")
     except (OSError, URLError, KeyError, ValueError, IndexError) as error:
         sys.exit("Import failed (" + type(error).__name__
                  + "). Check the key, connection, ID, cycle and response.")

