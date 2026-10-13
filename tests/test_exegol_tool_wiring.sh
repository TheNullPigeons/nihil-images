#!/bin/bash
set -eu

cd "$(dirname "$0")/.."

python - <<'PY'
import json

expected = {
    "adwsdomaindump": "adwsdomaindump",
    "EVENmonitor": "EVENmonitor",
    "gpoParser": "gpoParser",
    "pyGoldenGMSA": "pyGoldenGMSA",
    "RelayInformer": "relayinformer",
    "snaffler-ng": "snaffler",
    "SOAPy": "SOAPy",
    "badsecrets": "badsecrets",
    "pacu": "pacu",
}
tools = {
    tool["name"]: tool.get("cmd")
    for group in json.load(open("build/config/tools.json")).values()
    for tool in group
}
assert {name: tools.get(name) for name in expected} == expected
PY

for history in adwsdomaindump evenmonitor gpoParser pyGoldenGMSA relayinformer snaffler SOAPy badsecrets pacu; do
    test -s "build/config/history.d/$history"
done
