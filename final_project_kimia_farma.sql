-- Create the main analysis table
CREATE OR REPLACE TABLE `final_kimia_farma.kf_analysis` AS
WITH profit_calculation AS (
  SELECT 
    t.*,
    p.product_name,
    p.actual_price,
    p.discount_percentage,
    b.branch_name,
    b.kota,
    b.provinsi,
    b.rating_cabang,
    CASE
      WHEN p.actual_price <= 50000 THEN 0.10
      WHEN p.actual_price <= 100000 THEN 0.15
      WHEN p.actual_price <= 300000 THEN 0.20
      WHEN p.actual_price <= 500000 THEN 0.25
      ELSE 0.30
    END as persentase_gross_laba,
    p.actual_price * (1 - COALESCE(p.discount_percentage, 0)/100) as nett_sales
  FROM `final_kimia_farma.kf_final_transaction` t
  LEFT JOIN `final_kimia_farma.kf_product` p ON t.product_id = p.product_id
  LEFT JOIN `final_kimia_farma.kf_kantor_cabang` b ON t.branch_id = b.branch_id
)
SELECT 
  transaction_id,
  date,
  branch_id,
  branch_name,
  kota,
  provinsi,
  rating_cabang,
  customer_name,
  product_id,
  product_name,
  actual_price,
  discount_percentage,
  persentase_gross_laba,
  nett_sales,
  ROUND(nett_sales * persentase_gross_laba, 2) as nett_profit,
  rating_transaksi
FROM profit_calculation;


-- Monthly Sales Analysis
CREATE OR REPLACE TABLE `final_kimia_farma.monthly_sales` AS
SELECT 
  FORMAT_DATE('%Y-%m', date) as month,
  COUNT(DISTINCT transaction_id) as total_transactions,
  COUNT(DISTINCT customer_name) as unique_customers,
  SUM(nett_sales) as total_sales,
  SUM(nett_profit) as total_profit,
  AVG(rating_transaksi) as avg_transaction_rating
FROM `final_kimia_farma.kf_analysis`
GROUP BY 1
ORDER BY 1;

-- Branch Performance Analysis
CREATE OR REPLACE TABLE `final_kimia_farma.branch_performance` AS
SELECT 
  branch_id,
  branch_name,
  kota,
  provinsi,
  COUNT(DISTINCT transaction_id) as total_transactions,
  SUM(nett_sales) as total_sales,
  SUM(nett_profit) as total_profit,
  AVG(rating_transaksi) as avg_transaction_rating,
  rating_cabang
FROM `final_kimia_farma.kf_analysis`
GROUP BY 1, 2, 3, 4, 9
ORDER BY total_sales DESC;

