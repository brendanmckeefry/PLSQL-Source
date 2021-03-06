--########################################################################################################
--   VIEW SHOWING DETAILS OF STOCK DISSECTION EXTRACTIONS AND THE ASSOCIATED TIMES
--########################################################################################################

-- DROP VIEW FT_V_STKDISS_TIMER

CREATE OR REPLACE FORCE VIEW FT_V_STKDISS_TIMER
(
RECNO, DEPARTMENT, USERNAME, SALESOFFICE, STATUS,
EXTRACTSTARTDATE, EXTRACTSTARTDATE_STR, EXTRACTENDDATE, EXTRACTENDDATE_STR, 
EXTRACT_MINTAKEN, EXTRACT_SECTAKEN,
UPDATESTARTDATE, UPDATESTARTDATE_STR, UPDATEENDDATE, UPDATEENDDATE_STR, 
UPDATE_MINTAKEN, UPDATE_SECTAKEN,
 
NOOFLOTS,NOOFOLDDLVS,NOOFDLVSTOUPDATE,NOOFRETURNRECS,
DPTRECNO, LOGONNO, ISCOMPLETE, SALOFFNO, UNDISS

)

AS

SELECT 
STKDISSHDR_RECNO,
RTRIM((SELECT DEPARTMENTS.DPT_DESC FROM DEPARTMENTS WHERE DEPARTMENTS.DPTRECNO = STKDISS_HDR.DPTRECNO)) DEPARTMENT,
RTRIM((SELECT LOGONS.LOGONNAME FROM LOGONS WHERE LOGONS.LOGONNO  = STKDISS_HDR.LOGONNO)) LOGONNAME,
RTRIM((SELECT SALOFFNO.SALOFFDESC FROM SALOFFNO WHERE SALOFFNO.SALOFFNO  = STKDISS_HDR.SALOFFNO)) SALOFFNAME,
(CASE WHEN ISCOMPLETE = 1 THEN 'UPDATED' ELSE 'EXTRACT' END) STATUS,
DATERUN  EXTRACTSTARTDATE, TO_CHAR(DATERUN, 'DD/MM/YYYY HH24:MI:SS') AS EXTRACTSTARTDATE_STR, 
COMPLETEDT  EXTRACTENDDATE, TO_CHAR(COMPLETEDT, 'DD/MM/YYYY HH24:MI:SS') AS EXTRACTENDDATE_STR,
FLOOR(((COMPLETEDT - DATERUN )*24)*60) FULLEXTRACT_MINTAKEN,
ROUND((((COMPLETEDT - DATERUN )*24)*60*60)- (FLOOR(((COMPLETEDT - DATERUN )*24)*60) *60),0)   FULLEXTRACT_SECTAKEN,

PRIORTOUPDATE  UPDATESTARTDATE, TO_CHAR(PRIORTOUPDATE, 'DD/MM/YYYY HH24:MI:SS') AS UPDATESTARTDATE_STR, 
DATECOMPLETE  UPDATEENDDATE, TO_CHAR(DATECOMPLETE, 'DD/MM/YYYY HH24:MI:SS') AS UPDATEENDDATE_STR,
FLOOR(((DATECOMPLETE - PRIORTOUPDATE )*24)*60) UPDATE_MINTAKEN,
ROUND((((DATECOMPLETE - PRIORTOUPDATE )*24)*60*60)- (FLOOR(((DATECOMPLETE - PRIORTOUPDATE )*24)*60) *60),0)   UPDATE_SECTAKEN,

NVL((SELECT COUNT(*) FROM STKDISS_DETS WHERE STKDISS_DETS.STKDISSHDR_RECNO = STKDISS_HDR.STKDISSHDR_RECNO),0) NOOFLOTS,
NVL((SELECT COUNT(*) FROM STKDISS_DETS_DLV WHERE STKDISS_DETS_DLV.STKDISSHDR_RECNO= STKDISS_HDR.STKDISSHDR_RECNO),0) NOOFOLDDLVS,
NVL((SELECT COUNT(*) FROM STKDISS_DETS_ONALLOC WHERE STKDISS_DETS_ONALLOC.STKDISSHDR_RECNO = STKDISS_HDR.STKDISSHDR_RECNO),0) NOOFDLVSTOUPDATE,
NVL((SELECT COUNT(*) FROM STKDISS_RETURNS WHERE STKDISS_RETURNS.STKDISSHDR_RECNO = STKDISS_HDR.STKDISSHDR_RECNO),0) NOOFRETURNRECS, 
DPTRECNO, LOGONNO, ISCOMPLETE, SALOFFNO, UNDISS
 FROM STKDISS_HDR
 WHERE ISCOMPLETE IN (0,1)   -- 0 = EXTRACTED 1 = UPDATED  2 = EXTRACTIONS THAT WERE NEVER UPDATED
                             -- I FEEL THAT THERE IS NO POINT EXTRACTING TYPE 2
   
;

-- cVersionControlNo
COMMENT ON TABLE FT_V_STKDISS_TIMER IS  '1.0.1'; 