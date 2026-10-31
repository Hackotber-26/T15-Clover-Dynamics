import os
import sys
import glob
import math
import psycopg2
import pandas as pd
from dotenv import load_dotenv

load_dotenv(override=True)

HOST = "aws-0-eu-north-1.pooler.supabase.com"
PORT = 5432
DBNAME = "postgres"
USER = "postgres.eexjugulmhrtjirlgqpk"

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

def clean_val(v):
    if pd.isna(v):
        return None
    if isinstance(v, (float, int)) and math.isnan(v):
        return None
    return v

def run_migration_and_upload(password):
    print("=" * 60)
    print("  Supabase Direct Postgres Migration & Data Upload")
    print(f"  Target: {HOST}:{PORT}")
    print("=" * 60)

    # 1. Connect
    try:
        print("[+] Connecting to Supabase PostgreSQL database...")
        conn = psycopg2.connect(
            dbname=DBNAME,
            user=USER,
            password=password,
            host=HOST,
            port=PORT,
            connect_timeout=10
        )
        conn.autocommit = True
        cur = conn.cursor()
        print("[OK] Connected successfully to PostgreSQL!")
    except Exception as e:
        print(f"[!] Connection failed: {e}")
        return False

    # 2. Execute schema
    schema_path = os.path.join(os.path.dirname(__file__), "supabase_schema.sql")
    if os.path.exists(schema_path):
        print("\n[+] Applying 'supabase_schema.sql' DDL...")
        with open(schema_path, "r", encoding="utf-8") as f:
            sql_script = f.read()
        try:
            cur.execute(sql_script)
            print("[OK] All tables and indexes created successfully in public schema!")
        except Exception as e:
            print(f"[!] Error executing schema: {e}")
            return False

    # 3. Upload datasets
    datasets_dir = os.path.join(os.path.dirname(__file__), "datasets")
    print("\n[+] Uploading datasets...")
    
    total_uploaded = 0
    for filename, table in TABLE_ORDER:
        filepath = os.path.join(datasets_dir, filename)
        if not os.path.exists(filepath):
            print(f"[-] Skipping {filename} (not found)")
            continue

        df = pd.read_csv(filepath)
        cols = list(df.columns)
        quoted_cols = [f'"{c}"' for c in cols]
        cols_str = ", ".join(quoted_cols)
        placeholders = ", ".join(["%s"] * len(cols))

        insert_sql = f'INSERT INTO public."{table}" ({cols_str}) VALUES ({placeholders}) ON CONFLICT DO NOTHING;'
        
        records = [tuple(clean_val(x) for x in row) for row in df.itertuples(index=False, name=None)]
        
        from psycopg2.extras import execute_batch
        try:
            execute_batch(cur, insert_sql, records, page_size=1000)
            cur.execute(f'SELECT COUNT(*) FROM public."{table}";')
            count = cur.fetchone()[0]
            print(f"    [OK] '{table}': {count} rows in table")
            total_uploaded += 1
        except Exception as e:
            print(f"    [!] Error uploading {table}: {e}")

    conn.close()
    print("\n" + "=" * 60)
    print(f"  Complete! {total_uploaded}/{len(TABLE_ORDER)} tables loaded successfully.")
    print("=" * 60)
    return True

if __name__ == "__main__":
    pw = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("SUPABASE_DB_PASSWORD", "")
    if not pw:
        print("Usage: python migrate_and_upload.py <YOUR-SUPABASE-DB-PASSWORD>")
        sys.exit(1)
    run_migration_and_upload(pw)
