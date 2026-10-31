import os
import glob
import json
import math
import requests
import pandas as pd
from dotenv import load_dotenv

# Load environment
load_dotenv(override=True)

SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://eexjugulmhrtjirlgqpk.supabase.co").rstrip("/")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "").strip()
REST_URL = f"{SUPABASE_URL}/rest/v1"

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates"
}

# Upload order respecting foreign key constraints
TABLE_ORDER = [
    ("categories.csv", "categories"),
    ("suppliers.csv", "suppliers"),
    ("customers.csv", "customers"),
    ("customer_risk_profile.csv", "customer_risk_profile"),
    ("employees.csv", "employees"),
    ("products.csv", "products"),
    ("inventory.csv", "inventory"),
    ("expenses.csv", "expenses"),
    ("sales_raw.csv", "sales_raw"),
    ("invoices.csv", "invoices"),
    ("pending_payments.csv", "pending_payments"),
    ("purchase_orders.csv", "purchase_orders"),
    ("approval_queue.csv", "approval_queue"),
    ("collections_interactions.csv", "collections_interactions"),
    ("growth_initiatives.csv", "growth_initiatives"),
    ("price_history.csv", "price_history"),
    ("supplier_interactions.csv", "supplier_interactions")
]

def clean_record(rec):
    cleaned = {}
    for k, v in rec.items():
        if pd.isna(v):
            cleaned[k] = None
        elif isinstance(v, (float, int)) and math.isnan(v):
            cleaned[k] = None
        else:
            cleaned[k] = v
    return cleaned

def upload_table(csv_path, table_name, chunk_size=500):
    if not os.path.exists(csv_path):
        print(f"[-] File not found: {csv_path}")
        return False

    print(f"\n[+] Loading {csv_path} -> table '{table_name}'...")
    df = pd.read_csv(csv_path)
    total_rows = len(df)
    print(f"    Total rows to upload: {total_rows}")

    records = [clean_record(r) for r in df.to_dict(orient="records")]
    
    url = f"{REST_URL}/{table_name}"
    uploaded = 0

    for i in range(0, total_rows, chunk_size):
        chunk = records[i:i + chunk_size]
        try:
            resp = requests.post(url, headers=HEADERS, json=chunk, timeout=60)
            if resp.status_code in [200, 201, 204]:
                uploaded += len(chunk)
                print(f"    Uploaded {uploaded}/{total_rows} rows ({uploaded/total_rows*100:.1f}%)")
            else:
                print(f"    [!] Error uploading batch {i}..{i+len(chunk)}: HTTP {resp.status_code}")
                print(f"        Response: {resp.text[:300]}")
                return False
        except Exception as e:
            print(f"    [!] Network error uploading batch {i}: {e}")
            return False

    # Verify count
    try:
        count_resp = requests.get(f"{url}?select=count", headers={**HEADERS, "Prefer": "count=exact"}, timeout=15)
        content_range = count_resp.headers.get("Content-Range", "")
        print(f"    [OK] Successfully verified table '{table_name}'. Content-Range: {content_range}")
    except Exception:
        pass

    return True

def main():
    print("=" * 60)
    print("  Merchant AI Box -> Supabase Data Migration Tool")
    print(f"  Target: {SUPABASE_URL}")
    print("=" * 60)

    # 1. Health check Supabase
    try:
        r = requests.get(f"{REST_URL}/", headers=HEADERS, timeout=10)
        if r.status_code == 200:
            print("[OK] Supabase REST API connected successfully!")
        else:
            print(f"[!] Supabase connection returned HTTP {r.status_code}: {r.text[:200]}")
            return
    except Exception as e:
        print(f"[!] Failed to connect to Supabase: {e}")
        return

    # 2. Iterate through datasets
    datasets_dir = os.path.join(os.path.dirname(__file__), "datasets")
    success_count = 0
    failed = []

    for filename, table in TABLE_ORDER:
        csv_file = os.path.join(datasets_dir, filename)
        ok = upload_table(csv_file, table)
        if ok:
            success_count += 1
        else:
            failed.append((filename, table))

    print("\n" + "=" * 60)
    print(f"  Upload Summary: {success_count}/{len(TABLE_ORDER)} tables uploaded successfully.")
    if failed:
        print(f"  Failed tables ({len(failed)}):")
        for f, t in failed:
            print(f"    - {t} (from {f})")
        print("\n  NOTE: If tables do not exist yet, run 'supabase_schema.sql' in your")
        print("  Supabase Dashboard -> SQL Editor first, then rerun this script.")
    print("=" * 60)

if __name__ == "__main__":
    main()
