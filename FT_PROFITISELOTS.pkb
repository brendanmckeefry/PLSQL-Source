--
-- FT_PROFITISELOTS  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY FT_PROFITISELOTS AS

  PROCEDURE LOTPROFITABILITY(REQDISTSTAB_IN VARCHAR2, AUTOSALESTAB_IN VARCHAR2)
  IS
    SQL_STMT          VARCHAR2(10000);
    PARAMETER_LIST    FT_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    IF NOT FT_DB_UTILS.TABLE_EXISTS(REQDISTSTAB_IN) THEN
      PARAMETER_LIST('#PARAMNAME') := 'REQDISTSTAB_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(REQDISTSTAB_IN);
      FT_ERRORS.RAISE_ERROR(FT_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF NOT FT_DB_UTILS.TABLE_EXISTS(AUTOSALESTAB_IN) THEN
      PARAMETER_LIST('#PARAMNAME') := 'AUTOSALESTAB_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(AUTOSALESTAB_IN);
      FT_ERRORS.RAISE_ERROR(FT_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    -- When the table name is dynamic there is no point in using parameters as the execution plan cannot be cached
    SQL_STMT  :=  'UPDATE LOTPROFIT' ||  CONST.CR ||
                  'SET Reopened = 1' ||  CONST.CR ||
                  'WHERE lotprofit.LitIteNo IN (SELECT salestab.LitIteNo FROM ' || AUTOSALESTAB_IN || ' salestab)' ||  CONST.CR ||
                  ' AND ABS(ProfitAmount - (SELECT SUM(NVL(salestab.LitProfForSale, 0.0))' ||  CONST.CR ||
                  '                         FROM ' || AUTOSALESTAB_IN || ' salestab' ||  CONST.CR ||
                  '                         WHERE salestab.LitIteNo = lotprofit.LitIteNo)) > 0.009';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET IsException = 0' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)' ||  CONST.CR ||
                  ' AND EXISTS(SELECT * FROM LOTPROFIT lotprofit WHERE lotprofitsaloff.LitIteNo  = lotprofit.LitIteNo AND lotprofit.Reopened = 1)' ||  CONST.CR ||
                  ' AND IsException = 1';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTITE' ||  CONST.CR ||
                  'SET IsException = 0' ||  CONST.CR ||
                  'WHERE lotite.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)' ||  CONST.CR ||
                  ' AND EXISTS(SELECT * FROM LOTPROFIT lotprofit WHERE lotite.LitIteNo  = lotprofit.LitIteNo AND lotprofit.Reopened = 1)' ||  CONST.CR ||
                  ' AND IsException = 1';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET 	GrossSales = 0.0,' ||  CONST.CR ||
                  '     NettSales = 0.0,' ||  CONST.CR ||
                  '     Profit = 0.0,' ||  CONST.CR ||
                  '     ProfitPerc = 0.0,' ||  CONST.CR ||
                  '     SoldQtyEquiv = 0,' ||  CONST.CR ||
                  '     LheProfitPerc = 0.0,' ||  CONST.CR ||
                  '     POCosts = NVL((	SELECT SUM(itechg.IchAppAmt)' ||  CONST.CR ||
                  '                     FROM ITECHG itechg, EXPCHA expcha' ||  CONST.CR ||
                  '                     WHERE itechg.ExcRecNo = expcha.ExcChaRec' ||  CONST.CR ||
                  '                       AND NVL(expcha.ExcRecovFromPL, 0) = 0' ||  CONST.CR ||
                  '                       AND itechg.IchIstRecNo IS NULL' ||  CONST.CR ||
                  '                       AND itechg.CtyNo <> 1' ||  CONST.CR ||
                  '                       AND lotprofitsaloff.LitIteNo = itechg.LitRecNo), 0.0),' ||  CONST.CR ||
                  '     GoodsCost = NVL(( SELECT SUM(itechg.IchAppAmt)' ||  CONST.CR ||
                  '                       FROM ITECHG itechg, EXPCHA expcha' ||  CONST.CR ||
                  '                       WHERE itechg.ExcRecNo = expcha.ExcChaRec' ||  CONST.CR ||
                  '                         AND NVL(expcha.ExcRecovFromPL, 0) = 0' ||  CONST.CR ||
                  '                         AND itechg.IchIstRecNo IS NULL' ||  CONST.CR ||
                  '                         AND itechg.CtyNo = 1' ||  CONST.CR ||
                  '                         AND lotprofitsaloff.LitIteNo = itechg.LitRecNo), 0.0)' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'MERGE INTO LOTPROFITSALOFF lotprofitsaloff' ||  CONST.CR ||
                  'USING (' ||  CONST.CR ||
                  ' SELECT 	salestab.LitIteNo,' ||  CONST.CR ||
                  '         itesto.IstRecNo,' ||  CONST.CR ||
                  '         salestab.LheRecNo,' ||  CONST.CR ||
                  '         salestab.PorSalOff,' ||  CONST.CR ||
                  '         SUM(NVL(salestab.DelBaseGrVal, 0.0)) AS GrossSales,' ||  CONST.CR ||
                  '         SUM(NVL(salestab.DelBaseNettValNew, 0.0)) AS NettSales,' ||  CONST.CR ||
                  '         NVL(( SELECT SUM(itechg.IchAppAmt)' ||  CONST.CR ||
                  '               FROM ITECHG itechg, EXPCHA expcha' ||  CONST.CR ||
                  '               WHERE itechg.LitRecNo = salestab.LitIteNo' ||  CONST.CR ||
                  '                 AND itechg.ExcRecNo = expcha.ExcChaRec' ||  CONST.CR ||
                  '                 AND NVL(expcha.ExcRecovFromPL, 0) = 0' ||  CONST.CR ||
                  '                 AND itechg.IchIstRecNo IS NULL), 0.0) AS POCosts,' ||  CONST.CR ||
                  '         NVL(( SELECT SUM(itechg.IchAppAmt)' ||  CONST.CR ||
                  '               FROM ITECHG itechg, EXPCHA expcha' ||  CONST.CR ||
                  '               WHERE itechg.LitRecNo = salestab.LitIteNo' ||  CONST.CR ||
                  '                 AND itechg.ExcRecNo = expcha.ExcChaRec' ||  CONST.CR ||
                  '                 AND NVL(expcha.ExcRecovFromPL, 0) = 0' ||  CONST.CR ||
                  '                 AND itechg.CtyNo = 1' ||  CONST.CR ||
                  '                 AND itechg.IchIstRecNo IS NULL), 0.0) AS GoodsCost,' ||  CONST.CR ||
                  '         SUM(NVL(salestab.DelLitQtyNew, 0.0)) AS SoldQtyEquiv' ||  CONST.CR ||
                  'FROM ' || AUTOSALESTAB_IN || ' salestab' ||  CONST.CR ||
                  'INNER JOIN ITESTO itesto' ||  CONST.CR ||
                  q'[ ON itesto.IstLitNo = salestab.LitIteNo AND itesto.IstFstRec = 'Y']' ||  CONST.CR ||
                  'GROUP BY salestab.LitIteNo,' ||  CONST.CR ||
                  '         itesto.IstRecNo,' ||  CONST.CR ||
                  '         salestab.LheRecNo,' ||  CONST.CR ||
                  '         salestab.PorSalOff' ||  CONST.CR ||
                  ') salestab' ||  CONST.CR ||
                  'ON (salestab.IstRecNo = lotprofitsaloff.IstRecNo)' ||  CONST.CR ||
                  'WHEN MATCHED THEN' ||  CONST.CR ||
                  'UPDATE' ||  CONST.CR ||
                  'SET	lotprofitsaloff.LheRecNo = salestab.LheRecNo,' ||  CONST.CR ||
                  '     lotprofitsaloff.GrossSales = salestab.GrossSales,' ||  CONST.CR ||
                  '     lotprofitsaloff.NettSales = salestab.NettSales,' ||  CONST.CR ||
                  '     lotprofitsaloff.POCosts = salestab.POCosts - salestab.GoodsCost,' ||  CONST.CR ||
                  '     lotprofitsaloff.GoodsCost = salestab.GoodsCost,' ||  CONST.CR ||
                  '     lotprofitsaloff.Profit = salestab.NettSales - salestab.POCosts,' ||  CONST.CR ||
                  '     lotprofitsaloff.ProfitPerc = CASE WHEN ABS(salestab.NettSales) < 0.01 THEN 0.0 ELSE ROUND((salestab.NettSales - salestab.POCosts) / ABS(salestab.NettSales) * 100.0, 2) END,' ||  CONST.CR ||
                  '     lotprofitsaloff.SoldQtyEquiv = salestab.SoldQtyEquiv' ||  CONST.CR ||
                  'WHEN NOT MATCHED THEN' ||  CONST.CR ||
                  'INSERT ( lotprofitsaloff.LpsRecNo,' ||  CONST.CR ||
                  '         lotprofitsaloff.LitIteNo,' ||  CONST.CR ||
                  '         lotprofitsaloff.IstRecNo,' ||  CONST.CR ||
                  '         lotprofitsaloff.LheRecNo,' ||  CONST.CR ||
                  '         lotprofitsaloff.SalOffNo,' ||  CONST.CR ||
                  '         lotprofitsaloff.GrossSales,' ||  CONST.CR ||
                  '         lotprofitsaloff.NettSales,' ||  CONST.CR ||
                  '         lotprofitsaloff.POCosts,' ||  CONST.CR ||
                  '         lotprofitsaloff.GoodsCost,' ||  CONST.CR ||
                  '         lotprofitsaloff.Profit,' ||  CONST.CR ||
                  '         lotprofitsaloff.ProfitPerc,' ||  CONST.CR ||
                  '         lotprofitsaloff.SoldQtyEquiv,' ||  CONST.CR ||
                  '         lotprofitsaloff.Profitised)' ||  CONST.CR ||
                  q'[VALUES (SP_WIZGETCONTROL('NXTLPSRECNO' , 1, 'FT_COSTING'),]' ||  CONST.CR ||
                  '         salestab.LitIteNo,' ||  CONST.CR ||
                  '         salestab.IstRecNo,' ||  CONST.CR ||
                  '         salestab.LheRecNo,' ||  CONST.CR ||
                  '         salestab.PorSalOff,' ||  CONST.CR ||
                  '			    salestab.GrossSales,' ||  CONST.CR ||
                  '         salestab.NettSales,' ||  CONST.CR ||
                  '         salestab.POCosts - salestab.GoodsCost,' ||  CONST.CR ||
                  '         salestab.GoodsCost,' ||  CONST.CR ||
                  '         salestab.NettSales - salestab.POCosts,' ||  CONST.CR ||
                  '         CASE WHEN ABS(salestab.NettSales) < 0.01 THEN 0.0 ELSE ROUND((salestab.NettSales - salestab.POCosts) / ABS(salestab.NettSales) * 100.0, 2) END,' ||  CONST.CR ||
                  '         salestab.SoldQtyEquiv,' ||  CONST.CR ||
                  '         0)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET FullySoldInvoiced = NVL((SELECT MIN(CASE WHEN lotitercvd.RcvdQty = lotitesold.SoldQty THEN 1 ELSE 0 END)' ||  CONST.CR ||
                  '                             FROM 	(SELECT isttab.LitIteNo, SUM(NVL(isttab.TotQty, 0)) AS RcvdQty FROM ' || REQDISTSTAB_IN || ' isttab GROUP BY LitIteNo) lotitercvd,' ||  CONST.CR ||
                  '                                   (SELECT salestab.LitIteNo, SUM(NVL(salestab.DelLitQty, 0.0)) AS SoldQty FROM ' || AUTOSALESTAB_IN || q'[ salestab WHERE DelStatus = 'Inv' GROUP BY LitIteNo) lotitesold]' ||  CONST.CR ||
                  '                             WHERE lotitercvd.LitIteNo = lotitesold.LitIteNo(+)' ||  CONST.CR ||
                  '                               AND lotitercvd.LitIteNo = lotprofitsaloff.LitIteNo), 0)' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET HasGoodsCost = NVL(( SELECT CASE WHEN ABS(SUM(itechg.IchAppAmt)) > 0.009 THEN 1 ELSE 0 END' ||  CONST.CR ||
                  '							            FROM ITECHG itechg' ||  CONST.CR ||
                  '                         WHERE itechg.LitRecNo = lotprofitsaloff.LitIteNo' ||  CONST.CR ||
                  '                           AND itechg.CtyNo = 1' ||  CONST.CR ||
                  '                           AND itechg.IchIstRecNo IS NULL), 0)' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET POCostAuth =	NVL((SELECT MIN(CASE' ||  CONST.CR ||
                  '												          WHEN saloffno.LotProfitMeth IN(1, 2) AND ABS(NVL(itechg.IchAppAmt, 0.0) - NVL(authtogl.AuthToGLAmt, NVL(recovtogl.AuthToGLAmt, 0.0))) > 0.009 THEN 0' ||  CONST.CR ||
                  '                                 WHEN saloffno.LotProfitMeth IN(3, 4) AND ABS(NVL(authtogl.AuthToGLAmt, NVL(recovtogl.AuthToGLAmt, 0.0))) < 0.01 THEN 0' ||  CONST.CR ||
                  '                                 ELSE 1' ||  CONST.CR ||
                  '                                 END)' ||  CONST.CR ||
                  '                     FROM ITECHG itechg, EXPCHA expcha, SALOFFNO saloffno,' ||  CONST.CR ||
                  q'[                       (SELECT accite.AitIteRecNo, SUM(CASE WHEN accite.AitDrCr = 'C' THEN -1 * accite.AitBaseAmount ELSE accite.AitBaseAmount END) AS AuthToGLAmt]' ||  CONST.CR ||
                  '                         FROM ACCITE accite' ||  CONST.CR ||
                  '                         WHERE accite.AitGltRecNo > 0' ||  CONST.CR ||
                  '                         GROUP BY accite.AitIteRecNo) authtogl,' ||  CONST.CR ||
                  q'[                       (SELECT porecovite.PORecovAitIteRecNo, SUM(CASE WHEN porecovite.PORecovAitDrCr = 'C' THEN -1 * porecovite.PORecovAitBaseAmt ELSE porecovite.PORecovAitBaseAmt END) AS AuthToGLAmt]' ||  CONST.CR ||
                  '                         FROM PORECOVITE porecovite' ||  CONST.CR ||
                  '                         WHERE porecovite.PORecovPstRecNo = 34' ||  CONST.CR ||
                  '                           AND porecovite.PORecovGltRecNo IS NOT NULL' ||  CONST.CR ||
                  '                         GROUP BY porecovite.PORecovAitIteRecNo) recovtogl' ||  CONST.CR ||
                  '                     WHERE expcha.ExcChaRec = itechg.ExcRecNo' ||  CONST.CR ||
                  '                       AND saloffno.SalOffNo = lotprofitsaloff.SalOffNo' ||  CONST.CR ||
                  '                       AND itechg.LitRecNo = lotprofitsaloff.LitIteNo' ||  CONST.CR ||
                  '                       AND itechg.IchRecNo = authtogl.AitIteRecNo(+)' ||  CONST.CR ||
                  '                       AND itechg.IchRecNo = recovtogl.PORecovAitIteRecNo(+)' ||  CONST.CR ||
                  '                       AND NVL(expcha.ExcRecovFromPL, 0) = 0' ||  CONST.CR ||
                  '                       AND itechg.CtyNo = CASE WHEN saloffno.LotProfitMeth IN(2, 4) THEN 1 ELSE itechg.CtyNo END' ||  CONST.CR ||
                  '                       AND itechg.IchIstRecNo IS NULL' ||  CONST.CR ||
                  '                     GROUP BY saloffno.LotProfitMeth), 1)' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET SalesCostAuth = NVL((SELECT MIN( CASE' ||  CONST.CR ||
                  '                                     WHEN saloffno.LotProfitMeth IN(1, 2) AND ABS(NVL(itechg.IchAppAmt, 0.0) - NVL(authtogl.AuthToGLAmt, NVL(recovtogl.AuthToGLAmt, 0.0))) > 0.009 THEN 0' ||  CONST.CR ||
                  '                                     WHEN saloffno.LotProfitMeth IN(3, 4) AND ABS(NVL(authtogl.AuthToGLAmt, NVL(recovtogl.AuthToGLAmt, 0.0))) < 0.01 THEN 0' ||  CONST.CR ||
                  '                                     ELSE 1' ||  CONST.CR ||
                  '                                     END)' ||  CONST.CR ||
                  '                         FROM ITECHG itechg, EXPCHA expcha, SALOFFNO saloffno, ' || AUTOSALESTAB_IN || ' salestab,' ||  CONST.CR ||
                  q'[                           (SELECT accite.AitIteRecNo, SUM(CASE WHEN accite.AitDrCr = 'C' THEN -1 * accite.AitBaseAmount ELSE accite.AitBaseAmount END) AS AuthToGLAmt]' ||  CONST.CR ||
                  '                             FROM ACCITE accite' ||  CONST.CR ||
                  '                             WHERE accite.AitGltRecNo > 0' ||  CONST.CR ||
                  '                               AND accite.AitPstRecNo <> 45' ||  CONST.CR ||
                  '                             GROUP BY accite.AitIteRecNo) authtogl,' ||  CONST.CR ||
                  q'[                           (SELECT porecovite.PORecovAitIteRecNo, SUM(CASE WHEN porecovite.PORecovAitDrCr = 'C' THEN -1 * porecovite.PORecovAitBaseAmt ELSE porecovite.PORecovAitBaseAmt END) AS AuthToGLAmt]' ||  CONST.CR ||
                  '                             FROM PORECOVITE porecovite' ||  CONST.CR ||
                  '                             WHERE porecovite.PORecovPstRecNo = 34' ||  CONST.CR ||
                  '                               AND porecovite.PORecovGltRecNo IS NOT NULL' ||  CONST.CR ||
                  '                             GROUP BY porecovite.PORecovAitIteRecNo) recovtogl' ||  CONST.CR ||
                  '                         WHERE expcha.ExcChaRec = itechg.ExcRecNo' ||  CONST.CR ||
                  '                           AND saloffno.SalOffNo = lotprofitsaloff.SalOffNo' ||  CONST.CR ||
                  '                           AND itechg.DprRecNo = salestab.DprRecNo' ||  CONST.CR ||
                  '                           AND salestab.LitIteNo = lotprofitsaloff.LitIteNo' ||  CONST.CR ||
                  '                           AND itechg.IchRecNo = authtogl.AitIteRecNo(+)' ||  CONST.CR ||
                  '                           AND itechg.IchRecNo = recovtogl.PORecovAitIteRecNo(+)' ||  CONST.CR ||
                  '                           AND NVL(expcha.ExcRecovFromPL, 0) = 0' ||  CONST.CR ||
                  '                         GROUP BY saloffno.LotProfitMeth), 1)' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET SalesCostAuth = NVL((SELECT MIN( CASE' ||  CONST.CR ||
                  '                                     WHEN saloffno.LotProfitMeth IN(1, 2) AND ABS(NVL(itechg.IchAppAmt, 0.0) - NVL(authtogl.AuthToGLAmt, NVL(recovtogl.AuthToGLAmt, 0.0))) > 0.009 THEN 0' ||  CONST.CR ||
                  '                                     WHEN saloffno.LotProfitMeth IN(3, 4) AND ABS(NVL(authtogl.AuthToGLAmt, NVL(recovtogl.AuthToGLAmt, 0.0))) < 0.01 THEN 0' ||  CONST.CR ||
                  '                                     ELSE 1' ||  CONST.CR ||
                  '                                     END)' ||  CONST.CR ||
                  '                         FROM ITECHG itechg, EXPCHA expcha, SALOFFNO saloffno, ' || AUTOSALESTAB_IN || ' salestab,' ||  CONST.CR ||
                  q'[                           (SELECT accite.AitIteRecNo, SUM(CASE WHEN accite.AitDrCr = 'C' THEN -1 * accite.AitBaseAmount ELSE accite.AitBaseAmount END) AS AuthToGLAmt]' ||  CONST.CR ||
                  '                             FROM ACCITE accite' ||  CONST.CR ||
                  '                             WHERE accite.AitGltRecNo > 0' ||  CONST.CR ||
                  '                             GROUP BY accite.AitIteRecNo) authtogl,' ||  CONST.CR ||
                  q'[                           (SELECT porecovite.PORecovAitIteRecNo, SUM(CASE WHEN porecovite.PORecovAitDrCr = 'C' THEN -1 * porecovite.PORecovAitBaseAmt ELSE porecovite.PORecovAitBaseAmt END) AS AuthToGLAmt]' ||  CONST.CR ||
                  '                             FROM PORECOVITE porecovite' ||  CONST.CR ||
                  '                             WHERE porecovite.PORecovPstRecNo = 34' ||  CONST.CR ||
                  '                               AND porecovite.PORecovGltRecNo IS NOT NULL' ||  CONST.CR ||
                  '                             GROUP BY porecovite.PORecovAitIteRecNo) recovtogl' ||  CONST.CR ||
                  '                         WHERE expcha.ExcChaRec = itechg.ExcRecNo' ||  CONST.CR ||
                  '                           AND saloffno.SalOffNo = lotprofitsaloff.SalOffNo' ||  CONST.CR ||
                  '                           AND itechg.DelRecNo = salestab.DelRecNo' ||  CONST.CR ||
                  '                           AND itechg.IchRecNo = authtogl.AitIteRecNo(+)' ||  CONST.CR ||
                  '                           AND salestab.LitIteNo = lotprofitsaloff.LitIteNo' ||  CONST.CR ||
                  '                           AND NVL(expcha.ExcRecovFromPL, 0) = 0' ||  CONST.CR ||
                  '                         GROUP BY saloffno.LotProfitMeth), 1)' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)' ||  CONST.CR ||
                  ' AND SalesCostAuth = 1';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET OverSold = NVL((SELECT MAX(CASE WHEN lotite_link.OrgLitIteNo > 0 THEN 1 ELSE 0 END)' ||  CONST.CR ||
                  '                   FROM LOTITE_LINK lotite_link' ||  CONST.CR ||
                  '                   WHERE lotite_link.OrgLitIteNo = lotprofitsaloff.LitIteNo' ||  CONST.CR ||
                  '                     AND lotite_link.TypeFlag = 1' ||  CONST.CR ||
                  '                     AND lotite_link.Status = 1), 0)' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET (Profitised, Reopened)  = (SELECT 1, NVL(Reopened, 0)' ||  CONST.CR ||
                  '                               FROM LOTPROFIT lotprofit' ||  CONST.CR ||
                  '                               WHERE lotprofit.LitIteNo = lotprofitsaloff.LitIteNo)' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)' ||  CONST.CR ||
                  ' AND EXISTS(SELECT * FROM LOTPROFIT lotprofit WHERE lotprofit.LitIteNo = lotprofitsaloff.LitIteNo)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET CanProfitise = CASE' ||  CONST.CR ||
                  '                   WHEN Profitised = 1 AND Reopened = 0 THEN 0' ||  CONST.CR ||
                  '                   WHEN FullySoldInvoiced = 0 THEN 0' ||  CONST.CR ||
                  '                   WHEN HasGoodsCost = 0 THEN 0' ||  CONST.CR ||
                  '                   WHEN POCostAuth = 0 THEN 0' ||  CONST.CR ||
                  '                   WHEN SalesCostAuth = 0 THEN 0' ||  CONST.CR ||
                  '                   WHEN OverSold = 1 THEN 0' ||  CONST.CR ||
                  '                   ELSE 1' ||  CONST.CR ||
                  '                   END' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LitIteNo IN (SELECT isttab.LitIteNo FROM ' || REQDISTSTAB_IN || ' isttab)';
    EXECUTE IMMEDIATE SQL_STMT;

    SQL_STMT  :=  'UPDATE LOTPROFITSALOFF' ||  CONST.CR ||
                  'SET LheProfitPerc = (SELECT  CASE' ||  CONST.CR ||
                  '                             WHEN ABS(SUM(NVL(sublotprofitsaloff.NettSales, 0.0))) < 0.01 THEN 0.0' ||  CONST.CR ||
                  '                             ELSE ROUND(SUM(sublotprofitsaloff.Profit) / ABS(SUM(NVL(sublotprofitsaloff.NettSales, 0.0))) * 100.0, 2)' ||  CONST.CR ||
                  '                             END' ||  CONST.CR ||
                  '                     FROM LOTITE lotite, LOTDET lotdet, LOTPROFITSALOFF sublotprofitsaloff' ||  CONST.CR ||
                  '                     WHERE lotdet.DetLheRecNo = lotprofitsaloff.LheRecNo' ||  CONST.CR ||
                  '                       AND lotdet.DetRecNo = lotite.LitDetNo' ||  CONST.CR ||
                  '                       AND NVL(lotite.OnReserve, 0) = 0' ||  CONST.CR ||
                  '                       AND lotite.LitIteNo = sublotprofitsaloff.LitIteNo(+)' ||  CONST.CR ||
                  '                     )' ||  CONST.CR ||
                  'WHERE lotprofitsaloff.LheRecNo IN (SELECT salestab.LheRecNo FROM ' || AUTOSALESTAB_IN || ' salestab)';
    EXECUTE IMMEDIATE SQL_STMT;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_ERRORS.LOG_AND_STOP;
  END LOTPROFITABILITY;

END FT_PROFITISELOTS;
/
