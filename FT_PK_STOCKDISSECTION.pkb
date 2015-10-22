SET DEFINE OFF;
    CREATE OR REPLACE PACKAGE BODY FT_PK_STOCKDISSECTION
    AS
      cVersionControlNo   VARCHAR2(12) := '1.0.7'; -- Current Version Number

      --VARIABLES FOR OVER SOLD DETAILS
      GLBALLOCNO                    NUMBER(10)        :=0;
      GLBISOVERALLOC                NUMBER(1)        :=0;
      GLBOVERSOLD_ONLYBOXQTY        NUMBER(10)        :=0;   --- THIS IS THE BOX OVERSOLD QTY IGNORING ALL SPLITS FOR AN ALLOCATE LINE
      GLBOVERSOLD_BOXQTY            NUMBER(10)        := 0; --- THIS IS THE BOX OVERSOLD QTY INCLUDING ALL BOX EQUIVALENT OF THE SPLITS FOR AN ALLOCATE LINE
      GLBOVERSOLD_WGTQTY            NUMBER(10)        := 0; --- THIS IS THE WGT OVERSOLD QTY FOR AN ALLOCATE LINE
      GLBOVERSOLD_EACHQTY           NUMBER(10)        := 0; --- THIS IS THE EACH OVERSOLD QTY FOR AN ALLOCATE LINE
      GLBOVERSOLD_INNERQTY          NUMBER(10)        := 0; --- THIS IS THE INNER OVERSOLD QTY FOR AN ALLOCATE LINE


    ---*******************************************************************************************************************************************
    -- MAINRUN_FIRSTSTAGE AND MAINRUN_SNDSTAGE ARE THE PROCEDURE THAT CALLS ALL THE OTHERS
    -- thet were split to get the list of lotite numbers and then uese paradox to do the autocosting
    ---*******************************************************************************************************************************************

       PROCEDURE MAINRUN_FIRSTSTAGE(V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER)   IS
            VAR_LCONT                NUMBER(1) := 1;
            V_USERNO                 NUMBER(10);
      BEGIN

       -- TEMPORARY PIECE OF CODE
        IF VAR_LCONT = 1 THEN
            BEGIN
                DELETE FROM STKDISS_DETS WHERE STKDISS_DETS.STKDISSHDR_RECNO =V_HDRRECNO ;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;  -- IF THERE IS NOTHING TO DELETE THEN WE STILL WANT TO CONTINUE
                WHEN OTHERS THEN
                    NULL;
                     RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - MAINRUN - DELETE');
                    VAR_LCONT := 0;
            END;
        END IF;

        --  CALL ALL OTHER METHODS
        IF VAR_LCONT = 1 THEN
             BEGIN
                --UPDATE STKDISS_HDR SET STARTDT = NULL, MISSINGALLOCDT= NULL, EXTRACT_STKDT = NULL, ALREDYSLDDT = NULL, ONALLOCDT = NULL, COMPLETEDT = NULL
                --WHERE STKDISSHDR_RECNO = V_HDRRECNO;

                UPDATE STKDISS_HDR SET STARTDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

                WRITEMISSINGALLOCDETS();
                UPDATE STKDISS_HDR SET MISSINGALLOCDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

                EXTRACT_STK_FOR_DPT (V_DPTRECNO, V_HDRRECNO);
                UPDATE STKDISS_HDR SET EXTRACT_STKDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

            EXCEPTION
                WHEN OTHERS THEN
                raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                         NULL;
                         RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - MAINRUN - CALL METHODS');

            END;
        END IF;

        END MAINRUN_FIRSTSTAGE;


       PROCEDURE MAINRUN_SNDSTAGE(V_DPTRECNO IN NUMBER,
                                  V_HDRRECNO IN NUMBER,
                                  V_UPTODATE IN DATE,
                                  V_USEDLVDATE IN NUMBER)   IS
            VAR_LCONT                NUMBER(1) := 1;
            V_USERNO                 NUMBER(10);
      BEGIN


        --  CALL ALL OTHER METHODS
        IF VAR_LCONT = 1 THEN
             BEGIN
                UPDATE STKDISS_HDR SET ALREDYSLDDT_PRIOR = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;
                --IF V_UPTODATE IS NULL THEN  -- IF THIS IS A TPIE SITE THEN NO NEED TO GET OLD DATA AS THEY ARE NOT INTERESTED IN IT   -- 18Apr2014 took this out as the figure look wrong
                    EXTRACTALREDYSLD_DETS(V_HDRRECNO);
                --END IF;

                UPDATE STKDISS_HDR SET ALREDYSLDDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

                EXTRACTONALLOC_DETS(V_DPTRECNO, V_HDRRECNO,V_UPTODATE, V_USEDLVDATE);

                UPDATE STKDISS_HDR SET ONALLOCDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

                IF V_UPTODATE IS NULL THEN  -- IF THIS IS A TPIE SITE THEN NO NEED TO GET OLD DATA AS THEY ARE NOT INTERESTED IN IT
                    EXTRACTRETURN_DETS  (V_HDRRECNO);
                END IF;

                FINALCALCS(V_HDRRECNO);

                UPD_ACCCODE(V_HDRRECNO);

                UPDATE STKDISS_HDR SET COMPLETEDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

            EXCEPTION
                WHEN OTHERS THEN
                raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                         NULL;
                         RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - MAINRUN - CALL METHODS');

            END;
        END IF;

        END MAINRUN_SNDSTAGE;

    ---*******************************************************************************************************************************************
    -- THIS IS A FRIG THAT POPUALTES ANY ALLOCLITITENO, ALLOCDPTRECNO VALUES IN ALLOCATE THAT MAY HAVE BEEN MISSED
    -- I WOULD HOPE THAT IT PICKS NOTHING UP
    -- DO NOT THINK THE PREPACK STUFF IS RELAVENT BUTTHIS COULD PROVE WRONG IN THE LONG TERM
    ---*******************************************************************************************************************************************
        PROCEDURE WRITEMISSINGALLOCDETS   IS
        BEGIN
            BEGIN

		-- 13531 SOMETHING WAS CREATING DELTOALLS WITH -VE QTYIES AND SO THIS METHOD JUST CLEARS THEM DOWN BEFORE STOCK DISSECTION IS RUN
		-- ANOTHER FRIG BUT A NECESSARY ONE (BMK)
		FT_PK_ALLOCATE_CHECK.REPAIR_DELTOALL_MIN();

                UPDATE ALLOCATE
                SET ALLOCLITITENO = (SELECT MIN(ITESTO.ISTLITNO) FROM PALNOLOC, ITESTO WHERE PALNOLOC.PALLOCALLNO = ALLOCNO AND PALNOLOC.PALLOCISTRECNO = ITESTO.ISTRECNO)
                WHERE NVL(ALLOCLITITENO,0) = 0
                AND NVL(ALLOCISPREPPACK,0) = 0;

                UPDATE ALLOCATE
                SET ALLOCDPTRECNO = (SELECT MIN(DEPARTMENTSTOSMN.DPTRECNO) FROM DEPARTMENTSTOSMN, LOTITE
                                    WHERE LOTITE.LITITENO = ALLOCATE.ALLOCLITITENO
                                    AND LOTITE.LITBUYER             = DEPARTMENTSTOSMN.SMNNO)
                WHERE NVL(ALLOCDPTRECNO,0) = 0
                AND NVL(ALLOCLITITENO,0) <> 0
                AND NVL(ALLOCISPREPPACK,0) = 0;
                COMMIT;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                   NULL;
               WHEN OTHERS THEN
                    --NULL;
                    RAISE_APPLICATION_ERROR(-20001, 'Oracle Package -FT_PK_STOCKDISSECTION- WRITEMISSINGALLOCDETS');
            END;
        END WRITEMISSINGALLOCDETS;

    ---*******************************************************************************************************************************************
    -- EXTRACTS THE STOCK FIGURES FOR THE PASSED DEPARTMENT
    ---*******************************************************************************************************************************************
        PROCEDURE EXTRACT_STK_FOR_DPT  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER) IS
            VAR_LCONT                NUMBER(1) := 1;
            V_NUMOFRECS              NUMBER(10);
        BEGIN

        -- EXTRACT ALL THE ALLOCATE RECORDS THAT ARE FOR THIS DEPARTMENT
        -- PREPACK LINES ARE IGNORED AT THE MOMENT - THEY WILL HAVE TO BE PICKED UP EVENTUALLY AS THEY ARE RELEVANT FOR THE SPLITS
        IF VAR_LCONT = 1 THEN
            BEGIN
                INSERT INTO STKDISS_DETS
                (STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, SALOFFNO)
                (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, ALLOCLITITENO, ALLOCSALOFFNO FROM
                (SELECT  DISTINCT ALLOCATE.ALLOCLITITENO, ALLOCATE.ALLOCSALOFFNO
                FROM ALLOCATE
                WHERE ALLOCATE.ALLOCDPTRECNO = V_DPTRECNO
                AND NVL(ALLOCATE.ALLOCISPREPPACK,0) = 0
                ));
                V_NUMOFRECS              := SQL%ROWCOUNT;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_LCONT := 0;  -- IF THERE ARE NO RECORDS FOR THIS DEPARTMENT THEN THERE IS NO POINT IN CONTINUING
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_STK_FOR_DPT - EXTRACT');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- GET OVERSOLDS
        IF VAR_LCONT = 1 THEN
            EXTRACT_OVERSOLDLOTS (V_DPTRECNO,  V_HDRRECNO);
        END IF;


         -- GET NEW INTERDEPARTMENT TRANSFERS
        IF VAR_LCONT = 1 THEN
            EXTRACT_INTERDPTTRANSFERS (V_DPTRECNO,  V_HDRRECNO);
        END IF;

        -- UPDATE THE SALES OFFICE AND REMOVE ANY NOT FOR CURRENT SALESOFFICE
        IF VAR_LCONT = 1 THEN
            UPD_SALESOFFICE  ( V_HDRRECNO);
        END IF;



        -- REMOVE ANY LOTITES THAT MAY BE IN ALLOCATE BUT THAT HAVE NOT YET BEEN RECEIVED
        /*IF VAR_LCONT = 1 THEN
            BEGIN
                DELETE FROM STKDISS_DETS
                WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                AND     NVL(OPENINGQTY,0) <= 0
                AND     EXISTS ( SELECT 1 FROM  LOTITE WHERE LOTITE.LITITENO = STKDISS_DETS.LITITENO AND NVL(LITRCVIND, 'N') <> 'Y');
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_STK_FOR_DPT - DELETE EXPECTED');
                    VAR_LCONT := 0;
            END;
        END IF; */

        -- EXTRACT THE OPENING QTY FOR THESE RECORDS
        IF VAR_LCONT = 1 THEN
            UPD_OPENINGQTY  ( V_HDRRECNO);
        END IF;



        END EXTRACT_STK_FOR_DPT;


    ---*******************************************************************************************************************************************
    -- EXTRACTS THE OVERSOLD LINES FOR THE PASSED DEPARTMENT
    ---*******************************************************************************************************************************************
    PROCEDURE EXTRACT_OVERSOLDLOTS  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER) IS
            VAR_LCONT                NUMBER(1) := 1;
        BEGIN

    -- 9512 UPDATE ANY OF THESE THAT MAY BE OVERSOLD
        IF VAR_LCONT = 1 THEN
            BEGIN
                UPDATE STKDISS_DETS
                SET OVERSOLDLINE = 1
                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND EXISTS ( SELECT 1 FROM LOTITE_LINK WHERE LOTITE_LINK.NEWLITITENO = STKDISS_DETS.LITITENO AND STATUS = 1);
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - FLAG OVERSOLDLINE  - EXTRACT_OVERSOLDLOTS');
                    VAR_LCONT := 0;
            END;
        END IF;


    -- 9512 EXTRACT ALL THE OVERSOLD LOTITES THAT ARE FOR THIS DEPARTMENT
        IF VAR_LCONT = 1 THEN
            BEGIN
                INSERT INTO STKDISS_DETS
                (STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, SALOFFNO, OVERSOLDLINE)
                (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, NEWLITITENO, PORSALOFF, 1 FROM
                (SELECT  DISTINCT LOTITE_LINK.NEWLITITENO, PURORD.PORSALOFF
                FROM LOTITE_LINK, LOTITE, PURORD, DEPARTMENTSTOSMN
                WHERE STATUS = 1
                AND LOTITE_LINK.NEWLITITENO = LOTITE.LITITENO
                AND LOTITE.LITPORREC =  PURORD.PORRECNO
                AND LOTITE.LITBUYER =  DEPARTMENTSTOSMN.SMNNO
                AND DEPARTMENTSTOSMN.DPTRECNO =V_DPTRECNO
                AND NOT EXISTS ( SELECT 1 FROM STKDISS_DETS WHERE STKDISSHDR_RECNO = V_HDRRECNO AND STKDISS_DETS.LITITENO = LOTITE_LINK.NEWLITITENO)
                ));
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_OVERSOLDLOTS - OVERSOLDS');
                    VAR_LCONT := 0;
            END;
        END IF;

            -- 9512 - 01/07/2013  -- yet another change to what was asked for
            --  they now want the oversold lines to always show against the original POs until they are cleared and flag them as  **OVERSOLD**
    -- THIS GETS ALL THE LOTITE LINES THAT HAVE NOT YET BEEN EXTRACTED  - THEY ARE ONES THAT ARE FULLY SOLD BUT MAY HAVE HAD SOME OVERSOLDS LINES
        IF VAR_LCONT = 1 THEN
            BEGIN
                INSERT INTO STKDISS_DETS
                (STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, SALOFFNO, OVERSOLDLINE)
                (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, ORGLITITENO, PORSALOFF, 0 FROM
                (SELECT  DISTINCT LOTITE_LINK.ORGLITITENO, PURORD.PORSALOFF
                FROM LOTITE_LINK, LOTITE, PURORD, DEPARTMENTSTOSMN
                WHERE STATUS = 1
                AND LOTITE_LINK.NEWLITITENO = LOTITE.LITITENO
                AND LOTITE.LITPORREC =  PURORD.PORRECNO
                AND LOTITE.LITBUYER =  DEPARTMENTSTOSMN.SMNNO
                AND DEPARTMENTSTOSMN.DPTRECNO =V_DPTRECNO
                AND NOT EXISTS ( SELECT 1 FROM STKDISS_DETS WHERE STKDISSHDR_RECNO = V_HDRRECNO AND STKDISS_DETS.LITITENO = LOTITE_LINK.ORGLITITENO)
                ));
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;

                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_OVERSOLDLOTS - OVERSOLDS');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- 9512 FOR LINES THAT WERE OVERSOLD BUT HAVE SINCE BEEN MOVED THEY WISH TO DISPLAY THESE AS **TRANFER** AGAINST THE ORIGINAL LOT
        IF VAR_LCONT = 1 THEN
            BEGIN
                INSERT INTO STKDISS_DETS
                (STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, SALOFFNO, OVERSOLDLINE)

                (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, LITITENO, SALOFFNO, 0 FROM
                (SELECT DISTINCT LITITENO,  SALOFFNO FROM
                    (SELECT
                        ( SELECT ORGLITITENO FROM LOTITE_LINK WHERE  LOTITE_LINK.NEWLITITENO = DLV.LITITENO AND TYPEFLAG = 1) LITITENO,
                        STKDISS_DETS.SALOFFNO
                    FROM STKDISS_DETS_DLV DLV, STKDISS_DETS
                    WHERE   DLV.STKDISSHDR_RECNO = STKDISS_DETS.STKDISSHDR_RECNO
                    AND     DLV.LITITENO = STKDISS_DETS.LITITENO
                    AND     DLV.STKDISSHDR_RECNO = (SELECT MAX(STKDISSHDR_RECNO) FROM STKDISS_HDR WHERE DPTRECNO = V_DPTRECNO AND ISCOMPLETE = 1) -- AND STKDISSHDR_RECNO < V_HDRRECNO)
                    AND     DLV.OVERSOLDLINE  = 1
                    AND     EXISTS ( SELECT 1 FROM LOTITE_LINK WHERE  LOTITE_LINK.NEWLITITENO = DLV.LITITENO AND TYPEFLAG = 1 AND ORGLITITENO > 0)
                    AND     NOT EXISTS ( SELECT 1 FROM STKDISS_DETS_DLV THISDLVEXTRACT WHERE STKDISSHDR_RECNO = V_HDRRECNO AND DLV.LITITENO = THISDLVEXTRACT.LITITENO AND DLV.DELRECNO = THISDLVEXTRACT.DELRECNO)

                    UNION

                        SELECT
                        ( SELECT ORGLITITENO FROM LOTITE_LINK WHERE  LOTITE_LINK.NEWLITITENO = ALLOC.LITITENO AND TYPEFLAG = 1) LITITENO,
                        STKDISS_DETS.SALOFFNO
                    FROM STKDISS_DETS_ONALLOC ALLOC, STKDISS_DETS
                    WHERE   ALLOC.STKDISSHDR_RECNO = STKDISS_DETS.STKDISSHDR_RECNO
                    AND     ALLOC.LITITENO     = STKDISS_DETS.LITITENO
                    AND     ALLOC.STKDISSHDR_RECNO = (SELECT MAX(STKDISSHDR_RECNO) FROM STKDISS_HDR WHERE DPTRECNO = V_DPTRECNO AND ISCOMPLETE = 1)-- AND STKDISSHDR_RECNO < V_HDRRECNO)
                    AND     ALLOC.OVERSOLDLINE  = 1
                    AND     EXISTS ( SELECT 1 FROM LOTITE_LINK WHERE  LOTITE_LINK.NEWLITITENO = ALLOC.LITITENO AND TYPEFLAG = 1AND ORGLITITENO > 0)
                    AND     NOT EXISTS ( SELECT 1 FROM STKDISS_DETS_DLV THISDLVEXTRACT WHERE STKDISSHDR_RECNO = V_HDRRECNO AND ALLOC.LITITENO = THISDLVEXTRACT.LITITENO AND ALLOC.DELRECNO = THISDLVEXTRACT.DELRECNO)
                    ) TRANSFERDETS
                WHERE     NOT EXISTS ( SELECT 1 FROM STKDISS_DETS WHERE STKDISSHDR_RECNO = V_HDRRECNO AND STKDISS_DETS.LITITENO = TRANSFERDETS.LITITENO)
                )
                );
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;

                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_OVERSOLDLOTS - OVERSOLDS');
                    VAR_LCONT := 0;
            END;
        END IF;


    END EXTRACT_OVERSOLDLOTS;

    ---*******************************************************************************************************************************************
    -- EXTRACTS THE INTER DEPARTMENT TRANSFERS DONE SINCE THE LAST EXTRACT
    ---*******************************************************************************************************************************************

    PROCEDURE EXTRACT_INTERDPTTRANSFERS  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER) IS
            VAR_LCONT                NUMBER(1) := 1;
        BEGIN



        -- 06/09/2013 INTER DEPARTMENT TRANFERS CAN CONFIRM THE DELIVERY WHICH MEANS THE LOTITE IS NO LONGER IN ALLOCATE
        -- THIS HERE PICKS THEM UP
        IF VAR_LCONT = 1 THEN
            BEGIN
                INSERT INTO STKDISS_DETS
                (STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, SALOFFNO)
                (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, ISTLITNO , DLVSALOFFNO
                FROM
                (SELECT DISTINCT ITESTO.ISTLITNO , DELHED.DLVSALOFFNO
                FROM    DELHED, DELDET, DELPRICE,  DELTOIST, ITESTO
                WHERE   DELHED.DLVORDNO     = DELDET.DELDLVORDNO
                AND     DELDET.DELRECNO     = DELPRICE.DPRDELRECNO
                AND     DELPRICE.DPRRECNO   = DELTOIST.DISDPRRECNO
                AND     DELTOIST.DISISTRECNO = ITESTO.ISTRECNO
                -- BIT OF SHITTY CODE THAT TO ENSURE THAT THIS QUERY CHECKS ALL THE DELVIERIES SINCE THE LAST UPDATE
                -- IT ASSUMES THAT ANY NEW INTER TRANSFERSWILL HAVE A GREATER DLV THAN THE GREATEST ONE IN THE LAST UPDATE - THIS SHOULD BE OK AS THEY ARE CREATED IN ORDER BUT IT IS A BIT SHITTY
                AND     DELHED.DLVORDNO > (SELECT MAX(DLVORDNO) FROM STKDISS_DETS_ONALLOC
                                          WHERE STKDISSHDR_RECNO = (SELECT MAX(STKDISSHDR_RECNO) FROM STKDISS_HDR WHERE DPTRECNO = V_DPTRECNO AND ISCOMPLETE = 1))-- AND STKDISSHDR_RECNO < V_HDRRECNO))
                AND     DELHED.INTERDEPTFLAG > 0
                AND     DELHED.DLVSALOFFNO = (SELECT SALOFFNO FROM STKDISS_HDR WHERE STKDISS_HDR.STKDISSHDR_RECNO  = V_HDRRECNO)
                -- 26/11/2013  ADDED THIS LINE TO LIMIT THE LOTS TO ONLY THIS DEPARTMENT
                AND     EXISTS (SELECT 1 FROM LOTITE, DEPARTMENTSTOSMN WHERE LOTITE.LITITENO = ITESTO.ISTLITNO AND LOTITE.LITBUYER = DEPARTMENTSTOSMN.SMNNO AND DEPARTMENTSTOSMN.DPTRECNO = V_DPTRECNO )
                AND     EXISTS ( SELECT 1 FROM ORDERS, DEPARTMENTSTOSMN
                                    WHERE   DELHED.DLVORDRECNO = ORDERS.ORDRECNO
                                    AND     ORDERS.ORDSMNNO =  DEPARTMENTSTOSMN.SMNNO
                                    AND     DEPARTMENTSTOSMN.DPTRECNO =V_DPTRECNO)
                AND NOT EXISTS ( SELECT 1 FROM STKDISS_DETS WHERE STKDISSHDR_RECNO = V_HDRRECNO AND  ITESTO.ISTLITNO =  STKDISS_DETS.LITITENO)
                ));
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - FULLY SOLD INTER DEPARTMENT TRANFER LOTITES- EXTRACT');
                    VAR_LCONT := 0;
            END;
        END IF;

    END EXTRACT_INTERDPTTRANSFERS;


    ---*******************************************************************************************************************************************
    -- UPDATES THE SALES OFFICE FOR THE EXTRACTED LOTS AND REMOVES ANY NOT REQUIRED
    ---*******************************************************************************************************************************************

    PROCEDURE UPD_SALESOFFICE  (V_HDRRECNO IN NUMBER) IS
            VAR_LCONT                NUMBER(1) := 1;
        BEGIN

         -- GET THE SALES OFFICE FOR THE LOTS
        IF VAR_LCONT = 1 THEN
            BEGIN

                -- GET THE SALES OFFICE FOR THE STRAIGHT BULK
                UPDATE STKDISS_DETS SET SALOFFNO = ( SELECT PURORD.PORSALOFF FROM LOTITE, PURORD WHERE STKDISS_DETS.LITITENO = LOTITE.LITITENO AND LOTITE.LITPORREC = PURORD.PORRECNO )
                WHERE STKDISS_DETS.STKDISSHDR_RECNO = V_HDRRECNO
                AND  NVL(SALOFFNO, 0) = 0 ;
                COMMIT;

                -- GET THE SALES OFFICE FOR ANY THE SPLITS USING THE ORIGINAL PO NO
                UPDATE STKDISS_DETS SET SALOFFNO = ( SELECT PURORD.PORSALOFF FROM LOTITE, PURORD WHERE STKDISS_DETS.LITITENO = LOTITE.LITITENO AND LOTITE.LITSPLITPONO = PURORD.PORNO )
                WHERE STKDISS_DETS.STKDISSHDR_RECNO = V_HDRRECNO
                AND  NVL(SALOFFNO, 0) = 0;
                COMMIT;

                -- BIT OF A FRIG BUT IF WE HAVE NOT GOT A SALES OFFICE AT THIS POINT THEN JUST ASSUME IT IS FOR THIS SALES OFFICE
                UPDATE STKDISS_DETS SET SALOFFNO = ( SELECT SALOFFNO FROM STKDISS_HDR WHERE STKDISS_HDR.STKDISSHDR_RECNO  = V_HDRRECNO)
                WHERE STKDISS_DETS.STKDISSHDR_RECNO = V_HDRRECNO
                AND  NVL(SALOFFNO, 0) = 0;
                COMMIT;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - UPDATE STKDISS_DETS SALOFFNO ');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- REMOVE ANY LOTITES THAT MAY NOT BE FOR THIS SALES OFFICE
        IF VAR_LCONT = 1 THEN
            BEGIN
                DELETE FROM STKDISS_DETS
                WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                AND     NVL(SALOFFNO, 0) <> (SELECT SALOFFNO FROM STKDISS_HDR WHERE STKDISS_HDR.STKDISSHDR_RECNO  = V_HDRRECNO);
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - DELETE STKDISS_DETS <> SALOFFNO ');
                    VAR_LCONT := 0;
            END;
        END IF;



    END UPD_SALESOFFICE;


    ---*******************************************************************************************************************************************
    -- UPDATES THE OPENING QTY FOR THE EXTRACTED LOTS
    ---*******************************************************************************************************************************************
    PROCEDURE UPD_OPENINGQTY  (V_HDRRECNO IN NUMBER) IS
            VAR_LCONT                NUMBER(1) := 1;
        BEGIN

          -- EXTRACT THE OPENING QTY FOR THESE RECORDS
        IF VAR_LCONT = 1 THEN
            BEGIN
                -- 18Apr2014 took out the LITRCVIND = 'Y' part as this meant that some LOTS where not getting extracted as they were never flagged at 'Y'
                -- UPDATE STKDISS_DETS SET OPENINGQTY = ( SELECT LITQTYRCV FROM  LOTITE WHERE LOTITE.LITITENO = STKDISS_DETS.LITITENO AND LITRCVIND = 'Y')

                UPDATE STKDISS_DETS SET OPENINGQTY = ( SELECT LITQTYRCV FROM  LOTITE WHERE LOTITE.LITITENO = STKDISS_DETS.LITITENO AND LITRCVIND = 'Y')
                WHERE STKDISSHDR_RECNO = V_HDRRECNO;
                -- 18Apr2014 took this out otherwise the expected did not show
                --DELETE FROM STKDISS_DETS
                --WHERE STKDISSHDR_RECNO = V_HDRRECNO
                --AND NVL(OPENINGQTY,0) =0;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_LCONT := 0;  -- IF THERE ARE NO RECORDS FOR THIS DEPARTMENT THEN THERE IS NO POINT IN CONTINUING
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - UPD_OPENINGQTY - UPDATE OPENING');
                    VAR_LCONT := 0;
            END;
        END IF;


    END UPD_OPENINGQTY;


    ---*******************************************************************************************************************************************
    -- EXTRACTS THE ALREADY SOLD FIGURES AND THE VALUE OF THESE
    ---*******************************************************************************************************************************************
        PROCEDURE EXTRACTALREDYSLD_DETS  (V_HDRRECNO IN NUMBER) IS

        BEGIN
            DECLARE

            V_QTYALRDYSOLD              NUMBER(10) :=0;
            V_QTYALRDYSOLD_APPTOBOX     FLOAT :=0;
            V_VALUEALRDYSOLD            FLOAT :=0;
            V_DISC_ONALRDYSOLD          FLOAT :=0;
            V_REB_ONALRDYSOLD           FLOAT :=0;
            V_OTHCHG_ONALRDYSOLD           FLOAT :=0;
            VAR_LCONT                NUMBER(1) := 1;



            -- CURSOR TO EXTRACT THE LIST OF LOTITES THAT WE ARE CURRENTLY WORKING WITH
            CURSOR STKDISS_DETS_CURSOR(INS_HDRRECNO NUMBER) IS
                        (SELECT STKDISSDETS_RECNO, LITITENO, OVERSOLDLINE FROM STKDISS_DETS
                         WHERE STKDISSHDR_RECNO =    INS_HDRRECNO) ;
            STKDISS_DETS_RECORD STKDISS_DETS_CURSOR%ROWTYPE;

            -- CURSOR TO EXTRACT THE QTY ANF VALUE OF THE SALES FOR A LOTITE
            CURSOR SLDDETS_CURSOR(INS_LITITENO NUMBER) IS
                    ( SELECT
                                        /*
                                        INDEX(ITESTO, ITESTO_TOLOTITE) USE_NL(ITESTO)
                                        INDEX(DELTOIST, DELTOIST_TOITESTO) USE_NL(DELTOIST)
                                        INDEX(DELPRICE, PK_DELPRICE) USE_NL(DELPRICE)
                                        INDEX(DELDET, PK_DELDET) USE_NL(DELDET)
                                        INDEX(DELHED, PK_DELHED) USE_NL(DELHED)
                                        */
                                         DELHED.DLVORDNO, DELDET.DELRECNO, DELDET.DELQTYPER, DELPRICE.DELPRICE, DELPRICE.DELFREEOFCHG, DELPRICE.DELINVSTATUS, DELPRICE.DPRISPRICEADJONLY, DELPRICE.DPRCREATIONDATE,
                                         NVL(SUM(NVL(DELTOIST.DISSTKQTY,0)),0) DISSTKQTY, NVL(SUM(NVL(DELTOIST.DISNETTVALUE,0)),0) DISNETTVALUE,
                                         NVL(SUM(NVL( (SELECT ((SELECT SUM(NVL(ICHAPPAMT,0)) FROM ITECHG WHERE ITECHG.CTYNO = 97 AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO) /DELPRICE.DELPRCQTY) * DELTOIST.DISSTKQTY FROM DUAL),0)),0)  DISCOUNT,
                                         NVL(SUM(NVL( (SELECT ((SELECT SUM(NVL(ICHAPPAMT,0)) FROM ITECHG WHERE ITECHG.CTYNO = 98 AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO) /DELPRICE.DELPRCQTY) * DELTOIST.DISSTKQTY FROM DUAL),0)),0)  REBATE,
                                         -- 27/08/2013  the charges should all have the itesto number in itechg so there is no need to apportion them across the DELTOISTS
                                         /*NVL(SUM(NVL( (SELECT ((SELECT SUM(NVL(ICHAPPAMT,0))
                                                                   FROM ITECHG, EXPCHA
                                                                WHERE ITECHG.CTYNO NOT IN(97, 98)
                                                                AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO
                                                                AND Itechg.ExcRecNo = Expcha.ExcCharec
                                                                AND NVL(Expcha.EXCRECOVFROMPL,0) = 0) /DELPRICE.DELPRCQTY) * DELTOIST.DISSTKQTY FROM DUAL),0)),0)  OTH_CHG*/
                                        NVL(SUM(NVL( (SELECT (SELECT SUM(NVL(ICHAPPAMT,0))
                                                                   FROM ITECHG, EXPCHA
                                                                WHERE ITECHG.CTYNO NOT IN(97, 98)
                                                                AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO
                                                                AND Itechg.ExcRecNo = Expcha.ExcCharec
                                                                AND ITECHG.ICHISTRECNO = ITESTO.ISTRECNO
                                                                AND NVL(Expcha.EXCRECOVFROMPL,0) = 0) FROM DUAL),0)),0)  OTH_CHG


                                         FROM ITESTO, DELTOIST, DELPRICE, DELDET, DELHED, ORDERS
                                         WHERE ITESTO.ISTLITNO = INS_LITITENO
                                         AND DELTOIST.DISISTRECNO = ITESTO.ISTRECNO
                                         AND DELTOIST.DISDPRRECNO = DELPRICE.DPRRECNO
                                         AND DELPRICE.DPRDELRECNO = DELDET.DELRECNO
                                         AND DELDET.DELDLVORDNO =  DELHED.DLVORDNO
                                         AND DELHED.DLVORDRECNO = ORDERS.ORDRECNO
                                         AND DELINVSTATUS IN (1, 2, 3, 11, 12, 13)
                                        -- I'M IGNORING PRICE CREDITS AND DEBITS
                                         --AND (DELINVSTATUS IN (1,11) OR (DELINVSTATUS IN (2,12) AND DPRISPRICEADJONLY = 0))
                                         --AND NVL(DELPRICE.DELFREEOFCHG,0) =  0   -- MAY NEED TO DO SOMETHING ABOUT THESE
                                         AND NVL(DELHED.DLVTRANSSHIP ,0) = 0
                                         AND NVL(DELHED.TRANSFERFLG ,0) = 0
                   --  all lines against this lotite should only be for QTY PER = 1 (box) so this code is not really required but i am putting it in
                                         AND NVL(DELDET.DELQTYPER, 1) = 1
                                         AND NVL(DELPRICE.DELPRCQTY,0) <> 0
                                         AND NVL(ORDSALTYP, 'N')  <> 'R'   -- 08/05/2014 WE NEED TO IGNORE RTS LINES
                                         GROUP BY DELHED.DLVORDNO, DELDET.DELRECNO, DELDET.DELQTYPER, DELPRICE.DELPRICE, DELPRICE.DELFREEOFCHG, DELPRICE.DELINVSTATUS, DELPRICE.DPRISPRICEADJONLY, DELPRICE.DPRCREATIONDATE
                                        ) ;
            SLDDETS_RECORD SLDDETS_CURSOR%ROWTYPE;

            -- CURSOR TO EXTRACT THE QTY ANd VALUE OF THE PREPACK SALES FOR A LOTITE
            CURSOR PP_SLDDETS_CURSOR(INS_LITITENO NUMBER) IS
                    (SELECT
                     DELHED.DLVORDNO, DELDET.DELRECNO, DELDET.DELQTYPER, DELPRICE.DELPRICE, DELPRICE.DELFREEOFCHG, DELPRICE.DELINVSTATUS, DELPRICE.DPRISPRICEADJONLY, DELPRICE.DPRCREATIONDATE,
                     DELPRICE.DELPRCQTY,
                     NVL(SUM(NVL(PREPALINOUTSALES.BULKQTYEQUIV,0)),0) BULKQTY,
                     NVL(SUM(NVL(PREPALINOUTSALES.DPRQTYTHIS,0)),0) DPRQTYTHIS,  -- added 11/01/12

                     NVL(SUM(CASE WHEN NVL(PREPALINOUT.QTYOUTACCFOR,0) = NVL(PREPALINOUT.PPPALOUTQTY,0) OR PREPALINOUT.QTYBY = 1
                                  THEN NVL(PREPALINOUTSALES.BULKQTYEQUIV,0)
                                  -- 03/11/11 changed this from BULKQTYEQUIV to DPRQTYTHIS as this should use the used split qty to work out the apportionment
                                  --ELSE ROUND( NVL(PREPALINOUTSALES.BULKQTYEQUIV,0)/      (CASE PREPALINOUT.QTYBY  WHEN   2 THEN PRCWEIGHT
                                  ELSE ROUND( NVL(PREPALINOUTSALES.DPRQTYTHIS,0)/      (CASE PREPALINOUT.QTYBY  WHEN   2 THEN PRCWEIGHT

                                                                                                            WHEN   3 THEN PrcBoxQty
                                                                                                            ELSE   InnerQty
                                                                                                            END)

                                       ,2)

                                  END),0) BULKQTY_BOXEQUIV,

                     NVL(SUM(NVL(PREPALINOUTSALES.DPRBASEVALTHIS,0)),0) BASEVALUE,
                     NVL(SUM(NVL( (SELECT ((SELECT SUM(NVL(ICHAPPAMT,0)) FROM ITECHG WHERE ITECHG.CTYNO = 97 AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO) /DELPRICE.DELPRCQTY) * PREPALINOUTSALES.DPRQTYTHIS FROM DUAL),0)),0)  DISCOUNT,
                     NVL(SUM(NVL( (SELECT ((SELECT SUM(NVL(ICHAPPAMT,0)) FROM ITECHG WHERE ITECHG.CTYNO = 98 AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO) /DELPRICE.DELPRCQTY) * PREPALINOUTSALES.DPRQTYTHIS FROM DUAL),0)),0)  REBATE,
                -- 27/08/2013  the charges should all have the itesto number in itechg so there is no need to apportion them across the DELTOISTS
                     /*NVL(SUM(NVL( (SELECT ((SELECT SUM(NVL(ICHAPPAMT,0))
                                               FROM ITECHG, Expcha
                                            WHERE ITECHG.CTYNO NOT IN(97, 98)
                                            AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO
                                            AND Itechg.ExcRecNo = Expcha.ExcCharec
                                            AND NVL(Expcha.EXCRECOVFROMPL,0) = 0) /DELPRICE.DELPRCQTY) * PREPALINOUTSALES.DPRQTYTHIS FROM DUAL),0)),0)  OTH_CHG*/

                    NVL(SUM(NVL( (SELECT (SELECT SUM(NVL(ICHAPPAMT,0))
                                               FROM ITECHG, Expcha
                                            WHERE ITECHG.CTYNO NOT IN(97, 98)
                                            AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO
                                            AND ITECHG.EXCRECNO = EXPCHA.EXCCHAREC
                                            AND ITECHG.ICHISTRECNO = ITESTO.ISTRECNO
                                            AND NVL(Expcha.EXCRECOVFROMPL,0) = 0) FROM DUAL),0)),0)  OTH_CHG

                     FROM ITESTO, PREPALINOUT, PREPALINOUTSALES, DELPRICE,  DELDET, DELHED, PRDREC
                     WHERE PREPALINOUT.PALINBULKISTREC = ITESTO.ISTRECNO
                     AND PREPALINOUTSALES.PREPALINOUTRECNO     = PREPALINOUT.PREPALRECNO
                     AND DELPRICE.DPRRECNO = PREPALINOUTSALES.DELPRCRECNO
                     AND DELPRICE.DPRDELRECNO = DELDET.DELRECNO
                     AND DELDET.DELDLVORDNO =  DELHED.DLVORDNO
                     AND ITESTO.ISTPRDNO = PRDREC.PRCPRDNO
                     AND ITESTO.ISTLITNO   = INS_LITITENO
                     -- I'M IGNORING PRICE CREDITS AND DEBITS
                     --AND (DELINVSTATUS IN (1,11) OR (DELINVSTATUS IN (2,12) AND DPRISPRICEADJONLY = 0))
                     AND DELINVSTATUS IN (1, 2, 3, 11, 12, 13)
                     --AND NVL(DELPRICE.DELFREEOFCHG,0) =  0   -- MAY NEED TO DO SOMETHING ABOUT THESE
                     AND NVL(DELHED.DLVTRANSSHIP ,0) = 0
                     AND NVL(DELHED.TRANSFERFLG ,0) = 0
                     AND NVL(DELPRICE.DELPRCQTY,0) <> 0
                     GROUP BY DELHED.DLVORDNO, DELDET.DELRECNO, DELDET.DELQTYPER, DELPRICE.DELPRICE, DELPRICE.DELFREEOFCHG, DELPRICE.DELINVSTATUS, DELPRICE.DPRISPRICEADJONLY, DELPRICE.DPRCREATIONDATE, DELPRICE.DELPRCQTY
                     );

            PP_SLDDETS_RECORD PP_SLDDETS_CURSOR%ROWTYPE;


            BEGIN
                OPEN  STKDISS_DETS_CURSOR(V_HDRRECNO);
                LOOP
                    V_QTYALRDYSOLD              :=0;
                    V_QTYALRDYSOLD_APPTOBOX     :=0;
                    V_VALUEALRDYSOLD            :=0;
                    V_DISC_ONALRDYSOLD          :=0;
                    V_REB_ONALRDYSOLD           :=0;
                    V_OTHCHG_ONALRDYSOLD        :=0;

                    FETCH STKDISS_DETS_CURSOR INTO STKDISS_DETS_RECORD;
                    EXIT WHEN STKDISS_DETS_CURSOR%NOTFOUND;

                    BEGIN
                        OPEN  SLDDETS_CURSOR(STKDISS_DETS_RECORD.LITITENO);
                        LOOP
                            FETCH SLDDETS_CURSOR INTO SLDDETS_RECORD;
                            EXIT WHEN SLDDETS_CURSOR%NOTFOUND;

                            BEGIN
                                V_QTYALRDYSOLD              := V_QTYALRDYSOLD           + SLDDETS_RECORD.DISSTKQTY      ;
                                V_QTYALRDYSOLD_APPTOBOX     := V_QTYALRDYSOLD_APPTOBOX  + SLDDETS_RECORD.DISSTKQTY      ;
                                V_VALUEALRDYSOLD            := V_VALUEALRDYSOLD         + SLDDETS_RECORD.DISNETTVALUE   ;
                                V_DISC_ONALRDYSOLD          := V_DISC_ONALRDYSOLD       + SLDDETS_RECORD.DISCOUNT       ;
                                V_REB_ONALRDYSOLD           := V_REB_ONALRDYSOLD        + SLDDETS_RECORD.REBATE         ;
                                V_OTHCHG_ONALRDYSOLD        := V_OTHCHG_ONALRDYSOLD     + SLDDETS_RECORD.OTH_CHG        ;

                            END;

                            BEGIN
                                INSERT INTO STKDISS_DETS_DLV (
                                STKDISSDETS_DLV_RECNO, STKDISSHDR_RECNO, LITITENO, DLVORDNO, DELRECNO,
                                DELQTYPER, DELQTY, DELPRICE, DELNETTVALUE,DELFREEOFCHG, QTY_APPTOBOX,
                                DELINVSTATUS, DPRISPRICEADJONLY, DPRCREATIONDATE, DISC_ONALRDYSOLD, REB_ONALRDYSOLD, OTHCHG_ONALRDYSOLD,
                                OVERSOLDLINE)
                                (SELECT STKDISS_DETS_DLV_RECNO_SEQ.NEXTVAL, V_HDRRECNO, STKDISS_DETS_RECORD.LITITENO, SLDDETS_RECORD.DLVORDNO, SLDDETS_RECORD.DELRECNO,
                                SLDDETS_RECORD.DELQTYPER, SLDDETS_RECORD.DISSTKQTY,  SLDDETS_RECORD.DELPRICE,  SLDDETS_RECORD.DISNETTVALUE,
                                SLDDETS_RECORD.DELFREEOFCHG, SLDDETS_RECORD.DISSTKQTY,
                                SLDDETS_RECORD.DELINVSTATUS, SLDDETS_RECORD.DPRISPRICEADJONLY, SLDDETS_RECORD.DPRCREATIONDATE,
                                SLDDETS_RECORD.DISCOUNT, SLDDETS_RECORD.REBATE, SLDDETS_RECORD.OTH_CHG,
                                STKDISS_DETS_RECORD.OVERSOLDLINE
                                FROM DUAL);
                                commit;

                            EXCEPTION

                            WHEN OTHERS THEN
                                --NULL;
                                raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                                RAISE_APPLICATION_ERROR(-20001, 'FT_PK_STOCKDISSECTION - EXTRACTALREDYSLD_DETS  - STKDISS_DETS_DLV 2');
                                VAR_LCONT := 0;
                            END;

                        END LOOP;
                        CLOSE SLDDETS_CURSOR;

                        OPEN  PP_SLDDETS_CURSOR(STKDISS_DETS_RECORD.LITITENO);
                        LOOP
                            FETCH PP_SLDDETS_CURSOR INTO PP_SLDDETS_RECORD;
                            EXIT WHEN PP_SLDDETS_CURSOR%NOTFOUND;

                            BEGIN
                                V_QTYALRDYSOLD              := V_QTYALRDYSOLD           + PP_SLDDETS_RECORD.BULKQTY;
                                V_QTYALRDYSOLD_APPTOBOX     := V_QTYALRDYSOLD_APPTOBOX  + PP_SLDDETS_RECORD.BULKQTY_BOXEQUIV;
                                V_VALUEALRDYSOLD            := V_VALUEALRDYSOLD         + PP_SLDDETS_RECORD.BASEVALUE;
                                V_DISC_ONALRDYSOLD          := V_DISC_ONALRDYSOLD       + PP_SLDDETS_RECORD.DISCOUNT;
                                V_REB_ONALRDYSOLD           := V_REB_ONALRDYSOLD        + PP_SLDDETS_RECORD.REBATE;
                                V_OTHCHG_ONALRDYSOLD        := V_OTHCHG_ONALRDYSOLD     + PP_SLDDETS_RECORD.OTH_CHG        ;

                            END;


                            BEGIN

                                INSERT INTO STKDISS_DETS_DLV (
                                STKDISSDETS_DLV_RECNO, STKDISSHDR_RECNO, LITITENO, DLVORDNO, DELRECNO,
                                DELQTYPER, DELQTY, DELPRICE, DELNETTVALUE,DELFREEOFCHG, QTY_APPTOBOX,
                                DELINVSTATUS, DPRISPRICEADJONLY, DPRCREATIONDATE, DISC_ONALRDYSOLD, REB_ONALRDYSOLD, OTHCHG_ONALRDYSOLD,
                                OVERSOLDLINE)
                                ( SELECT STKDISS_DETS_DLV_RECNO_SEQ.NEXTVAL,
                                V_HDRRECNO, STKDISS_DETS_RECORD.LITITENO, PP_SLDDETS_RECORD.DLVORDNO, PP_SLDDETS_RECORD.DELRECNO,
                                PP_SLDDETS_RECORD.DELQTYPER,
                                PP_SLDDETS_RECORD.DPRQTYTHIS,   -- PP_SLDDETS_RECORD.DELPRCQTY, changed 11/01/2012
                                PP_SLDDETS_RECORD.DELPRICE,  PP_SLDDETS_RECORD.BASEVALUE,
                                PP_SLDDETS_RECORD.DELFREEOFCHG, PP_SLDDETS_RECORD.BULKQTY_BOXEQUIV,
                                PP_SLDDETS_RECORD.DELINVSTATUS, PP_SLDDETS_RECORD.DPRISPRICEADJONLY, PP_SLDDETS_RECORD.DPRCREATIONDATE,
                                PP_SLDDETS_RECORD.DISCOUNT, PP_SLDDETS_RECORD.REBATE, PP_SLDDETS_RECORD.OTH_CHG,
                                STKDISS_DETS_RECORD.OVERSOLDLINE
                                FROM DUAL);
                                commit;

                            EXCEPTION

                            WHEN OTHERS THEN
                                --NULL;
                                raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                                RAISE_APPLICATION_ERROR(-20001, 'FT_PK_STOCKDISSECTION - EXTRACTALREDYSLD_DETS  - other');
                            END;


                        END LOOP;
                        CLOSE PP_SLDDETS_CURSOR;
                    END;

                    BEGIN
                        update STKDISS_DETS SET QTYALRDYSOLD = V_QTYALRDYSOLD,
                        QTYALRDYSOLD_APPTOBOX   = V_QTYALRDYSOLD_APPTOBOX,
                        STKDISS_DETS.DATEDONE=   SYSDATE,  -- THIS WAS ADDED AS THE QUERY WAS TAKING ALONG TIME AND I WANTED TO SEE IF THERE WAS A PARTICULAR LINE THAT SLOWED IT DOWN
                        STKDISS_DETS.VALUEALRDYSOLD = V_VALUEALRDYSOLD,
                        STKDISS_DETS.DISC_ONALRDYSOLD = V_DISC_ONALRDYSOLD,
                        STKDISS_DETS.REB_ONALRDYSOLD = V_REB_ONALRDYSOLD,
                        STKDISS_DETS.OTHCHG_ONALRDYSOLD = V_OTHCHG_ONALRDYSOLD
                        where  STKDISS_DETS.STKDISSDETS_RECNO = STKDISS_DETS_RECORD.STKDISSDETS_RECNO;
                        commit;

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20001, 'FT_PK_STOCKDISSECTION - EXTRACTALREDYSLD_DETS  - NO DATA FOUND');
                    WHEN OTHERS THEN
                        --NULL;
                        RAISE_APPLICATION_ERROR(-20001, 'FT_PK_STOCKDISSECTION - EXTRACTALREDYSLD_DETS  - other');
                    END;

                END LOOP;
                CLOSE STKDISS_DETS_CURSOR;

                -- 27/11/2013 MOVED THIS QUERY HERE FROM ABOVE IN THE LOOP  - SEEMS TO HAVE SPEEDED UP THE EXTRACT SIGNIFICANTLY
                IF VAR_LCONT = 1 THEN
                BEGIN
                    --  for all our normal lines calc the cdt/dbt values AND qtyies and store them in the DPRCDTVAL AND DPRCDTQTY
                        UPDATE STKDISS_DETS_DLV
                        SET DPRCDTVAL = ( SELECT SUM(NVL(DELNETTVALUE,0)- NVL(DISC_ONALRDYSOLD,0) -  NVL(REB_ONALRDYSOLD,0) - NVL(OTHCHG_ONALRDYSOLD,0))
                                                            FROM STKDISS_DETS_DLV CDTAMT
                                                            WHERE CDTAMT.STKDISSHDR_RECNO = STKDISS_DETS_DLV.STKDISSHDR_RECNO
                                                            AND  CDTAMT.DELINVSTATUS IN (2,3, 12, 13)
                                                            AND CDTAMT.DELRECNO  = STKDISS_DETS_DLV.DELRECNO
                                                            AND ABS(NVL(DELNETTVALUE, 0)) > 0.0001),
                           /* DPRCDTQTY   = ( SELECT SUM(NVL(DELQTY,0))  CDT_QTY
                                                            FROM STKDISS_DETS_DLV CDTAMT
                                                            WHERE CDTAMT.STKDISSHDR_RECNO = V_HDRRECNO
                                                            AND  CDTAMT.DELINVSTATUS IN (2, 12)
                                                            AND CDTAMT.DELRECNO  = STKDISS_DETS_DLV.DELRECNO
                                                            AND CDTAMT.DPRISPRICEADJONLY = 0),
                            DPRCDTQTY_APPTOBOX   = ( SELECT SUM(NVL(QTY_APPTOBOX,0))  CDT_QTY_APPTOBOX
                                                            FROM STKDISS_DETS_DLV CDTAMT
                                                            WHERE CDTAMT.STKDISSHDR_RECNO = V_HDRRECNO
                                                            AND  CDTAMT.DELINVSTATUS IN (2, 12)
                                                            AND CDTAMT.DELRECNO  = STKDISS_DETS_DLV.DELRECNO
                                                            AND CDTAMT.DPRISPRICEADJONLY = 0)*/
                        (DPRCDTQTY, DPRCDTQTY_APPTOBOX) = ( SELECT
                                                            SUM(NVL(DELQTY,0))  CDT_QTY,
                                                            SUM(NVL(QTY_APPTOBOX,0))  CDT_QTY_APPTOBOX
                                                            FROM STKDISS_DETS_DLV CDTAMT
                                                            WHERE CDTAMT.STKDISSHDR_RECNO = STKDISS_DETS_DLV.STKDISSHDR_RECNO
                                                            AND CDTAMT.DELINVSTATUS IN (2, 12)
                                                            AND CDTAMT.DELRECNO = STKDISS_DETS_DLV.DELRECNO
                                                            AND CDTAMT.DPRISPRICEADJONLY = 0)

                        WHERE STKDISSHDR_RECNO = V_HDRRECNO
                        AND  DELINVSTATUS IN (1, 11);
                        commit;

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        Null;
                    WHEN OTHERS THEN
                        --NULL;
                        RAISE_APPLICATION_ERROR(-20001, 'Ft_PK_STOCKDISSECTION - EXTRACTALREDYSLD_DETS  - Upd DPRCDTVAL');
                    END;
                END IF;


                -- 9512
    -- EXTRACT THE DELIVERY DETAILS FOR  ANY  DELIVERIES  THAT HAVE BEEN CONFIRMED AGAINST AN OVER-SOLD PO
    -- THESE NEED TO BE REFLECTED AGAINST THE ORIGINAL LOTITES
    -- I DO THIS BY ADDING IN A DUPLICATE RECORD FOR THE ORIGINAL LOTITE - AND SO THESE TRANSACTIONS WILL NOW APPEAR TWICE IN THE SYSTEM
     -- ONCE AGAINST THE OVER-SOLD PO AND ONCE AGAINST THE PO THEY ORIGINALLY CAME FROM

                IF VAR_LCONT = 1 THEN
                    BEGIN
                        INSERT INTO STKDISS_DETS_DLV (
                                        STKDISSDETS_DLV_RECNO, STKDISSHDR_RECNO, LITITENO, DLVORDNO, DELRECNO,
                                        DELQTYPER, DELQTY, DELPRICE, DELNETTVALUE,DELFREEOFCHG, QTY_APPTOBOX,
                                        DELINVSTATUS, DPRISPRICEADJONLY, DPRCREATIONDATE, DISC_ONALRDYSOLD, REB_ONALRDYSOLD, OTHCHG_ONALRDYSOLD,
                                        DPRCDTVAL, DPRCDTQTY, DPRCDTQTY_APPTOBOX, OVERSOLDLINE)
                         (SELECT STKDISS_DETS_DLV_RECNO_SEQ.NEXTVAL, V_HDRRECNO,
                            (SELECT ORGLITITENO FROM LOTITE_LINK WHERE LOTITE_LINK.NEWLITITENO = STKDISS_DETS_DLV.LITITENO  AND  LOTITE_LINK.TYPEFLAG = 1 AND  LOTITE_LINK.STATUS = 1) LITITENO,
                                DLVORDNO, DELRECNO,
                                        DELQTYPER, DELQTY, DELPRICE, DELNETTVALUE,DELFREEOFCHG, QTY_APPTOBOX,
                                        DELINVSTATUS, DPRISPRICEADJONLY, DPRCREATIONDATE, DISC_ONALRDYSOLD, REB_ONALRDYSOLD, OTHCHG_ONALRDYSOLD,
                                        DPRCDTVAL, DPRCDTQTY, DPRCDTQTY_APPTOBOX, 3 OVERSOLDLINE
                          FROM STKDISS_DETS_DLV
                          WHERE STKDISSHDR_RECNO =  V_HDRRECNO
                          AND  STKDISS_DETS_DLV.OVERSOLDLINE = 1
                          AND EXISTS ( SELECT 1 FROM LOTITE_LINK WHERE LOTITE_LINK.NEWLITITENO = STKDISS_DETS_DLV.LITITENO
                                                                  AND  LOTITE_LINK.TYPEFLAG = 1
                                                                  AND  LOTITE_LINK.STATUS = 1
                                                                  AND LOTITE_LINK.ORGLITITENO > 0)
                        );

                        COMMIT;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                        WHEN OTHERS THEN
                            NULL;
                            RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTALREDYSLD_DETS - INSERT OVERSOLD LINES ');
                            VAR_LCONT := 0;
                    END;
                END IF;

                -- add these to the header details
                IF VAR_LCONT = 1 THEN
                    BEGIN
                        UPDATE STKDISS_DETS SET
                        QTYALRDYSOLD            = NVL(QTYALRDYSOLD,0) + NVL((SELECT SUM(NVL(QTY_APPTOBOX,0)) FROM STKDISS_DETS_DLV DLV WHERE DLV.STKDISSHDR_RECNO =  V_HDRRECNO AND DLV.LITITENO = STKDISS_DETS.LITITENO AND  OVERSOLDLINE = 3) ,0),
                        QTYALRDYSOLD_APPTOBOX   = NVL(QTYALRDYSOLD_APPTOBOX,0) + NVL((SELECT SUM(NVL(QTY_APPTOBOX,0)) FROM STKDISS_DETS_DLV DLV WHERE DLV.STKDISSHDR_RECNO =  V_HDRRECNO AND DLV.LITITENO = STKDISS_DETS.LITITENO AND  OVERSOLDLINE = 3) ,0),
                        STKDISS_DETS.DATEDONE=   SYSDATE,  -- THIS WAS ADDED AS THE QUERY WAS TAKING ALONG TIME AND I WANTED TO SEE IF THERE WAS A PARTICULAR LINE THAT SLOWED IT DOWN
                        STKDISS_DETS.VALUEALRDYSOLD         = NVL(VALUEALRDYSOLD,0)      +  NVL((SELECT SUM(NVL(DELNETTVALUE,0)) FROM STKDISS_DETS_DLV DLV WHERE DLV.STKDISSHDR_RECNO =  V_HDRRECNO AND  DLV.LITITENO = STKDISS_DETS.LITITENO AND  OVERSOLDLINE = 3) ,0),
                        STKDISS_DETS.DISC_ONALRDYSOLD       = NVL(DISC_ONALRDYSOLD,0)    +  NVL((SELECT SUM(NVL(DISC_ONALRDYSOLD,0)) FROM STKDISS_DETS_DLV DLV WHERE DLV.STKDISSHDR_RECNO =  V_HDRRECNO AND DLV.LITITENO = STKDISS_DETS.LITITENO AND  OVERSOLDLINE = 3) ,0),
                        STKDISS_DETS.REB_ONALRDYSOLD        = NVL(REB_ONALRDYSOLD,0)     +  NVL((SELECT SUM(NVL(REB_ONALRDYSOLD,0))  FROM STKDISS_DETS_DLV DLV WHERE DLV.STKDISSHDR_RECNO =  V_HDRRECNO AND DLV.LITITENO = STKDISS_DETS.LITITENO AND  OVERSOLDLINE = 3) ,0),
                        STKDISS_DETS.OTHCHG_ONALRDYSOLD     = NVL(OTHCHG_ONALRDYSOLD,0)  +  NVL((SELECT SUM(NVL(OTHCHG_ONALRDYSOLD,0)) FROM STKDISS_DETS_DLV DLV WHERE DLV.STKDISSHDR_RECNO =  V_HDRRECNO AND DLV.LITITENO = STKDISS_DETS.LITITENO AND  OVERSOLDLINE = 3) ,0)
                        WHERE STKDISSHDR_RECNO =  V_HDRRECNO
                        AND EXISTS ( SELECT 1 FROM STKDISS_DETS_DLV DLV WHERE STKDISSHDR_RECNO =  V_HDRRECNO AND  DLV.LITITENO = STKDISS_DETS.LITITENO AND  OVERSOLDLINE = 3)
                        ;
                        commit;

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                        WHEN OTHERS THEN
                            NULL;
                            RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTALREDYSLD_DETS - INSERT OVERSOLD LINES ');
                            VAR_LCONT := 0;
                    END;
                END IF;


            END;
    --*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*
    --  THERE IS MORE WORK NEEDED HERE TO GET THE SALES THAT ARE AGAINST SPLIT ALLOCATES
    --*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*-BMK-*


        END EXTRACTALREDYSLD_DETS;


    ---*******************************************************************************************************************************************
    -- -- EXTRACTS THE DETAILS OF THE DELIVERIES THAT ARE STILL AGAINST THE ALLOCATE
    ---*******************************************************************************************************************************************
        PROCEDURE EXTRACTONALLOC_DETS  (V_DPTRECNO IN NUMBER,
                                        V_HDRRECNO IN NUMBER,
                                        V_UPTODATE IN DATE,
                                        V_USEDLVDATE IN NUMBER) IS

           VAR_LCONT                NUMBER(1) := 1;
           VAR_UPTODATE             DATE := SYSDATE + 365;

        BEGIN

        -- DELETE ANY EXISTING RECORDS FOR THIS HEADER - THERE SHOULD NOT REALLY BE ANY BUT JUST IN CASE
        IF VAR_LCONT = 1 THEN
            BEGIN
                DELETE FROM STKDISS_DETS_ONALLOC WHERE STKDISSHDR_RECNO = V_HDRRECNO;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - DELETE');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- TPIE WANTED THE ABILITY TO EXTRACT DELIVERIES UP TO A CERTAIN DATE
        -- so if they are using this then the VAR_UPTODATE will be set at the passed in required date - else is is set a a year forward from today to catch all delvieries
        IF VAR_LCONT = 1 THEN
            IF V_UPTODATE IS NOT NULL THEN
            BEGIN
                VAR_UPTODATE := V_UPTODATE;
            END;
            END IF;
        END IF;

        -- EXTRACT THE DELIVERY DETAILS FOR  ANY  DELIVERIES  DIRECTLY AGAINST THE ALLOCATE
        IF VAR_LCONT = 1 THEN
            BEGIN
                INSERT INTO STKDISS_DETS_ONALLOC
                (STKDISSDETSONALLOC_RECNO, STKDISSHDR_RECNO, LITITENO, DLVORDNO, DELRECNO, ACTCSTCODE, DELQTYPER, DELQTY, DELDET_DALQTY, DELQTY_BOXEQUIV, DELTOALL_ID  )
                ( SELECT
                 /*INDEX(ALLOCATE, ALLOCATE_DPTRECNO) USE_NL(ALLOCATE)
                    INDEX(DELTOALL, DELTOALL_DALALLOCNO2IDX) USE_NL(DELTOALL)
                    INDEX(DELDET, PK_DELDET) USE_NL(DELDET)
                    INDEX(DELHED, PK_DELHED) USE_NL(DELHED)
                    INDEX(ORDERS, PK_ORDERS) USE_NL(ORDERS)*/
                STKDISS_DETSONALLOC_RECNO_SEQ.NEXTVAL, V_HDRRECNO,
                ALLOCATE.ALLOCLITITENO, DELDET.DELDLVORDNO,  DELDET.DELRECNO, ORDERS.ACTCSTCODE, DELDET.DELQTYPER,
                DELDET.DELQTY,
                (CASE WHEN NVL(DELTOALL.ACTSPLITQTY,0) = 0  THEN DELTOALL.DALQTY ELSE DELTOALL.ACTSPLITQTY END )DELDET_DALQTY,
                DELTOALL.DALQTY DELQTY_BOXEQUIV,
                DELTOALL.DALWIZUNIQUEID
                FROM ALLOCATE, DELTOALL, DELDET, DELHED, ORDERS
                WHERE ALLOCATE.ALLOCNO = DELTOALL.DALALLOCNO
                AND DELTOALL.DALTYPERECNO =  DELDET.DELRECNO
                AND DELDET.DELDLVORDNO = DELHED.DLVORDNO
                AND DELHED.DLVORDRECNO = ORDERS.ORDRECNO
                AND DELTOALL.DALRECORDTYPE= 1
                AND DELHED.DLVSALOFFNO = ( SELECT SALOFFNO FROM STKDISS_HDR WHERE STKDISSHDR_RECNO = V_HDRRECNO)

                AND NVL(ORDERS.ORDSALTYP, 'N')  <> 'R'   -- 12/12/2014 WE NEED TO IGNORE RTS LINES

                AND (CASE WHEN V_USEDLVDATE = 1 THEN TO_DATE(NVL(DELHED.DLVDELDATE, SYSDATE), 'DD/MM/YY') ELSE TO_DATE(NVL(DELHED.DLVSHPDATE, SYSDATE), 'DD/MM/YY') END) <= TO_DATE(VAR_UPTODATE, 'DD/MM/YY')

                AND NVL(DELTOALL.ALLFLAG,0) = 0  -- THIS IS SET TO 1 ONCE THE DELIVERY HAS BEEN UPDATED IN STOCK DISSECTION
                AND ALLOCATE.ALLOCDPTRECNO = V_DPTRECNO/* Formatted on 21/01/2011 13:00:19 (QP5 v5.115.810.9015) */
                AND NVL(ALLOCATE.ALLOCISPREPPACK,0) = 0
                AND EXISTS ( SELECT 1 FROM STKDISS_DETS WHERE  STKDISSHDR_RECNO = V_HDRRECNO AND LITITENO = ALLOCATE.ALLOCLITITENO)  --31/03/2014  ADDED COS AN EXPECTED PO IS NOT WRITTEN TO STKDISS_DETS BUT THIS WASW PICKING UP SALES AGAINST THEM AND ALLOWING THEM TO BE UPDATED
                );

                COMMIT;
         EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - EXTRACT DLVS');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- 9512 FLAG THE OVERSOLD LINES

        IF VAR_LCONT = 1 THEN
            BEGIN
                UPDATE STKDISS_DETS_ONALLOC
                SET OVERSOLDLINE = 1
		WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND EXISTS ( SELECT 1 FROM LOTITE_LINK WHERE LOTITE_LINK.NEWLITITENO = STKDISS_DETS_ONALLOC.LITITENO AND  LOTITE_LINK.STATUS = 1);
                COMMIT;
         EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;-- ITS NO PROBLEM IF THERE ARE NO RECORDS
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - FLAG OVERSOLDLINE');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- 9512
        -- EXTRACT THE DELIVERY DETAILS FOR  ANY  DELIVERIES  THAT HAVE BEEN ALLOCATED TO OVER-SOLD PO
        -- THESE NEED TO BE REFLECTED AGAINST THE ORIGINAL LOTITES
        -- I DO THIS BY ADDING IN A DUPLICATE RECORD FOR THE ORIGINAL LOTITE - AND SO THESE TRANSACTIONS WILL NOW APPEAR TWICE IN THE SYSTEM
        -- ONCE AGAINST THE OVER-SOLD PO AND ONCE AGAINST THE PO THEY ORIGINALLY CAME FROM
        -- THIS IS ONLY VALID FOR OVER-SOLD LINES THAT WERE CREATED FOR OVER-ALLOCATED LINES **NOT** WHEN THE OVERSOLD AMOUNT WAS NOT AGAINST A VALID STOCK LINE
        IF VAR_LCONT = 1 THEN
            BEGIN
                INSERT INTO STKDISS_DETS_ONALLOC
                (STKDISSDETSONALLOC_RECNO, STKDISSHDR_RECNO, LITITENO, DLVORDNO, DELRECNO, ACTCSTCODE, DELQTYPER, DELQTY, DELDET_DALQTY, DELQTY_BOXEQUIV, DELTOALL_ID  )
                (SELECT   STKDISS_DETSONALLOC_RECNO_SEQ.NEXTVAL, V_HDRRECNO,
                ( SELECT ORGLITITENO FROM LOTITE_LINK WHERE LOTITE_LINK.NEWLITITENO = STKDISS_DETS_ONALLOC.LITITENO  AND  LOTITE_LINK.STATUS = 1) LITITENO ,
                    DLVORDNO, DELRECNO, ACTCSTCODE, DELQTYPER, DELQTY, DELDET_DALQTY, DELQTY_BOXEQUIV, DELTOALL_ID
                    FROM STKDISS_DETS_ONALLOC
                    WHERE STKDISS_DETS_ONALLOC.STKDISSHDR_RECNO = V_HDRRECNO
                    AND OVERSOLDLINE = 1
                    AND EXISTS ( SELECT 1 FROM LOTITE_LINK WHERE LOTITE_LINK.NEWLITITENO = STKDISS_DETS_ONALLOC.LITITENO  AND  LOTITE_LINK.STATUS = 1
                    AND LOTITE_LINK.ORGLITITENO > 0));   -- THIS WILL IGNORE THE OVERSOLDS THAT WERE NOT AGAINST PO'S TO START WITH
                COMMIT;
         EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - INSERT OVERSOLD LINES ');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- EXTRACT THE DELIVERY DETAILS FOR  ANY LINES THAT ARE NOT FULLY ALLOCATED
        -- cos 1 saleman could be against multiple departments this may mean a dlv showing up in multiple departments
        IF VAR_LCONT = 1 THEN
            BEGIN
               INSERT INTO STKDISS_DETS_ONALLOC
                (STKDISSDETSONALLOC_RECNO, STKDISSHDR_RECNO, LITITENO, DLVORDNO, DELRECNO, ACTCSTCODE, DELQTYPER, DELQTY, DELDET_DALQTY, DELQTY_BOXEQUIV, DELTOALL_ID )
                ( SELECT
                /*INDEX(ORDERS, ORDERS_CSTCODE2IDX) USE_NL(ORDERS)
                    INDEX(DELHED, PK_DELHED) USE_NL(DELHED)
                    INDEX(DELDET, PK_DELDET) USE_NL(DELDET)*/
                STKDISS_DETSONALLOC_RECNO_SEQ.NEXTVAL, V_HDRRECNO,
                (DELDET.DELPRCPRDNO)*-1 LITITENO, DELDET.DELDLVORDNO,  DELDET.DELRECNO, ORDERS.ACTCSTCODE, DELDET.DELQTYPER,
                DELDET.DELQTY DELQTY,
                DELDET.DELQTY-               --  THIS IS SUBTRACTED COS A LINE COULD BE PARTLY ALLOCATED AND WE ONLY WISH TO SEE THE UNALLOCATED PART HERE
                NVL((SELECT /* INDEX(DELTOALL, DELTOALL_DALTYPERECNO) USE_NL(DELTOALL)*/
                        SUM(CASE  NVL(DELTOALL.ACTSPLITQTY,0) WHEN 0 THEN NVL(DALQTY,0) ELSE NVL(DELTOALL.ACTSPLITQTY,0) END)
                        FROM DELTOALL
                        WHERE DELTOALL.DALTYPERECNO =  DELDET.DELRECNO
                        AND DELTOALL.DALRECORDTYPE= 1),0)  DELDET_DALQTY,
                0 DELQTY_BOXEQUIV,
                0 DELTOALL_ID
                FROM DELHED, ORDERS, DEPARTMENTSTOSMN, DELDET
                WHERE ORDERS.ORDCSTCODE IS NOT NULL
                AND (DELHED.DLVRELINV IS NULL or DELHED.DLVRELINV = 'Pik')
                AND DELHED.DLVORDRECNO = ORDERS.ORDRECNO
                AND DELHED.DLVSALOFFNO = ( SELECT SALOFFNO FROM STKDISS_HDR WHERE STKDISSHDR_RECNO = V_HDRRECNO)           --9468
                AND ORDERS.ORDSMNNO =  DEPARTMENTSTOSMN.SMNNO
                AND DELHED.DLVORDNO = DELDET.DELDLVORDNO
                AND DEPARTMENTSTOSMN.DPTRECNO =V_DPTRECNO
                -- 14/05/2014  added this as
                AND (CASE WHEN V_USEDLVDATE = 1 THEN TO_DATE(NVL(DELHED.DLVDELDATE, SYSDATE), 'DD/MM/YY') ELSE TO_DATE(NVL(DELHED.DLVSHPDATE, SYSDATE), 'DD/MM/YY') END) <= TO_DATE(VAR_UPTODATE, 'DD/MM/YY')
                --AND DELDET.DELQTY IS NOT NULL         --LOG 8025

                AND NVL(ORDSALTYP, 'N')  <> 'R'   -- 08/05/2014 WE NEED TO IGNORE RTS LINES

                AND NVL(DELDET.DELQTY,0) <> NVL((SELECT /* INDEX(DELTOALL, DELTOALL_DALTYPERECNO) USE_NL(DELTOALL)*/
                                SUM(CASE  NVL(DELTOALL.ACTSPLITQTY,0) WHEN 0 THEN NVL(DALQTY,0) ELSE NVL(DELTOALL.ACTSPLITQTY,0) END)
                                FROM DELTOALL, allocate
                                WHERE DELTOALL.DALTYPERECNO =  DELDET.DELRECNO
                    AND DELTOALL.DALALLOCNO = allocate.allocno        --LOG 8025
                                AND DELTOALL.DALRECORDTYPE= 1),0));

                COMMIT;

                -- the unallocated lines will have no box equivalent so i need to calc that
                UPDATE STKDISS_DETS_ONALLOC
                SET DELQTY_BOXEQUIV = DELDET_DALQTY
                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND LITITENO < 0
                AND DELQTYPER = 1;
                COMMIT;


                UPDATE STKDISS_DETS_ONALLOC ONALLOC
                SET DELQTY_BOXEQUIV = CEIL(DELDET_DALQTY/(SELECT (CASE ONALLOC.DELQTYPER WHEN   2 THEN PRCWEIGHT
                                                                      WHEN   3 THEN PrcBoxQty
                                                                      ELSE   InnerQty
                                                                      END)
                                                            FROM PRDREC WHERE PRCPRDNO = ((ONALLOC.LITITENO)*-1))
                                           )
                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND LITITENO < 0
                AND DELQTYPER <> 1
                AND DELDET_DALQTY > 0;
                COMMIT;

                UPDATE STKDISS_DETS_ONALLOC ONALLOC
                SET QTY_APPTOBOX = DELDET_DALQTY
                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND DELQTYPER = 1
                AND DELDET_DALQTY > 0;
                COMMIT;


                UPDATE STKDISS_DETS_ONALLOC ONALLOC
                SET QTY_APPTOBOX = ROUND(DELDET_DALQTY/(SELECT (CASE ONALLOC.DELQTYPER WHEN   2 THEN PRCWEIGHT
                                                                      WHEN   3 THEN PrcBoxQty
                                                                      ELSE   InnerQty
                                                                      END)
                                                            FROM DELDET, PRDREC
                                                            WHERE ONALLOC.DELRECNO = DELDET.DELRECNO
                                                            AND PRDREC.PRCPRDNO = DELDET.DELPRCPRDNO), 2)

                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND DELQTYPER <> 1
                AND DELDET_DALQTY > 0;
                COMMIT;


         EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - EXTRACT DLVS');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- FOR LINES THAT ARE NOT FULLY ALLOCATED ADD IN A DETS RECORD
        -- i'M PUTTING THE lititeno in as the negative of the product number
        IF VAR_LCONT = 1 THEN
            BEGIN
               INSERT INTO STKDISS_DETS (   STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, OPENINGQTY, QTYALRDYSOLD, VALUEALRDYSOLD, DISC_ONALRDYSOLD, REB_ONALRDYSOLD, OTHCHG_ONALRDYSOLD,
                                            QTYSOLDONALLOC, QTYSOLDONALLOC_APPTOBOX, VALUEONALLOC, DISC_ONALLOC,    REB_ONALLOC, OTHCHG_ONALLOC, QTYBALANCE, AVEPRICE, AVEPRICE_NETT, HASCHG,
                                            SALOFFNO )
               (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, STKDISSHDR_RECNO, LITITENO, 0, 0, 0,0,0,0, 0,0,0,0,0,0,0,0, 0, 0,
                (SELECT SALOFFNO from STKDISS_HDR    WHERE STKDISSHDR_RECNO = V_HDRRECNO) -- 24/03/2014 ADDED THIS OTHERWISE IT IS NOT TREATING THEM AS FOR THIS SALES OFFICE
                FROM
                    (SELECT DISTINCT LITITENO, STKDISSHDR_RECNO from STKDISS_DETS_ONALLOC    WHERE LITITENO < 0    AND STKDISSHDR_RECNO = V_HDRRECNO));
                COMMIT;
         EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - EXTRACT DLVS');
                    VAR_LCONT := 0;
            END;
        END IF;



        -- UPDATE THE PRICE AND VALUE DETAILS
        -- I AM ASSUMING THAT THERE IS ONLY ONE DELPRICE - IF NOT I AM IGNORING THAT LINE
        IF VAR_LCONT = 1 THEN
            BEGIN
                UPDATE STKDISS_DETS_ONALLOC
                SET  (DELPRICE, DELNETTVALUE, DELFREEOFCHG) = (SELECT DELPRICE.DELPRICE, DELPRICE.DELNETTVALUE, DELPRICE.DELFREEOFCHG
                                                                FROM DELPRICE
                                                                WHERE DELPRICE.DPRDELRECNO = STKDISS_DETS_ONALLOC.DELRECNO)
                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND EXISTS ( select 1 from dual where (SELECT COUNT(*) FROM DELPRICE WHERE DELPRICE.DPRDELRECNO = STKDISS_DETS_ONALLOC.DELRECNO) = 1);
                COMMIT;

                -- IF WE HAVE LINES THAT ARE ALLOCATED ACROSS DIFF DELTOALLS THEN WE NEED TO APPORTION THEM
                UPDATE STKDISS_DETS_ONALLOC
                SET  (DELNETTVALUE ) = (DELNETTVALUE/DELQTY) * DELDET_DALQTY
                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND NVL(DELFREEOFCHG,0) = 0
                AND NVL(DELNETTVALUE,0) > 0
                AND NVL(DELQTY,0) <>  NVL(DELDET_DALQTY,0)
                AND NVL(DELQTY,0) > 0;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_LCONT := 0;  -- IF THERE ARE NO RECORDS FOR THIS DEPARTMENT THEN THERE IS NO POINT IN CONTINUING
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - UPDATE DELPRICE');
                    VAR_LCONT := 0;
            END;
        END IF;


        -- GET THE REBATE AND DISCOUNT VALUES FOR THE
        IF VAR_LCONT = 1 THEN
            BEGIN
                UPDATE STKDISS_DETS_ONALLOC
                SET  DISC_ONALLOC =  (SELECT SUM(NVL(ICHAPPAMT,0)) FROM ITECHG, DELPRICE WHERE STKDISS_DETS_ONALLOC.DELRECNO =DELPRICE.DPRDELRECNO  AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO AND  ITECHG.CTYNO = 97),
                REB_ONALLOC       = (SELECT SUM(NVL(ICHAPPAMT,0)) FROM ITECHG, DELPRICE WHERE STKDISS_DETS_ONALLOC.DELRECNO =DELPRICE.DPRDELRECNO  AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO AND  ITECHG.CTYNO = 98),

                /*OTHCHG_ONALLOC    = (SELECT SUM(NVL(ICHAPPAMT,0))
                                       FROM ITECHG, DELPRICE, Expcha
                                     WHERE STKDISS_DETS_ONALLOC.DELRECNO =DELPRICE.DPRDELRECNO
                                     AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO
                                     AND ITECHG.CTYNO NOT IN  (97, 98)
                                     AND Itechg.ExcRecNo = Expcha.ExcCharec
                                     AND NVL(Expcha.EXCRECOVFROMPL,0) = 0)*/
    -- 27/08/2013  the charges should all have the itesto number in itechg so there is no need to apportion them across the DELTOISTS
                OTHCHG_ONALLOC    = (SELECT SUM(NVL(ICHAPPAMT,0))
                                       FROM ITECHG, DELPRICE, EXPCHA, ITESTO
                                     WHERE STKDISS_DETS_ONALLOC.DELRECNO =DELPRICE.DPRDELRECNO
                                     AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO
                                     AND ITECHG.CTYNO NOT IN  (97, 98)
                                     AND STKDISS_DETS_ONALLOC.LITITENO = ITESTO.ISTLITNO
                                     and ITESTO.ISTRECNO = ITECHG.ICHISTRECNO
                                     AND Itechg.ExcRecNo = Expcha.ExcCharec
                                     AND NVL(Expcha.EXCRECOVFROMPL,0) = 0)
                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND DELQTY > 0;
                COMMIT;
                --  APPORTION THE DISC AND REBATES ACROSS THIS DELTOALL LINE
                UPDATE STKDISS_DETS_ONALLOC
                SET  DISC_ONALLOC =  (DISC_ONALLOC/DELQTY) * DELDET_DALQTY,
                REB_ONALLOC       =  (REB_ONALLOC/DELQTY) * DELDET_DALQTY
                -- 27/08/2013  the charges should all have the itesto number in itechg so there is no need to apportion them across the DELTOISTS
                --,            OTHCHG_ONALLOC    =  (OTHCHG_ONALLOC/DELQTY) * DELDET_DALQTY
                WHERE STKDISSHDR_RECNO = V_HDRRECNO
                AND DELQTY > 0
                AND NVL(DELQTY,0) <>  NVL(DELDET_DALQTY,0);
                COMMIT;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_LCONT := 0;  -- IF THERE ARE NO RECORDS FOR THIS DEPARTMENT THEN THERE IS NO POINT IN CONTINUING
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - GET REBATE + DISC');
                    VAR_LCONT := 0;
            END;
        END IF;


        IF VAR_LCONT = 1 THEN
            BEGIN
                UPDATE STKDISS_DETS SET
                (QTYSOLDONALLOC, QTYSOLDONALLOC_APPTOBOX,  VALUEONALLOC, DISC_ONALLOC, REB_ONALLOC, OTHCHG_ONALLOC) =
                (SELECT SUM(NVL(DELQTY_BOXEQUIV,0)), SUM(NVL(QTY_APPTOBOX,0)), SUM(NVL(DELNETTVALUE,0)), SUM(NVL(DISC_ONALLOC,0)), SUM(NVL(REB_ONALLOC,0)), SUM(NVL(OTHCHG_ONALLOC,0))
                 FROM STKDISS_DETS_ONALLOC
                 WHERE STKDISSHDR_RECNO = V_HDRRECNO
                 AND STKDISS_DETS_ONALLOC.LITITENO = STKDISS_DETS.LITITENO)
                WHERE STKDISSHDR_RECNO = V_HDRRECNO;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_LCONT := 0;  -- IF THERE ARE NO RECORDS FOR THIS DEPARTMENT THEN THERE IS NO POINT IN CONTINUING
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - GET REBATE + DISC');
                    VAR_LCONT := 0;
            END;
        END IF;

        /*
        30/04/2014  BMK removed this code as they now expect to see these lots in stock and sales dissection
        IF VAR_LCONT = 1 THEN
            IF V_UPTODATE IS NOT NULL THEN
            BEGIN
            -- IF WE ARE USING THE EXTRACT UP TO DATE THEN WE DO NOT WANT TO SEE ANY LOTS THAT DO NOT HAVE SALES AGAINST THEM
                BEGIN
                    DELETE FROM STKDISS_DETS
                    WHERE STKDISSHDR_RECNO = V_HDRRECNO
                    AND NOT EXISTS ( SELECT 1 FROM STKDISS_DETS_ONALLOC
                                     WHERE STKDISSHDR_RECNO = V_HDRRECNO
                                    AND STKDISS_DETS_ONALLOC.LITITENO = STKDISS_DETS.LITITENO)  ;
                    COMMIT;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                        VAR_LCONT := 0;  -- IF THERE ARE NO RECORDS FOR THIS DEPARTMENT THEN THERE IS NO POINT IN CONTINUING
                    WHEN OTHERS THEN
                        NULL;
                        RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTONALLOC_DETS - DELETE FROM STKDISS_DETS ');
                        VAR_LCONT := 0;
                END;
            END;
            END IF;
        END IF;  */

        END EXTRACTONALLOC_DETS;


    ---*******************************************************************************************************************************************
    -- -- EXTRACTS THE DETAILS OF RETURNS AGAINST THE LOTITES THAT ARE ON THIS HEADER
    ---*******************************************************************************************************************************************
        PROCEDURE EXTRACTRETURN_DETS  (V_HDRRECNO IN NUMBER) IS

           VAR_LCONT                NUMBER(1) := 1;

        BEGIN

        -- DELETE ANY EXISTING RECORDS FOR THIS HEADER - THERE SHOUL DNOT REALLY BE ANY BUT JUST IN CASE
        IF VAR_LCONT = 1 THEN
            BEGIN
                DELETE FROM STKDISS_RETURNS WHERE STKDISSHDR_RECNO = V_HDRRECNO;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTRETURN_DETS - DELETE');
                    VAR_LCONT := 0;
            END;
        END IF;


        -- EXTRACT THE DELIVERY DETAILS FOR  ANY  DELIVERIES  DIRECTLY AGAINST THE ALLOCATE
        IF VAR_LCONT = 1 THEN
            BEGIN
                INSERT INTO STKDISS_RETURNS
                (RETURNS_RECNO, STKDISSHDR_RECNO, LITITENO, RETURNPRICE, RETURNQTY)
                (SELECT STKDISS_RETURNS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, LITITENO, LOTRETURNPRICE, LOTRETURNQTY
                FROM
                (select LOTRETURNPRICES.LITITENO, LOTRETURNPRICES.LOTRETURNPRICE, SUM(LOTRETURNPRICES.LOTRETURNQTY) LOTRETURNQTY
                from STKDISS_DETS, LOTRETURNPRICES
                    where STKDISS_DETS.LITITENO =  LOTRETURNPRICES.LITITENO
                    and STKDISSHDR_RECNO = V_HDRRECNO
                    GROUP BY LOTRETURNPRICES.LITITENO, LOTRETURNPRICES.LOTRETURNPRICE));
                COMMIT;
         EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;-- ITS NO PROBLEM IF THERE IS NO RECORDS
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACTRETURN_DETS - EXTRACT RETURNS');
                    VAR_LCONT := 0;
            END;
        END IF;


    END EXTRACTRETURN_DETS;


    ---*******************************************************************************************************************************************
    -- EXTRACTS THE ALREADY SOLD FIGURES AND THE VALUE OF THESE
    ---*******************************************************************************************************************************************
        PROCEDURE FINALCALCS (V_HDRRECNO IN NUMBER) IS

                VAR_LCONT                NUMBER(1) := 1;
            V_NUMOFRECS              NUMBER(10);
        BEGIN



        -- EXTRACT THE OPENING QTY FOR THESE RECORDS
        IF VAR_LCONT = 1 THEN
            BEGIN
                UPDATE STKDISS_DETS
                SET QTYBALANCE  = NVL(OPENINGQTY,0) - NVL(QTYALRDYSOLD,0)- NVL(QTYSOLDONALLOC,0),
                --AVEPRICE = ROUND((CASE WHEN NVL(QTYALRDYSOLD,0) + NVL(QTYSOLDONALLOC,0) = 0 THEN 0 ELSE (NVL(VALUEALRDYSOLD,0) + NVL(VALUEONALLOC,0) )/(NVL(QTYALRDYSOLD,0) + NVL(QTYSOLDONALLOC,0) ) END),2),
                --AVEPRICE_NETT = ROUND((CASE WHEN NVL(QTYALRDYSOLD,0) + NVL(QTYSOLDONALLOC,0) = 0 THEN 0 ELSE (NVL(VALUEALRDYSOLD,0)  + NVL(VALUEONALLOC,0) - NVL(DISC_ONALRDYSOLD,0) - NVL(REB_ONALRDYSOLD,0) -  NVL(DISC_ONALLOC,0) - NVL(REB_ONALLOC,0))/(NVL(QTYALRDYSOLD,0) + NVL(QTYSOLDONALLOC,0) ) END),2)
                AVEPRICE = ROUND((CASE WHEN NVL(QTYALRDYSOLD_APPTOBOX,0) + NVL(QTYSOLDONALLOC_APPTOBOX,0) = 0 THEN 0 ELSE (NVL(VALUEALRDYSOLD,0) + NVL(VALUEONALLOC,0) )/(NVL(QTYALRDYSOLD_APPTOBOX,0) + NVL(QTYSOLDONALLOC_APPTOBOX,0) ) END),2),
                AVEPRICE_NETT = ROUND((CASE WHEN NVL(QTYALRDYSOLD_APPTOBOX,0) + NVL(QTYSOLDONALLOC_APPTOBOX,0) = 0 THEN 0 ELSE (NVL(VALUEALRDYSOLD,0)  + NVL(VALUEONALLOC,0) - NVL(DISC_ONALRDYSOLD,0) - NVL(REB_ONALRDYSOLD,0) - NVL(OTHCHG_ONALRDYSOLD,0) -NVL(DISC_ONALLOC,0) - NVL(REB_ONALLOC,0) - NVL(OTHCHG_ONALLOC,0) )/(NVL(QTYALRDYSOLD_APPTOBOX,0) + NVL(QTYSOLDONALLOC_APPTOBOX,0) ) END),2)
                WHERE STKDISSHDR_RECNO = V_HDRRECNO;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_LCONT := 0;  -- IF THERE ARE NO RECORDS FOR THIS DEPARTMENT THEN THERE IS NO POINT IN CONTINUING
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_STK_FOR_DPT - UPDATE OPENING');
                    VAR_LCONT := 0;
            END;
        END IF;


        END FINALCALCS;

            -- determines whether an allocate or deltoall is against an overallocated stock line - this does not include expected IN THE CALCULATION
        FUNCTION ISALLOCATE_OVERALLOC  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER )
        RETURN  NUMBER IS RET_ISOVERALLOC NUMBER(1):= 0;
        BEGIN

            RET_ISOVERALLOC :=   CHKISALLOCATE_OVERALLOC ( V_ALLOCNO, V_DELTOALL_ID, FALSE, NULL );
            RETURN RET_ISOVERALLOC;

        END ISALLOCATE_OVERALLOC;

            -- determines whether an allocate or deltoall is against an overallocated stock line - this does not include expected IN THE CALCULATION
        FUNCTION ISALLOCATE_OVERALLOC  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER, V_UPTODATE IN DATE )
        RETURN  NUMBER IS RET_ISOVERALLOC NUMBER(1):= 0;
        BEGIN

            RET_ISOVERALLOC :=   CHKISALLOCATE_OVERALLOC ( V_ALLOCNO, V_DELTOALL_ID, FALSE, V_UPTODATE);
            RETURN RET_ISOVERALLOC;

        END ISALLOCATE_OVERALLOC;

        -- determines whether an allocate or deltoall is against an overallocated stock line - this does include expected IN THE CALCULATION
        FUNCTION ISALLOCATE_OVERALLOC_INCEXP  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER)
        RETURN  NUMBER IS RET_ISOVERALLOC NUMBER(1):= 0;
        BEGIN

            RET_ISOVERALLOC :=   CHKISALLOCATE_OVERALLOC ( V_ALLOCNO, V_DELTOALL_ID, TRUE, NULL );
            RETURN RET_ISOVERALLOC;

        END ISALLOCATE_OVERALLOC_INCEXP;

        -- determines whether an allocate or deltoall is against an overallocated stock line - this does include expected IN THE CALCULATION
        FUNCTION ISALLOCATE_OVERALLOC_INCEXP  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER, V_UPTODATE IN DATE)
        RETURN  NUMBER IS RET_ISOVERALLOC NUMBER(1):= 0;
        BEGIN

            RET_ISOVERALLOC :=   CHKISALLOCATE_OVERALLOC ( V_ALLOCNO, V_DELTOALL_ID, TRUE, V_UPTODATE );
            RETURN RET_ISOVERALLOC;

        END ISALLOCATE_OVERALLOC_INCEXP;

    -- WE COULD HAVE A SITUATION WHERE THE ORIGINAL BOX LINE IS SHOWING AN OVER ALLOCATE IE ALLOCQTY < ALLOCALLOC
    -- THIS HAPPENS WHEN A USER ALLOCATES AGAINST A SPLIT AND THERE IS ENOUGHT SPLIT ALREADY MADE TO COVER THAT SAY YOU ALLOC 8 AND THERE IS 8 AVAIL
    -- THEN ANOTHER LINE IS PUT ON FOR A SPLIT OF 1 WHICH NEEDS 1 BOX TO MAKE THE SPLIT
    -- THEN THE ORIGINAL LINE IS REDUCED - WE WILL END UP WITH THE 8 AVAIL BUT THE DELTOALL FOR THE 2ND LINE STILL HAVING A DALQTY =1
    -- THIS METHOD JUST SUMS UP THE AMOUNTS AND CHECKS
        FUNCTION CHKISALLOCATE_OVERALLOC  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER, V_INC_EXPECTED in BOOLEAN, V_UPTODATE IN DATE)
        RETURN  NUMBER IS RET_ISOVERALLOC NUMBER(1):= 0;

        VAR_LCONT                   NUMBER(1) := 1;
        VAR_USEALLOCNO              NUMBER(10) ;

        VAR_ALLOCQTY_SPLIT          NUMBER(10) ;

        VAR_PROD_WEIGHT             FLOAT ;
        VAR_PROD_EACHQTY            NUMBER(10) ;
        VAR_PROD_INNERQTY           NUMBER(10) ;

        VAR_EXIST_BOX_QTY           NUMBER(10) ;
        VAR_EXP_BOX_QTY             NUMBER(10) ;

        VAR_ALRDY_SPLITQTY_WGT      NUMBER(10) ;
        VAR_ALRDY_SPLITQTY_EACH     NUMBER(10) ;
        VAR_ALRDY_SPLITQTY_INNER    NUMBER(10) ;

        VAR_BOXREQFORSPLIT_WGT      NUMBER(10) ;
        VAR_BOXREQFORSPLIT_EACH     NUMBER(10) ;
        VAR_BOXREQFORSPLIT_INNER    NUMBER(10) ;


        VAR_REQ_SPLITQTY_BOX        NUMBER(10) ;
        VAR_REQ_SPLITQTY_WGT        NUMBER(10) ;
        VAR_REQ_SPLITQTY_EACH       NUMBER(10) ;
        VAR_REQ_SPLITQTY_INNER      NUMBER(10) ;

        VAR_ALLOC_AND_EXP           NUMBER(10) ;
        VAR_ACTSPLITQTY_THISALLOC   NUMBER(10) ;

        BEGIN

        --VARIABLES FOR OVER SOLD DETAILS
          GLBISOVERALLOC := 0;
          GLBOVERSOLD_ONLYBOXQTY        :=0;   --- THIS IS THE BOX OVERSOLD QTY IGNORING ALL SPLITS FOR AN ALLOCATE LINE
          GLBOVERSOLD_BOXQTY            := 0; --- THIS IS THE BOX OVERSOLD QTY INCLUDING ALL BOX EQUIVALENT OF THE SPLITS FOR AN ALLOCATE LINE
          GLBOVERSOLD_WGTQTY            := 0; --- THIS IS THE WGT OVERSOLD QTY FOR AN ALLOCATE LINE
          GLBOVERSOLD_EACHQTY           := 0; --- THIS IS THE EACH OVERSOLD QTY FOR AN ALLOCATE LINE
          GLBOVERSOLD_INNERQTY          := 0; --- THIS IS THE INNER OVERSOLD QTY FOR AN ALLOCATE LINE



            IF VAR_LCONT = 1 THEN
                IF NVL(V_ALLOCNO,0) = 0 AND NVL(V_DELTOALL_ID,0) = 0 THEN
                BEGIN
                    VAR_LCONT := 0;
                END;
                END IF;
            END IF;



            IF VAR_LCONT = 1 THEN
            BEGIN
                IF NVL(V_ALLOCNO,0) = 0 THEN
                    BEGIN
                        SELECT DELTOALL.DALALLOCNO INTO VAR_USEALLOCNO
                        FROM DELTOALL
                        WHERE DALWIZUNIQUEID =  V_DELTOALL_ID
                        AND NVL(DELTOALL.DALALLOCNO,0) > 0;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;
                            VAR_LCONT := 0;  -- IF THERE ARE NO DELTOALL RECORD SO NO POINT IN CONTINUING
                    WHEN OTHERS THEN
                        NULL;
                        RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - ISALLOCATE_OVERALLOC - GET ALLOCNO FROM DELTOALL '||TO_CHAR(V_DELTOALL_ID));
                        VAR_LCONT := 0;
                    END;
                 ELSE
                    BEGIN
                    VAR_USEALLOCNO :=V_ALLOCNO;
                    END;
                 END IF;
            END;
            END IF;

        -- AT THIS STAGE WE SHOULD HAVE A POSITIVE ALLOCATE NO  - NOW GET ITS DETAILS
            IF VAR_LCONT = 1 THEN
            BEGIN
                SELECT NVL(ALLOCATE.ALLOCQTY,0), NVL(ALLOCATE.ALLOCEXP,0),
                NVL(ALLOCATE.ALLOCQTY_SPLIT,0)+
                NVL((SELECT SUM(NVL(DALQTY,0)) FROM DELTOALL WHERE  DELTOALL.DALALLOCNO = ALLOCATE.ALLOCNO AND NVL(DELTOALL.QTYPER,1) =1),0) + -- paul homer added this 01/08/2012 but i think it is not really required just covering up an issue elsewhere
                NVL((SELECT SUM(NVL(ACTSPLITQTY,0)) FROM DELTOALL WHERE  DELTOALL.DALALLOCNO = ALLOCATE.ALLOCNO AND NVL(DELTOALL.QTYPER,1) >1),0) ACTSPLITQTY,
                FLOOR(NVL(PRCWEIGHT,0)), NVL(PRCBOXQTY,0), NVL(INNERQTY,0)
                INTO VAR_EXIST_BOX_QTY, VAR_EXP_BOX_QTY, VAR_ALLOCQTY_SPLIT, VAR_PROD_WEIGHT, VAR_PROD_EACHQTY, VAR_PROD_INNERQTY
                FROM ALLOCATE, PRDREC
                WHERE ALLOCATE.ALLOCPRDNO = PRDREC.PRCPRDNO
                AND ALLOCATE.ALLOCNO =  VAR_USEALLOCNO ;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_LCONT := 0;  -- THE ALLOCATE OR PRDREC MUST NOT EXIST
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - ISALLOCATE_OVERALLOC - HAS ALLOCATE ANY SPLITS ' ||TO_CHAR(VAR_USEALLOCNO));
                    VAR_LCONT := 0;
            END;
            END IF;

            -- SEE IF THIS ALLOCATE HAS HAD ANY ALLOCATE QTY ALREADY CREATED - IF NOT THEN WE CAN NOT HAVE AN OVER ALLOCATE
            IF VAR_LCONT = 1 THEN
                IF VAR_ALLOCQTY_SPLIT = 0 THEN
                BEGIN
                    --  WE HAVE NO SPLIT QTY
                    VAR_LCONT := 0;
                END;
                END IF;
            END IF;

            -- OUR ALLOCATE LINE HAS SPLITS - NOW SEE IF WE HAVE HAD ANY ALREADY CREATED
            IF VAR_LCONT = 1 THEN
            BEGIN
                SELECT
                    SUM(NVL((CASE WHEN  SPLITALLOCATE.ALLOCBY = 2 THEN NVL(SPLITALLOCATE.ALLOCQTY,0) - NVL(SPLITALLOCATE.ALLOCALLOC,0) ELSE 0 END ),0))  ALRDY_SPLITQTY_WGT,
                    SUM(NVL((CASE WHEN  SPLITALLOCATE.ALLOCBY = 3 THEN NVL(SPLITALLOCATE.ALLOCQTY,0) - NVL(SPLITALLOCATE.ALLOCALLOC,0) ELSE 0 END ),0))  ALRDY_SPLITQTY_EACH,
                    SUM(NVL((CASE WHEN  SPLITALLOCATE.ALLOCBY = 4 THEN NVL(SPLITALLOCATE.ALLOCQTY,0) - NVL(SPLITALLOCATE.ALLOCALLOC,0) ELSE 0 END ),0))  ALRDY_SPLITQTY_INNER
                INTO VAR_ALRDY_SPLITQTY_WGT, VAR_ALRDY_SPLITQTY_EACH, VAR_ALRDY_SPLITQTY_INNER
                    FROM ALLOCATE ORGALLOC , ALLOCATE SPLITALLOCATE
                    WHERE ORGALLOC.ALLOCNO = VAR_USEALLOCNO
                    AND SPLITALLOCATE.ALLOCPRDNO                 = ORGALLOC.ALLOCPRDNO
                    AND NVL(SPLITALLOCATE.ALLOCPONO, -1)           = NVL(ORGALLOC.ALLOCPONO, -1)
                    AND NVL(SPLITALLOCATE.ALLOCLITID, '*')         = NVL(ORGALLOC.ALLOCLITID, '*')
                    AND SPLITALLOCATE.ALLOCSTCLOC                  = ORGALLOC.ALLOCSTCLOC
                    AND NVL(SPLITALLOCATE.ALLOCPACKPAL, -1)        = NVL(ORGALLOC.ALLOCPACKPAL, -1)
                    AND NVL(SPLITALLOCATE.ALLOCBY, 0) > 1;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- NO SPLITS ALREADY CREATED
                    NULL;
                    VAR_ALRDY_SPLITQTY_WGT  := 0;
                    VAR_ALRDY_SPLITQTY_EACH := 0;
                    VAR_ALRDY_SPLITQTY_INNER := 0;

                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - ISALLOCATE_OVERALLOC - GET ALREADY CREATED SPLITS ' ||TO_CHAR(VAR_USEALLOCNO));
                    VAR_LCONT := 0;
            END;
            END IF;


        -- OUR ALLOCATE LINE HAS SPLITS - NOW GET THE REQUIRED SPLIT QTYIES
            IF VAR_LCONT = 1 THEN
            BEGIN
                IF  V_UPTODATE IS NULL THEN
                BEGIN
                    SELECT
                        (SUM(NVL((CASE WHEN NVL(DELTOALL_SPLIT.QTYPER,1) = 1 THEN NVL(DELTOALL_SPLIT.DALQTY, 0) ELSE 0 END),0)))    REQ_SPLITQTY_BOX,
                        (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 2 THEN NVL(DELTOALL_SPLIT.ACTSPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_WGT,
                        (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 3 THEN NVL(DELTOALL_SPLIT.ACTSPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_EACH,
                        (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 4 THEN NVL(DELTOALL_SPLIT.ACTSPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_INNER
                    INTO VAR_REQ_SPLITQTY_BOX,  VAR_REQ_SPLITQTY_WGT, VAR_REQ_SPLITQTY_EACH, VAR_REQ_SPLITQTY_INNER
                    FROM DELTOALL DELTOALL_SPLIT
                    WHERE DELTOALL_SPLIT.DALALLOCNO = VAR_USEALLOCNO;
                END;
                ELSE
                BEGIN
                 -- TPIE ONLY WANT THE OVERALLOCATE CHECK IN STOCK DISSECTION TO INCLUDE SALES UP TO A DATE
                  /*  SELECT
                        (SUM(NVL((CASE WHEN NVL(DELTOALL_SPLIT.QTYPER,1) = 1 THEN NVL(DELTOALL_SPLIT.ALLOCATED_QTY, 0) ELSE 0 END),0)))    REQ_SPLITQTY_BOX,
                        (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 2 THEN NVL(DELTOALL_SPLIT.SPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_WGT,
                        (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 3 THEN NVL(DELTOALL_SPLIT.SPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_EACH,
                        (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 4 THEN NVL(DELTOALL_SPLIT.SPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_INNER
                    INTO VAR_REQ_SPLITQTY_BOX,  VAR_REQ_SPLITQTY_WGT, VAR_REQ_SPLITQTY_EACH, VAR_REQ_SPLITQTY_INNER
                    FROM FT_V_DELTOALL DELTOALL_SPLIT
                    WHERE DELTOALL_SPLIT.ALLOCNO = VAR_USEALLOCNO
                    AND   (
                            (DELRECNO IS NULL)
                            OR
                            (DELRECNO IS NOT NULL AND  TO_DATE(NVL(SHIP_DATE, SYSDATE), 'DD/MM/YY')  <= TO_DATE(V_UPTODATE, 'DD/MM/YY'))
                            );  */

                    SELECT
                      (SUM(NVL((CASE WHEN NVL(DELTOALL_SPLIT.QTYPER,1) = 1 THEN NVL(DELTOALL_SPLIT.DALQTY, 0) ELSE 0 END),0)))    REQ_SPLITQTY_BOX,
                      (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 2 THEN NVL(DELTOALL_SPLIT.ACTSPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_WGT,
                      (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 3 THEN NVL(DELTOALL_SPLIT.ACTSPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_EACH,
                      (SUM(NVL((CASE WHEN DELTOALL_SPLIT.QTYPER = 4 THEN NVL(DELTOALL_SPLIT.ACTSPLITQTY, 0) ELSE 0 END),0)))      REQ_SPLITQTY_INNER
                    INTO VAR_REQ_SPLITQTY_BOX,  VAR_REQ_SPLITQTY_WGT, VAR_REQ_SPLITQTY_EACH, VAR_REQ_SPLITQTY_INNER
                    FROM DELTOALL DELTOALL_SPLIT
                    WHERE DELTOALL_SPLIT.DALALLOCNO = VAR_USEALLOCNO
                    AND ( DELTOALL_SPLIT.DALRECORDTYPE <> 1
                        OR (DELTOALL_SPLIT.DALRECORDTYPE = 1
                            AND EXISTS (SELECT 1 FROM DELDET, DELHED
                                      WHERE DELDET.DELRECNO = DELTOALL_SPLIT.DALTYPERECNO
                                      AND DELDET.DELDLVORDNO =DELHED.DLVORDNO
                                      AND TO_DATE(NVL(DLVSHPDATE, SYSDATE), 'DD/MM/YY')  <= TO_DATE(V_UPTODATE, 'DD/MM/YY'))));
                END;
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    -- IF THERE IS NO DATA FOUND HERE THEN THERE IS NO DELTOALLS AND THEREFORE CAN BE NO OVER ALLOCATIONS
                    VAR_LCONT := 0;

                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - ISALLOCATE_OVERALLOC -  REQUIRED SPLIT QTYIES  '  ||TO_CHAR(VAR_USEALLOCNO));
                    VAR_LCONT := 0;
            END;
            END IF;



    -- NOW
            IF VAR_LCONT = 1 THEN
            BEGIN
                IF  V_INC_EXPECTED THEN
                BEGIN
                    VAR_EXIST_BOX_QTY := VAR_EXIST_BOX_QTY + VAR_EXP_BOX_QTY;
                END;
                END IF;

                -- BOXS
                IF VAR_REQ_SPLITQTY_BOX > 0 THEN
                BEGIN
                -- SUBTRACT THE DELTOALL BOX QTY FROM THE PHYSICAL STOCK
                    VAR_EXIST_BOX_QTY := VAR_EXIST_BOX_QTY - VAR_REQ_SPLITQTY_BOX;
                    IF VAR_EXIST_BOX_QTY < 0 THEN
                        GLBOVERSOLD_ONLYBOXQTY := ABS(VAR_EXIST_BOX_QTY);
                    END IF;
                END;
                END IF;




                --WEIGHT
                -- DO WE HAVE ANY DELTOALLS FOR SPLIT WGT
                IF VAR_REQ_SPLITQTY_WGT > 0  THEN
                BEGIN
                    -- SUBTRACT ANY ALREADY SPLIT WGT FROM OTHER ALLOCATES TO GET THE WGT FIGURE WE REQUIRE
                    VAR_REQ_SPLITQTY_WGT := VAR_REQ_SPLITQTY_WGT - NVL(VAR_ALRDY_SPLITQTY_WGT,0);

                    -- DO WE REQUIRE SOME SPLIT WEIGHT
                    IF VAR_REQ_SPLITQTY_WGT > 0 AND VAR_PROD_WEIGHT > 0 THEN
                    BEGIN
                        -- CALC THE BOX EQUIVALENT OF THE WEIGHT REQUIRED
                        VAR_BOXREQFORSPLIT_WGT := CEIL(VAR_REQ_SPLITQTY_WGT/FLOOR(VAR_PROD_WEIGHT));

                        -- IF WE REQUIRE MORE BOXS TO FULFIL THE WEIGHT ALLOCATED THEN WE HAVE AN OVERSELL
                        IF VAR_BOXREQFORSPLIT_WGT > VAR_EXIST_BOX_QTY THEN
                        BEGIN
                            GLBOVERSOLD_WGTQTY := VAR_REQ_SPLITQTY_WGT ;

                            IF VAR_EXIST_BOX_QTY > 0 THEN
                                -- IF WE HAVE ANY BOXES LEFT THEN WE CAN USE THEN TO FULFIL SOME OF THE WEIGHT
                                GLBOVERSOLD_WGTQTY := GLBOVERSOLD_WGTQTY - (VAR_EXIST_BOX_QTY * FLOOR(VAR_PROD_WEIGHT));
                            END IF;
                        END;
                        END IF;

                        VAR_EXIST_BOX_QTY := VAR_EXIST_BOX_QTY - VAR_BOXREQFORSPLIT_WGT;
                    END;
                    END IF;
                END;
                END IF;



               -- EACH
                -- DO WE HAVE ANY DELTOALLS FOR SPLIT EACH
                IF VAR_REQ_SPLITQTY_EACH > 0  THEN
                BEGIN
                    -- SUBTRACT ANY ALREADY SPLIT EACH FROM OTHER ALLOCATES TO GET THE EACH FIGURE WE REQUIRE
                    VAR_REQ_SPLITQTY_EACH := VAR_REQ_SPLITQTY_EACH - NVL(VAR_ALRDY_SPLITQTY_EACH,0);

                    -- DO WE STILL REQUIRE SOME MORE SPLIT EACH
                    IF VAR_REQ_SPLITQTY_EACH > 0 AND VAR_PROD_EACHQTY > 0 THEN
                    BEGIN
                        VAR_BOXREQFORSPLIT_EACH  := CEIL(VAR_REQ_SPLITQTY_EACH/VAR_PROD_EACHQTY);

                        -- IF WE REQUIRE MORE BOXS TO FULFIL THE EACH ALLOCATED THEN WE HAVE AN OVERSELL
                        IF VAR_BOXREQFORSPLIT_EACH > VAR_EXIST_BOX_QTY THEN
                        BEGIN
                            GLBOVERSOLD_EACHQTY := VAR_REQ_SPLITQTY_EACH;
                             IF VAR_EXIST_BOX_QTY > 0 THEN
                                -- IF WE HAVE ANY BOXES LEFT THEN WE CAN USE THEN TO FULFIL SOME OF THE WEIGHT
                                GLBOVERSOLD_EACHQTY := GLBOVERSOLD_EACHQTY - (VAR_EXIST_BOX_QTY * VAR_PROD_EACHQTY);
                            END IF;
                        END;
                        END IF;

                        VAR_EXIST_BOX_QTY := VAR_EXIST_BOX_QTY -  VAR_BOXREQFORSPLIT_EACH;

                    END;
                    END IF;
                END;
                END IF;


                -- INNER
                -- DO WE HAVE ANY DELTOALLS FOR SPLIT INNER
                IF VAR_REQ_SPLITQTY_INNER > 0  THEN
                BEGIN
                    -- SUBTRACT ANY ALREADY SPLIT INNER FROM OTHER ALLOCATES TO GET THE INNER FIGURE WE REQUIRE
                    VAR_REQ_SPLITQTY_INNER := VAR_REQ_SPLITQTY_INNER - NVL(VAR_ALRDY_SPLITQTY_INNER,0);

                    -- DO WE STILL REQUIRE SOME MORE SPLIT INNER
                    IF VAR_REQ_SPLITQTY_INNER > 0 AND VAR_PROD_INNERQTY > 0 THEN
                    BEGIN
                        VAR_BOXREQFORSPLIT_INNER  := CEIL(VAR_REQ_SPLITQTY_INNER/VAR_PROD_INNERQTY);

                        -- IF WE REQUIRE MORE BOXS TO FULFIL THE INNER ALLOCATED THEN WE HAVE AN OVERSELL
                        IF VAR_BOXREQFORSPLIT_INNER > VAR_EXIST_BOX_QTY THEN
                        BEGIN
                            GLBOVERSOLD_INNERQTY := VAR_REQ_SPLITQTY_INNER;
                             IF VAR_EXIST_BOX_QTY > 0 THEN
                                -- IF WE HAVE ANY BOXES LEFT THEN WE CAN USE THEN TO FULFIL SOME OF THE WEIGHT
                                GLBOVERSOLD_INNERQTY := GLBOVERSOLD_INNERQTY - (VAR_EXIST_BOX_QTY * VAR_PROD_INNERQTY);
                            END IF;
                        END;
                        END IF;

                        VAR_EXIST_BOX_QTY := VAR_EXIST_BOX_QTY -  VAR_BOXREQFORSPLIT_INNER;

                    END;
                    END IF;
                END;
                END IF;

                 --SR 13987. if RTS done alloc qty will be negative. in ordermanagement new ticking overallocated does not show this as this proc returns 0.
                IF VAR_LCONT = 1 THEN
                BEGIN

                   VAR_ALLOC_AND_EXP := 0;

                   IF VAR_ACTSPLITQTY_THISALLOC = 0 AND VAR_EXP_BOX_QTY < 0 THEN
                      SELECT (ALLOCQTY + ALLOCEXP) - ALLOCALLOC
                      INTO VAR_ALLOC_AND_EXP
                      FROM ALLOCATE WHERE ALLOCNO = VAR_USEALLOCNO;

                      IF VAR_ALLOC_AND_EXP < 0 THEN
                         VAR_EXIST_BOX_QTY := VAR_ALLOC_AND_EXP;
                      END IF;

                   END IF;
                END;
                END IF;


          --- THIS IS THE BOX OVERSOLD QTY INCLUDING ALL BOX EQUIVALENT OF THE SPLITS FOR AN ALLOCATE LINE
                IF VAR_LCONT = 1 THEN
                BEGIN
                    GLBALLOCNO := VAR_USEALLOCNO;

                    IF VAR_EXIST_BOX_QTY < 0 THEN
                    BEGIN
                        RET_ISOVERALLOC := 1;
                        GLBISOVERALLOC := 1;
                        GLBOVERSOLD_BOXQTY            := ABS(VAR_EXIST_BOX_QTY);
                    END;
                    END IF;
                END;
                END IF;




            END;
            END IF;

        RETURN RET_ISOVERALLOC;


        END CHKISALLOCATE_OVERALLOC;


    -- *****IMPORTANT**** THIS FUNCTION SHOULD NEVER BE CALLED ON ITS OWN
    -- FUNCTION ISALLOCATE_OVERALLOC SHOULD BE CALLED FIRST WHICH WILL POPULATE THE VARIABLES
    FUNCTION GET_OVERALLOC_DETAILS  ( V_ALLOCNO in NUMBER, WHICHFLD in VARCHAR2)
        RETURN  NUMBER
        IS
        V_RETFLD NUMBER :=0 ;
        V_ISOVERALLOC NUMBER :=0 ;
          BEGIN

                IF GLBALLOCNO <> V_ALLOCNO THEN
                    V_ISOVERALLOC := ISALLOCATE_OVERALLOC(V_ALLOCNO, NULL);
                END IF;

                IF GLBISOVERALLOC > 0 THEN
                    IF GLBALLOCNO = V_ALLOCNO THEN
                       IF    WHICHFLD = 'ONLYBOXQTY' THEN
                                V_RETFLD := GLBOVERSOLD_ONLYBOXQTY;
                       ELSIF WHICHFLD = 'BOXQTY' THEN
                                V_RETFLD := GLBOVERSOLD_BOXQTY;
                       ELSIF WHICHFLD = 'WGTQTY' THEN
                                V_RETFLD := GLBOVERSOLD_WGTQTY;
                       ELSIF TRIM(WHICHFLD) = 'EACHQTY' THEN
                                V_RETFLD := GLBOVERSOLD_EACHQTY;
                       ELSIF WHICHFLD = 'INNERQTY' THEN
                                V_RETFLD := GLBOVERSOLD_INNERQTY;
                       ELSE
                               V_RETFLD := 0;
                       END IF;
                    END IF;
                 END IF;
                 RETURN V_RETFLD;

        END GET_OVERALLOC_DETAILS;


    ---*******************************************************************************************************************************************
    -- IF A USER DOES AN EXTRACT, BUT DOES NOT UPDATE IT AND THEN DOES ANOTHER EXTRACT THE INTERMEDIATE ONE IS STORED SO CHANGES CAN BE VIEWED
    -- THIS REMOVES THESE UNCOMMITTED EXTRACTIONS FROM THE TABLES
    ---*******************************************************************************************************************************************
        PROCEDURE REMOVEUNCOMMITTED  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER) IS
        BEGIN

        BEGIN
            DELETE FROM STKDISS_DETS_ONALLOC    WHERE STKDISSHDR_RECNO  IN ( select STKDISSHDR_RECNO from stkdiss_hdr where STKDISSHDR_RECNO < V_HDRRECNO and DPTRECNO = V_DPTRECNO and ISCOMPLETE =  2 AND SALOFFNO = ( SELECT SALOFFNO FROM  stkdiss_hdr where STKDISSHDR_RECNO = V_HDRRECNO)) ;
            DELETE FROM STKDISS_RETURNS         WHERE STKDISSHDR_RECNO  IN ( select STKDISSHDR_RECNO from stkdiss_hdr where STKDISSHDR_RECNO < V_HDRRECNO and DPTRECNO = V_DPTRECNO and ISCOMPLETE =  2 AND SALOFFNO = ( SELECT SALOFFNO FROM  stkdiss_hdr where STKDISSHDR_RECNO = V_HDRRECNO));
            DELETE FROM STKDISS_DETS_DLV        WHERE STKDISSHDR_RECNO  IN ( select STKDISSHDR_RECNO from stkdiss_hdr where STKDISSHDR_RECNO < V_HDRRECNO and DPTRECNO = V_DPTRECNO and ISCOMPLETE =  2 AND SALOFFNO = ( SELECT SALOFFNO FROM  stkdiss_hdr where STKDISSHDR_RECNO = V_HDRRECNO));
            DELETE FROM STKDISS_DETS            WHERE STKDISSHDR_RECNO  IN ( select STKDISSHDR_RECNO from stkdiss_hdr where STKDISSHDR_RECNO < V_HDRRECNO and DPTRECNO = V_DPTRECNO and ISCOMPLETE =  2 AND SALOFFNO = ( SELECT SALOFFNO FROM  stkdiss_hdr where STKDISSHDR_RECNO = V_HDRRECNO));
            COMMIT;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
                -- IF THERE ARE NO RECORDS THIS IS NOT AN ISSUE
            WHEN OTHERS THEN
                NULL;
                RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - REMOVEUNCOMMITTED');

        END;


            END REMOVEUNCOMMITTED;


    ---*******************************************************************************************************************************************
    -- THIS IS TO DELETE ALL RECORDS RELATING TO AN EXTRACT. THIS REMOVES ALL EXTRACTIONS FROM THE TABLES
    --
    ---*******************************************************************************************************************************************
        PROCEDURE REMOVEFULLEXTRACT  ( V_HDRRECNO IN NUMBER) IS
        BEGIN

        BEGIN


            DELETE FROM STKDISS_DETS_ONALLOC    WHERE STKDISSHDR_RECNO  = V_HDRRECNO;
            DELETE FROM STKDISS_RETURNS         WHERE STKDISSHDR_RECNO  = V_HDRRECNO;
            DELETE FROM STKDISS_DETS_DLV        WHERE STKDISSHDR_RECNO  = V_HDRRECNO;
            DELETE FROM STKDISS_DETS            WHERE STKDISSHDR_RECNO  = V_HDRRECNO;
            DELETE FROM STKDISS_HDR             WHERE STKDISSHDR_RECNO  = V_HDRRECNO;
            COMMIT;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
                -- IF THERE ARE NO RECORDS THIS IS NOT AN ISSUE
            WHEN OTHERS THEN
                NULL;
                RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - REMOVEFULLEXTRACT');

        END;


        END REMOVEFULLEXTRACT;


        PROCEDURE MAINRUN_ALLLOTS_FIRSTSTAGE(V_DPTRECNO IN NUMBER,
                                             V_HDRRECNO IN NUMBER,
                                             V_PONO     IN NUMBER,
                                             V_LHERECNO IN NUMBER,
                                             V_SUPCLARECNO IN NUMBER,
                                             V_SUPGRPNO IN NUMBER,
                                             V_PAYTYP   IN NUMBER)   IS
            VAR_LCONT                NUMBER(1) := 1;
            V_USERNO                 NUMBER(10);
      BEGIN

       -- TEMPORARY PIECE OF CODE
        IF VAR_LCONT = 1 THEN
            BEGIN
                DELETE FROM STKDISS_DETS WHERE STKDISS_DETS.STKDISSHDR_RECNO =V_HDRRECNO ;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;  -- IF THERE IS NOTHING TO DELETE THEN WE STILL WANT TO CONTINUE
                WHEN OTHERS THEN
                    NULL;
                     RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - MAINRUN ALLLOTS - DELETE');
                    VAR_LCONT := 0;
            END;
        END IF;

        --  CALL ALL OTHER METHODS
        IF VAR_LCONT = 1 THEN
             BEGIN
                --UPDATE STKDISS_HDR SET STARTDT = NULL, MISSINGALLOCDT= NULL, EXTRACT_STKDT = NULL, ALREDYSLDDT = NULL, ONALLOCDT = NULL, COMPLETEDT = NULL
                --WHERE STKDISSHDR_RECNO = V_HDRRECNO;

                UPDATE STKDISS_HDR SET STARTDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

                WRITEMISSINGALLOCDETS();
                UPDATE STKDISS_HDR SET MISSINGALLOCDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

                EXTRACT_STK_FOR_DETAILS (V_DPTRECNO, V_HDRRECNO, V_PONO, V_LHERECNO, V_SUPCLARECNO, V_SUPGRPNO);

                UPDATE STKDISS_HDR SET EXTRACT_STKDT = SYSDATE  WHERE STKDISSHDR_RECNO = V_HDRRECNO;

            EXCEPTION
                WHEN OTHERS THEN
                    raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - MAINRUN ALLLOTS - CALL METHODS');

            END;
        END IF;

        -- REMOVES THE LOTS THAT DO NOT HAVE THE PAYMENT TYPE OR PO OR POT THAT WE WANT
        IF VAR_LCONT = 1 THEN
            REMOVELOTS(V_HDRRECNO, V_PONO, V_LHERECNO,V_PAYTYP);
        END IF;

        END MAINRUN_ALLLOTS_FIRSTSTAGE;


    ---*******************************************************************************************************************************************
    -- -- EXTRACTS THE STOCK FIGURES FOR THE PASSED DEPARTMENT, PO, LOT
    ---*******************************************************************************************************************************************
    PROCEDURE EXTRACT_STK_FOR_DETAILS  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER,  V_PONO     IN NUMBER, V_LHERECNO IN NUMBER, V_SUPCLARECNO IN NUMBER, V_SUPGRPNO IN NUMBER) IS
            VAR_LCONT                NUMBER(1) := 1;
        BEGIN

        -- EXTRACT ALL THE LOTITE  RECORDS THAT ARE FOR THIS DEPARTMENT, PO OR LOT
        -- PREPACK LINES ARE IGNORED AT THE MOMENT - AS THEY ARE PICKED UP UNDER BULK AS SPLITS
        IF VAR_LCONT = 1 THEN
            BEGIN
               IF NVL(V_PONO,0) > 0 or NVL(V_LHERECNO,0) > 0 THEN
                   IF NVL(V_PONO,0) > 0 THEN
                        INSERT INTO STKDISS_DETS
                        (STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, SALOFFNO)
                        (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, LITITENO, SALOFFNO FROM
                            (SELECT DISTINCT LITITENO,(CASE WHEN NVL(ITESTO.TRNSALOFFNO,0) = 0 THEN PURORD.PORSALOFF ELSE ITESTO.TRNSALOFFNO END) SALOFFNO
                            FROM ITESTO, LOTITE, PURORD, DEPARTMENTSTOSMN
                            WHERE  ITESTO.ISTLITNO             =   LOTITE.LITITENO
                            AND    ITESTO.ISTPONO               =   PURORD.PORNO
                            AND    LOTITE.LITBUYER             =   DEPARTMENTSTOSMN.SMNNO

                            AND    DEPARTMENTSTOSMN.DPTRECNO   =   V_DPTRECNO
                            AND    ITESTO.ISTPONO               =   V_PONO
                            ));
                    ELSE
                        INSERT INTO STKDISS_DETS
                        (STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, SALOFFNO)
                        (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, LITITENO, SALOFFNO FROM
                            (SELECT DISTINCT LITITENO,(CASE WHEN NVL(ITESTO.TRNSALOFFNO,0) = 0 THEN PURORD.PORSALOFF ELSE ITESTO.TRNSALOFFNO END) SALOFFNO
                            FROM ITESTO, LOTITE, PURORD, DEPARTMENTSTOSMN
                            WHERE  ITESTO.ISTLITNO             =   LOTITE.LITITENO
                            AND    ITESTO.ISTPONO               =   PURORD.PORNO
                            AND    LOTITE.LITBUYER             =   DEPARTMENTSTOSMN.SMNNO

                            AND    DEPARTMENTSTOSMN.DPTRECNO   =   V_DPTRECNO
                            AND    ITESTO.ISTLOTNO               =   V_LHERECNO
                            ));

                    END IF;
                ELSE
                    INSERT INTO STKDISS_DETS
                        (STKDISSDETS_RECNO, STKDISSHDR_RECNO, LITITENO, SALOFFNO)
                        (SELECT STKDISS_DETS_RECNO_SEQ.NEXTVAL, V_HDRRECNO, LITITENO, SALOFFNO FROM
                            (SELECT DISTINCT LITITENO,(CASE WHEN NVL(ITESTO.TRNSALOFFNO,0) = 0 THEN PURORD.PORSALOFF ELSE ITESTO.TRNSALOFFNO END) SALOFFNO
                            FROM ITESTO, LOTITE, PURORD, DEPARTMENTSTOSMN
                            WHERE  ITESTO.ISTLITNO             =   LOTITE.LITITENO
                            AND    ITESTO.ISTPONO               =   PURORD.PORNO
                            AND    LOTITE.LITBUYER             =   DEPARTMENTSTOSMN.SMNNO

                            AND    DEPARTMENTSTOSMN.DPTRECNO   =   V_DPTRECNO
                            AND EXISTS ( SELECT 1 FROM LOTPROFITSALOFF WHERE LOTPROFITSALOFF.LITITENO = ITESTO.ISTLITNO AND (NVL(PROFITISED,0) = 0 OR NVL(REOPENED,0) = 1))
                            ));
                 END IF;
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_STK_FOR_DPT - EXTRACT');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- remove any that are not for this CURRENT SALESOFFICE
        IF VAR_LCONT = 1 THEN
            UPD_SALESOFFICE  ( V_HDRRECNO);
        END IF;

        -- SOME OF THESE OVERSOLD LOTS MAY NOT BE FOR THE PO/;LOT THAT I WANT BUT WE'LL GET THEM ANYWAY AND REMOVE THEM BELOW
        IF VAR_LCONT = 1 THEN
            EXTRACT_OVERSOLDLOTS (V_DPTRECNO,  V_HDRRECNO);
        END IF;


        /*  NO NEED FOR THIS CODE AS ANY RELEVANT INTERDEPARTMENT TRANSFERS WILL BE EXTRACTED ON THE LOT

            -- GET NEW INTERDEPARTMENT TRANSFERS
        IF VAR_LCONT = 1 THEN
            EXTRACT_INTERDPTTRANSFERS (V_DPTRECNO,  V_HDRRECNO);
        END IF;*/

       -- UPDATE THE SALES OFFICE AND REMOVE ANY NOT FOR CURRENT SALESOFFICE
        IF VAR_LCONT = 1 THEN
            UPD_SALESOFFICE  ( V_HDRRECNO);
        END IF;

        IF VAR_LCONT = 1 THEN

           --Either, one of or both of these will be null: V_SUPCLARECNO V_SUPGRPNO

            BEGIN
               IF NVL(V_SUPCLARECNO,0) > 0 OR NVL(V_SUPGRPNO,0) > 0 THEN

                  IF NVL(V_SUPCLARECNO,0) > 0 THEN
                     BEGIN
                       DELETE FROM STKDISS_DETS
                       WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                       AND EXISTS (SELECT 1 FROM LOTITE
                                        WHERE LOTITE.LITITENO   =   STKDISS_DETS.LITITENO
                                        AND NVL(LOTITE.LITSENCODE,0)    <>  V_SUPCLARECNO);

                        COMMIT;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;
                        WHEN OTHERS THEN
                            RAISE_APPLICATION_ERROR(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                            NULL;
                            RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_STK_FOR_DETAILS- DELETE SUPPLIERS ');
                     END;
                  END IF;

                  --Remove records for All suppliers in SUPPLIER GROUP (SR 06/06/14 12150)
                   IF NVL(V_SUPGRPNO,0) > 0 THEN
                     BEGIN
                       DELETE FROM STKDISS_DETS
                       WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                       AND EXISTS (SELECT 1 FROM LOTITE
                                        WHERE LOTITE.LITITENO   =   STKDISS_DETS.LITITENO
                                        AND NVL(LOTITE.LITSENCODE,0) NOT IN(select CsdCstCode from cstanRec Where CsdCsgRecNo = V_SUPGRPNO ) );
                        COMMIT;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;
                        WHEN OTHERS THEN
                            RAISE_APPLICATION_ERROR(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                            NULL;
                            RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_STK_FOR_DETAILS- DELETE SUPPLIERS (GROUP) ');
                     END;
                  END IF;

               END IF;
            END;
        END IF;


    -- EXTRACT THE OPENING QTY FOR THESE RECORDS
        IF VAR_LCONT = 1 THEN
            UPD_OPENINGQTY  ( V_HDRRECNO);
        END IF;


    END EXTRACT_STK_FOR_DETAILS;


    ---*******************************************************************************************************************************************
    -- -- REMOVES ALL LOTS THAT WE DO NOT REQUIRE
    ---*******************************************************************************************************************************************

    PROCEDURE REMOVELOTS(V_HDRRECNO IN NUMBER,
                         V_PONO     IN NUMBER,
                         V_LHERECNO IN NUMBER,
                         V_PAYTYP   IN NUMBER)   IS
            VAR_LCONT                NUMBER(1) := 1;

      BEGIN


      -- DELETE ANY OF THESE THAT ARE FOR POS THAT WE DO NOT REQUIRE
        IF VAR_LCONT = 1 THEN
            IF NVL(V_PONO,0) > 0 THEN
                BEGIN
                        DELETE FROM STKDISS_DETS
                        WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                        AND EXISTS (SELECT 1 FROM LOTITE, PURORD
                                    WHERE LOTITE.LITITENO   =   STKDISS_DETS.LITITENO
                                    AND PURORD.PORRECNO     =   LOTITE.LITPORREC
                                    AND PURORD.PORNO    <>  V_PONO);
                    COMMIT;
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                    WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                        NULL;
                        RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_STK_FOR_DETAILS- DELETE PO ');

                END;
             END IF;
        END IF;

        -- DELETE ANY OF THESE THAT ARE FOR LOTS THAT WE DO NOT REQUIRE
        IF VAR_LCONT = 1 THEN
            IF NVL(V_LHERECNO,0) > 0 THEN
                BEGIN
                    DELETE FROM STKDISS_DETS
                    WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                    AND EXISTS (SELECT 1 FROM LOTITE, LOTDET, LOTHED
                                    WHERE LOTITE.LITITENO   =   STKDISS_DETS.LITITENO
                                    AND LOTDET.DETRECNO     =   LOTITE.LITDETNO
                                    AND LOTDET.DETLHERECNO    <>  V_LHERECNO);
                    COMMIT;
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                    WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                        NULL;
                        RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - EXTRACT_STK_FOR_DETAILS- DELETE LOTS ');

                END;
             END IF;
        END IF;
      -- DELETE ANY OF THESE THAT ARE HAVE A PAYMENT TYPE THAT WE DO NOT REQUIRE
        IF VAR_LCONT = 1 THEN
            IF NVL(V_PAYTYP,0) > 0 THEN
                 BEGIN
                    IF V_USELITPAYTYP = 1 THEN
                        DELETE FROM STKDISS_DETS
                        WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                        AND EXISTS (SELECT 1 FROM LOTITE, LOTDET, LOTHED
                                    WHERE LOTITE.LITITENO   =   STKDISS_DETS.LITITENO
                                    AND LOTDET.DETRECNO     =   LOTITE.LITDETNO
                                    AND LOTHED.LHERECNO     =   LOTDET.DETLHERECNO
                                    AND NVL(LOTITE.LITPAYTYP, LOTHED.LHEPAYTYP)    <>  V_PAYTYP);
                    ELSE
                        DELETE FROM STKDISS_DETS
                        WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                        AND EXISTS (SELECT 1 FROM LOTITE, LOTDET, LOTHED
                                    WHERE LOTITE.LITITENO   =   STKDISS_DETS.LITITENO
                                    AND LOTDET.DETRECNO     =   LOTITE.LITDETNO
                                    AND LOTHED.LHERECNO     =   LOTDET.DETLHERECNO
                                    AND NVL(LOTHED.LHEPAYTYP,0)    <>  V_PAYTYP);
                    END IF;
                    COMMIT;
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                    WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                        NULL;
                        RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - MAINRUN ALLLOTS - DELETE PAY TYPES ');

                END;
             END IF;
        END IF;

    END REMOVELOTS;



    ---*******************************************************************************************************************************************
    -- UPDATES THE SALES OFFICE SPECIFIC ACCOUNT CODE FOR THE LOTS AND THE DELIVERIES
    -- THE ACCOUNT CODE  WAS ADDED TO SPEED UP THE PARADOX QUERIES AS FT_PKAGE_ACCOUNTS.GETACCCODE WAS PROVING SLOW   - THIS HAS A REFRESH ISSUE IN THAT IF A CODE IS CHANGED IT WILL NOT REFRESH
    -- HOWEVER AS THE MAJORITY OF EXTRACT ARE FOR TODAY I THINK THE RISK HERE IS MINIMAL
    -- THE ACCRECNO WAS ADDED ATO SIMPLFY THE QUERIES - IE REMOVE THE NEED FOR A PATH FROM STKDISS_DETS_DLV -> DELHED -> ORDERS -> ACCCLASS -> ACCOUNTS
    ---*******************************************************************************************************************************************

    PROCEDURE UPD_ACCCODE  (V_HDRRECNO IN NUMBER) IS
            VAR_LCONT                NUMBER(1) := 1;
        BEGIN

         -- GET THE SALES OFFICE FOR THE LOTS
        IF VAR_LCONT = 1 THEN
            BEGIN

                UPDATE STKDISS_DETS SET SO_ACCCODE = ( SELECT FT_PK_ACCOUNTS.GETACCCODE(LOTITE.LITSENCODE, STKDISS_DETS.SALOFFNO) FROM LOTITE WHERE STKDISS_DETS.LITITENO = LOTITE.LITITENO )
                WHERE STKDISS_DETS.STKDISSHDR_RECNO = V_HDRRECNO;
                COMMIT;

                UPDATE STKDISS_DETS_DLV SET SO_ACCCODE =  (SELECT FT_PK_ACCOUNTS.GETACCCODE(ORDERS.ACTCSTCODE, DELHED.DLVSALOFFNO)
                                                            FROM DELHED, ORDERS
                                                            WHERE STKDISS_DETS_DLV.DLVORDNO          =  DELHED.DLVORDNO
                                                            AND DELHED.DLVORDRECNO                  = ORDERS.ORDRECNO),
                                            ACCRECNO =  (SELECT ACCCLASS.CLAACCNO
                                                            FROM DELHED, ORDERS, ACCCLASS
                                                            WHERE STKDISS_DETS_DLV.DLVORDNO         = DELHED.DLVORDNO
                                                            AND DELHED.DLVORDRECNO                  = ORDERS.ORDRECNO
                                                            AND ACCCLASS.CLARECNO                   = ORDERS.ACTCSTCODE)
                WHERE STKDISS_DETS_DLV.STKDISSHDR_RECNO = V_HDRRECNO;
                COMMIT;

                UPDATE STKDISS_DETS_ONALLOC SET SO_ACCCODE =  (SELECT FT_PK_ACCOUNTS.GETACCCODE(STKDISS_DETS_ONALLOC.ACTCSTCODE, DELHED.DLVSALOFFNO)
                                                            FROM DELHED
                                                            WHERE STKDISS_DETS_ONALLOC.DLVORDNO          =  DELHED.DLVORDNO)
                WHERE STKDISS_DETS_ONALLOC.STKDISSHDR_RECNO = V_HDRRECNO;
                COMMIT;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - UPDATE STKDISS_DETS SALOFFNO ');
                    VAR_LCONT := 0;
            END;
        END IF;

        -- REMOVE ANY LOTITES THAT MAY NOT BE FOR THIS SALES OFFICE
        IF VAR_LCONT = 1 THEN
            BEGIN
                DELETE FROM STKDISS_DETS
                WHERE   STKDISSHDR_RECNO = V_HDRRECNO
                AND     NVL(SALOFFNO, 0) <> (SELECT SALOFFNO FROM STKDISS_HDR WHERE STKDISS_HDR.STKDISSHDR_RECNO  = V_HDRRECNO);
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    NULL;
                    RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_STOCKDISSECTION - DELETE STKDISS_DETS <> SALOFFNO ');
                    VAR_LCONT := 0;
            END;
        END IF;



    END UPD_ACCCODE;

    ---*******************************************************************************************************************************************
    -- SIMPLE PROCEDURE TO UPDATE THE DELIVERY TO DISSECTED IF IT IS VALID  - DOES DELHED AND DELTOALL
    -- THIS DOES ALL VALIDITY CHECKS ON THE DELVIERY AND IF ANY FAIL IT DOESN'T UPDATE THE DELIVERY AND DOESN'T REPORT AN ERROR
    ---*******************************************************************************************************************************************
    PROCEDURE DISSECTDELIVERY  (V_DLVORDNO IN NUMBER) IS
            VAR_NOOFERRS                  NUMBER(10) := 0;
        BEGIN

        -- CHECK SALES OFFICE PREFERENCE - IF TELESALES_AUTODISSECT IS NOT 1 THEN DO NOT CONTINUE
        IF VAR_NOOFERRS = 0 THEN
        BEGIN
              SELECT COUNT(*) NOOF INTO  VAR_NOOFERRS
              FROM SALOFFNO
              WHERE SALOFFNO = (SELECT DLVSALOFFNO FROM DELHED WHERE DLVORDNO = V_DLVORDNO)
              AND TELESALES_AUTODISSECT = 0;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    FT_PK_ERRORS.LOG_AND_CONTINUE;
                    VAR_NOOFERRS := 1;
            END;
        END IF;

        -- ENSURE DELHED IS NOT ALREADY DISSECTED OR IS not at blank or picked status, OR IS A TRANSHIPMENT, TRANSFER, INTERDEPARTMENT LINE
        IF VAR_NOOFERRS = 0 THEN
            BEGIN
              SELECT COUNT(*) NOOF INTO VAR_NOOFERRS FROM DELHED WHERE DLVORDNO = V_DLVORDNO
              AND
              (ISOPENFORMORE = 2
              OR
              NVL(DLVRELINV, '***') NOT IN ('***', 'Pik')
              OR
              DLVTRANSSHIP IS NOT NULL
              OR
              TRANSFERFLG IS NOT NULL
              OR
              INTERDEPTFLAG IS NOT NULL)
              ;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    FT_PK_ERRORS.LOG_AND_CONTINUE;
                    VAR_NOOFERRS := 1;
            END;
        END IF;

         -- ARE THERE ANY -VE QUANTITIES IN DELDET or that are not at blank or picked status
        IF VAR_NOOFERRS = 0 THEN
            BEGIN
              SELECT COUNT(*) NOOF INTO VAR_NOOFERRS FROM DELDET WHERE DELDLVORDNO = V_DLVORDNO
              AND
              (DELQTY < 0
              OR
              NVL(DELSTATUS, '***') NOT IN ('***', 'Pik'))
              ;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    FT_PK_ERRORS.LOG_AND_CONTINUE;
                    VAR_NOOFERRS := 1;
            END;
        END IF;

        -- ARE THERE ANY -VE QUANTITIES IN DELTOALL
        IF VAR_NOOFERRS = 0 THEN
            BEGIN
              SELECT COUNT(*) NOOF INTO VAR_NOOFERRS
              FROM DELTOALL, DELDET
              WHERE DELTOALL.DALTYPERECNO =  DELDET.DELRECNO
              AND DALRECORDTYPE = 1
              AND DELDLVORDNO = V_DLVORDNO
              AND NVL(DELTOALL.DALQTY,0) < 0 OR NVL(DELTOALL.ACTSPLITQTY ,0) < 0;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    NULL;
                 WHEN OTHERS THEN
                    FT_PK_ERRORS.LOG_AND_CONTINUE;
                    VAR_NOOFERRS := 1;
            END;
        END IF;


        -- ARE THERE ANY DELDETS WHERE THEY ARE NOT FULLY ALLOCATED TO DELTOALLS
        IF VAR_NOOFERRS = 0 THEN
            BEGIN
              SELECT COUNT(*) NOOF INTO VAR_NOOFERRS
              FROM
              (SELECT DELRECNO,
                      NVL(DELQTY, 0) DELQTY ,
                      NVL((SELECT SUM(CASE WHEN DELDET.DELQTYPER > 1 THEN NVL(ACTSPLITQTY, 0) ELSE NVL(DALQTY, 0) END) 
                           FROM DELTOALL 
                           WHERE  DELTOALL.DALTYPERECNO =  DELDET.DELRECNO 
                           AND DALRECORDTYPE = 1 
                           AND NVL(DELTOALL.DALQTY,0) + NVL(DELTOALL.ACTSPLITQTY,0) > 0 ),0) DALQTY
              FROM DELDET
              WHERE DELDLVORDNO = V_DLVORDNO)
              WHERE DELQTY > DALQTY;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    FT_PK_ERRORS.LOG_AND_CONTINUE;
                    VAR_NOOFERRS := 1;
            END;
        END IF;

        -- ARE THERE ANY DELTOALLS AGAINST ALLOCATES THAT ARE OVERSOLD
        IF VAR_NOOFERRS = 0 THEN
            BEGIN
              SELECT COUNT(*) NOOF INTO VAR_NOOFERRS
              FROM
              (SELECT DALWIZUNIQUEID, FT_PK_STOCKDISSECTION.ISALLOCATE_OVERALLOC(NULL, DELTOALL.DALWIZUNIQUEID, DELHED.DLVSHPDATE)  ISALLOCATE_OVERALLOC
              FROM DELTOALL, DELDET, DELHED
              WHERE DELTOALL.DALTYPERECNO =  DELDET.DELRECNO
              AND DELDET.DELDLVORDNO = DELHED.DLVORDNO 
              AND DALRECORDTYPE = 1
              AND DELDLVORDNO = V_DLVORDNO)
              WHERE ISALLOCATE_OVERALLOC = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    FT_PK_ERRORS.LOG_AND_CONTINUE;
                    VAR_NOOFERRS := 1;
            END;
        END IF;

        -- ARE THERE ANY DELDETS AGAINST DEFAULT PRODUCTS - THESE CAN BE HANDLED IN THE STOCK DISSECTION PROGRAM
        IF VAR_NOOFERRS = 0 THEN
            BEGIN
              SELECT COUNT(*) NOOF INTO VAR_NOOFERRS
              FROM DELDET, PRDREC
              WHERE DELDET.DELPRCPRDNO = PRDREC.PRCPRDNO
              AND DELDLVORDNO = V_DLVORDNO
              AND NVL(PRDREC.DEFAULTPRD,0) = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    FT_PK_ERRORS.LOG_AND_CONTINUE;
                    VAR_NOOFERRS := 1;
            END;
        END IF;

        IF VAR_NOOFERRS = 0 THEN
            BEGIN
              FLAGDELIVERY(V_DLVORDNO, 0);
            END;
        END IF;

    END DISSECTDELIVERY;


    ---*******************************************************************************************************************************************
    -- SIMPLE PROCEDURE TO UPDATE THE DELIVERY TO DISSECTED IF IT IS VALID  - DOES DELHED AND DELTOALL
    -- THIS DOES ALL VALIDITY CHECKS ON THE DELVIERY AND IF ANY FAIL IT DOESN'T UPDATE THE DELIVERY AND DOESN'T REPORT AN ERROR
    ---*******************************************************************************************************************************************
    PROCEDURE FLAGDELIVERY  (V_DLVORDNO IN NUMBER, V_UNDISSECT IN NUMBER) IS
            VAR_LCONT                  NUMBER(1) := 1;
        BEGIN

        IF VAR_LCONT = 1 THEN
        BEGIN
          IF  V_UNDISSECT = 0 THEN
          BEGIN
            UPDATE DELTOALL SET ALLFLAG = 1
            WHERE DALTYPERECNO IN (SELECT DELRECNO FROM DELDET WHERE DELDLVORDNO = V_DLVORDNO);
            COMMIT;

            UPDATE DELHED SET ISOPENFORMORE = 2 WHERE DLVORDNO = V_DLVORDNO;
            COMMIT;
          END ;
          ELSE
          BEGIN
            UPDATE DELTOALL SET ALLFLAG = NULL
            WHERE DALTYPERECNO IN (SELECT DELRECNO FROM DELDET WHERE DELDLVORDNO = V_DLVORDNO);
            COMMIT;

            UPDATE DELHED SET ISOPENFORMORE = 1 WHERE DLVORDNO = V_DLVORDNO;
            COMMIT;
          END;
          END IF;
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL;
                WHEN OTHERS THEN
                    FT_PK_ERRORS.LOG_AND_STOP;
                    VAR_LCONT := 0;
            END;
        END IF;

  END FLAGDELIVERY;


  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
         RETURN cSpecVersionControlNo;
    ELSE
        RETURN cVersionControlNo;
    END IF;

  END CURRENTVERSION;


    -- initialisation section
    BEGIN
        BEGIN

            SELECT (CASE WHEN UPPER(SYSPREFVALUE) = 'TRUE' THEN 1 ELSE 0 END) LUSELITPAYTYP
            INTO V_USELITPAYTYP
            FROM WIZSYSPREF WHERE SYSPREFNAME = 'LUSELITPAYTYP' ;
        EXCEPTION
            WHEN OTHERS THEN
                raise_application_error(-20001,'An error was encountered - '||SQLCODE||' -ERROR- '||SQLERRM);
                RAISE_APPLICATION_ERROR(-20001, 'FT_PKAGE_AUTOCHECK -INIT');
                V_USELITPAYTYP  := 0;

        END;


    END FT_PK_STOCKDISSECTION;
