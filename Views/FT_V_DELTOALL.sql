--########################################################################################################
-- View for DELAUDITS    
--########################################################################################################

CREATE OR REPLACE FORCE VIEW FT_V_DELTOALL
(
   RECORDTYPE,
   ORDER_TYPE,
   RECORDTYPE_EXT,
   ALLOCATED_QTY,
   ALLFLAG,
   ALLFLAGDESC,
   QTYPER,
   QTYPER_DESC,
   SPLITQTY,
   RESERVATION_NO,
   DELIVERY_NO,
   TICKETNO,
   WO_NO,
   WO_DATE,
   INTERNAL_CUST_NO,
   CUSTOMER_CODE,
   CUSTOMER_NAME,
   ORDER_QTY,
   DELIVERY_QTY,
   SALEMAN_NO,
   SALEMAN_NAME,
   SALES_OFFICE_NO,
   SALES_OFFICE,
   DLV_DATE,
   SHIP_DATE,
   PALLET_NO,
   WIZUNIQUEID,
   TYPERECNO,
   ALLOCNO,
   PRGDETNO,
   DELRECNO,
   PHRRECNO,
   PALLOCRECNO
)
AS
   SELECT /*+ INDEX (DELTOALL, PK_DELTOALL)  USE_NL(DELTOALL)          INDEX (DELDET, PK_DELDET)  USE_NL(DELDET)
                 INDEX (DELHED, PK_DELHED)  USE_NL(DELHED)              INDEX (ORDERS, PK_ORDERS)  USE_NL(ORDERS)
                 INDEX (ACCCLASS, ACCCLASS_ACCCLASS_CLARECNO2IDX)  USE_NL(ACCCLASS)             INDEX (ACCOUNTS, PK_ACCOUNTS)  USE_NL(ACCOUNTS)*/
         DISTINCT
            DALRECORDTYPE,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELTOALL'
                      AND LKUPFIELDNAME = 'DALRECORDTYPE'
                      AND LKUPNO = DELTOALL.DALRECORDTYPE)
               ORDTYPE,
            NULL RECORDTYPE_EXT,
            DELTOALL.DALQTY ALLOCATED_QTY,
            DELTOALL.ALLFLAG,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELTOALL'
                      AND LKUPFIELDNAME = 'ALLFLAG'
                      AND LKUPNO = DELTOALL.ALLFLAG)
               ALLFLAGDESC,
            DELDET.DELQTYPER QTYPER,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'MARKETDELDETS'
                      AND LKUPFIELDNAME = 'PRCBYWGT'
                      AND LOOKUPS.LKUPNO = NVL (DELDET.DELQTYPER, 1))
               QTYPER_DESC,
            DELTOALL.ACTSPLITQTY SPLITQTY,
            (CASE
                WHEN DELHED.DLVPRGHEDNO IS NULL
                THEN
                   (SELECT   MIN (PRGREFNO)
                      FROM   PRGDETTODDET
                     WHERE   PDESDELRECNO = DELDET.DELRECNO)
                ELSE
                   DELHED.DLVPRGHEDNO
             END)
               PRGREFNO,
            DELHED.DLVORDNO,
            (SELECT   TNTNO
               FROM   TKTNT
              WHERE   TKTNT.TNTDLVORDNO = DELHED.DLVORDNO)
               TICKETNO,
            NULL WO_NO,
            NULL WO_DATE,
            ORDERS.ACTCSTCODE CSTCODE,
            ACCOUNTS.ACCCODE CUSTCODE,
            ACCOUNTS.ACCNAME CUSTNAME,
            0 ORDERQTY,
            DELDET.DELQTY QTYDLV,
            ORDERS.ORDSMNNO SMNNO,
            SMN.SMNNAME,
            DLVSALOFFNO SALOFFNO,
            SALOFFNO.SALOFFDESC,
            DELHED.DLVDELDATE DLVDATE,
            DELHED.DLVSHPDATE SHIPDATE,
            (CASE
                WHEN PALNOLOC.PALLETNO IS NULL
                THEN
                   PALNOLOC.PALLOCSUPPALLETREF
                ELSE
                   PALNOLOC.PALLETNO
             END)
               PALLETNO,
            DALWIZUNIQUEID,
            DELTOALL.DALTYPERECNO,
            DELTOALL.DALALLOCNO ALLOCNO,
            NULL PDERECNO,
            DELDET.DELRECNO,
            NULL PHRRECNO,
            PALNOLOC.PALLOCRECNO
     FROM   DELTOALL,
            DELDET,
            DELHED,
            ORDERS,
            ACCCLASS,
            ACCOUNTS,
            SMN,
            SALOFFNO,
            PALNOLOC
    WHERE       DELTOALL.DALTYPERECNO = DELDET.DELRECNO
            AND DELDET.DELDLVORDNO = DELHED.DLVORDNO
            AND DELHED.DLVORDRECNO = ORDERS.ORDRECNO
            AND ORDERS.ACTCSTCODE = ACCCLASS.CLARECNO(+)
            AND ACCCLASS.CLAACCCODE = ACCOUNTS.ACCCODE(+)
            AND ORDERS.ORDSMNNO = SMN.SMNNO(+)
            AND DELHED.DLVSALOFFNO = SALOFFNO.SALOFFNO
            AND DELTOALL.DALPALLOCRECNO = PALNOLOC.PALLOCRECNO(+)
            AND DELTOALL.DALALLOCNO > 0
            AND (NVL (DELTOALL.DALQTY, 0) > 0 OR NVL (ACTSPLITQTY, 0) > 0)
            AND DELTOALL.DALRECORDTYPE = 1                            --DELDET
   UNION
   --RESERVATIONS
   SELECT /*+ INDEX (DELTOALL, PK_DELTOALL)  USE_NL(DELTOALL)        INDEX (PRGDET, PK_PRGDET_TODELTOALL)  USE_NL(PRGDET)
           INDEX (PRGHED, PK_PRGHED)  USE_NL(PRGHED)
           INDEX (ACCCLASS, ACCCLASS_ACCCLASS_CLARECNO2IDX)  USE_NL(ACCCLASS)             INDEX (ACCOUNTS, PK_ACCOUNTS)  USE_NL(ACCOUNTS)           */
         DISTINCT
            DALRECORDTYPE,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELTOALL'
                      AND LKUPFIELDNAME = 'DALRECORDTYPE'
                      AND LKUPNO = DELTOALL.DALRECORDTYPE)
               ORDTYPE,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'PRGHED'
                      AND LKUPFIELDNAME = 'PRGTYP'
                      AND LKUPNO = PRGHED.PRGTYP)
               RECORDTYPE_EXT,
            DELTOALL.DALQTY ALLOCATED_QTY,
            DELTOALL.ALLFLAG,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELTOALL'
                      AND LKUPFIELDNAME = 'ALLFLAG'
                      AND LKUPNO = DELTOALL.ALLFLAG)
               ALLFLAGDESC,
            DELTOALL.QTYPER,
            NULL QTYPER_DESC,
            DELTOALL.ACTSPLITQTY SPLITQTY,
            PRGHED.PRGREFNO,
            NULL DLVORDNO,
            NULL TICKETNO,
            NULL WO_NO,
            NULL WO_DATE,
            PRGHED.PRGCSTCODE CSTCODE,
            ACCOUNTS.ACCCODE CUSTCODE,
            ACCOUNTS.ACCNAME CUSTNAME,
            DECODE (PRGHED.PRGTYP,
                    2, PRGDET.PDEORDERQTY,
                    PRGDET.PDEFORECASTQTY)
               ORDERQTY,
            DECODE (PRGHED.PRGTYP, 2, PRGDET.PDEDLVDQTY, 0) QTYDLV,
            PRGDET.SMNNO SMNNO,
            SMN.SMNNAME,
            PRGHED.SALESOFFICEFLAG,
            SALOFFNO.SALOFFDESC,
            PRGHED.PRGDLVDATE DLVDATE,
            PRGHED.PRGSHIPDATE SHIPDATE,
            (CASE
                WHEN PALNOLOC.PALLETNO IS NULL
                THEN
                   PALNOLOC.PALLOCSUPPALLETREF
                ELSE
                   PALNOLOC.PALLETNO
             END)
               PALLETNO,
            DALWIZUNIQUEID,
            DELTOALL.DALTYPERECNO,
            DELTOALL.DALALLOCNO ALLOCNO,
            PRGDET.PDERECNO PDERECNO,
            NULL DELRECNO,
            NULL PHRRECNO,
            PALNOLOC.PALLOCRECNO
     FROM   DELTOALL,
            PRGDET,
            PRGHED,
            ACCCLASS,
            ACCOUNTS,
            SMN,
            SALOFFNO,
            PALNOLOC
    WHERE       DELTOALL.DALTYPERECNO = PRGDET.DALALLRECNO
            AND PRGDET.PDEPRGREFNO = PRGHED.PRGREFNO
            AND PRGHED.PRGCSTCODE = ACCCLASS.CLARECNO(+)
            AND ACCCLASS.CLAACCCODE = ACCOUNTS.ACCCODE(+)
            AND PRGDET.SMNNO = SMN.SMNNO(+)
            AND PRGHED.SALESOFFICEFLAG = SALOFFNO.SALOFFNO(+)
            AND DELTOALL.DALPALLOCRECNO = PALNOLOC.PALLOCRECNO(+)
            AND DELTOALL.DALALLOCNO > 0
            AND DELTOALL.DALQTY > 0
            AND DELTOALL.DALRECORDTYPE = 3                            --PRGDET
   UNION
   --PREPACK
   SELECT /*+ INDEX (DELTOALL, PK_DELTOALL)  USE_NL(DELTOALL)        INDEX (PRERECON, PK_PRERECON)  USE_NL(PRERECON)
           INDEX (PREWORKS, PK_PREWORKS)  USE_NL(PREWORKS) INDEX (PREWODOC, PK_PREWODOC)  USE_NL(PREWODOC)
           INDEX (PREPROD, PK_PREPROD)  USE_NL(PREPROD)

          INDEX (ACCCLASS, ACCCLASS_ACCCLASS_CLARECNO2IDX)  USE_NL(ACCCLASS)             INDEX (ACCOUNTS, PK_ACCOUNTS)  USE_NL(ACCOUNTS)
          */
         DISTINCT
            DALRECORDTYPE,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELTOALL'
                      AND LKUPFIELDNAME = 'DALRECORDTYPE'
                      AND LKUPNO = DELTOALL.DALRECORDTYPE)
               ORDTYPE,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'PREWODOC'
                      AND LKUPFIELDNAME = 'WORKORDERTYPE'
                      AND LKUPNO = PREWODOC.WORKORDERTYPE)
               RECORDTYPE_EXT,
            DELTOALL.DALQTY ALLOCATED_QTY,
            DELTOALL.ALLFLAG,
            (SELECT   LKUPDESC
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELTOALL'
                      AND LKUPFIELDNAME = 'ALLFLAG'
                      AND LKUPNO = DELTOALL.ALLFLAG)
               ALLFLAGDESC,
            DELTOALL.QTYPER,
            NULL QTYPER_DESC,
            DELTOALL.ACTSPLITQTY SPLITQTY,
            NULL PRGREFNO,
            NULL DLVORDNO,
            NULL TICKETNO,
            PREWORKS.WODOCNO,
            PREWORKS.WODATEREQ,
            PREPROD.PRECLARECNO CSTCODE,
            ACCOUNTS.ACCCODE CUSTCODE,
            ACCOUNTS.ACCNAME CUSTNAME,
            0 ORDERQTY,
            0 QTYDLV,
            NULL SMNNO,
            NULL SMNNAME,
            PREWODOC.PRESALOFFNO,
            SALOFFNO.SALOFFDESC,
            NULL DLVDATE,
            NULL SHIPDATE,
            (CASE
                WHEN PALNOLOC.PALLETNO IS NULL
                THEN
                   PALNOLOC.PALLOCSUPPALLETREF
                ELSE
                   PALNOLOC.PALLETNO
             END)
               PALLETNO,
            DALWIZUNIQUEID,
            DELTOALL.DALTYPERECNO,
            DELTOALL.DALALLOCNO ALLOCNO,
            NULL PDERECNO,
            NULL DELRECNO,
            DELTOALL.DALTYPERECNO PHRRECNO,
            PALNOLOC.PALLOCRECNO
     FROM   DELTOALL,
            PRERECON,
            PREWORKS,
            PREWODOC,
            PREPROD,
            ACCCLASS,
            ACCOUNTS,
            SALOFFNO,
            PALNOLOC
    WHERE       DELTOALL.DALTYPERECNO = PRERECON.PHRRECNO
            AND PRERECON.PHRWORECNO = PREWORKS.WORECNO
            AND PREWORKS.WODOCNO = PREWODOC.PREWODOCNO
            AND PREPROD.PRERECNO = PREWORKS.WOPRERECNO
            AND PREPROD.PRECLARECNO = ACCCLASS.CLARECNO(+)
            AND ACCCLASS.CLAACCCODE = ACCOUNTS.ACCCODE(+)
            AND PREWODOC.PRESALOFFNO = SALOFFNO.SALOFFNO(+)
            AND DELTOALL.DALPALLOCRECNO = PALNOLOC.PALLOCRECNO(+)
            AND DELTOALL.DALALLOCNO > 0
            AND DELTOALL.DALQTY > 0
            AND DELTOALL.DALRECORDTYPE = 2;			
	--PRERECON

-- cVersionControlNo 
COMMENT ON TABLE FT_V_DELTOALL IS  '1.0.0';  