with Raw_Clicks as (SELECT
post_evar56 as Adobe_Tracking_ID, 
DATE(timestamp(post_cust_hit_time_gmt), "America/New_York") AS Adobe_Date,
DATETIME(timestamp(post_cust_hit_time_gmt), "America/New_York") AS Adobe_Timestamp,
post_evar19 as Player_Event,
post_evar7 as Binge_Details
FROM `nbcu-ds-prod-001.feed.adobe_clickstream` 
WHERE post_evar56 is not null
and post_cust_hit_time_gmt is not null 
and post_evar7 is not null
and post_evar7 not like "%display"
and extract(YEAR from timestamp(post_cust_hit_time_gmt))=2022 
and extract(month from timestamp(post_cust_hit_time_gmt))=11
and extract(day from timestamp(post_cust_hit_time_gmt))=26) -- select timerange:DATE(timestamp(post_cust_hit_time_gmt), "America/New_York") <= DATE_ADD(CURRENT_DATE(), INTERVAL -1 day))

SELECT 
Adobe_Tracking_ID,
Adobe_Date,
Adobe_Timestamp,
Player_Event,
Binge_Details,
case when Binge_Details like "%auto-play" then "Auto-Play" 
     when Binge_Details like '%cue%up%click' then "Clicked-Up-Next" 
     when Binge_Details like "%dismiss" then "Dismiss" 
     when Player_Event like "%details:%" and Binge_Details is not null then "Manual-Selection"
     when Binge_Details like '%deeplink%' then "Manual-Selection"
     when Binge_Details like 'rail%click'then "Manual-Selection" 
else null end as Video_Start_Type,
null device_name,
null Feeder_Video,
null Feeder_Video_Id,
case when Player_Event like "%details:%" and Binge_Details is not null then REGEXP_REPLACE(Player_Event, r'\w+:', '')
     when Binge_Details like "%auto-play" then  REGEXP_EXTRACT(Binge_Details, r"[|][|](.*)[|]")
     when Binge_Details like '%cue%up%click' then  REGEXP_EXTRACT(Binge_Details, r"[|][|](.*)[|]")
     when Binge_Details like 'rail%click'then REGEXP_EXTRACT(Binge_Details, r"[|]([a-zA-Z0-9\s-.:]+)[|]click")
else null end as Display_Name,
null video_id,
null num_seconds_played_no_ads
FROM Raw_Clicks
union all
SELECT
adobe_tracking_id as Adobe_Tracking_ID,
adobe_date as Adobe_Date,
TIMESTAMP_ADD(adobe_timestamp , INTERVAL -40 second) as Adobe_Timestamp,
null Player_Event,
null Binge_Details,
'Vdo_End' as Video_Start_Type,
device_name,
Lag(display_name) over (partition by adobe_tracking_id,adobe_date order by adobe_timestamp) as Feeder_Video,
Lag(video_id) over (partition by adobe_tracking_id,adobe_date order by adobe_timestamp) as Feeder_Video_Id,
display_name as Display_Name,
video_id,
num_seconds_played_no_ads
FROM 
`nbcu-ds-prod-001.PeacockDataMartSilver.SILVER_VIDEO`
where adobe_tracking_ID is not null
and adobe_date = '2022-11-26'
and media_load = False and num_seconds_played_with_ads > 0
order by Adobe_Tracking_ID, Adobe_Timestamp;
