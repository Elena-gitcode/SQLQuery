

/*
==========================================================================================================
Device Start-Stop Cycle Duration

Created             Date 
Elena Ivanova       2020-Aug-14
==========================================================================================================
*/

-- Create table 

CREATE TABLE    #LndTable
	(
	EventId             varchar(50)
	, DeviceId          varchar(50)
	, [Name]            varchar(10)
	, Epoch             bigint
	)

-- Insert values

INSERT INTO #LndTable	(EventId, DeviceId, [Name], Epoch) VALUES
    ('cae7f748-0f15-49bc-baee-e4715c919743', 'device000001', 'start', '1584674123023'),
    ('d753124b-12b7-4875-8dd5-2d4702b2f45e', 'device000002', 'start', '1584674129112'),
    ('056232cd-5ffc-4ac4-9197-f4a779a6d14e', 'device000001', 'heartbeat', '1584674145224'),
    ('a6da9bf6-15f9-4005-aef2-e50faf4ba0ff', 'device000001', 'stop', '1584674254345'),
    ('8b390817-7599-48eb-b344-4c4bef387ea0', 'device089042', 'heartbeat', '1584674378443'),
    ('898314df-c9a8-4b17-a753-b40cef8ec0bd', 'device000001', 'start', '1587630125000'),
    ('fbeba1ad-1231-4829-b121-072be1ed0a39', 'device129365', 'start', '1587630125034'),
    ('7b6fb919-5697-43cf-acb8-bb3a03a3804d', 'device012001', 'error', '1587630126544'),
    ('4a6be2a8-7de8-462a-8d8a-3a29e36dd823', 'device000001', 'stop', '1587632464012'); 

SELECT EventId, DeviceId, [Name], Epoch FROM  #LndTable;

-- Trasform data

DECLARE     @No_StartStop_Cycles int
SELECT      @No_StartStop_Cycles = count(*) FROM #LndTable WHERE [Name] IN ('Start')
--print     @No_StartStop_Cycles

SELECT      DeviceId,
            EventId,
            [Name],
            Epoch, 
            NTILE(@No_StartStop_Cycles) OVER(ORDER BY DeviceId, Epoch) AS PairNumber  
INTO	    #TfmTable
    FROM        #LndTable
        WHERE       [Name] IN ('start', 'stop') 

SELECT DeviceId, EventId, [Name], Epoch, PairNumber FROM  #TfmTable

-- Prepare data for reporting 
		
SELECT      strt.DeviceId as [DeviceId],
            strt.EventId as [Start EventId],
            strt.Epoch as [Start Epoch],
            dateadd(ms, strt.Epoch%(3600*24*1000), dateadd(day, strt.Epoch/(3600*24*1000), '1970-01-01 00:00:00.000')) as [Start DateTime],
            stp.EventId as [Stop EventId],
            stp.Epoch as [Stop Epoch],
            dateadd(ms, stp.Epoch%(3600*24*1000), dateadd(day, stp.Epoch/(3600*24*1000), '1970-01-01 00:00:00.000')) as [Stop DateTime],
            (stp.Epoch - strt.Epoch) Duration_ms,
            (stp.Epoch - strt.Epoch)/1000 Duration_s,
            (stp.Epoch - strt.Epoch)/(1000*60) Duration_min
INTO        #RptTable
FROM        #TfmTable as strt
INNER JOIN  #TfmTable as stp on strt.DeviceId = stp.DeviceId and strt.PairNumber = stp.PairNumber
    WHERE    strt.[Name] IN ('start')
        AND     stp.[Name] IN ('stop') 


SELECT * FROM #RptTable

-- Aggregation and Filter (Alternatively, can be done on Power BI etc Report)

DECLARE     @DeviceId varchar(50) 
SET         @DeviceId = 'device000001'

SELECT      [DeviceId],
            sum(Duration_ms) as [Total_Duration_ms],
            sum(Duration_s) as [Total_Duration_s],
            sum(Duration_min) as [Total_Duration_min]
FROM        #RptTable
   WHERE        [DeviceId] = @DeviceId
        GROUP BY    [DeviceId]

-- Delete Temp Tables

DROP TABLE #LndTable
DROP TABLE #TfmTable
DROP TABLE #RptTable