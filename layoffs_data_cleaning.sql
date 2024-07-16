-- GLOBAL LAYOFFS

-- DATA CLEANING  

SELECT *
FROM layoffs;

-- STEPS TO BE FOLLOWED:
-- 1. Remove duplicates
-- 2. Standardize the Data
-- 3. Null values or blank values 
-- 4. Remove irrelevant columns 

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- REMOVING DUPLICATES
-- Add a row number column to check if there are any duplicates 
-- Using partition by columns 

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging;

-- Checking for duplicates, where row_num>1
-- Using Common Table Expression 
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte 
WHERE row_num > 1;

SELECT * 
FROM layoffs_staging 
WHERE company = 'Casper';

-- Creating a table where duplicate values will be removed 

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging;

-- getting the duplicate records in this table 
SELECT * 
FROM layoffs_staging2 
WHERE row_num > 1;

-- delete the duplicate records 
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

SELECT * 
FROM layoffs_staging2;

-- Duplicates removed 

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- STANDARDIZE THE DATA 
-- Finding issues in the Data and fixing it 

-- Checking issues in company
SELECT company, TRIM(company) 
FROM layoffs_staging2;

-- ISSUES FOUND:
-- 1. Leading and trailing spaces in company column 

-- Remove the leading and trailing spaces 
UPDATE layoffs_staging2 
SET company = TRIM(company);

-- Check the update 
SELECT * 
FROM layoffs_staging2;


-- Checking issues in industry 
SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;

-- ISSUES FOUND: 
-- 1. Crypto, Crypto Currency, CryptoCurrency - same industry 
-- 2. A null value and a blank value 

-- Change Crypto, Crypto Currency, CryptoCurrency industries as a single industry 
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; 

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Check for distinct industry update
SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;


-- Checking issues in country
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- ISSUES FOUND:
-- 1. United States and United States. as two different countries

-- Change United States and United States. into a single country 
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Check for country update 
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- The date column has data type as 'text' 
-- Needs to be changed to datetime 
SELECT `date` 
FROM layoffs_staging2;

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update the date column format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Check update 
SELECT `date` 
FROM layoffs_staging2;

-- Update the datatype to 'date' 
ALTER TABLE layoffs_staging2 
MODIFY COLUMN `date` DATE; 

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- NULL VALUES OR BLANK VALUES
-- Checking for missing values in industry
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry = '';

-- Checking if industry can be populated with some value 
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Population of industry for Airbnb
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Update blanks to nulls
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1 
JOIN layoffs_staging2 t2
ON t1.company = t2.company 
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

-- Check the update 
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- Bally's is the only one still having NULL industry 
SELECT *
FROM layoffs_staging2
WHERE company LIKE "Bally's%";

-- Bally's has only one record for layoff so the industry can not be updated 

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- REMOVE IRRELEVANT COLUMNS 
-- Checking total_laid_off and percentage_laid_off for null values 
-- These records will be redundant 
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Remove the row_num column 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- -----------------------------------------------------------------------------------------------------------------------------------------

-- CLEANED DATA 
SELECT * 
FROM layoffs_staging2;