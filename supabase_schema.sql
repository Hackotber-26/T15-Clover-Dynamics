-- ====================================================================
-- Supabase Schema for Merchant AI Box (SME Growth Advisor)
-- Run this in your Supabase Dashboard: SQL Editor -> New Query -> Run
-- ====================================================================

-- 1. Categories
CREATE TABLE IF NOT EXISTS public.categories (
    "CategoryID" TEXT PRIMARY KEY,
    "CategoryName" TEXT NOT NULL,
    "GST_Rate" NUMERIC DEFAULT 0.05
);

-- 2. Suppliers
CREATE TABLE IF NOT EXISTS public.suppliers (
    "SupplierID" TEXT PRIMARY KEY,
    "SupplierName" TEXT NOT NULL,
    "ContactPerson" TEXT,
    "ContactEmail" TEXT,
    "Phone" TEXT,
    "PrimaryCategory" TEXT,
    "ReliabilityScore" NUMERIC DEFAULT 5
);

-- 3. Customers
CREATE TABLE IF NOT EXISTS public.customers (
    "CustomerID" TEXT PRIMARY KEY,
    "DisplayName" TEXT NOT NULL,
    "ContactName" TEXT,
    "Email" TEXT,
    "Phone" TEXT,
    "Address" TEXT,
    "PaymentTermsDays" INTEGER DEFAULT 30,
    "CreditLimit" NUMERIC DEFAULT 100000
);

-- 4. Customer Risk Profile
CREATE TABLE IF NOT EXISTS public.customer_risk_profile (
    "CustomerID" TEXT PRIMARY KEY REFERENCES public.customers("CustomerID") ON DELETE CASCADE,
    "DisplayName" TEXT,
    "ContactName" TEXT,
    "Phone" TEXT,
    "PaymentTermsDays" INTEGER,
    "CreditLimit" NUMERIC,
    "OverdueInvoiceCount" INTEGER DEFAULT 0,
    "TotalOverdueAmount" NUMERIC DEFAULT 0,
    "AvgDaysOverdue" NUMERIC DEFAULT 0,
    "MaxDaysOverdue" INTEGER DEFAULT 0,
    "PaymentReliabilityScore" NUMERIC DEFAULT 10,
    "RiskTier" TEXT,
    "PreferredChannel" TEXT
);

-- 5. Employees
CREATE TABLE IF NOT EXISTS public.employees (
    "EmployeeID" TEXT PRIMARY KEY,
    "EmployeeName" TEXT NOT NULL,
    "JobRole" TEXT,
    "HireDate" DATE,
    "TrainingCode" TEXT,
    "IsActive" INTEGER DEFAULT 1
);

-- 6. Products
CREATE TABLE IF NOT EXISTS public.products (
    "ProductID" TEXT PRIMARY KEY,
    "ProductName" TEXT NOT NULL,
    "CategoryID" TEXT REFERENCES public.categories("CategoryID"),
    "SupplierID" TEXT REFERENCES public.suppliers("SupplierID"),
    "StandardMarkup" NUMERIC DEFAULT 1.2,
    "DefaultSellingPrice" NUMERIC NOT NULL,
    "Description" TEXT,
    "UnitOfMeasurement" TEXT DEFAULT 'Unit'
);

-- 7. Inventory
CREATE TABLE IF NOT EXISTS public.inventory (
    "ProductID" TEXT PRIMARY KEY REFERENCES public.products("ProductID") ON DELETE CASCADE,
    "QuantityInStock" INTEGER DEFAULT 0,
    "ReorderPoint" INTEGER DEFAULT 10
);

-- 8. Expenses
CREATE TABLE IF NOT EXISTS public.expenses (
    "ExpenseID" TEXT PRIMARY KEY,
    "ExpenseDate" DATE NOT NULL,
    "ExpenseCode" TEXT,
    "AmountSpent" NUMERIC NOT NULL,
    "Description" TEXT
);

-- 9. Sales Raw
CREATE TABLE IF NOT EXISTS public.sales_raw (
    "SaleID" TEXT PRIMARY KEY,
    "SalesDate" DATE NOT NULL,
    "SalesTime" TIME,
    "CustomerID" TEXT,
    "ProductID" TEXT,
    "Quantity" INTEGER NOT NULL,
    "UnitPrice" NUMERIC NOT NULL,
    "TotalAmount" NUMERIC NOT NULL
);

-- 10. Invoices
CREATE TABLE IF NOT EXISTS public.invoices (
    "InvoiceID" TEXT PRIMARY KEY,
    "InvoiceDate" DATE NOT NULL,
    "CustomerID" TEXT,
    "TotalInvoiceValue" NUMERIC NOT NULL,
    "SalesID_JSON" TEXT,
    "Status" TEXT DEFAULT 'Pending'
);

-- 11. Pending Payments
CREATE TABLE IF NOT EXISTS public.pending_payments (
    id BIGSERIAL PRIMARY KEY,
    "InvoiceID" TEXT,
    "InvoiceDate" DATE,
    "DueDate" DATE,
    "CustomerID" TEXT,
    "AmountPending" NUMERIC NOT NULL,
    "DaysOverdue" INTEGER DEFAULT 0
);

-- 12. Purchase Orders
CREATE TABLE IF NOT EXISTS public.purchase_orders (
    "PO_ID" TEXT PRIMARY KEY,
    "PODate" DATE NOT NULL,
    "SupplierID" TEXT,
    "ProductID" TEXT,
    "CostPerUnit" NUMERIC NOT NULL,
    "QuantityOrdered" INTEGER NOT NULL,
    "TotalAmountSpent" NUMERIC NOT NULL
);

-- 13. Approval Queue
CREATE TABLE IF NOT EXISTS public.approval_queue (
    "ActionID" TEXT PRIMARY KEY,
    "AgentType" TEXT,
    "EntityID" TEXT,
    "EntityName" TEXT,
    "ActionType" TEXT,
    "RiskTier" TEXT,
    "Status" TEXT DEFAULT 'Pending Approval',
    "ReasoningSummary" TEXT,
    "ProposedDate" DATE
);

-- 14. Collections Interactions
CREATE TABLE IF NOT EXISTS public.collections_interactions (
    "InteractionID" TEXT PRIMARY KEY,
    "InvoiceID" TEXT,
    "CustomerID" TEXT,
    "Date" DATE,
    "Channel" TEXT,
    "ActionType" TEXT,
    "Notes" TEXT,
    "Status" TEXT
);

-- 15. Growth Initiatives
CREATE TABLE IF NOT EXISTS public.growth_initiatives (
    "InitiativeID" TEXT PRIMARY KEY,
    "Title" TEXT NOT NULL,
    "Category" TEXT,
    "Status" TEXT,
    "TargetMetric" TEXT,
    "TargetValuePercent" NUMERIC,
    "ActualValuePercent" NUMERIC,
    "StartDate" DATE,
    "CheckInDate" DATE,
    "Notes" TEXT
);

-- 16. Price History
CREATE TABLE IF NOT EXISTS public.price_history (
    "PriceChangeID" TEXT PRIMARY KEY,
    "ProductID" TEXT,
    "ProductName" TEXT,
    "ChangeDate" DATE,
    "OldPrice" NUMERIC,
    "NewPrice" NUMERIC,
    "ChangePercent" NUMERIC,
    "VolumeImpactPercent" NUMERIC,
    "RecoveryDays" INTEGER,
    "ProfitMarginChangePercent" NUMERIC,
    "Notes" TEXT
);

-- 17. Supplier Interactions
CREATE TABLE IF NOT EXISTS public.supplier_interactions (
    "InteractionID" TEXT PRIMARY KEY,
    "SupplierID" TEXT,
    "Date" DATE,
    "Channel" TEXT,
    "EventType" TEXT,
    "Notes" TEXT
);

-- ====================================================================
-- Disable Row Level Security (or allow all access to service_role/anon)
-- ====================================================================
ALTER TABLE public.categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_risk_profile DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_raw DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.pending_payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_queue DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections_interactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_initiatives DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_history DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_interactions DISABLE ROW LEVEL SECURITY;

-- Grant permissions to public, authenticated, and service_role
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- Helper RPC function to allow running dynamic SQL via service role if ever needed
CREATE OR REPLACE FUNCTION public.execute_sql(sql_query text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    EXECUTE sql_query;
END;
$$;
