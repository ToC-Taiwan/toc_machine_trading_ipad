import json
import os
from datetime import datetime

import yaml
from yaml.loader import SafeLoader

current_build = str()
current_build_number = int()

with open("pubspec.yaml") as f:
    data = yaml.load(f, Loader=SafeLoader)
    wrods = data["version"].split("+")
    if len(wrods) != 2:
        raise Exception("version format error")

    current_build = wrods[0]
    current_build_number = int(wrods[1])

data: list[dict] = []
if os.stat("./data/build.json").st_size != 0:
    with open("./data/build.json") as f:
        data = json.load(f)


with open("./data/build.json", "w") as outfile:
    tmp = {
        "build_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "version": current_build,
        "build_number": current_build_number + 1,
    }
    data.append(tmp)
    outfile.write(f"{json.dumps(data, indent=4)}\n")
