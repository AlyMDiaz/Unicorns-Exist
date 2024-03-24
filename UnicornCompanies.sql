
/***********************************************************************************************************************
Unicorn Companies:
 Private companies with a valuation $1 billion and over as of March 2022."
 (Dataset source: MavenAnalytics.io/dataplayground)

Data dictionary:
Field	Description
Company:	Company name
Valuation:	Company valuation in billions (B) of dollars
Date Joined:	The date in which the company reached $1 billion in valuation (YYYY-MM-DD)
Industry:	Company industry
City:	City the company was founded in
Country:	Country the company was founded in
Continent:	Continent the company was founded in
Year Founded:	Year the company was founded
Funding:	Total amount raised across all funding rounds in billions (B) or millions (M) of dollars
Select Investors:	Top 4 investing firms or individual investors (some have less than 4)

**********************************************************************************************************************/


-- Clean up unicorn companies dataset for Tableau EDA visualization
  -- Resolve:
	  -- Valuation and Funding contain non-numeric characters
      -- Valuation and Funding are datatype NVARCHAR
	  -- Funding is in both Millions and Billions
	  -- Date_joined format is YYYY-MM-DD
	  -- Investors all listed in same column
	  -- Australia is listed as continent Oceania
	  -- Artificial Intelligence formatted 2 different ways in industry

  --Remove $B and $M from Valuation and Funding numbers, convert to DECIMAL,
  -- and convert all Funding numbers to Billions in new table
      --1) Select B into temp table UC_Billions and remove $B
	  --2) Alter funding datatype to DECIMAL
	  --3) Select M into temp table UC_Millions and remove $M
	  --4) Alter funding datatype to DECIMAL
	  --5) Divide M by 1000 to convert to B
	  --6) Union all into new table UC_Clean and order by Valuation
	  --7) Remove $B from Valuation
	  --8) Alter valuation datatype to DECIMAL
	  --9) Remove $B from valuation numbers
	  --10) Rename Valuation and Funding to specify in Billions
	  --11) Change all instances of Oceania to Australia in Continent column
	  --12)  Change all instances of Artificial Intelligence to Artificial intelligence
	  --12) Export to CSV

	 

-- Explore/visualizations:
  -- Which investors have highest ROI
  -- Which investors are vested in the most Unicorn companies
  -- Top (#) Unicorn companies by Valuation
  -- Location of Unicorn companies (map): by city, country, and/or continent
  -- Which Unicorn company has higest ROI
  -- Which year most Unicorn companies founded in
  -- What industries most Unicorn companies in
  -- Number years between founding and date joined

--Create database for Unicorn Companies data
CREATE DATABASE UnicornCompanies;
GO

USE UnicornCompanies;
GO

--Display starting dataset
SELECT * FROM UC_Original;
GO


-- Select funding containing B into temp table,
--  remove $ and B from funding, convert to DECIMAL

-- Select funding containing B into temp table
SELECT *
INTO #UC_Billions
FROM UC_Original
WHERE Funding LIKE '%B%';
GO

-- Remove $B from funding
UPDATE #UC_Billions
SET Funding = TRIM('$B' FROM Funding);
GO

--Change funding datatype to DECIMAL from NVARCHAR(50)
ALTER TABLE #UC_Billions ALTER COLUMN Funding DECIMAL(5,2);
GO

--Display UC_Billions
SELECT * FROM #UC_Billions;
GO


-- Select funding containing M into temp table, remove $ and M from funding,
-- convert to DECIMAL, divide by 1000 to convert to billions

--Select funding containing M into new table
SELECT *
INTO #UC_Millions
FROM UC_Original
WHERE Funding LIKE '%M%';
GO

-- Remove $M from valuation
UPDATE #UC_Millions
SET Funding = TRIM('$M' FROM Funding);
GO

--Change funding datatype to DECIMAL(5,2) from NVARCHAR(50)
ALTER TABLE #UC_Millions ALTER COLUMN Funding DECIMAL(5,2);
GO

----Divide by 1000 to convert to billions
UPDATE #UC_Millions
SET Funding = Funding/1000;
GO

--Display UC_Millions
SELECT * FROM #UC_Millions;


--UNION #UC_Millions and #UC_Billions into new table (in billions)
--  and remove $B from Valuation, convert to DECIMAL

SELECT *
INTO UC_Clean
FROM #UC_Billions
UNION ALL
SELECT *
FROM #UC_Millions;
GO

--Remove $B from Valuation
UPDATE UC_Clean
SET Valuation = TRIM('$B' FROM Valuation);
GO

--Change valuation datatype to DECIMAL(5,2) from NVARCHAR(50)
ALTER TABLE UC_Clean ALTER COLUMN Valuation DECIMAL(5,2);
GO

--Change Valuation and Funding column names to specify in Billions
sp_rename 'UC_Clean.Valuation', 'Valuation_Billions', 'COLUMN';
GO

sp_rename 'UC_Clean.Funding', 'Funding_Billions', 'COLUMN';
GO

--Change Oceania to Australia
UPDATE UC_Clean
SET Continent = 'Australia'
WHERE Continent = 'Oceania';
GO

--Fix capitalization for Artificial intelligence
UPDATE UC_Clean
SET Industry = 'Artificial intelligence'
WHERE Industry = 'Artificial Intelligence';
GO

--Display UC_Clean
SELECT * FROM UC_Clean
ORDER BY Valuation_Billions DESC;
GO

--Separate investors into new table
SELECT Company, value AS Investor
INTO Investors
FROM UC_Clean
	CROSS APPLY STRING_SPLIT(Select_Investors, ',');
GO

----Display Investors
SELECT * FROM Investors;
GO

--Aggregate count of investors
SELECT value as Investor, COUNT(*) AS Companies_invested_in
INTO Investor_Totals
FROM UC_Clean  
    CROSS APPLY STRING_SPLIT(Select_Investors, ',')  
GROUP BY value;
GO

--Display Investor_Totals
SELECT * FROM Investor_Totals;
GO

--Display UC_Clean
SELECT * FROM UC_Clean;
GO