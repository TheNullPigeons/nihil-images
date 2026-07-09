#!/usr/bin/env python3
"""Import BloodHound Legacy custom queries into BloodHound CE (PostgreSQL)."""

import json
import os
import sys
import subprocess

QUERIES_FILE = "/opt/nihil/build/assets/bloodhound-customqueries.json"
PG_PORT = "5433"
PG_DB = "bloodhound"
PG_USER = "postgres"


def run_psql(sql):
    result = subprocess.run(
        ["su", "-s", "/bin/bash", PG_USER, "-c", f"psql -p {PG_PORT} -d {PG_DB}"],
        input=sql, capture_output=True, text=True
    )
    return result.returncode == 0, result.stderr


def main():
    if not os.path.exists(QUERIES_FILE):
        print(f"  ✗ {QUERIES_FILE} not found", file=sys.stderr)
        sys.exit(1)

    with open(QUERIES_FILE) as f:
        data = json.load(f)

    queries = data.get("queries", [])
    imported = 0
    skipped = 0

    for q in queries:
        name = q.get("name", "").replace("'", "''")
        category = q.get("category", "").replace("'", "''")
        full_name = f"{category} - {name}" if category else name

        query_list = q.get("queryList", [])
        if not query_list:
            continue
        cypher = query_list[-1].get("query", "").replace("'", "''")
        if not cypher:
            continue

        sql = (
            f"INSERT INTO saved_queries (user_id, name, query, description, created_at, updated_at) "
            f"VALUES (NULL, '{full_name}', '{cypher}', '{category}', NOW(), NOW()) "
            f"ON CONFLICT (user_id, name) DO NOTHING;"
        )
        ok, err = run_psql(sql)
        if ok:
            imported += 1
        else:
            skipped += 1

    print(f"  ✓ BloodHound CE: {imported} custom queries imported ({skipped} skipped)")


if __name__ == "__main__":
    main()
