import json
import os
import unittest
from io import BytesIO
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
from urllib.error import HTTPError
 
from fec_sample import build, normalize
 
 
class FederalTests(unittest.TestCase):
     committee = "C00000001"
 
     def test_duplicate_and_missing_amount(self):
         row = {"committee_id": self.committee, "sub_id": "11"}
         sample = normalize({"results": [row, row]}, self.committee, 2024, "2026-04-15")
         self.assertEqual(len(sample["rows"]), 1)
         self.assertIsNone(sample["rows"][0]["amount"])
         changed = dict(row, contribution_receipt_amount=25)
         with self.assertRaises(ValueError):
             normalize({"results": [row, changed]}, self.committee, 2024, "t")
 
     def test_rate_limit_preserves_snapshot(self):
         with TemporaryDirectory() as root, patch.dict(os.environ, FEC_API_KEY="test"):
             previous = os.getcwd()
             try:
                 os.chdir(root)
                 empty = BytesIO(json.dumps({"results": []}).encode())
                 with patch("fec_sample.urlopen", return_value=empty):
                     build(self.committee, 2024)
                 path = Path("sample-" + self.committee + "-2024.json")
                 saved = path.read_bytes()
                 error = HTTPError("test", 429, "limit", {}, None)
                 with patch("fec_sample.urlopen", side_effect=error):
                     with self.assertRaises(HTTPError):
                         build(self.committee, 2024)
                 self.assertEqual(saved, path.read_bytes())
                 self.assertEqual(len(list(Path("snapshots").iterdir())), 1)
             finally:
                 os.chdir(previous)
 
 
if __name__ == "__main__":
     unittest.main()
