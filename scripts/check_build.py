#!/opt/homebrew/bin/python3

import json

import yaml
from yaml.loader import SafeLoader

last_build_number = int()

with open("./data/build.json") as f:
    data = json.load(f)

last_build_number = int(data[len(data) - 1]["build_number"])

with open("pubspec.yaml") as f:
    data = yaml.load(f, Loader=SafeLoader)
    wrods = data["version"].split("+")
    if len(wrods) != 2:
        raise Exception("version format error")

    if int(wrods[1]) < last_build_number:
        raise Exception("build number not changed")
