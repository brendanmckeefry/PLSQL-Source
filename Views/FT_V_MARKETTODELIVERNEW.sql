--########################################################################################################
--   VIEW SHOWING THE TIME TAKEN TO RUN THE 3 DIFFERENT PROCESSES IN MARKETTODELIVERNEW
--########################################################################################################

-- DROP VIEW FT_V_MARKETTODELIVER_TIMER

CREATE OR REPLACE FORCE VIEW FT_V_MARKETTODELIVER_TIMER
(RECNO, SALESOFFICE,
TYPEDESC, 
USERNAME,
RECS_UPDATED, 
MIN_DIFF,  SEC_DIFF,  
STARTTIME, ENDTIME, 
NOOFERRS, EXTRAINFO,
SALOFFNO, TYPE, LOGONNO, 
STARTTIME_STR, ENDTIME_STR
)
AS

SELECT MTDNEWRECNO, 
(SELECT SALOFFNO.SALOFFDESC FROM SALOFFNO WHERE SALOFFNO.SALOFFNO = MTDNEW_SALOFFNO) SALOFFDESC, 
RTRIM(MTDNEW_TIMERTYPEDESC), 
RTRIM((SELECT LOGONS.LOGONNAME FROM LOGONS WHERE LOGONS.LOGONNO  = MTDNEWLOGONNO)) LOGONNAME,
MTDNEW_NOOFRECSUPD,  
FLOOR(((MTDNEW_ENDTIME - MTDNEW_STARTTIME )*24)*60) MIN_DIFF,
ROUND((((MTDNEW_ENDTIME - MTDNEW_STARTTIME )*24)*60*60)- (FLOOR(((MTDNEW_ENDTIME - MTDNEW_STARTTIME )*24)*60) *60),0)   SEC_DIFF,
MTDNEW_STARTTIME, MTDNEW_ENDTIME, 
MTDNEW_NOOFERRS, MTDNEW_EXTRAINFO,
MTDNEW_SALOFFNO,  MTDNEW_TIMERTYPE,  MTDNEWLOGONNO,
TO_CHAR(MTDNEW_STARTTIME, 'DD/MM/YYYY HH24:MI:SS') AS STARTTIME_STR,
TO_CHAR(MTDNEW_ENDTIME, 'DD/MM/YYYY HH24:MI:SS') AS ENDTIME_STR


FROM MARKETTODELIVERNEW_TIMER ORDER BY 1 DESC;

-- cVersionControlNo
COMMENT ON TABLE FT_V_MARKETTODELIVER_TIMER IS  '1.0.1'; 