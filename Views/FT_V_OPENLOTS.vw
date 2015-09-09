CREATE OR REPLACE FORCE VIEW FT_V_OPENLOTS(OPLITITENO, OPLHERECNO, OPPORNO, OPFFSVESNO, OPLITSENCODE, OPCLAACCODE, OPACCNAME, OPLHEPAYTYP, OPPAYTYP, OPPAYTYPDESC, OPLITPRDNO, OPPRCPRDREF, PRCDESCRIPTION, OPEXPTDDATE, OPDEPTNO, OPDEPTDESC, OPTOTRCVD, MOVTOTRCVD, OPGROSSSALES, MOVGROSSSALES, OPSALESQTY, MOVSALESQTY, OPNETTSALESVALUE, MOVNETTSALESVALUE, OPPROFIT, MOVPROFIT, OPPERCPROFIT, MOVPERCPROFIT, OPREOPENED, ISOPENLOT, SALOFFNO, ONRESERVE, OPREPORTQTY, MOVREPORTQTY, OPOPENPRCQTY, MOVOPENPRCQTY, OPLITUNICOST, POCLOSED, OPCURQTY, MOVCURQTY, OPTOTCOST, MOVTOTCOST, OPSTKVALUE, MOVSTKVALUE, OPTOTALGDSCOST, MOVTOTALGDSCOST, OPAUTHGDSCOST, MOVAUTHGDSCOST, OPGDSCOSTACCRUED, MOVGDSCOSTACCRUED, OPTOTALCHGCOST, MOVTOTALCHGCOST, OPAUTHCHGCOST, MOVAUTHCHGCOST, OPCHGCOSTACCRUED, MOVCHGCOSTACCRUED, OPTOTSUPREBATE, MOVTOTSUPREBATE, OPTOTAUTHSUPREBATE, MOVTOTAUTHSUPREBATE, OPSUPREBATEACCRUED, MOVSUPREBATEACCRUED, PORRECNO, LHESUPREF, LITSTCLOC, LITRCVDATE) AS 
WITH 
SUM_SALES AS (
  SELECT  DPRSTOLOTS.DTLLITITENO, 
          DPRSTOLOTS.DTLSALOFFNO,
          SUM(DPRSTOLOTS.DTLSALESVALUE) AS DTLSALESVALUE,  
          SUM(DPRSTOLOTS.DTLBULKSALESQTY) AS DTLBULKSALESQTY,  
          SUM(DPRSTOLOTS.DTLOPENPRCQTY) AS DTLOPENPRCQTY
  FROM DPRSTOLOTS
  GROUP BY DPRSTOLOTS.DTLLITITENO, DPRSTOLOTS.DTLSALOFFNO),
SUM_SALES_CHGS AS ( 
  SELECT  DPRSTOLOTS.DTLLITITENO, 
          DPRSTOLOTS.DTLSALOFFNO,
          SUM(CASE WHEN DPRSTOLOTSCHGS.DTLCHGSCTYNO = 1 THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP ELSE 0.0 END) AS GOODSCOST,
          SUM(CASE WHEN DPRSTOLOTSCHGS.DTLCHGSCHARGECLASS = 4 THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP ELSE 0.0 END)  AS SUPREBATE,
          SUM(CASE WHEN DPRSTOLOTSCHGS.DTLCHGSTYPNO = 1 THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP ELSE 0.0 END) AS SALESCOST,
          SUM(CASE WHEN DPRSTOLOTSCHGS.DTLCHGSTYPNO = 2 THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP ELSE 0.0 END) AS POCOST,
          SUM(DPRSTOLOTSCHGS.DTLCHGSBASEAPP) AS TOTALCOST
  FROM DPRSTOLOTS  
  INNER JOIN DPRSTOLOTSCHGS
    ON DPRSTOLOTSCHGS.DTLCHGSDTLRECNO = DPRSTOLOTS.DTLRECNO
  WHERE DPRSTOLOTSCHGS.DTLCHGSEXCLFROMPL = 0
  GROUP BY DPRSTOLOTS.DTLLITITENO, DPRSTOLOTS.DTLSALOFFNO),
SUM_PO_CHGS AS ( 
  SELECT  BALTOLOTS.BTLLITITENO, 
          BALTOLOTS.BTLSALOFFNO,
          SUM(BALTOLOTSCHGS.BASEAPP) AS TOTALCOST,
          SUM(CASE WHEN BALTOLOTSCHGS.CHARGECLASS = 4 THEN 0.0 ELSE BALTOLOTSCHGS.ONSTOCKBASEAPP END) AS STOCKVALUE,
          SUM(CASE WHEN BALTOLOTSCHGS.CTYNO = 1 THEN BALTOLOTSCHGS.BASEAPP ELSE 0.0 END) AS GOODSCOST,
          SUM(CASE WHEN BALTOLOTSCHGS.CTYNO = 1 THEN AUTHTOGL.AITBASEAMOUNT ELSE 0.0 END) AS GOODSAUTH,
          SUM(CASE WHEN BALTOLOTSCHGS.CTYNO <> 1 AND BALTOLOTSCHGS.CHARGECLASS <> 4 THEN BALTOLOTSCHGS.BASEAPP ELSE 0.0 END) AS POCOST,
          SUM(CASE WHEN BALTOLOTSCHGS.CTYNO <> 1 THEN NVL(AUTHTOGL.AITBASEAMOUNT, RECOVTOGL.AITBASEAMOUNT) ELSE 0.0 END) AS POCOSTAUTH,
          SUM(CASE WHEN BALTOLOTSCHGS.CHARGECLASS = 4 THEN BALTOLOTSCHGS.BASEAPP ELSE 0.0 END) AS SUPREBATE,
          SUM(CASE WHEN BALTOLOTSCHGS.CHARGECLASS = 4 THEN NVL(AUTHTOGL.AITBASEAMOUNT, RECOVTOGL.AITBASEAMOUNT) ELSE 0.0 END) AS SUPREBATEAUTH
  FROM BALTOLOTS
  INNER JOIN BALTOLOTSCHGS
    ON BALTOLOTSCHGS.BTLRECNO = BALTOLOTS.BTLRECNO
  LEFT OUTER JOIN (SELECT ACCITE.AITITERECNO, SUM(CASE WHEN ACCITE.AITDRCR = 'C' THEN -1 * ACCITE.AITBASEAMOUNT ELSE ACCITE.AITBASEAMOUNT END) AS AITBASEAMOUNT FROM ACCITE WHERE ACCITE.AITGLTRECNO > 0 GROUP BY ACCITE.AITITERECNO) AUTHTOGL
    ON AUTHTOGL.AITITERECNO = BALTOLOTSCHGS.ICHRECNO
  LEFT OUTER JOIN (SELECT PORECOVITE.PORECOVAITITERECNO, SUM(CASE WHEN PORECOVITE.PORECOVAITDRCR = 'C' THEN -1 * PORECOVITE.PORECOVAITBASEAMT ELSE PORECOVITE.PORECOVAITBASEAMT END) AS AITBASEAMOUNT FROM PORECOVITE WHERE PORECOVITE.PORECOVGLTRECNO > 0 AND PORECOVITE.PORECOVPSTRECNO = 34 GROUP BY PORECOVITE.PORECOVAITITERECNO) RECOVTOGL
    ON RECOVTOGL.PORECOVAITITERECNO = BALTOLOTSCHGS.ICHRECNO    
  WHERE EXCLFROMPL = 0
  GROUP BY BALTOLOTS.BTLLITITENO, BALTOLOTS.BTLSALOFFNO),
REPORTED_PRICES AS (
  SELECT  LOTRETURNPRICES.LITITENO,
          SUM(LOTRETURNPRICES.LOTRETURNQTY) AS LOTRETURNQTY
  FROM LOTRETURNPRICES
  GROUP BY LOTRETURNPRICES.LITITENO),
LAST_PROFITISE AS (
  SELECT * 
  FROM OPENLOTSARCHIVE 
  WHERE PROFHISTRECNO IN(SELECT MAX(PROFHISTRECNO) FROM LOTPROFITHISTORY GROUP BY LITITENO))
SELECT  LOTITE.LITITENO AS OPLITITENO,
        LOTHED.LHERECNO AS OPLHERECNO,
        PURORD.PORNO AS OPPORNO,
        PURORD.FFSVESNO AS OPFFSVESNO,
        LOTITE.LITSENCODE AS OPLITSENCODE,
        CAST(BSDL_PKAGE_ACCOUNTS.GETACCCODE(ACCCLASS.CLARECNO, PURORD.PORSALOFF) AS VARCHAR(8)) AS OPCLAACCODE,
        ACCOUNTS.ACCNAME AS OPACCNAME,
        LOTITE.LITPAYTYP AS OPLHEPAYTYP,
        CATDESC.LKUPNO AS OPPAYTYP,
        CATDESC.LKUPDESC AS OPPAYTYPDESC,
        PRDREC.PRCPRDNO AS OPLITPRDNO,
        PRDREC.PRCPRDREF AS OPPRCPRDREF,
        PRDREC.PRCDESCRIPTION,
        PURORD.EXPTDDATE AS OPEXPTDDATE,
        DEPARTMENTS.DPTRECNO AS OPDEPTNO,
        DEPARTMENTS.DPT_DESC AS OPDEPTDESC,
        BALTOLOTS.RCVQTY AS OPTOTRCVD,
        BALTOLOTS.RCVQTY - NVL(LAST_PROFITISE.OPTOTRCVD, 0) AS MOVTOTRCVD,
        NVL(SUM_SALES.DTLSALESVALUE, 0.0) AS OPGROSSSALES,
        NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(LAST_PROFITISE.OPGROSSSALES, 0.0) AS MOVGROSSSALES,
        NVL(SUM_SALES.DTLBULKSALESQTY, 0.0) AS OPSALESQTY,
        NVL(SUM_SALES.DTLBULKSALESQTY, 0.0) - NVL(LAST_PROFITISE.OPSALESQTY, 0.0)  AS MOVSALESQTY,
        NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.SALESCOST, 0.0) AS OPNETTSALESVALUE,
        (NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.SALESCOST, 0.0)) - NVL(LAST_PROFITISE.OPNETTSALESVALUE , 0.0) AS MOVNETTSALESVALUE,
        NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.TOTALCOST, 0.0) AS OPPROFIT,
        NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.TOTALCOST, 0.0) - NVL(LAST_PROFITISE.OPPROFIT , 0.0) AS MOVPROFIT,
        ROUND((NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.TOTALCOST, 0.0)) / NULLIF((NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.SALESCOST, 0.0)), 0.0) * 100.0, 2) AS OPPERCPROFIT,
        CASE
          WHEN LOTPROFITSALOFF.REOPENED = 1 AND (NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.SALESCOST, 0.0)) = 0.0 THEN ROUND(SIGN((NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.TOTALCOST, 0.0))) * 100.0, 2)
          ELSE ROUND((NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.TOTALCOST, 0.0) - NVL(LAST_PROFITISE.OPPROFIT, 0.0)) / NULLIF((NVL(SUM_SALES.DTLSALESVALUE, 0.0) - NVL(SUM_SALES_CHGS.SALESCOST, 0.0)), 0.0) * 100.0, 2)
        END AS MOVPERCPROFIT,
        LOTPROFITSALOFF.REOPENED AS OPREOPENED,
        LOTPROFITSALOFF.ISOPENLOT,
        LOTPROFITSALOFF.SALOFFNO,
        NVL(LOTITE.ONRESERVE, 0) AS ONRESERVE,
        REPORTED_PRICES.LOTRETURNQTY AS OPREPORTQTY,
        NVL(REPORTED_PRICES.LOTRETURNQTY, 0) - NVL(LAST_PROFITISE.OPREPORTQTY, 0.0) AS MOVREPORTQTY,
        SUM_SALES.DTLOPENPRCQTY AS OPOPENPRCQTY,
        SUM_SALES.DTLOPENPRCQTY - NVL(LAST_PROFITISE.OPOPENPRCQTY, 0.0) AS MOVOPENPRCQTY,
        CASE 
          WHEN LOTPROFITSALOFF.REOPENED = 1 THEN NULL
          WHEN LOTITE.LITPAYTYP = 8 THEN (NVL(SUM_SALES_CHGS.POCOST, 0.0) - NVL(SUM_SALES_CHGS.SUPREBATE, 0.0)) / NULLIF(SUM_SALES.DTLBULKSALESQTY, 0.0) 
          ELSE (NVL(SUM_PO_CHGS.TOTALCOST, 0.0) - NVL(SUM_PO_CHGS.SUPREBATE, 0.0)) / NULLIF(BALTOLOTS.RCVQTY, 0)
        END AS OPLITUNICOST,
        LOTITE.LITRCVCOMPLETE AS POCLOSED,
        BALTOLOTS.ONSTOCKQTY AS OPCURQTY,
        BALTOLOTS.ONSTOCKQTY - NVL(LAST_PROFITISE.OPCURQTY, 0) AS MOVCURQTY,
        NVL(SUM_PO_CHGS.TOTALCOST, 0.0) AS OPTOTCOST,
        NVL(SUM_PO_CHGS.TOTALCOST, 0.0) - NVL(LAST_PROFITISE.OPTOTCOST, 0.0) AS MOVTOTCOST,
        CASE WHEN LOTITE.LITPAYTYP = 8 THEN 0.0 ELSE NVL(SUM_PO_CHGS.STOCKVALUE, 0.0) END AS OPSTKVALUE,
        (CASE WHEN LOTITE.LITPAYTYP = 8 THEN 0.0 ELSE NVL(SUM_PO_CHGS.STOCKVALUE, 0.0) END) - NVL(LAST_PROFITISE.OPSTKVALUE, 0.0) AS MOVSTKVALUE,
        --NVL(SUM_PO_CHGS.GOODSCOST, 0.0) AS OPTOTALGDSCOST,
        --NVL(SUM_PO_CHGS.GOODSCOST, 0.0) - NVL(LAST_PROFITISE.OPTOTALGDSCOST, 0.0) AS MOVTOTALGDSCOST,
        CASE 
          WHEN LOTITE.LITPAYTYP = 8 AND NVL(REPORTED_PRICES.LOTRETURNQTY, 0) >  NVL(SUM_SALES.DTLBULKSALESQTY, 0.0) THEN SUM_PO_CHGS.GOODSCOST * REPORTED_PRICES.LOTRETURNQTY / NULLIF(BALTOLOTS.RCVQTY, 0) + NVL(SUM_PO_CHGS.GOODSAUTH, 0.0)
          WHEN LOTITE.LITPAYTYP = 8 THEN NVL(SUM_SALES_CHGS.GOODSCOST, 0.0) - NVL(SUM_PO_CHGS.GOODSAUTH, 0.0) + NVL(SUM_PO_CHGS.GOODSAUTH, 0.0)
          ELSE NVL(SUM_PO_CHGS.GOODSCOST, 0.0) 
        END AS OPTOTALGDSCOST,
        CASE 
          WHEN LOTITE.LITPAYTYP = 8 AND NVL(REPORTED_PRICES.LOTRETURNQTY, 0) >  NVL(SUM_SALES.DTLBULKSALESQTY, 0.0) THEN SUM_PO_CHGS.GOODSCOST * REPORTED_PRICES.LOTRETURNQTY / NULLIF(BALTOLOTS.RCVQTY, 0) + NVL(SUM_PO_CHGS.GOODSAUTH, 0.0)
          WHEN LOTITE.LITPAYTYP = 8 THEN NVL(SUM_SALES_CHGS.GOODSCOST, 0.0) - NVL(SUM_PO_CHGS.GOODSAUTH, 0.0) + NVL(SUM_PO_CHGS.GOODSAUTH, 0.0)
          ELSE NVL(SUM_PO_CHGS.GOODSCOST, 0.0) 
        END - NVL(LAST_PROFITISE.OPTOTALGDSCOST, 0.0) AS MOVTOTALGDSCOST,
        NVL(SUM_PO_CHGS.GOODSAUTH, 0.0) AS OPAUTHGDSCOST,
        NVL(SUM_PO_CHGS.GOODSAUTH, 0.0) - NVL(LAST_PROFITISE.OPAUTHGDSCOST, 0.0) AS MOVAUTHGDSCOST,
        CASE 
          WHEN LOTITE.LITPAYTYP = 8 AND NVL(REPORTED_PRICES.LOTRETURNQTY, 0) >  NVL(SUM_SALES.DTLBULKSALESQTY, 0.0) THEN SUM_PO_CHGS.GOODSCOST * REPORTED_PRICES.LOTRETURNQTY / NULLIF(BALTOLOTS.RCVQTY, 0)
          WHEN LOTITE.LITPAYTYP = 8 THEN NVL(SUM_SALES_CHGS.GOODSCOST, 0.0) - NVL(SUM_PO_CHGS.GOODSAUTH, 0.0) 
          ELSE NVL(SUM_PO_CHGS.GOODSCOST, 0.0) - NVL(SUM_PO_CHGS.GOODSAUTH, 0.0) 
        END AS OPGDSCOSTACCRUED,
        CASE 
          WHEN LOTITE.LITPAYTYP = 8 AND NVL(REPORTED_PRICES.LOTRETURNQTY, 0) >  NVL(SUM_SALES.DTLBULKSALESQTY, 0.0) THEN SUM_PO_CHGS.GOODSCOST * REPORTED_PRICES.LOTRETURNQTY / NULLIF(BALTOLOTS.RCVQTY, 0)
          WHEN LOTITE.LITPAYTYP = 8 THEN NVL(SUM_SALES_CHGS.GOODSCOST, 0.0) - NVL(SUM_PO_CHGS.GOODSAUTH, 0.0) 
          ELSE NVL(SUM_PO_CHGS.GOODSCOST, 0.0) - NVL(SUM_PO_CHGS.GOODSAUTH, 0.0) 
        END - NVL(LAST_PROFITISE.OPGDSCOSTACCRUED, 0.0) AS MOVGDSCOSTACCRUED,
        (NVL(SUM_PO_CHGS.POCOST, 0.0) + NVL(SUM_SALES_CHGS.SUPREBATE, 0.0)) AS OPTOTALCHGCOST,
        (NVL(SUM_PO_CHGS.POCOST, 0.0) + NVL(SUM_SALES_CHGS.SUPREBATE, 0.0)) - NVL(LAST_PROFITISE.OPTOTALCHGCOST, 0.0) AS MOVTOTALCHGCOST,
        NVL(SUM_PO_CHGS.POCOSTAUTH, 0.0) AS OPAUTHCHGCOST,
        NVL(SUM_PO_CHGS.POCOSTAUTH, 0.0) - NVL(LAST_PROFITISE.OPAUTHCHGCOST, 0.0) AS MOVAUTHCHGCOST,
        NVL(SUM_PO_CHGS.POCOST, 0.0) + NVL(SUM_SALES_CHGS.SUPREBATE, 0.0) - NVL(SUM_PO_CHGS.POCOSTAUTH, 0.0) AS OPCHGCOSTACCRUED,
        (NVL(SUM_PO_CHGS.POCOST, 0.0) + NVL(SUM_SALES_CHGS.SUPREBATE, 0.0) - NVL(SUM_PO_CHGS.POCOSTAUTH, 0.0)) - NVL(LAST_PROFITISE.OPCHGCOSTACCRUED, 0.0) AS MOVCHGCOSTACCRUED,
        NVL(SUM_SALES_CHGS.SUPREBATE, 0.0) AS OPTOTSUPREBATE,
        NVL(SUM_SALES_CHGS.SUPREBATE, 0.0) - NVL(LAST_PROFITISE.OPTOTSUPREBATE, 0.0) AS MOVTOTSUPREBATE,
        NVL(SUM_PO_CHGS.SUPREBATEAUTH, 0.0) AS OPTOTAUTHSUPREBATE,
        NVL(SUM_PO_CHGS.SUPREBATEAUTH, 0.0) - NVL(LAST_PROFITISE.OPTOTAUTHSUPREBATE, 0.0) AS MOVTOTAUTHSUPREBATE,
        NVL(SUM_SALES_CHGS.SUPREBATE, 0.0) - NVL(SUM_PO_CHGS.SUPREBATEAUTH, 0.0)  AS OPSUPREBATEACCRUED,
        (NVL(SUM_SALES_CHGS.SUPREBATE, 0.0) - NVL(LAST_PROFITISE.OPTOTSUPREBATE, 0.0)) - (NVL(SUM_PO_CHGS.SUPREBATEAUTH, 0.0) - NVL(LAST_PROFITISE.OPTOTAUTHSUPREBATE, 0.0))  AS MOVSUPREBATEACCRUED,
        PURORD.PORRECNO,
        LOTHED.LHESUPREF,
        LOTITE.LITSTCLOC,
        LOTITE.LITRCVDATE
FROM BALTOLOTS
INNER JOIN LOTITE
  ON LOTITE.LITITENO = BALTOLOTS.BTLLITITENO
INNER JOIN LOTDET
  ON LOTDET.DETRECNO = LOTITE.LITDETNO
INNER JOIN LOTHED
  ON LOTHED.LHERECNO = LOTDET.DETLHERECNO
INNER JOIN PURORD 
  ON PURORD.PORRECNO = LOTHED.LHEPORRECNO
INNER JOIN PRDREC
  ON PRDREC.PRCPRDNO = LOTITE.LITPRDNO
INNER JOIN ACCCLASS
  ON ACCCLASS.CLARECNO = LOTHED.LHESENCODE
INNER JOIN ACCOUNTS
  ON ACCOUNTS.ACCRECNO = ACCCLASS.CLAACCNO
INNER JOIN DEPARTMENTSTOSMN
  ON DEPARTMENTSTOSMN.SMNNO = LOTITE.LITBUYER
INNER JOIN DEPARTMENTS
  ON DEPARTMENTS.DPTRECNO = DEPARTMENTSTOSMN.DPTRECNO
INNER JOIN ACCCATDESC
  ON ACCCATDESC.CLACLASS = LOTITE.LITPAYTYP--NVL(LOTITE.LITPAYTYP, LOTHED.LHEPAYTYP)
INNER JOIN LOOKUPS CATDESC
  ON CATDESC.LKUPNO = ACCCATDESC.CLACLASSDESC AND CATDESC.LKUPTABLE = 'ACCCATDESC' AND CATDESC.LKUPFIELDNAME = 'CLACLASSDESC'
INNER JOIN LOTPROFITSALOFF
  ON LOTPROFITSALOFF.LITITENO = LOTITE.LITITENO
LEFT OUTER JOIN SUM_SALES
  ON SUM_SALES.DTLLITITENO = BALTOLOTS.BTLLITITENO AND SUM_SALES.DTLSALOFFNO = BALTOLOTS.BTLSALOFFNO
LEFT OUTER JOIN SUM_SALES_CHGS
  ON SUM_SALES_CHGS.DTLLITITENO = BALTOLOTS.BTLLITITENO AND SUM_SALES_CHGS.DTLSALOFFNO = BALTOLOTS.BTLSALOFFNO
LEFT OUTER JOIN SUM_PO_CHGS
  ON SUM_PO_CHGS.BTLLITITENO = BALTOLOTS.BTLLITITENO AND SUM_PO_CHGS.BTLSALOFFNO = BALTOLOTS.BTLSALOFFNO  
LEFT OUTER JOIN REPORTED_PRICES
  ON REPORTED_PRICES.LITITENO = BALTOLOTS.BTLLITITENO 
LEFT OUTER JOIN LAST_PROFITISE
  ON LAST_PROFITISE.OPLITITENO = BALTOLOTS.BTLLITITENO WITH READ ONLY;
 
COMMENT ON TABLE FT_V_OPENLOTS  IS 'v1.0.1 - View to give open lot information';
 
