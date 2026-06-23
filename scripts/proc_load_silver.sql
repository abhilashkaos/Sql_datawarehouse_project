/*
This Stored Procedure is meant to transform the data presnet in bronze schema tables and load the same in Silver Schema Tables

The command to run this procedure is Exec silver.load_silver;    
*/

Create or Alter Procedure silver.load_silver as
begin
    begin try
        print '==============================================================';
        print 'Silver Table Loading begins';
        print '==============================================================';
        ---Transformation Query

        ----CRM CUST INFO
        declare @start_time datetime,@end_time datetime,@batch_start_time datetime,@batch_end_time datetime
        set @batch_start_time = getdate()
        print '---------------------------------------------------------------';
        print 'Truncate silver.crm_cust_info';
        print '---------------------------------------------------------------';
        set @start_time = getdate()
        truncate table silver.crm_cust_info
        print '---------------------------------------------------------------';
        print 'Inserting data in silver.crm_cust_info';
        print '---------------------------------------------------------------';
        insert into silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        select
            cst_id,                      -- keep as-is
            cst_key,                     -- keep as-is
            trim(cst_firstname) as cst_firstname,   -- standardization: remove extra spaces
            trim(cst_lastname) as cst_lastname,      -- standardization: remove extra spaces
            case
                when trim(upper(cst_marital_status)) = 'M' then 'Married'   -- standardization
                when trim(upper(cst_marital_status)) = 'S' then 'Single'    -- standardization
                else 'n/a'
            end as cst_marital_status,
            case
                when trim(upper(cst_gndr)) = 'F' then 'Female'               -- standardization
                when trim(upper(cst_gndr)) = 'M' then 'Male'                 -- standardization
                else 'n/a'
            end as cst_gndr,
            cst_create_date
        from (
            select *,
                   ROW_NUMBER() over(
                       partition by cst_id
                       order by cst_create_date desc
                   ) as rnk   -- deduplication / keeping latest record
            from bronze.crm_cust_info
            where cst_id is not null   -- cleansing: remove null keys
        ) t
        where rnk = 1;                  -- deduplication: keep one row per customer

        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';

        ----CRM PRD INFO
        print '---------------------------------------------------------------';
        print 'Truncate silver.crm_prd_info';
        print '---------------------------------------------------------------';

        set @start_time = getdate()
        
        truncate table silver.crm_prd_info
        print '---------------------------------------------------------------';
        print 'Inserting data in silver.crm_prd_info';
        print '---------------------------------------------------------------';
        
        INSERT INTO silver.crm_prd_info (
            prd_id,
            prd_key,
            cat_id,
            sales_prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt 
        )


        select prd_id,
        prd_key,
        replace(SUBSTRING(prd_key,1,5),'-','_') as cat_id,---Derived Column category from prd_key
        SUBSTRING(prd_key,7,len(prd_key)-6) as sales_prd_key,---Derived sales product category from prd_key
        prd_nm,
        isnull(prd_cost,0) as prd_cost,---removing nulls from cost
        case when upper(trim(prd_line)) = 'M' then 'Mountain'
	         when upper(trim(prd_line)) = 'S' then 'Other Sales'
	         when upper(trim(prd_line)) = 'R' then 'Road'
	         when upper(trim(prd_line)) = 'T' then 'Touring'
	         else 'n/a'
        end as prd_line,---Mapping product line
        cast(prd_start_dt as date) as prd_start_dt,
        cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt) -1 as date) as prd_end_dt---creating sequenced end date data enrichment 
        from bronze.crm_prd_info
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';

        ----CRM SALES DETAILS
        print '---------------------------------------------------------------';
        print 'Truncate silver.crm_sales_details';
        print '---------------------------------------------------------------';
        set @start_time = GETDATE()
        truncate table silver.crm_sales_details
        print '---------------------------------------------------------------';
        print 'Inserting data in silver.crm_sales_details';
        print '---------------------------------------------------------------';

        insert into silver.crm_sales_details(sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price)

        select sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        case when sls_order_dt <= 0 or len(sls_order_dt) != 8 then null
	         else  cast(cast(sls_order_dt as nvarchar) as date)
        end as sls_order_dt,
        case when sls_due_dt <= 0 or len(sls_due_dt) != 8 then null
	         else  cast(cast(sls_due_dt as nvarchar) as date)
        end as sls_due_dt,
        case when sls_due_dt <= 0 or len(sls_due_dt) != 8 then null
	         else  cast(cast(sls_due_dt as nvarchar) as date)
        end as sls_due_dt,
        case when sls_sales <=0 or sls_sales is null or sls_sales != abs(sls_price) * sls_quantity then abs(sls_price) * sls_quantity
	         else sls_sales
        end as sls_sales,
        sls_quantity,
        case when sls_price <= 0 or sls_price is null then sls_sales/nullif(sls_quantity,0)
	         else sls_price
        end as sls_price from bronze.crm_sales_details 
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';

        -------ERP CUST
        print '---------------------------------------------------------------';
        print 'Truncate silver.erp_cust_az12';
        print '---------------------------------------------------------------';
        set @start_time = getdate()
        truncate table silver.erp_cust_az12
        print '---------------------------------------------------------------';
        print 'Inserting data in silver.erp_cust_az12';
        print '---------------------------------------------------------------';

        insert into silver.erp_cust_az12(
        cid,
        bdate,
        gen
        )

        select 
        substring(cid,charindex('AW',cid),len(cid)) as cid,
        case when bdate > getdate() then null
	         else bdate
        end as bdate,case when upper(trim(gen)) in ('M','MALE') then 'Male'
        when upper(trim(gen)) in ('F','FEMALE') then 'Female'
        else null
        end as gen from 
        bronze.erp_cust_az12 
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';

        ----ERP LOC
        print '---------------------------------------------------------------';
        print 'Truncate silver.erp_loc_a101';
        print '---------------------------------------------------------------';
        set @start_time = getdate()
        truncate table silver.erp_loc_a101
        print '---------------------------------------------------------------';
        print 'Inserting data in silver.erp_loc_a101';
        print '---------------------------------------------------------------';

        insert into silver.erp_loc_a101(cid,cntry)

        select replace(cid,'-','') as cid,
        case when trim(cntry) = 'DE' then 'Germany'
             when trim(cntry) in ('US','USA') then 'United States'
             when trim(cntry) = '' or trim(cntry) is null then 'n/a'
             else trim(cntry)
        end as cntry
        from bronze.erp_loc_a101
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';

        -----ERP PROD
        print '---------------------------------------------------------------';
        print 'Truncate silver.erp_px_cat_g1v2';
        print '---------------------------------------------------------------';
        set @start_time = getdate()
        truncate table silver.erp_px_cat_g1v2
        print '---------------------------------------------------------------';
        print 'Inserting data in silver.erp_px_cat_g1v2';
        print '---------------------------------------------------------------';

        insert into silver.erp_px_cat_g1v2(
        id,
        cat,
        subcat,
        maintenance)
        select id,
        cat,
        subcat,
        maintenance from bronze.erp_px_cat_g1v2
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';
        set @batch_end_time = getdate()

        print'======================================================================================';
        print'Silver Layer Load Complete';
        print 'Load duration : '+ cast(datediff(second,@batch_start_time,@batch_end_time) as nvarchar)+ 'seconds';
        print'======================================================================================';
    end try
    begin catch
        print '=========================================================';
        print 'Error occured during loading';
        print 'Error Message' +' '+ cast(error_message() as nvarchar);
        print 'Error Message'+' '+ cast(error_state() as nvarchar);
        print '=========================================================';
    end catch
end
