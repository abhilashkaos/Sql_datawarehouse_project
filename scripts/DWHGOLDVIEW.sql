/*
This is the Final layer of the DWH project, where Tranformed Tables(Silver Layer) are further integrated to Fact and Dimention Tables 
there by forming the star schema data model.


*/
-------------GOLD.DIM_CUSTOMERS

create or alter view gold.dim_customers as 
select 
row_number() over( order by ci.cst_id) as customer_key,---creating a surrogate key that will link to Fact table
ci.cst_id as customer_id,
ci.cst_key customer_number,
ci.cst_firstname as first_name,
ci.cst_lastname last_name,
ci.cst_marital_status martial_status,
case when ci.cst_gndr != 'n/a' then ci.cst_gndr---CRM is the master data hence only for n/a values we will refer erp
	 else COALESCE(ec.gen,'n/a') 
end as gender,
el.cntry as country,
ec.bdate birthdate, 
ci.cst_create_date as create_date from silver.crm_cust_info ci -- joing all customer tables
left join														
silver.erp_cust_az12 ec
on ci.cst_key = ec.cid
left join
silver.erp_loc_a101 el
on
ci.cst_key = el.cid

---------GOLD.DIM_PRODUCTS

create or alter view gold.dim_products as
select 
row_number() over(order by prd_start_dt,sales_prd_key) as product_key,---creating a surrogate key that will link to Fact table
prd_id as product_id,
sales_prd_key as product_number,
prd_nm as product_name,
cat_id as category_id,
px.cat as category,
px.subcat as subcategory,
px.maintenance,
prd_cost as product_cost,
prd_line as product_line,
prd_start_dt as start_date from silver.crm_prd_info pd
left join 
(select id,
cat,
subcat,
maintenance from silver.erp_px_cat_g1v2) px
on pd.cat_id = px.id
where prd_end_dt is null---Only selecting those products which are still active

--GOLD.FACT_SALES

create or alter view gold.fact_sales as
select  sls_ord_num as order_number,
dp.product_key,----surrogate key from product table(foreign key)
dc.customer_key,----surrogate key from customer table(foreign key)
sls_order_dt as order_date,
sls_ship_dt as shipping_date,
sls_due_dt as due_date,
sls_sales as sales_amount,
sls_quantity as quantity,
sls_price as price
from silver.crm_sales_details cs
left join 
(select * from gold.dim_products) dp
on cs.sls_prd_key = dp.product_number
left join 
(select * from gold.dim_customers) dc
on cs.sls_cust_id = dc.customer_id
