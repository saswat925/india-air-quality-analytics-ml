USE AQI_Analytics;
GO

---check data 
select * from  AQI_Next_Hour_Predictions;

---row count=10790
SELECT COUNT(*) AS total_predictions
FROM AQI_Next_Hour_Predictions;

--basic analaysis
SELECT
    COUNT(*) AS total_predictions,
    round(AVG(next_hour_aqi),2) AS avg_actual_aqi,
    round(AVG(predicted_aqi),2) AS avg_predicted_aqi,
    round(AVG(absolute_error),2) AS MAE,
    round(MAX(absolute_error),2) AS max_error,
    round(MIN(absolute_error),2) AS min_error
FROM AQI_Next_Hour_Predictions;
--total_predictions	avg_actual_aqi	avg_predicted_aqi	  MAE	     max_error	  min_error
--    10790	           82.22	         79.76	         9.35	      95.64	          0

--Actual vs Predicted
SELECT TOP 20
    time,
    next_hour_aqi AS actual_aqi,
    predicted_aqi,
    prediction_error,
    absolute_error
FROM AQI_Next_Hour_Predictions
ORDER BY time;
--Key Prediction Insights
--The model is generally performing well.
--Many predictions are very close to the actual AQI, with errors around 1–4 AQI points.
--The model predicts higher AQI values reasonably well.
--Actual AQI 133 → Predicted 135.39 → Error 2.39
--Actual AQI 122 → Predicted 124.01 → Error 2.01
--Some predictions have larger errors.
--Actual 137 → Predicted 119.88 → Error 17.12
--Actual 67 → Predicted 80.43 → Error 13.43
--Actual 88 → Predicted 100.71 → Error 12.71
--The model makes both overpredictions and underpredictions.
--Actual 56 → Predicted 59.75 → Overprediction
--Actual 73 → Predicted 66.10 → Underprediction
--There is no obvious consistent direction of error in this sample.
--Since both positive and negative errors occur, the model is not simply predicting AQI too high or too low all the time.

--Best Predictions
SELECT TOP 20
    time,
    next_hour_aqi AS actual_aqi,
    predicted_aqi,
    prediction_error,
    absolute_error
FROM AQI_Next_Hour_Predictions
ORDER BY absolute_error ASC;
--Extremely accurate predictions
--The actual and predicted AQI values are almost identical.
--Example: Actual 56, predicted 56.0009 → error only 0.0009 AQI.
--Example: Actual 95, predicted 94.9972 → error only 0.0028 AQI.
--Very small absolute errors
--All 20 observations have an absolute error below 0.02 AQI.
--This means the model is almost perfectly matching the actual AQI for these particular observations.
--Both overprediction and underprediction occur
--Negative prediction_error → model overpredicted.
--Positive prediction_error → model underpredicted.
--Example: 56 → 56.0009 = slight overprediction.
--Example: 95 → 94.9972 = slight underprediction.
--Accuracy is consistent across different AQI levels
--The model performs extremely accurately for AQI values such as 42, 51, 56, 95, 122 and 162.
--So this sample is not limited to only low AQI values.

-- Prediction Accuracy
SELECT
    COUNT(*) AS total_predictions,

    SUM(CASE WHEN absolute_error <= 5 THEN 1 ELSE 0 END) AS within_5_AQI,
    SUM(CASE WHEN absolute_error <= 10 THEN 1 ELSE 0 END) AS within_10_AQI,
    SUM(CASE WHEN absolute_error <= 20 THEN 1 ELSE 0 END) AS within_20_AQI,

    ROUND(
        100.0 * SUM(CASE WHEN absolute_error <= 5 THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS accuracy_within_5_pct,

    ROUND(
        100.0 * SUM(CASE WHEN absolute_error <= 10 THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS accuracy_within_10_pct,

    ROUND(
        100.0 * SUM(CASE WHEN absolute_error <= 20 THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS accuracy_within_20_pct

FROM AQI_Next_Hour_Predictions;
--total_predictions	within_5_AQI	within_10_AQI	within_20_AQI	accuracy_within_5_pct	accuracy_within_10_pct	accuracy_within_20_pct
--10790	             4380	           7088	            9585	       40.59	                  65.69	              88.83

-- Prediction Direction
SELECT
    CASE
        WHEN prediction_error < 0 THEN 'Overprediction'
        WHEN prediction_error > 0 THEN 'Underprediction'
        ELSE 'Exact Prediction'
    END AS prediction_type,

    COUNT(*) AS prediction_count,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM AQI_Next_Hour_Predictions), 2
    ) AS percentage

FROM AQI_Next_Hour_Predictions

GROUP BY
    CASE
        WHEN prediction_error < 0 THEN 'Overprediction'
        WHEN prediction_error > 0 THEN 'Underprediction'
        ELSE 'Exact Prediction'
    END;
    ---prediction_type	prediction_count	percentage
      --Overprediction	4628	           42.89
      --Underprediction	6162	           57.11

      -- Worst Predictions
SELECT TOP 10
    time,
    next_hour_aqi AS actual_aqi,
    predicted_aqi,
    prediction_error,
    absolute_error
FROM AQI_Next_Hour_Predictions
ORDER BY absolute_error DESC;

--worst errors show that the model struggles with sudden/high AQI changes.

--Actual 163 → predicted 258.64 → error 95.64
--Actual 166 → predicted 260.63 → error 94.63
--Actual 173 → predicted 93.58 → error 79.42
--Actual 185 → predicted 107.71 → error 77.29
--What this means
--High AQI spikes are difficult for the model to predict accurately.
--The model sometimes strongly overpredicts and sometimes strongly underpredicts.
--This explains why your MAE is 9.35 even though many individual predictions are extremely accurate.
--The model is generally useful, but extreme AQI events remain its main weakness.



--| Metric                |     Result |
--| --------------------- | ---------: |
--| Total predictions     | **10,790** |
--| Average actual AQI    |  **82.22** |
--| Average predicted AQI |  **79.76** |
--| MAE                   |   **9.35** |
--| Maximum error         |  **95.64** |
--| Within ±5 AQI         | **40.59%** |
--| Within ±10 AQI        | **65.69%** |
--| Within ±20 AQI        | **88.83%** |
--| Overprediction        | **42.89%** |
--| Underprediction       | **57.11%** |

--Major project conclusion

--The Random Forest model provides reasonably good next-hour AQI predictions, with an MAE of 9.35. Around 88.83% of predictions are within ±20 AQI points, while 65.69% are within ±10 points. The model performs well on many normal observations but struggles with sudden AQI spikes and extreme pollution events. It shows slightly more underprediction (57.11%) than overprediction (42.89%).
