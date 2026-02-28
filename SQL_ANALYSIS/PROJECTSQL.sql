-------------Overview----------------------------
CREATE VIEW View_Superstore_Overview
AS
SELECT 
    ROUND(SUM(Sales), 2) AS [Total_Sales],                -- ÅÌãÇáí ÇáãÈíÚÇÊ
    ROUND(SUM(Profit), 2) AS [Total_Profit],              -- ÅÌãÇáí ÇáÃÑÈÇÍ
    COUNT(DISTINCT Order_ID) AS [Total_Orders],           -- ÚÏÏ ÇáØáÈÇÊ
    COUNT(DISTINCT Customer_ID) AS [Total_Customers],     -- ÚÏÏ ÇáÚãáÇÁ
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS [Profit_Margin_Percent], -- äÓÈÉ ÇáÑÈÍ
    SUM(Quantity) AS [Total_Quantity_Sold],               -- ÅÌãÇáí ÇáÞØÚ ÇáãÈÇÚÉ
    AVG(Discount) * 100 AS [Avg_Discount_Percent]         -- ãÊæÓØ ÇáÎÕã ÇáãÚØì
FROM [End_PROJECT].[dbo].[Sample - Superstore];
select * from View_Superstore_Overview
-----------------------Time Trend---------------------------
CREATE VIEW View_Superstore_Time_Trends
AS
SELECT 
    YEAR(Order_Date) AS [Order_Year],
    MONTH(Order_Date) AS [Order_Month],
    -- 1. ãÄÔÑ ÇáãÈíÚÇÊ
    ROUND(SUM(Sales), 2) AS [Monthly_Sales],
    -- 2. ãÄÔÑ ÇáÃÑÈÇÍ
    ROUND(SUM(Profit), 2) AS [Monthly_Profit],
    -- 3. ãÄÔÑ ÚÏÏ ÇáÚãáíÇÊ
    COUNT(DISTINCT Order_ID) AS [Monthly_Orders],
    -- 4. ãÄÔÑ ãÊæÓØ ÞíãÉ ÇáØáÈ (AOV) - ãåã ÌÏÇð ááÊÌÇÑ
    ROUND(SUM(Sales) / COUNT(DISTINCT Order_ID), 2) AS [Avg_Order_Value],
    -- 5. äÓÈÉ ÇáÑÈÍ
    ROUND((SUM(Profit) / NULLIF(SUM(Sales), 0)) * 100, 2) AS [Profit_Margin_Percent]
FROM [End_PROJECT].[dbo].[Sample - Superstore]
GROUP BY YEAR(Order_Date), MONTH(Order_Date);
-------------
SELECT * FROM View_Superstore_Time_Trends
ORDER BY [Order_Year] DESC, [Order_Month] DESC;
---------------------Category_Performance------------
CREATE VIEW View_Category_Performance
AS
WITH Category_Totals AS (
    -- ÍÓÇÈ ÇáÅÌãÇáíÇÊ ÃæáÇð áÊÓåíá ÍÓÇÈ ÇáäÓÈ ÇáãÆæíÉ áÇÍÞÇð
    SELECT 
        Category,
        Sub_Category,
        SUM(Sales) AS SubCat_Sales,
        SUM(Profit) AS SubCat_Profit,
        SUM(Quantity) AS SubCat_Quantity,
        -- ÍÓÇÈ ãÊæÓØ ÇáÎÕã ááÝÆÉ
        AVG(Discount) * 100 AS Avg_Discount_Percent
    FROM [End_PROJECT].[dbo].[Sample - Superstore]
    GROUP BY Category, Sub_Category
)
SELECT 
    Category,
    Sub_Category,
    ROUND(SubCat_Sales, 2) AS Sales,
    ROUND(SubCat_Profit, 2) AS Profit,
    SubCat_Quantity AS Quantity_Sold,
    -- äÓÈÉ ÇáÑÈÍíÉ (Profit Margin)
    ROUND((SubCat_Profit / NULLIF(SubCat_Sales, 0)) * 100, 2) AS Profit_Margin_Percent,
    -- ãÊæÓØ ÇáÎÕã
    ROUND(Avg_Discount_Percent, 2) AS Avg_Discount,
    -- ÊÑÊíÈ ÇáÝÆÉ ÇáÝÑÚíÉ ÏÇÎá ÇáÝÆÉ ÇáÑÆíÓíÉ ÈäÇÁð Úáì ÇáãÈíÚÇÊ
    DENSE_RANK() OVER (PARTITION BY Category ORDER BY SubCat_Sales DESC) AS Sales_Rank_In_Category
FROM Category_Totals;
-------------
SELECT * FROM View_Category_Performance
ORDER BY Category, Sales_Rank_In_Category;
----------------- Loss_Deep_Dive--------------
CREATE VIEW View_Loss_Deep_Dive
AS
SELECT 
    Category,
    Sub_Category,
    Region,
    State,
    COUNT(Order_ID) AS Total_Orders,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Loss,
    -- ÍÓÇÈ ãÊæÓØ ÇáÎÕã Ýí åÐå ÇáãäØÞÉ/ÇáÝÆÉ
    ROUND(AVG(Discount) * 100, 2) AS Avg_Discount_Percent,
    -- äÓÈÉ ÇáÎÓÇÑÉ ááãÈíÚÇÊ
    ROUND((SUM(Profit) / NULLIF(SUM(Sales), 0)) * 100, 2) AS Loss_Margin_Percent
FROM [End_PROJECT].[dbo].[Sample - Superstore]
WHERE Profit < 0  -- äÑßÒ ÝÞØ Úáì ÇáÚãáíÇÊ ÇáÊí ÍÞÞÊ ÎÓÇÑÉ
GROUP BY Category, Sub_Category, Region, State;
------------
SELECT TOP 10 * FROM View_Loss_Deep_Dive
ORDER BY Total_Loss ASC; -- ASC áÊÑÊíÈ ÇáÃÑÞÇã ÇáÓÇáÈÉ ãä ÇáÃÕÛÑ (ÇáÃßËÑ ÎÓÇÑÉ)
--------------Discount_Impact_Study------------------------------
CREATE VIEW View_Discount_Impact_Study
AS
SELECT 
    CASE 
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.2 THEN 'Low Discount (0-20%)'
        WHEN Discount <= 0.5 THEN 'Medium Discount (20-50%)'
        ELSE 'High Discount (>50%)'
    END AS Discount_Range,
    COUNT(*) AS Order_Count,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(AVG(Profit), 2) AS Avg_Profit_Per_Order
FROM [End_PROJECT].[dbo].[Sample - Superstore]
GROUP BY 
    CASE 
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.2 THEN 'Low Discount (0-20%)'
        WHEN Discount <= 0.5 THEN 'Medium Discount (20-50%)'
        ELSE 'High Discount (>50%)'
    END;
---------------------------
 SELECT * FROM View_Discount_Impact_Study
ORDER BY Total_Profit DESC;
-------------------------------View_Discount_Hunters------------------
CREATE VIEW View_Discount_Hunters
AS
SELECT TOP 20
    Customer_Name,
    Segment,
    COUNT(Order_ID) AS Total_Orders,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(AVG(Discount) * 100, 2) AS Avg_Discount_Taken,
    -- ãÄÔÑ ÈäÓãíå "Discount Reliance" (ãÏì ÇÚÊãÇÏå Úáì ÇáÎÕã)
    COUNT(CASE WHEN Discount >= 0.5 THEN 1 END) AS High_Discount_Orders
FROM [End_PROJECT].[dbo].[Sample - Superstore]
GROUP BY Customer_Name, Segment
ORDER BY Total_Profit ASC; -- ÈäÑÊÈ ãä ÇáÃßËÑ ÎÓÇÑÉ ááÃÞá
------------
SELECT * FROM View_Discount_Hunters;
-------------------Rescue_Strategy---------------
CREATE VIEW View_Rescue_Strategy
AS
SELECT 
    Region,
    State,
    Category,
    Sub_Category,
    SUM(Sales) AS Lost_Sales_Volume,
    SUM(Profit) AS Total_Loss,
    AVG(Discount) * 100 AS Current_Avg_Discount,
    -- ÇáÊæÕíÉ ÇáãÞÊÑÍÉ ÈäÇÁð Úáì ÇáÈíÇäÇÊ
    CASE 
        WHEN AVG(Discount) >= 0.7 THEN 'Critical: Reduce Discount to Max 20%'
        WHEN AVG(Discount) >= 0.5 THEN 'Urgent: Review Pricing Strategy'
        ELSE 'Monitor: High Shipping or Operations Cost'
    END AS [Action_Required]
FROM [End_PROJECT].[dbo].[Sample - Superstore]
WHERE Profit < 0
GROUP BY Region, State, Category, Sub_Category
HAVING SUM(Profit) < -1000; -- äÑßÒ ÝÞØ Úáì ÇáÎÓÇÆÑ ÇáãÄËÑÉ (ÃßËÑ ãä 1000 ÏæáÇÑ)
-------------------------
SELECT 
    Action_Required, 
    State, 
    Sub_Category, 
    Total_Loss
FROM [View_Rescue_Strategy]
ORDER BY Total_Loss ASC;
--------------------Basket_Analysis-------------
CREATE VIEW View_Market_Basket_Analysis
AS
SELECT 
    A.Sub_Category AS Product_A, 
    B.Sub_Category AS Product_B, 
    COUNT(*) AS Times_Bought_Together
FROM [End_PROJECT].[dbo].[Sample - Superstore] A
INNER JOIN [End_PROJECT].[dbo].[Sample - Superstore] B 
    ON A.Order_ID = B.Order_ID              -- äÝÓ ÇáØáÈ
    AND A.Sub_Category < B.Sub_Category    -- ÚÔÇä äãäÚ ÊßÑÇÑ (Ã¡È) æ (È¡Ã) æäãäÚ ÑÈØ ÇáãäÊÌ ÈäÝÓå
GROUP BY A.Sub_Category, B.Sub_Category;
----------------
SELECT TOP 10 * FROM [View_Market_Basket_Analysis]
ORDER BY Times_Bought_Together DESC;
-----------
CREATE VIEW View_Customer
AS
SELECT 
    Customer_ID,
    Customer_Name,
    COUNT(Order_ID) AS Frequency, -- ÇÔÊÑì ßÇã ãÑÉ
    round(SUM(Sales),2) AS Monetary,      -- ÏÝÚ ßÇã ÅÌãÇáÇð
    DATEDIFF(day, MAX(Order_Date), (SELECT MAX(Order_Date) FROM [End_PROJECT].[dbo].[Sample - Superstore])) AS Recency -- ÈÞÇáå ßÇã íæã ãÇ ÇÔÊÑÔ
FROM [End_PROJECT].[dbo].[Sample - Superstore]
GROUP BY Customer_ID, Customer_Name;
--------------
select Top(10) * from View_Customer
