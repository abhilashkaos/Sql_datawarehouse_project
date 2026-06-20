/*
This Stored Procedure is meant to truncate existing data and load fresh data in bronze schema for all the tables related crm and erp 
from source crm and erp files
*/




create or alter procedure bronze.load_bronze as
begin
    begin try
        declare @start_time datetime, @end_time datetime, @batch_start_time datetime,@batch_end_time datetime
        set @batch_start_time = getdate()
        -- ============================================================
        -- CRM: Customer Info Truncate & Load Data
        -- ============================================================
        print '========================================================';
        print 'Loading Bronze Layer';
        print '========================================================';

        print '--------------------------------------------------------';
        print 'Loading CRM Tables';
        print '--------------------------------------------------------';

        
        print '>>>>>>>>>Truncating Table : bronze.crm_cust_info';
        set @start_time = getdate()
        Truncate table bronze.crm_cust_info;
        print '>>>>>>>>>Inserting data in Table : bronze.crm_cust_info';

        bulk insert bronze.crm_cust_info
        from 'C:\Users\abhil\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        with(
        firstrow = 2,
        fieldterminator = ',',
        tablock
        );
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';
        -- ============================================================
        -- CRM: Product Info Truncate & Load
        -- ============================================================
        
        print '>>>>>>>>>Truncating Table : bronze.crm_prd_info';
        set @start_time = getdate()
        Truncate table bronze.crm_prd_info;

        print '>>>>>>>>>Inserting data in Table : bronze.crm_prd_info';
        bulk insert bronze.crm_prd_info
        from 'C:\Users\abhil\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        with(
        firstrow = 2,
        fieldterminator = ',',
        tablock
        );
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';
        -- ============================================================
        -- CRM: Sales Details Truncate & Load
        -- ============================================================
    
        print '>>>>>>>>>Truncating Table : bronze.crm_sales_details';
        set @start_time = getdate()
        Truncate table bronze.crm_sales_details;
    
        print '>>>>>>>>>Inserting data in Table : bronze.crm_sales_details';
        bulk insert bronze.crm_sales_details
        from 'C:\Users\abhil\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        with(
        firstrow = 2,
        fieldterminator = ',',
        tablock
        );
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';
        
        print '--------------------------------------------------------';
        print 'Loading ERP Tables';
        print '--------------------------------------------------------';

        -- ============================================================
        -- ERP: Customer (AZ12) Truncate & Load
        -- ============================================================
        print '>>>>>>>>>Truncating Table : bronze.erp_cust_az12';
        set @start_time = getdate()
        Truncate table bronze.erp_cust_az12;
        print '>>>>>>>>>Inserting data in Table : bronze.erp_cust_az12';
        bulk insert bronze.erp_cust_az12
        from 'C:\Users\abhil\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        with(
        firstrow = 2,
        fieldterminator = ',',
        tablock
        );
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';
        -- ============================================================
        -- ERP: Location (A101) Truncate & Load
        -- ============================================================
        print '>>>>>>>>>Truncating Table : bronze.erp_loc_a101';
        set @start_time = getdate()
        Truncate table bronze.erp_loc_a101;
        print '>>>>>>>>>Inserting data in Table : bronze.erp_loc_a101';
        bulk insert bronze.erp_loc_a101
        from 'C:\Users\abhil\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        with(
        firstrow = 2,
        fieldterminator = ',',
        tablock
        );
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';

        -- ============================================================
        -- ERP: Product Category (G1V2) Truncate & Load
        -- ============================================================
        print '>>>>>>>>>Truncating Table : bronze.erp_px_cat_g1v2';
        set @start_time = getdate()
        Truncate table bronze.erp_px_cat_g1v2;
        print '>>>>>>>>>Inserting data in Table : bronze.erp_px_cat_g1v2';
        bulk insert bronze.erp_px_cat_g1v2
        from 'C:\Users\abhil\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        with(
        firstrow = 2,
        fieldterminator = ',',
        tablock
        );
        set @end_time = getdate()
        print 'Load duration : '+ cast(datediff(second,@start_time,@end_time) as nvarchar)+ 'seconds';
        set @batch_end_time = getdate()
        print'======================================================================================';
        print'Bronze Layer Load Complete';
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
