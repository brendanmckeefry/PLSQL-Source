--########################################################################################################
-- View for Sales Details   -     Used for Entering Delivery lines into sales screens   
--########################################################################################################

-- DROP VIEW FT_V_DISPLAYSALESDETAILS;

/* Formatted on 18/12/2014 14:14:51 (QP5 v5.115.810.9015) */
CREATE OR REPLACE FORCE VIEW FT_V_DISPLAYSALESDETAILS
(
   ACTCSTCODE,
   CLAACCCODE,
   ACCDESC,
   ORDSMNNO,
   ORDSMNNAME,
   DLVDPTRECNO,
   DLVDEPARTMENTDESC,
   DLVORDNO,
   DLVDELDATE,
   DLVRELINV,
   DLVSTKLOC,
   STCLOCDESC,
   DLVCURRECNO,
   DLVCOMNO,
   DLVCOMMENT,
   DLVDLTRECNO,
   ISOPENFORMORE,
   HEDSYSCALCPALS,
   USERINPPALS,
   DELHEDDLVPRTSTAT,
   DELHEDDLVPRTSTATDESC,
   INTERDEPTFLAG,
   DELRECNO,
   DELPRCPRDNO,
   DELCLTPRDNO,
   DELQTY,
   DELQTYPER,
   DELQTYPERCHAR,
   DELQTYPERDESC,
   DELPRICEPER,
   DELPRICEPERCHAR,
   DELPRICEPERDESC,
   DELCOMNO,
   DELCOMMENT,
   DELSTATUS,
   DELDETPIKPRTSTAT,
   DELHEDPIKPRTSTATDESC,
   DELDETDLVPRTSTAT,
   DELDETDLVPRTSTATDESC,
   DELDETSMNNO,
   DELDETSMNNAME,
   DPRRECNO,
   DELPRICE_PRICE,
   DELNETTVALUE,
   DELVATVALUE,
   DELFREEOFCHG,
   DLV_DELPRICE_CNT,
   ALL_DELPRICE_CNT,
   ALL_DELNETTVALUE,
   ALL_DELVATVALUE,
   DPRPREAS,
   DPRPREASDESC,
   PALTODEL_CNT,
   DELTOALL_CNT,
   ANYDELTOALL_STKDISS,
   TOT_DELTOALLQTY,
   ANYOVERSOLDPOS,
   OVERALLOCATED,
   PRCDESCRIPTION,
   PRCPRDREF,
   PRCSHORTDESC,
   DEFAULTPRD,
   POWONO,
   LOTNO,
   DPTRECNO,
   DEPARTMENTDESC
)
AS
   SELECT                                                            -- ORDERS
         ORDERS.ACTCSTCODE,
            (BSDL_PKAGE_ACCOUNTS.GETACCCODE (ORDERS.ACTCSTCODE, 2))
               CLAACCCODE,
            (SELECT   ACCOUNTS.ACCNAME
               FROM   ACCCLASS, ACCOUNTS
              WHERE   ACCCLASS.CLAACCNO = ACCOUNTS.ACCRECNO
                      AND ACCCLASS.CLARECNO = ORDERS.ACTCSTCODE)
               ACCDESC,
            ORDERS.ORDSMNNO AS ORDSMNNO,
            (SELECT   SMN.SMNNAME
               FROM   SMN
              WHERE   SMN.SMNNO = ORDERS.ORDSMNNO)
               ORDSMNNAME,
            (CASE
                WHEN (SELECT   COUNT (DPTRECNO)
                        FROM   DEPARTMENTSTOSMN
                       WHERE   DEPARTMENTSTOSMN.SMNNO = ORDERS.ORDSMNNO) > 1
                THEN
                   NULL
                ELSE
                   (SELECT   DEPARTMENTSTOSMN.DPTRECNO
                      FROM   DEPARTMENTSTOSMN
                     WHERE   DEPARTMENTSTOSMN.SMNNO = ORDERS.ORDSMNNO)
             END)
               DLVDPTRECNO,
            (CASE
                WHEN (SELECT   COUNT (DPTRECNO)
                        FROM   DEPARTMENTSTOSMN
                       WHERE   DEPARTMENTSTOSMN.SMNNO = ORDERS.ORDSMNNO) > 1
                THEN
                   '*'
                ELSE
                   (SELECT   DPT_DESC
                      FROM   DEPARTMENTSTOSMN, DEPARTMENTS
                     WHERE   DEPARTMENTSTOSMN.DPTRECNO = DEPARTMENTS.DPTRECNO
                             AND DEPARTMENTSTOSMN.SMNNO = ORDERS.ORDSMNNO)
             END)
               DLVDEPARTMENTDESC,
            -- DELHED
            DELHED.DLVORDNO,
            DELHED.DLVDELDATE,
            DELHED.DLVRELINV,
            DELHED.DLVSTKLOC,
            (SELECT   STOCLOC.STCLOCDESC
               FROM   STOCLOC
              WHERE   STOCLOC.STCRECNO = DELHED.DLVSTKLOC)
               STCLOCDESC,
            DELHED.DLVCURRECNO,
            DELHED.DLVCOMNO,
            (SELECT   MIN (DELCOMM)
               FROM   DELCOMMS
              WHERE       DELCOMMTYPRECNO = DELHED.DLVORDNO
                      AND DELTYP = 3
                      AND DELCOMMS.DELCOMMSEQ = 1)
               DLVCOMMENT,
            DELHED.DLVDLTRECNO,
            DELHED.ISOPENFORMORE,
            DELHED.HEDSYSCALCPALS,
            DELHED.USERINPPALS,
            NVL (DELHED.DLVPRTSTAT, 0) DELHEDDLVPRTSTAT,
            (SELECT   MIN (LKUPDESC)
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELHED'
                      AND LKUPFIELDNAME = 'DLVPRTSTAT'
                      AND LKUPNO = DELHED.DLVPRTSTAT)
               DELHEDDLVPRTSTATDESC,
            DELHED.INTERDEPTFLAG,
            --DELDET
            DELDET.DELRECNO,
            DELDET.DELPRCPRDNO,
            DELDET.DELCLTPRDNO,
            NVL (DELDET.DELQTY, 0) DELQTY,
            NVL (DELDET.DELQTYPER, 1) DELQTYPER,
            (SELECT   UPPER (SUBSTR (MIN (LKUPDESC), 1, 1))
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'MARKETDELDETS'
                      AND LKUPFIELDNAME = 'PRCBYWGT'
                      AND LKUPNO = NVL (DELDET.DELQTYPER, 1))
               DELQTYPERCHAR,
            (SELECT   MIN (LKUPDESC)
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'MARKETDELDETS'
                      AND LKUPFIELDNAME = 'PRCBYWGT'
                      AND LKUPNO = NVL (DELDET.DELQTYPER, 1))
               DELQTYPERDESC,
            NVL (DELDET.DELPRICEPER, 1) DELPRICEPER,
            (SELECT   UPPER (SUBSTR (MIN (LKUPDESC), 1, 1))
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'MARKETDELDETS'
                      AND LKUPFIELDNAME = 'PRCBYWGT'
                      AND LKUPNO = NVL (DELDET.DELPRICEPER, 1))
               DELPRICEPERCHAR,
            (SELECT   MIN (LKUPDESC)
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'MARKETDELDETS'
                      AND LKUPFIELDNAME = 'PRCBYWGT'
                      AND LKUPNO = NVL (DELDET.DELPRICEPER, 1))
               DELPRICEPERDESC,
            DELDET.DELCOMNO,
            (SELECT   MIN (DELCOMM)
               FROM   DELCOMMS
              WHERE       DELCOMMTYPRECNO = DELHED.DLVORDNO
                      AND DELTYP = 4
                      AND DELCOMMS.DELCOMMSEQ = 1)
               DELCOMMENT,
            DELDET.DELSTATUS,
            NVL (DELDET.PRTSTAT, 0) DELDETPIKPRTSTAT,
            (SELECT   MIN (LKUPDESC)
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELDET'
                      AND LKUPFIELDNAME = 'PRTSTAT'
                      AND LKUPNO = DELDET.PRTSTAT)
               DELHEDPIKPRTSTATDESC,
            NVL (DELDET.DLVPRTSTAT, 0) DELDETDLVPRTSTAT,
            (SELECT   MIN (LKUPDESC)
               FROM   LOOKUPS
              WHERE       LKUPTABLE = 'DELDET'
                      AND LKUPFIELDNAME = 'DLVPRTSTAT'
                      AND LKUPNO = DELHED.DLVPRTSTAT)
               DELDETDLVPRTSTATDESC,
            DELDET.DELSMNNO DELDETSMNNO,
            (SELECT   SMNNAME
               FROM   SMN
              WHERE   SMN.SMNNO = DELDET.DELSMNNO)
               DELDETSMNNAME,
--DELPRICE
            (CASE
                WHEN (SELECT   COUNT (DPRRECNO) CNT
                        FROM   DELPRICE
                       WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
                       AND DELPRICE.DELINVSTATUS = 1  ) = 1
                THEN
                   (SELECT   MIN (DPRRECNO)
                      FROM   DELPRICE
                     WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
                     AND DELPRICE.DELINVSTATUS = 1  )
                ELSE
                   NULL
             END) DPRRECNO,
             
            NVL (
               (CASE
                   WHEN (SELECT   COUNT (DPRRECNO) CNT
                           FROM   DELPRICE
                          WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
                          AND DELPRICE.DELINVSTATUS = 1  ) = 1
                   THEN
                      (SELECT   MAX (NVL (DELPRICE, 0))
                         FROM   DELPRICE
                        WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
                        AND DELPRICE.DELINVSTATUS = 1  )
                   ELSE
                      NULL
                END),
               0
            ) DELPRICE_PRICE,
            
            NVL ( (SELECT   SUM (NVL (DELNETTVALUE, 0))
                     FROM   DELPRICE
                    WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
                    AND DELPRICE.DELINVSTATUS = 1  ), 0)
               DELNETTVALUE,
            NVL ( (SELECT   SUM (NVL (DELVATVALUE, 0))
                     FROM   DELPRICE
                    WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
                    AND DELPRICE.DELINVSTATUS = 1  ), 0)
               DELVATVALUE,
            NVL (
               (CASE
                   WHEN (SELECT   COUNT (DPRRECNO) CNT
                           FROM   DELPRICE
                          WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
                          AND DELPRICE.DELINVSTATUS = 1  ) = 1
                   THEN
                      (SELECT   MIN (DELFREEOFCHG)
                         FROM   DELPRICE
                        WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO)
                   ELSE
                      NULL
                END),
               0
            )DELFREEOFCHG,
            (SELECT   COUNT (DPRRECNO) CNT
               FROM   DELPRICE
              WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
              AND DELPRICE.DELINVSTATUS in (1, 11)  )
               DLV_DELPRICE_CNT,
             (SELECT   COUNT (DPRRECNO) CNT
               FROM   DELPRICE
              WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO)            
               ALL_DELPRICE_CNT,
            NVL ( (SELECT   SUM (NVL (DELNETTVALUE, 0))
                     FROM   DELPRICE
                    WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO  ), 0)
               ALL_DELNETTVALUE,
            NVL ( (SELECT   SUM (NVL (DELVATVALUE, 0))
                     FROM   DELPRICE
                    WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO), 0)
               ALL_DELVATVALUE,
            
            (SELECT   MIN (DPRPREAS) DPRPREAS
               FROM   DELPRICE
              WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO)
               DPRPREAS,
            (SELECT   MIN (PREASCOMM.PRESCOMM) PREASCOMM
               FROM   DELPRICE, PREASCOMM
              WHERE   DELDET.DELRECNO = DELPRICE.DPRDELRECNO
                      AND DELPRICE.DPRPREAS = PREASCOMM.PRESCOMMRECNO)
               DPRPREASDESC,
            -- OTHER
            NVL ( (SELECT   COUNT (PALLOCRECNO) CNT
                     FROM   PALTODEL
                    WHERE   PALTODEL.pallocdelrecno = DELDET.DELRECNO), 0)
               PALTODEL_CNT,
            NVL (
               (SELECT   COUNT (DALWIZUNIQUEID) CNT
                  FROM   DELTOALL SUBDELTOALL
                 WHERE   SUBDELTOALL.DALTYPERECNO = DELDET.DELRECNO
                         AND SUBDELTOALL.DALRECORDTYPE = 1),
               0
            )
               DELTOALL_CNT,
            NVL (
               (SELECT   COUNT (DALWIZUNIQUEID) CNT
                  FROM   DELTOALL SUBDELTOALL
                 WHERE       SUBDELTOALL.DALTYPERECNO = DELDET.DELRECNO
                         AND SUBDELTOALL.DALRECORDTYPE = 1
                         AND NVL (SUBDELTOALL.ALLFLAG, 0) = 1),
               0
            )
               ANYDELTOALL_STKDISS,
            NVL (
               (SELECT   (CASE
                             WHEN DELDET.DELQTYPER = 1
                             THEN
                                SUM (NVL (SUBDELTOALL.DALQTY, 0))
                             ELSE
                                SUM (NVL (SUBDELTOALL.ACTSPLITQTY, 0))
                          END)
                  FROM   DELTOALL SUBDELTOALL
                 WHERE   SUBDELTOALL.DALTYPERECNO = DELDET.DELRECNO
                         AND SUBDELTOALL.DALRECORDTYPE = 1),
               0
            )
               TOT_DELTOALLQTY,
            (SELECT   COUNT ( * ) ANYOVERSOLDPOS
               FROM   DELTOALL SUBDELTOALL,
                      ALLOCATE SUBALLOCATE,
                      LOTITE SUBLOTITE
              WHERE       DELDET.DELRECNO = SUBDELTOALL.DALTYPERECNO
                      AND SUBDELTOALL.DALRECORDTYPE = 1
                      AND SUBDELTOALL.DALALLOCNO = SUBALLOCATE.ALLOCNO
                      AND SUBLOTITE.LITITENO = SUBALLOCATE.ALLOCLITITENO
                      AND POTYPEIND = 2)
               ANYOVERSOLDPOS,
            0 OVERALLOCATED,                                -- NEEDS SOME WORK
            -- PRDREC
            PRDREC.PRCDESCRIPTION,
            PRDREC.PRCPRDREF,
            --PRDREC.PRCSHORTDESC,
            FT_PK_PRODUCTS.GETPRDSHORTCODE (DELDET.DELPRCPRDNO,
                                            DELHED.DLVSALOFFNO)
               PRCSHORTDESC,
            PRDREC.DEFAULTPRD,
            -- BULlSHIT STOCK ONES
            NULL POWONO,
            NULL LOTNO,
            NULL DPTRECNO,
            NULL DEPARTMENTDESC
     FROM   DELHED,
            ORDERS,
            DELDET,
            PRDREC
    WHERE       DELHED.DLVORDRECNO = ORDERS.ORDRECNO
            AND DELHED.DLVORDNO = DELDET.DELDLVORDNO
            AND DELDET.DELPRCPRDNO = PRDREC.PRCPRDNO;
-- AND DELHED.DLVORDNO = 222929;;

COMMENT ON TABLE FT_V_DISPLAYSALESDETAILS IS  '11.0.1'; -- cVersionControlNo 