--########################################################################################################
-- FT_V_PO (View)
-- 
-- Developer view to display purchase order details
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE FORCE VIEW FT_V_PO
(
   PORRECNO,
   PORNO,
   LHERECNO,
   LITITENO,
   LITID,
   LHESENCODE,
   LITSTCLOC,
   LITORGEXP,
   LITQTYRCV,
   LITPALQTY,
   LITRCVPALS,
   EXPTDDATE,
   LITEXPDATE,
   LITRCVDATE,
   LITUNICOST,
   LITRCVCOMPLETE,
   LITNETTWGT,
   PRCWEIGHT,
   DUTYWGT,
   LITPURBYTYP,
   LITSTANDNOOF,
   DEFQCNARREC,
   WGTFLAG,
   PORSALOFF,
   DESPATCHLOC,
   RCVINGTYP,
   LHEPAYTYP,
   LITPRDNO,
   LITBUYER,
   PRCREF1,
   PRCREF2,
   PRCREF3,
   PRCREF4,
   PRCREF5,
   PRCREF6,
   ISEXCEPTION,
   ONRESERVE,
   PORCLOSED
)
AS
   SELECT PURORD.PORRECNO,
          PURORD.PORNO,
          LOTHED.LHERECNO,
          LOTITE.LITITENO,
          LOTITE.LITID,
          LOTHED.LHESENCODE,
          LOTITE.LITSTCLOC,
          LOTITE.LITORGEXP,
          LOTITE.LITQTYRCV,
          LOTITE.LITPALQTY,
          LOTITE.LITRCVPALS,
          PURORD.EXPTDDATE,
          LOTITE.LITEXPDATE,
          LOTITE.LITRCVDATE,
          LOTITE.LITUNICOST,
          LOTITE.LITRCVCOMPLETE,
          LOTITE.LITNETTWGT,
          PRDREC.PRCWEIGHT,
          (LOTITE.DUTYBOXWGT * NVL (LOTITE.LITQTYRCV, LOTITE.LITORGEXP))
             AS DUTYWGT,
          LOTITE.LITPURBYTYP,
          LOTITE.LITSTANDNOOF,
          LOTITE.DEFQCNARREC,
          LOTITE.WGTFLAG,
          NVL (PURORD.PORSALOFF, -32000) PORSALOFF,
          PURORD.DESPATCHLOC,
          PURORD.RCVINGTYP,
          NVL (LOTITE.LITPAYTYP, LOTHED.LHEPAYTYP) AS LHEPAYTYP,
          LOTITE.LITPRDNO,
          LOTITE.LITBUYER,
          PRDREC.PRCREF1,
          PRDREC.PRCREF2,
          PRDREC.PRCREF3,
          PRDREC.PRCREF4,
          PRDREC.PRCREF5,
          PRDREC.PRCREF6,
          LOTITE.ISEXCEPTION,
          LOTITE.ONRESERVE,
          NVL (PURORD.PORCLOSED, 0) AS PORCLOSED
     FROM PURORD
          INNER JOIN LOTHED
             ON LOTHED.LHEPORRECNO = PURORD.PORRECNO
          INNER JOIN LOTDET
             ON LOTDET.DETLHERECNO = LOTHED.LHERECNO
          INNER JOIN LOTITE
             ON LOTITE.LITDETNO = LOTDET.DETRECNO
          INNER JOIN PRDREC
             ON PRDREC.PRCPRDNO = LOTITE.LITPRDNO
   WITH READ ONLY;
