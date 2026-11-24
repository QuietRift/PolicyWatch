import json
import os
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
 
from city_directory import build_directory, kind, run
 
HEADER = ("Domain name,Domain type,Organization name,Suborganization name,"
          "City,State,Security contact email\n")
 
 
def sheet(*rows):
    return HEADER + "".join(",".join(row) + "\n" for row in rows)
 
 
class CityTests(unittest.TestCase):
    def test_groups_one_government_and_drops_email(self):
        raw = sheet(
            ("detroitmi.gov", "City", "City of Detroit - ITSD", "", "Detroit", "MI", "a@x.org"),
            ("detroit.gov", "City", "City of Detroit", "", "Detroit", "MI", "b@x.org"),
            ("ohio.gov", "State or territory", "State of Ohio", "", "Columbus", "OH", "c@x.org"),
        )
        result = build_directory(raw, "MI", "t")
        self.assertEqual(result["count"], 1)
        detroit = result["cities"][0]
        self.assertEqual(detroit["primary"], "detroit.gov")
        self.assertEqual(len(detroit["domains"]), 2)
        self.assertNotIn("@", json.dumps(result))
 
    def test_same_name_in_two_counties_stays_separate(self):
        raw = sheet(
            ("berlintwpioniami.gov", "City", "Berlin Township", "", "Ionia", "MI", ""),
            ("berlintwpstclairmi.gov", "City", "Berlin Township", "", "Allenton", "MI", ""),
        )
        self.assertEqual(build_directory(raw, "MI", "t")["count"], 2)
 
    def test_kinds(self):
        self.assertEqual(kind("City of Detroit"), "City")
        self.assertEqual(kind("Village of Leonard"), "Village")
        self.assertEqual(kind("Addison Townhsip"), "Township")
        self.assertEqual(kind("Kalamazoo Public Library"), "Other")
        self.assertEqual(kind("City of Roseville Police Department"), "Other")
 
    def test_bad_columns_rejected(self):
        with self.assertRaises(ValueError):
            build_directory("a,b\n1,2\n", "MI", "t")
 
    def test_empty_result_keeps_previous_file(self):
        with TemporaryDirectory() as root:
            previous = os.getcwd()
            try:
                os.chdir(root)
                good = Path("good.csv")
                good.write_text(sheet(("leonardmi.gov", "City", "Village of Leonard", "",
                                       "Leonard", "MI", "")))
                run("MI", str(good))
                saved = Path("cities-MI.json").read_bytes()
                empty = Path("empty.csv")
                empty.write_text(HEADER)
                with self.assertRaises(ValueError):
                    run("MI", str(empty))
                self.assertEqual(saved, Path("cities-MI.json").read_bytes())
            finally:
                os.chdir(previous)
 
 
if __name__ == "__main__":
    unittest.main()
