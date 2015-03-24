COMMENT ON TABLE FT_V_PROFITPERLOT IS  'v1.0.0 - View sales and profitability by lot';

CREATE OR REPLACE FORCE VIEW FT_V_PROFITPERLOT
(
   LITITENO,
   PO_NUMBER,
   SALES_OFFICE_NO,
   PRCPRDNO,
   PRODUCT_REF,
   PRODUCT_DESCRIPTION,
   LITQTY,
   BULK_SALES_QTY,
   ACT_SALES_QTY,
   SALES_VALUE,
   SALES_COST,
   DISCOUNT_AMT,
   REBATE_AMT,
   EXPL_SALES_COST,
   EXTERN_SALES_COMM_HAND,
   PURCHASE_COST,
   PROFIT,
   OPEN_PRICE
)
AS
   SELECT LOTITE.LITITENO,
          PORNO,
          PORSALOFF,
          PRCPRDNO,
          PRCPRDREF,
          PRCDESCRIPTION,
          CASE
             WHEN LITRCVCOMPLETE = 'Y' THEN NVL (LITQTYRCV, 0)
             ELSE NVL (LITORGEXP, 0)
          END
             LITQTY,
          SALES_VALUES.DTLBULKSALESQTY TOTALBULKSALESQTY,
          SALES_VALUES.DTLSOLDSALESQTY TOTALACTSALESQTY,
          SALES_VALUES.DTLSALESVALUE TOTALSALESVALUE,
          NVL (SALES_COSTS.TOTSALESCOSTS, 0.0) TOTSALESCOSTS,
          NVL (SALES_COSTS.DISCOUNT_AMT, 0.0) DISCOUNT_AMT,
          NVL (SALES_COSTS.REBATE_AMT, 0.0) REBATE_AMT,
          NVL (SALES_COSTS.EXPLSALESCOSTS, 0.0) AS EXPLSALESCOSTS,
          NVL (SALES_COSTS.EXTERNCOMMHAND, 0.0) AS EXTERNCOMMHAND,
          ROUND (
             (CASE
                 WHEN LITRCVCOMPLETE = 'Y'
                 THEN
                    CASE
                       WHEN NVL (LITQTYRCV, 0) > 0
                       THEN
                          NVL (LitDelCost, 0) / NVL (LITQTYRCV, 0) * 1.00
                       ELSE
                          0
                    END
                 ELSE
                    CASE
                       WHEN NVL (LITORGEXP, 0) > 0
                       THEN
                          NVL (LitDelCost, 0) / NVL (LITORGEXP, 0) * 1.00
                       ELSE
                          0
                    END
              END)
             * SALES_VALUES.DTLBULKSALESQTY,
             2)
             TOTALPURCHASECOST,
          SALES_VALUES.DTLSALESVALUE - NVL (SALES_COSTS.TOTSALESCOSTS, 0.0)
          - (ROUND (
                (CASE
                    WHEN LITRCVCOMPLETE = 'Y'
                    THEN
                       CASE
                          WHEN NVL (LITQTYRCV, 0) > 0
                          THEN
                             NVL (LitDelCost, 0) / NVL (LITQTYRCV, 0) * 1.00
                          ELSE
                             0
                       END
                    ELSE
                       CASE
                          WHEN NVL (LITORGEXP, 0) > 0
                          THEN
                             NVL (LitDelCost, 0) / NVL (LITORGEXP, 0) * 1.00
                          ELSE
                             0
                       END
                 END)
                * SALES_VALUES.DTLBULKSALESQTY,
                2))
             PROFIT,
          SALES_VALUES.DTLOPENPRCQTY TOTOPENPRCQTY
     FROM LOTITE,
          PURORD,
          PRDREC,
          (  SELECT DPRSTOLOTS.DTLLITITENO,
                    SUM (NVL (DPRSTOLOTS.DTLBULKSALESQTY, 0.0)) DTLBULKSALESQTY,
                    SUM (NVL (DPRSTOLOTS.DTLSOLDSALESQTY, 0.0)) DTLSOLDSALESQTY,
                    SUM (NVL (DPRSTOLOTS.DTLSALESVALUE, 0.0)) DTLSALESVALUE,
                    SUM (NVL (DPRSTOLOTS.DTLOPENPRCQTY, 0.0)) DTLOPENPRCQTY
               FROM DPRSTOLOTS
           GROUP BY DTLLITITENO) SALES_VALUES,
          (  SELECT DPRSTOLOTS.DTLLITITENO,
                    SUM (CASE WHEN DPRSTOLOTSCHGS.DTLCHGSEXCLFROMPL = 0 THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP ELSE 0.0 END) TOTSALESCOSTS,
                    SUM (CASE WHEN DPRSTOLOTSCHGS.DTLCHGSEXCLFROMPL = 1 THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP ELSE 0.0 END) EXPLSALESCOSTS,
                    SUM (CASE WHEN DPRSTOLOTSCHGS.DTLCHGSCTYNO = 97 THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP ELSE 0.0 END) DISCOUNT_AMT,
                    SUM (CASE WHEN DPRSTOLOTSCHGS.DTLCHGSCTYNO = 98 THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP ELSE 0.0 END) REBATE_AMT,
                    SUM (CASE WHEN DPRSTOLOTSCHGS.DTLCHGSEXCLFROMPL = 0 AND DPRSTOLOTSCHGS.DTLCHGSCHARGECLASS IN(5, 6) THEN DPRSTOLOTSCHGS.DTLCHGSBASEAPP  ELSE 0.0 END) AS EXTERNCOMMHAND
               FROM DPRSTOLOTS, DPRSTOLOTSCHGS
              WHERE DPRSTOLOTSCHGS.DTLCHGSDTLRECNO = DPRSTOLOTS.DTLRECNO
           GROUP BY DPRSTOLOTS.DTLLITITENO) SALES_COSTS
    WHERE     LOTITE.LITPORREC = PURORD.PORRECNO
          AND LOTITE.LITPRDNO = PRDREC.PRCPRDNO
          AND LOTITE.LITITENO = SALES_VALUES.DTLLITITENO
          AND LOTITE.LITITENO = SALES_COSTS.DTLLITITENO(+);
