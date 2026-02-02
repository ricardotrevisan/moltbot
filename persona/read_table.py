#!/usr/bin/env python3
# read_table.py
# Usage:
#   python3 read_table.py --host postgres_n8n --port 5432 --db openclaw --user openclawdb --password 'd1mens10n' --table teste_openclaw --format csv
# Formats: csv | table

import argparse
import csv
import sys
import psycopg2
from psycopg2.extras import RealDictCursor
from tabulate import tabulate

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--host", required=True)
    p.add_argument("--port", type=int, default=5432)
    p.add_argument("--db", required=True)
    p.add_argument("--user", required=True)
    p.add_argument("--password", required=True)
    p.add_argument("--table", required=True)
    p.add_argument("--format", choices=["csv","table"], default="table")
    args = p.parse_args()

    conn = psycopg2.connect(
        host=args.host,
        port=args.port,
        dbname=args.db,
        user=args.user,
        password=args.password,
        connect_timeout=10
    )

    with conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(f"SELECT * FROM {args.table};")
            rows = cur.fetchall()

    if args.format == "csv":
        if not rows:
            sys.exit(0)
        writer = csv.DictWriter(sys.stdout, fieldnames=rows[0].keys())
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    else:
        if not rows:
            print("(no rows)")
            return
        print(tabulate([list(r.values()) for r in rows], headers=list(rows[0].keys()), tablefmt="github"))

if __name__ == "__main__":
    main()
