CREATE DATABASE AQI_Analytics;
GO

use AQI_Analytics

---check data 
select * from AQI_Data;
select count(*) from AQI_Data;

--Check cities
SELECT 
    COUNT(DISTINCT city) AS total_cities
FROM dbo.AQI_Data;--50 cities
--City-wise records
SELECT 
    city,
    COUNT(*) AS record_count
FROM dbo.AQI_Data
GROUP BY city
ORDER BY record_count DESC;
--The dataset exhibits a perfectly balanced distribution across all 50 cities with exactly 1,080 records each, indicating uniform temporal sampling with zero geographic collection bias.
--Missing values
SELECT
    SUM(CASE WHEN pm2_5 IS NULL THEN 1 ELSE 0 END) AS pm2_5_nulls,
    SUM(CASE WHEN pm10 IS NULL THEN 1 ELSE 0 END) AS pm10_nulls,
    SUM(CASE WHEN carbon_monoxide IS NULL THEN 1 ELSE 0 END) AS co_nulls,
    SUM(CASE WHEN nitrogen_dioxide IS NULL THEN 1 ELSE 0 END) AS no2_nulls,
    SUM(CASE WHEN sulphur_dioxide IS NULL THEN 1 ELSE 0 END) AS so2_nulls,
    SUM(CASE WHEN ozone IS NULL THEN 1 ELSE 0 END) AS ozone_nulls,
    SUM(CASE WHEN us_aqi IS NULL THEN 1 ELSE 0 END) AS aqi_nulls
FROM AQI_Data;--no missing value found
--Duplicate timestamp + city
SELECT
    city,
    time,
    COUNT(*) AS duplicate_count
FROM dbo.AQI_Data
GROUP BY city, time
HAVING COUNT(*) > 1;--no duplicate found
--Overall AQI statistics
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT city) AS total_cities,
    ROUND(AVG(CAST(us_aqi AS FLOAT)), 2) AS avg_aqi,
    MIN(us_aqi) AS min_aqi,
    MAX(us_aqi) AS max_aqi
FROM AQI_Data;
--total_records	total_cities	avg_aqi	  min_aqi	max_aqi
---54000	          50	      79.51	     15	      418
--City-wise AQI analysis
--This is one of the most important analyses.

SELECT
    city,
    state,
    COUNT(*) AS records,
    ROUND(AVG(CAST(us_aqi AS FLOAT)), 2) AS avg_aqi,
    MIN(us_aqi) AS min_aqi,
    MAX(us_aqi) AS max_aqi
FROM dbo.AQI_Data
GROUP BY city, state
ORDER BY avg_aqi DESC;
--insights
--Key Findings & Insights:
--Top Polluted Cities: Delhi tops the list with the highest average AQI of 154.12 and a peak spike of 418, followed closely by Punjab industrial hubs (Amritsar: 146.98, Ludhiana: 146.76) and Meerut (139.81).

--Regional Disparity (North vs South): Northern/Indo-Gangetic plains suffer the heaviest pollution load, whereas Southern cities consistently record the healthiest air quality (Mysuru: 34.54, Coimbatore: 41.50, Bengaluru: 44.58).

--Cleanest Air: Mysuru recorded the lowest average AQI (34.54) nationwide, while Coimbatore recorded the best single minimum reading at 15.

--High Volatility: Meerut and Delhi showed extreme fluctuations—Meerut swung from a low of 63 to a hazardous peak of 354.

--Airshed Overlap: Bhubaneswar and Cuttack registered identical metrics across the board (Avg: 76.84, Min: 48, Max: 136), reflecting shared regional meteorology.

--Even Distribution: Each city has an identical count of 1,080 records, ensuring a balanced dataset with no geographic sample bias.

--Metric	                  City	        State	Avg AQI	   Min AQI	Max AQI
--Top Most (Highest AQI)	  Delhi	        Delhi	154.12	      70	418
--Bottom Most (Lowest AQI)	  Mysuru	 Karnataka	34.54	      16	61

--AQI category analysis
SELECT
    aqi_category,
    COUNT(*) AS records,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER(),
        2
    ) AS percentage
FROM dbo.AQI_Data
GROUP BY aqi_category
ORDER BY records DESC;

---aqi_category	                   records	percentage
--Moderate	                        36366	67.34
--Unhealthy for Sensitive Groups	7537	13.96
--Good	                            6989	12.94
--Unhealthy	                        2916	5.40
--Very Unhealthy	                 134	0.25
--Hazardous	                          58	0.11

--City + AQI category
SELECT
    city,
    aqi_category,
    COUNT(*) AS records
FROM dbo.AQI_Data
GROUP BY city, aqi_category
ORDER BY city, records DESC;

--Extreme Risk is Hyper-Localized: Only 2 cities hit Hazardous (Delhi: 43 days, Meerut: 15 days).

--Chronic vs Spike Pollution: Ludhiana and Amritsar suffer worse daily air than Delhi, spending >50% of all days in "Unhealthy" (613 and 592 days).

--Coastal/Western Stability: Mumbai, Ahmedabad, and Surat are 100% Moderate (1,080/1,080 days)—never clean (Good = 0), but never severely polluted.

--Plateau Clean Air Pocket: Nashik (91%), Mysuru (85%), Pune (84%), and Bengaluru (76%) spend the vast majority of time in Good air.

--The "Sensitive Group" Trap: Tier-2 inland cities (Jaipur, Patna, Jammu) rarely cross into "Hazardous", but keep vulnerable people at risk for 30–70% of the year.

--Monthly AQI analysis
SELECT
    year,
    month,
    ROUND(AVG(CAST(us_aqi AS FLOAT)), 2) AS avg_aqi,
    MAX(us_aqi) AS max_aqi,
    MIN(us_aqi) AS min_aqi
FROM dbo.AQI_Data
GROUP BY year, month
ORDER BY year, month;
--year	month	avg_aqi	max_aqi	min_aqi
--2026	 8	     79.65	418	     15
--2026	 9	     79.19	332	     18

--Day-of-week analysis
SELECT
    day_name,
    COUNT(*) AS records,
    ROUND(AVG(CAST(us_aqi AS FLOAT)), 2) AS avg_aqi
FROM dbo.AQI_Data
GROUP BY day_name, day_of_week
ORDER BY day_of_week;
--day_name	records	avg_aqi
--Monday	8400	78.16
--Tuesday	7200	80.33
--Wednesday	7200	81.8
--Thursday	7200	82.58
--Friday	7200	81.03
--Saturday	8400	77.07
--Sunday	8400	76.7

--Hourly AQI analysis
SELECT
    hour,
    ROUND(AVG(CAST(us_aqi AS FLOAT)), 2) AS avg_aqi,
    MAX(us_aqi) AS max_aqi,
    MIN(us_aqi) AS min_aqi
FROM dbo.AQI_Data
GROUP BY hour
ORDER BY hour;
--* **Evening Rush-Hour Peak (17:00–19:00):** Average AQI climbs sharply from 15:00 and peaks at **18:00 (85.55)**, driven by evening traffic congestion and drop in atmospheric boundary layer height.
--* **Afternoon Maximum Spike (14:00–15:00):** The national maximum AQI reaches its absolute peak of **418** between **14:00 and 15:00** before gradually declining.
--* **Early Morning Clean Window (02:00–07:00):** Air quality is cleanest and most stable in early morning hours, with average AQI bottoming out at **77.98** (02:00–04:00) and nationwide minimums dropping to **15** (04:00–08:00).
--* **Mid-Day Secondary Build-up:** Maximum AQI begins a steep morning surge starting at **09:00 (361)** and crosses 400 by **12:00 (407)** as industrial activity and midday photochemical reactions intensify.
--* **Night Stagnation (22:00–01:00):** AQI steadily resets back down to the 78 baseline by midnight as city traffic subsides.

---Pollutant analysis
SELECT
    round(AVG(pm2_5),2) AS avg_pm25,
    round(AVG(pm10),2) AS avg_pm10,
    round(AVG(carbon_monoxide),2) AS avg_co,
    round(AVG(nitrogen_dioxide),2) AS avg_no2,
   round(AVG(sulphur_dioxide),2) AS avg_so2,
    round(AVG(ozone),2)  AS avg_ozone
FROM AQI_Data;
--avg_pm25	avg_pm10	avg_co	avg_no2	avg_so2	avg_ozone
--24.16	      36.07	    311.54	12.04	10.05	72.06

--City-wise pollutant analysis
SELECT
    city,
    ROUND(AVG(pm2_5), 2) AS avg_pm25,
    ROUND(AVG(pm10), 2) AS avg_pm10,
    ROUND(AVG(carbon_monoxide), 2) AS avg_co,
    ROUND(AVG(nitrogen_dioxide), 2) AS avg_no2,
    ROUND(AVG(sulphur_dioxide), 2) AS avg_so2,
    ROUND(AVG(ozone), 2) AS avg_ozone,
    ROUND(AVG(CAST(us_aqi AS FLOAT)), 2) AS avg_aqi
FROM dbo.AQI_Data
GROUP BY city
ORDER BY avg_aqi DESC;
--* **$PM_{2.5}$ Drives the Top Tier:** The worst 3 cities—Amritsar ($60.89$), Ludhiana ($60.35$), and Delhi ($60.06$)—have nearly $10\times$ higher $PM_{2.5}$ than cleanest cities like Mysuru ($6.48$) and Nashik ($6.69$).
--* **Delhi Leads in Multiple Hazards:** Delhi records the highest levels nationwide for $PM_{10}$ ($119.15$), $CO$ ($791.54$), and $NO_2$ ($35.96$), making it a broad-spectrum emission hotspot.
--* **Severe $SO_2$ Industrial Hotspots:** Coastal/industrial belts—Raipur ($46.88$), Visakhapatnam ($46.25$), and Surat ($43.38$)—exhibit massive sulfur dioxide concentrations ($>4\times$ Delhi and $>20\times$ southern cities).
--* **Desert Dust Impact (High $PM_{10}$ / $PM_{2.5}$ Ratio):** Rajasthan cities like Jaipur ($PM_{10}: 92.12$ vs $PM_{2.5}: 32.84$) and Jodhpur ($77.35$ vs $27.11$) show coarse-particle dominance from arid soil and wind-blown dust rather than combustion.
--* **The Hill Station Ozone Anomaly:** Shimla has very low particulate matter ($PM_{2.5}: 18.92$) but the **highest Ozone ($110.85$)** nationwide, driven by intense UV exposure at higher elevation and stratospheric intrusion.
--* **Southern Plateau Clean Belt:** Mysuru, Nashik, Pune, and Coimbatore maintain single-digit $PM_{2.5}$ ($<8.0$), minimal $PM_{10}$ ($<15.0$), and low precursor gases across all indicators.


ALTER TABLE dbo.AQI_Data
ADD time_period VARCHAR(20),
    season VARCHAR(20);

UPDATE dbo.AQI_Data
SET
    time_period =
        CASE
            WHEN hour BETWEEN 6 AND 10 THEN 'Morning'
            WHEN hour BETWEEN 11 AND 16 THEN 'Afternoon'
            WHEN hour BETWEEN 17 AND 21 THEN 'Evening'
            ELSE 'Night'
        END,

    season =
        CASE
            WHEN month IN (12, 1, 2) THEN 'Winter'
            WHEN month IN (3, 4, 5) THEN 'Summer'
            WHEN month IN (6, 7, 8, 9) THEN 'Monsoon'
            ELSE 'Post_Monsoon'
        END;

        -----Check counts
SELECT
    time_period,
    COUNT(*) AS records
FROM dbo.AQI_Data
GROUP BY time_period
ORDER BY time_period;
---time_period	records
--Afternoon	    13500
--Evening	    11250
--Morning	    11250
--Night	        18000


--Verify
SELECT
    city,
    time,
    hour,
    month,
    time_period,
    season,
    us_aqi,
    aqi_category
FROM dbo.AQI_Data
ORDER BY time
OFFSET 0 ROWS
FETCH NEXT 20 ROWS ONLY;

---check season
SELECT
    season,
    COUNT(*) AS records
FROM dbo.AQI_Data
GROUP BY season;
