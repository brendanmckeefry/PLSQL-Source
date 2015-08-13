CREATE OR REPLACE PACKAGE BODY FT_PK_AUTOCOSTING AS
  
  cVersionControlNo   VARCHAR2(12) := '1.0.2'; -- Current Version Number
  
  PROCESSTODO     INTEGER := 1;
  PROCESSINPROG   INTEGER := 2;
  PROCESSLOT      INTEGER := 3;
  PROCESSJIT      INTEGER := 10;
  G_SID           INTEGER := SYS_CONTEXT('USERENV','SID');
  G_CHUNKSIZE     INTEGER := 1000;

  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE  
      RETURN cVersionControlNo;
    END IF;                
  END CURRENTVERSION;

  -- Helper Procedure to deal with looping of bulk exceptions --
  PROCEDURE LOG_BULK_DPR_ERRORS(DPRRECS_IN RECORD_NUMBERS, FTERR_IN IN FT_ERROR_CODES.FTERRORNO%TYPE)
  IS 
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    L_DPRRECNO        INTEGER;   
  BEGIN 
    FOR INDX IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
      BEGIN
        L_DPRRECNO := DPRRECS_IN(SQL%BULK_EXCEPTIONS(INDX).ERROR_INDEX);
        PARAMETER_LIST('#DPRRECNO') := L_DPRRECNO;
        FT_PK_ERRORS.RAISE_ERROR(FTERR_IN,  PARAMETER_LIST);           
      EXCEPTION
        WHEN OTHERS THEN
          FT_PK_ERRORS.LOG_AND_CONTINUE;
      END;
     END LOOP;
  END LOG_BULK_DPR_ERRORS;
  --------------------------------------------------------------
  -- Helper Procedure to deal with looping Of bulk exceptions --
  PROCEDURE LOG_BULK_LOT_ERRORS(LITRECS_IN RECORD_NUMBERS, FTERR_IN IN FT_ERROR_CODES.FTERRORNO%TYPE)
  IS 
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    L_LITITENO        INTEGER;   
  BEGIN 
    FOR INDX IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
      BEGIN
        L_LITITENO := LITRECS_IN(SQL%BULK_EXCEPTIONS(INDX).ERROR_INDEX);
        PARAMETER_LIST('#LITITENO') := L_LITITENO;
        FT_PK_ERRORS.RAISE_ERROR(FTERR_IN,  PARAMETER_LIST);           
      EXCEPTION
        WHEN OTHERS THEN
          FT_PK_ERRORS.LOG_AND_CONTINUE;
      END;
     END LOOP;
  END LOG_BULK_LOT_ERRORS;
  --------------------------------------------------------------

  PROCEDURE ENQUEUE_LITRECS(LITRECS_IN RECORD_NUMBERS, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE)
  IS
  BEGIN    
    FOR INDX IN LITRECS_IN.FIRST..LITRECS_IN.LAST LOOP
      MERGE INTO AUTOCOSTSTODO
      USING(
            SELECT  AUTOCOSTSTODO.AUTOCOSTREC, 
                    LOTITE.LITITENO,
                    PROCESSTODO AS PROCESSSTAT,
                    NVL((SELECT PORSALOFF FROM PURORD WHERE PORRECNO = LITPORREC), (SELECT PRESALOFFNO FROM PREWODOC, PREWORKS WHERE WODOCNO = PREWODOCNO AND WORECNO = LITWORECNO)) AS SALOFFNO,
                    BITOR(AUTOCOSTTYPES.WRITEPREPALINOUT, NVL(AUTOCOSTSTODO.WRITEPREPALINOUT, CONST.C_FALSE)) AS WRITEPREPALINOUT,
                    BITOR(AUTOCOSTTYPES.DOAUTCOSTADHOCCHGS, NVL(AUTOCOSTSTODO.DOAUTCOSTADHOCCHGS, CONST.C_FALSE)) AS DOAUTCOSTADHOCCHGS,
                    BITOR(AUTOCOSTTYPES.TRANSFERATCOST, NVL(AUTOCOSTSTODO.TRANSFERATCOST, CONST.C_FALSE)) AS TRANSFERATCOST,
                    BITOR(AUTOCOSTTYPES.CALCSALESCOSTDPRTABLE, NVL(AUTOCOSTSTODO.CALCSALESCOSTDPRTABLE, CONST.C_FALSE)) AS CALCSALESCOSTDPRTABLE,
                    BITOR(AUTOCOSTTYPES.TRANSFERADDCHGSAPP, NVL(AUTOCOSTSTODO.TRANSFERADDCHGSAPP, CONST.C_FALSE)) AS TRANSFERADDCHGSAPP,
                    BITOR(AUTOCOSTTYPES.CALCULATEGOODSCOST, NVL(AUTOCOSTSTODO.CALCULATEGOODSCOST, CONST.C_FALSE)) AS CALCULATEGOODSCOST,
                    BITOR(AUTOCOSTTYPES.LOTPROFITABILITY, NVL(AUTOCOSTSTODO.LOTPROFITABILITY, CONST.C_FALSE)) AS LOTPROFITABILITY,
                    BITOR(AUTOCOSTTYPES.RECALCULATEWOCOSTS, NVL(AUTOCOSTSTODO.RECALCULATEWOCOSTS, CONST.C_FALSE)) AS RECALCULATEWOCOSTS,
                    BITOR(AUTOCOSTTYPES.GETSALES, NVL(AUTOCOSTSTODO.GETSALES, CONST.C_FALSE)) AS GETSALES
            FROM LOTITE LOTITE
            LEFT OUTER JOIN AUTOCOSTSTODO
              ON LOTITE.LITITENO = AUTOCOSTSTODO.LITITENO AND AUTOCOSTSTODO.PROCESSSTAT = PROCESSTODO
            INNER JOIN AUTOCOSTTYPES
              ON AUTOCOSTTYPES.COSTCHNGTYPENO = COSTCHNGTYPE_IN
            WHERE LOTITE.LITITENO = LITRECS_IN(INDX)
            ) NEWAUTOCOSTREC
      ON (NEWAUTOCOSTREC.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC AND NEWAUTOCOSTREC.PROCESSSTAT = AUTOCOSTSTODO.PROCESSSTAT)
      WHEN MATCHED THEN
        UPDATE
        SET AUTOCOSTSTODO.WRITEPREPALINOUT = NEWAUTOCOSTREC.WRITEPREPALINOUT,
            AUTOCOSTSTODO.DOAUTCOSTADHOCCHGS = NEWAUTOCOSTREC.DOAUTCOSTADHOCCHGS,
            AUTOCOSTSTODO.TRANSFERATCOST = NEWAUTOCOSTREC.TRANSFERATCOST,
            AUTOCOSTSTODO.CALCSALESCOSTDPRTABLE = NEWAUTOCOSTREC.CALCSALESCOSTDPRTABLE,
            AUTOCOSTSTODO.TRANSFERADDCHGSAPP = NEWAUTOCOSTREC.TRANSFERADDCHGSAPP,
            AUTOCOSTSTODO.CALCULATEGOODSCOST = NEWAUTOCOSTREC.CALCULATEGOODSCOST,
            AUTOCOSTSTODO.LOTPROFITABILITY = NEWAUTOCOSTREC.LOTPROFITABILITY,
            AUTOCOSTSTODO.RECALCULATEWOCOSTS = NEWAUTOCOSTREC.RECALCULATEWOCOSTS,
            AUTOCOSTSTODO.GETSALES = NEWAUTOCOSTREC.GETSALES
      WHEN NOT MATCHED THEN
        INSERT( AUTOCOSTSTODO.LITITENO,
                AUTOCOSTSTODO.PROCESSSTAT,
                AUTOCOSTSTODO.SALOFFNO,
                AUTOCOSTSTODO.WRITEPREPALINOUT,
                AUTOCOSTSTODO.DOAUTCOSTADHOCCHGS,
                AUTOCOSTSTODO.TRANSFERATCOST,
                AUTOCOSTSTODO.CALCSALESCOSTDPRTABLE,
                AUTOCOSTSTODO.TRANSFERADDCHGSAPP,
                AUTOCOSTSTODO.CALCULATEGOODSCOST,
                AUTOCOSTSTODO.LOTPROFITABILITY,
                AUTOCOSTSTODO.RECALCULATEWOCOSTS,
                AUTOCOSTSTODO.GETSALES)
        VALUES( NEWAUTOCOSTREC.LITITENO,
                NEWAUTOCOSTREC.PROCESSSTAT,
                NEWAUTOCOSTREC.SALOFFNO,
                NEWAUTOCOSTREC.WRITEPREPALINOUT,
                NEWAUTOCOSTREC.DOAUTCOSTADHOCCHGS,
                NEWAUTOCOSTREC.TRANSFERATCOST,
                NEWAUTOCOSTREC.CALCSALESCOSTDPRTABLE,
                NEWAUTOCOSTREC.TRANSFERADDCHGSAPP,
                NEWAUTOCOSTREC.CALCULATEGOODSCOST,
                NEWAUTOCOSTREC.LOTPROFITABILITY,
                NEWAUTOCOSTREC.RECALCULATEWOCOSTS,
                NEWAUTOCOSTREC.GETSALES);
      COMMIT;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;
  END ENQUEUE_LITRECS;
  
  PROCEDURE ENQUEUE_DPRRECS(DPRRECS_IN RECORD_NUMBERS, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE)
  IS
  BEGIN
    FOR INDX IN DPRRECS_IN.FIRST..DPRRECS_IN.LAST LOOP
      MERGE INTO AUTOCOSTSTODO
      USING(
            SELECT  AUTOCOSTSTODO.AUTOCOSTREC,
                    DELPRICE.DPRRECNO,
                    PROCESSTODO AS PROCESSSTAT,
                    (SELECT DLVSALOFFNO FROM DELHED, DELDET WHERE DLVORDNO = DELDLVORDNO AND DELRECNO = DPRDELRECNO) AS SALOFFNO,
                    BITOR(AUTOCOSTTYPES.WRITEPREPALINOUT, NVL(AUTOCOSTSTODO.WRITEPREPALINOUT, CONST.C_FALSE)) AS WRITEPREPALINOUT,
                    BITOR(AUTOCOSTTYPES.DOAUTCOSTADHOCCHGS, NVL(AUTOCOSTSTODO.DOAUTCOSTADHOCCHGS, CONST.C_FALSE)) AS DOAUTCOSTADHOCCHGS,
                    BITOR(AUTOCOSTTYPES.TRANSFERATCOST, NVL(AUTOCOSTSTODO.TRANSFERATCOST, CONST.C_FALSE)) AS TRANSFERATCOST,
                    BITOR(AUTOCOSTTYPES.CALCSALESCOSTDPRTABLE, NVL(AUTOCOSTSTODO.CALCSALESCOSTDPRTABLE, CONST.C_FALSE)) AS CALCSALESCOSTDPRTABLE,
                    BITOR(AUTOCOSTTYPES.TRANSFERADDCHGSAPP, NVL(AUTOCOSTSTODO.TRANSFERADDCHGSAPP, CONST.C_FALSE)) AS TRANSFERADDCHGSAPP,
                    BITOR(AUTOCOSTTYPES.CALCULATEGOODSCOST, NVL(AUTOCOSTSTODO.CALCULATEGOODSCOST, CONST.C_FALSE)) AS CALCULATEGOODSCOST,
                    BITOR(AUTOCOSTTYPES.LOTPROFITABILITY, NVL(AUTOCOSTSTODO.LOTPROFITABILITY, CONST.C_FALSE)) AS LOTPROFITABILITY,
                    BITOR(AUTOCOSTTYPES.RECALCULATEWOCOSTS, NVL(AUTOCOSTSTODO.RECALCULATEWOCOSTS, CONST.C_FALSE)) AS RECALCULATEWOCOSTS,
                    BITOR(AUTOCOSTTYPES.GETSALES, NVL(AUTOCOSTSTODO.GETSALES, CONST.C_FALSE)) AS GETSALES
            FROM DELPRICE
            LEFT OUTER JOIN AUTOCOSTSTODO
              ON DELPRICE.DPRRECNO = AUTOCOSTSTODO.DPRRECNO AND AUTOCOSTSTODO.PROCESSSTAT = PROCESSTODO
            INNER JOIN AUTOCOSTTYPES
              ON AUTOCOSTTYPES.COSTCHNGTYPENO = COSTCHNGTYPE_IN
            WHERE DELPRICE.DPRRECNO = DPRRECS_IN(INDX)
            ) NEWAUTOCOSTREC
      ON (NEWAUTOCOSTREC.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC AND NEWAUTOCOSTREC.PROCESSSTAT = AUTOCOSTSTODO.PROCESSSTAT)
      WHEN MATCHED THEN
          UPDATE
          SET AUTOCOSTSTODO.WRITEPREPALINOUT = NEWAUTOCOSTREC.WRITEPREPALINOUT,
              AUTOCOSTSTODO.DOAUTCOSTADHOCCHGS = NEWAUTOCOSTREC.DOAUTCOSTADHOCCHGS,
              AUTOCOSTSTODO.TRANSFERATCOST = NEWAUTOCOSTREC.TRANSFERATCOST,
              AUTOCOSTSTODO.CALCSALESCOSTDPRTABLE = NEWAUTOCOSTREC.CALCSALESCOSTDPRTABLE,
              AUTOCOSTSTODO.TRANSFERADDCHGSAPP = NEWAUTOCOSTREC.TRANSFERADDCHGSAPP,
              AUTOCOSTSTODO.CALCULATEGOODSCOST = NEWAUTOCOSTREC.CALCULATEGOODSCOST,
              AUTOCOSTSTODO.LOTPROFITABILITY = NEWAUTOCOSTREC.LOTPROFITABILITY,
              AUTOCOSTSTODO.RECALCULATEWOCOSTS = NEWAUTOCOSTREC.RECALCULATEWOCOSTS,
              AUTOCOSTSTODO.GETSALES = NEWAUTOCOSTREC.GETSALES
      WHEN NOT MATCHED THEN
        INSERT(   AUTOCOSTSTODO.DPRRECNO,
                  AUTOCOSTSTODO.PROCESSSTAT,
                  AUTOCOSTSTODO.SALOFFNO,
                  AUTOCOSTSTODO.WRITEPREPALINOUT,
                  AUTOCOSTSTODO.DOAUTCOSTADHOCCHGS,
                  AUTOCOSTSTODO.TRANSFERATCOST,
                  AUTOCOSTSTODO.CALCSALESCOSTDPRTABLE,
                  AUTOCOSTSTODO.TRANSFERADDCHGSAPP,
                  AUTOCOSTSTODO.CALCULATEGOODSCOST,
                  AUTOCOSTSTODO.LOTPROFITABILITY,
                  AUTOCOSTSTODO.RECALCULATEWOCOSTS,
                  AUTOCOSTSTODO.GETSALES)
         VALUES(  NEWAUTOCOSTREC.DPRRECNO,
                  NEWAUTOCOSTREC.PROCESSSTAT,
                  NEWAUTOCOSTREC.SALOFFNO,
                  NEWAUTOCOSTREC.WRITEPREPALINOUT,
                  NEWAUTOCOSTREC.DOAUTCOSTADHOCCHGS,
                  NEWAUTOCOSTREC.TRANSFERATCOST,
                  NEWAUTOCOSTREC.CALCSALESCOSTDPRTABLE,
                  NEWAUTOCOSTREC.TRANSFERADDCHGSAPP,
                  NEWAUTOCOSTREC.CALCULATEGOODSCOST,
                  NEWAUTOCOSTREC.LOTPROFITABILITY,
                  NEWAUTOCOSTREC.RECALCULATEWOCOSTS,
                  NEWAUTOCOSTREC.GETSALES);
      COMMIT;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN  
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;
  END ENQUEUE_DPRRECS;
  
  PROCEDURE ENQUEUE_LIT(LITITENO_IN AUTOCOSTSTODO.LITITENO%TYPE, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE)
  IS
  BEGIN
    ENQUEUE_LITRECS(RECORD_NUMBERS(LITITENO_IN), COSTCHNGTYPE_IN);
  END ENQUEUE_LIT;
  
  PROCEDURE ENQUEUE_DPR(DPRRECNO_IN AUTOCOSTSTODO.DPRRECNO%TYPE, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE)
  IS
  BEGIN
    ENQUEUE_DPRRECS(RECORD_NUMBERS(DPRRECNO_IN), COSTCHNGTYPE_IN);
  END ENQUEUE_DPR;                        
 
  PROCEDURE ENQUEUE_DPRRECS_AA(DPRRECS_IN T_INTEGER_ARRAY, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE)
  AS
     DELPRICEIDS RECORD_NUMBERS := RECORD_NUMBERS();
  BEGIN
    FOR I IN DPRRECS_IN.FIRST..DPRRECS_IN.LAST
    LOOP
      DELPRICEIDS.EXTEND;
      DELPRICEIDS(I) := DPRRECS_IN(I);
    END LOOP;
    ENQUEUE_DPRRECS(DELPRICEIDS, COSTCHNGTYPE_IN);
    RETURN;
  END ENQUEUE_DPRRECS_AA;
  
  PROCEDURE EMPTY_AUTOCOSTS_PEND
  IS
  BEGIN
    FOR AUTOCOST_ITR IN(SELECT AUTOCOSTREC FROM AUTOCOSTS_PEND) LOOP
      DELETE FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOST_ITR.AUTOCOSTREC;
      COMMIT;
    END LOOP;
  END EMPTY_AUTOCOSTS_PEND;
  
  PROCEDURE PRIORITISE_LITRECS(LITRECS_IN RECORD_NUMBERS)
  IS
  BEGIN
    RESET_DEAD_SESSIONS();
    EMPTY_AUTOCOSTS_PEND();
      
    FOR INDX IN LITRECS_IN.FIRST..LITRECS_IN.LAST LOOP
      --Insert for LOTITE
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS( SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND AUTOCOSTSTODO.LITITENO = LITRECS_IN(INDX)) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP;  
      
      --Insert for bulk sales DELTOIST
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND EXISTS(SELECT * FROM ITESTO INNER JOIN DELTOIST ON DELTOIST.DISISTRECNO = ITESTO.ISTRECNO WHERE AUTOCOSTSTODO.DPRRECNO = DELTOIST.DISDPRRECNO AND ITESTO.ISTLITNO = LITRECS_IN(INDX))) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP; 

      --Insert for prepack sales PREPALINOUTSALES
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND EXISTS(SELECT * FROM ITESTO INNER JOIN PREPALINOUT ON ITESTO.ISTRECNO = PREPALINOUT.PALINBULKISTREC INNER JOIN PREPALINOUTSALES ON PREPALINOUT.PREPALRECNO = PREPALINOUTSALES.PREPALINOUTRECNO WHERE AUTOCOSTSTODO.DPRRECNO = PREPALINOUTSALES.DELPRCRECNO AND ITESTO.ISTLITNO = LITRECS_IN(INDX))) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP; 
      
      --Insert for bulk allocations DELTOALL
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND EXISTS(SELECT * FROM ITESTO INNER JOIN PALNOLOC ON ITESTO.ISTRECNO = PALNOLOC.PALLOCISTRECNO INNER JOIN DELTOALL ON PALNOLOC.PALLOCALLNO = DELTOALL.DALALLOCNO INNER JOIN DELPRICE ON DELTOALL.DALTYPERECNO = DELPRICE.DPRDELRECNO AND DELTOALL.DALRECORDTYPE = 1 WHERE AUTOCOSTSTODO.DPRRECNO = DELPRICE.DPRRECNO AND ITESTO.ISTLITNO = LITRECS_IN(INDX))) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP;    
      
      --Insert for prepack allocations DELTOALL
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND EXISTS(SELECT * FROM ITESTO INNER JOIN PREPALINOUT ON ITESTO.ISTRECNO = PREPALINOUT.PALINBULKISTREC INNER JOIN PALNOLOC ON PREPALINOUT.PPPALLOCRECNOOUT = PALNOLOC.PALLOCRECNO INNER JOIN DELTOALL ON PALNOLOC.PALLOCALLNO = DELTOALL.DALALLOCNO INNER JOIN DELPRICE ON DELTOALL.DALTYPERECNO = DELPRICE.DPRDELRECNO AND DELTOALL.DALRECORDTYPE = 1 WHERE AUTOCOSTSTODO.DPRRECNO = DELPRICE.DPRRECNO AND ITESTO.ISTLITNO = LITRECS_IN(INDX))) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP;    
    END LOOP;
       
  EXCEPTION
    WHEN OTHERS THEN  
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;    
  END PRIORITISE_LITRECS;
  
  PROCEDURE PRIORITISE_LIT(LITITENO_IN AUTOCOSTSTODO.LITITENO%TYPE)
  IS
  BEGIN
    PRIORITISE_LITRECS(RECORD_NUMBERS(LITITENO_IN));
  END PRIORITISE_LIT;

  PROCEDURE PRIORITISE_DPRRECS(DPRRECS_IN RECORD_NUMBERS)
  IS
  BEGIN
    RESET_DEAD_SESSIONS();
    EMPTY_AUTOCOSTS_PEND();
    
    FOR INDX IN DPRRECS_IN.FIRST..DPRRECS_IN.LAST LOOP
      --Insert for DELPRICE
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND DPRRECNO = DPRRECS_IN(INDX)) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP;  
    
      --Insert for bulk sales DELTOIST
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND EXISTS(SELECT * FROM ITESTO INNER JOIN DELTOIST ON DELTOIST.DISISTRECNO = ITESTO.ISTRECNO WHERE AUTOCOSTSTODO.LITITENO = ITESTO.ISTLITNO AND DELTOIST.DISDPRRECNO = DPRRECS_IN(INDX))) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP;  
      
      --Insert for prepack sales PREPALINOUTSALES
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND EXISTS(SELECT * FROM ITESTO INNER JOIN PREPALINOUT ON ITESTO.ISTRECNO = PREPALINOUT.PALINBULKISTREC INNER JOIN PREPALINOUTSALES ON PREPALINOUT.PREPALRECNO = PREPALINOUTSALES.PREPALINOUTRECNO WHERE AUTOCOSTSTODO.LITITENO = ITESTO.ISTLITNO AND PREPALINOUTSALES.DELPRCRECNO = DPRRECS_IN(INDX))) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP;
      
      --Insert for bulk allocations DELTOALL
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND EXISTS(SELECT * FROM DELPRICE INNER JOIN DELTOALL ON DELTOALL.DALTYPERECNO = DELPRICE.DPRDELRECNO AND DELTOALL.DALRECORDTYPE = 1 INNER JOIN PALNOLOC ON PALNOLOC.PALLOCALLNO = DELTOALL.DALALLOCNO INNER JOIN ITESTO ON ITESTO.ISTRECNO = PALNOLOC.PALLOCISTRECNO WHERE AUTOCOSTSTODO.LITITENO = ITESTO.ISTLITNO AND DELPRICE.DPRRECNO = DPRRECS_IN(INDX))) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP;      
      
      --Insert for prepack allocations DELTOALL
      FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND EXISTS(SELECT * FROM DELPRICE INNER JOIN DELTOALL ON DELTOALL.DALTYPERECNO = DELPRICE.DPRDELRECNO AND DELTOALL.DALRECORDTYPE = 1 INNER JOIN PALNOLOC ON PALNOLOC.PALLOCALLNO = DELTOALL.DALALLOCNO INNER JOIN PREPALINOUT ON PREPALINOUT.PPPALLOCRECNOOUT = PALNOLOC.PALLOCRECNO INNER JOIN ITESTO ON ITESTO.ISTRECNO = PREPALINOUT.PALINBULKISTREC WHERE AUTOCOSTSTODO.LITITENO = ITESTO.ISTLITNO AND DELPRICE.DPRRECNO = DPRRECS_IN(INDX))) LOOP
        INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
        VALUES(AUTOCOST_ITR.AUTOCOSTREC);
        COMMIT;
      END LOOP;
    END LOOP;
       
  EXCEPTION
    WHEN OTHERS THEN  
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;                 
  END PRIORITISE_DPRRECS;
  
  PROCEDURE PRIORITISE_DPR(DPRRECNO_IN AUTOCOSTSTODO.DPRRECNO%TYPE)
  IS
  BEGIN
    PRIORITISE_DPRRECS(RECORD_NUMBERS(DPRRECNO_IN));
  END PRIORITISE_DPR;  
  
  PROCEDURE PRIORITISE_SALOFF(SALOFFNO_IN SALOFFNO.SALOFFNO%TYPE)
  IS
  BEGIN
    RESET_DEAD_SESSIONS();
    EMPTY_AUTOCOSTS_PEND();
  
    FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG) AND NOT EXISTS(SELECT * FROM AUTOCOSTS_PEND WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC) AND AUTOCOSTSTODO.SALOFFNO = NVL(NULLIF(SALOFFNO_IN, CONST.C_ALL), AUTOCOSTSTODO.SALOFFNO)) LOOP
      --Insert for sales office
      INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
      VALUES(AUTOCOST_ITR.AUTOCOSTREC);
      COMMIT;  
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP; 
  END PRIORITISE_SALOFF;
  
  PROCEDURE PRIORITISE_ALL
  IS 
  BEGIN
    PRIORITISE_SALOFF(CONST.C_ALL);
  END PRIORITISE_ALL;
  
  PROCEDURE PROCESS_ALL
  IS
  BEGIN
    RESET_DEAD_SESSIONS();
    EMPTY_AUTOCOSTS_PEND();
  
    FOR AUTOCOST_ITR IN(SELECT AUTOCOSTSTODO.AUTOCOSTREC FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.PROCESSSTAT IN(PROCESSTODO, PROCESSINPROG)) LOOP
      --Insert all
      INSERT INTO AUTOCOSTS_PEND(AUTOCOSTREC)
      VALUES(AUTOCOST_ITR.AUTOCOSTREC);
      COMMIT;  
    END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;     
  END PROCESS_ALL;
  
  PROCEDURE EMPTY_AUTOCOSTS_PROCESS
  IS
  BEGIN
    FOR AUTOCOST_ITR IN(SELECT AUTOCOSTREC FROM AUTOCOSTS_PROCESS) LOOP
      DELETE FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.AUTOCOSTREC = AUTOCOST_ITR.AUTOCOSTREC;
      COMMIT;
    END LOOP;
  END EMPTY_AUTOCOSTS_PROCESS;  
  
  PROCEDURE SET_IN_PROGRESS    
  IS
    AUTOCOSTS_PROCESS_REC     AUTOCOSTS_PROCESS%ROWTYPE;
    
    CURSOR RECORDS_TO_PROCESS_CUR
    IS
    SELECT  AUTOCOSTSTODO.AUTOCOSTREC,
            AUTOCOSTSTODO.LITITENO,
            AUTOCOSTSTODO.DPRRECNO,
            AUTOCOSTSTODO.WRITEPREPALINOUT,
            AUTOCOSTSTODO.DOAUTCOSTADHOCCHGS,
            AUTOCOSTSTODO.TRANSFERATCOST,
            AUTOCOSTSTODO.CALCSALESCOSTDPRTABLE,
            AUTOCOSTSTODO.TRANSFERADDCHGSAPP,
            AUTOCOSTSTODO.CALCULATEGOODSCOST,
            AUTOCOSTSTODO.LOTPROFITABILITY,
            AUTOCOSTSTODO.RECALCULATEWOCOSTS,
            AUTOCOSTSTODO.GETSALES
    FROM AUTOCOSTSTODO
    WHERE AUTOCOSTSTODO.SESSIONNO = G_SID;
  BEGIN   
    FOR AUTOCOST_ITR IN(SELECT AUTOCOSTS_PEND.AUTOCOSTREC FROM AUTOCOSTS_PEND INNER JOIN AUTOCOSTSTODO ON AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC WHERE AUTOCOSTSTODO.SESSIONNO IS NULL AND ROWNUM < G_CHUNKSIZE ORDER BY AUTOCOSTREC) LOOP
      UPDATE AUTOCOSTSTODO
      SET AUTOCOSTSTODO.PROCESSSTAT = PROCESSINPROG,
          AUTOCOSTSTODO.SESSIONNO = G_SID
      WHERE AUTOCOSTSTODO.AUTOCOSTREC = AUTOCOST_ITR.AUTOCOSTREC
        AND AUTOCOSTSTODO.PROCESSSTAT = PROCESSTODO
        AND AUTOCOSTSTODO.SESSIONNO IS NULL;      
      COMMIT;
    END LOOP;
    
    EMPTY_AUTOCOSTS_PROCESS();
    
    FOR AUTOCOST_ITR IN RECORDS_TO_PROCESS_CUR LOOP
      AUTOCOSTS_PROCESS_REC := NULL;
      AUTOCOSTS_PROCESS_REC.AUTOCOSTREC := AUTOCOST_ITR.AUTOCOSTREC;
      AUTOCOSTS_PROCESS_REC.LITITENO := AUTOCOST_ITR.LITITENO;
      AUTOCOSTS_PROCESS_REC.DPRRECNO := AUTOCOST_ITR.DPRRECNO;
      AUTOCOSTS_PROCESS_REC.WRITEPREPALINOUT := AUTOCOST_ITR.WRITEPREPALINOUT;
      AUTOCOSTS_PROCESS_REC.DOAUTCOSTADHOCCHGS := AUTOCOST_ITR.DOAUTCOSTADHOCCHGS;
      AUTOCOSTS_PROCESS_REC.TRANSFERATCOST := AUTOCOST_ITR.TRANSFERATCOST;
      AUTOCOSTS_PROCESS_REC.CALCSALESCOSTDPRTABLE := AUTOCOST_ITR.CALCSALESCOSTDPRTABLE;
      AUTOCOSTS_PROCESS_REC.TRANSFERADDCHGSAPP := AUTOCOST_ITR.TRANSFERADDCHGSAPP;
      AUTOCOSTS_PROCESS_REC.CALCULATEGOODSCOST := AUTOCOST_ITR.CALCULATEGOODSCOST;
      AUTOCOSTS_PROCESS_REC.LOTPROFITABILITY := AUTOCOST_ITR.LOTPROFITABILITY;
      AUTOCOSTS_PROCESS_REC.RECALCULATEWOCOSTS := AUTOCOST_ITR.RECALCULATEWOCOSTS;
      AUTOCOSTS_PROCESS_REC.GETSALES := AUTOCOST_ITR.GETSALES;

      INSERT INTO AUTOCOSTS_PROCESS
      VALUES AUTOCOSTS_PROCESS_REC;
      COMMIT;
      
      FT_PK_DGP.ENQUEUE_DGPDPRSTODO(AUTOCOST_ITR.DPRRECNO);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;      
  END SET_IN_PROGRESS;
  
  PROCEDURE REMOVE_RECS
  IS
  BEGIN     
    FOR AUTOCOST_ITR IN(SELECT AUTOCOSTS_PROCESS.AUTOCOSTREC FROM AUTOCOSTS_PROCESS) LOOP
      DELETE FROM AUTOCOSTSTODO
      WHERE AUTOCOSTSTODO.AUTOCOSTREC = AUTOCOST_ITR.AUTOCOSTREC;
      COMMIT;
    END LOOP;
    
    EMPTY_AUTOCOSTS_PROCESS();
    
    -- Other session may have cleared the records
    FOR AUTOCOST_ITR IN(SELECT AUTOCOSTS_PEND.AUTOCOSTREC FROM AUTOCOSTS_PEND WHERE NOT EXISTS (SELECT * FROM AUTOCOSTSTODO WHERE AUTOCOSTSTODO.AUTOCOSTREC = AUTOCOSTS_PEND.AUTOCOSTREC)) LOOP
      DELETE FROM AUTOCOSTS_PEND
      WHERE AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOST_ITR.AUTOCOSTREC; 
      COMMIT;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;   
  END REMOVE_RECS;
  
  FUNCTION PENDING_REC_CNT_SESSION RETURN INTEGER
  IS
    RET_COUNT     INTEGER := 0;
  BEGIN
    SELECT COUNT(*) 
    INTO RET_COUNT
    FROM AUTOCOSTS_PROCESS;
    
    RETURN RET_COUNT;
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;     
  END PENDING_REC_CNT_SESSION;
  
  FUNCTION PENDING_REC_CNT_OTHER RETURN INTEGER
  IS
    RET_COUNT     INTEGER := 0;
  BEGIN  
    SELECT COUNT(*) 
    INTO RET_COUNT
    FROM AUTOCOSTS_PEND
    INNER JOIN AUTOCOSTSTODO
      ON AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC
    WHERE AUTOCOSTSTODO.PROCESSSTAT = PROCESSINPROG
      AND AUTOCOSTSTODO.SESSIONNO <>  G_SID;
    
    RETURN RET_COUNT;
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;     
  END PENDING_REC_CNT_OTHER;  

  PROCEDURE RESET_DEAD_SESSIONS 
  IS
    ACTIVE_SID    RECORD_NUMBERS := FT_PK_SESSION_UTILS.LIST_ACTIVE_SID();
  BEGIN
    FOR AUTOCOST_ITR IN(SELECT DEADSESSIONS.AUTOCOSTREC FROM AUTOCOSTSTODO DEADSESSIONS WHERE DEADSESSIONS.SESSIONNO NOT IN(SELECT * FROM TABLE(ACTIVE_SID)) ORDER BY 1) LOOP
      UPDATE AUTOCOSTSTODO
      SET PROCESSSTAT = PROCESSTODO,
          SESSIONNO = NULL
      WHERE AUTOCOSTREC = AUTOCOST_ITR.AUTOCOSTREC;
      COMMIT;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;     
  END RESET_DEAD_SESSIONS; 
    
  PROCEDURE TRANSFORM_LOTS_TO_DPR
  IS
    AUTOCOSTS_PROCESS_REC     AUTOCOSTS_PROCESS%ROWTYPE;
    
    CURSOR BULK_LOTS_CUR
    IS
    SELECT  MIN(AUTOCOSTS_PROCESS.AUTOCOSTREC) AS AUTOCOSTREC,
            DELTOIST.DISDPRRECNO AS DPRRECNO,
            MAX(AUTOCOSTS_PROCESS.WRITEPREPALINOUT) AS WRITEPREPALINOUT,
            MAX(AUTOCOSTS_PROCESS.DOAUTCOSTADHOCCHGS) AS DOAUTCOSTADHOCCHGS,
            MAX(AUTOCOSTS_PROCESS.TRANSFERATCOST) AS TRANSFERATCOST,
            MAX(AUTOCOSTS_PROCESS.CALCSALESCOSTDPRTABLE) AS CALCSALESCOSTDPRTABLE,
            MAX(AUTOCOSTS_PROCESS.TRANSFERADDCHGSAPP) AS TRANSFERADDCHGSAPP,
            MAX(AUTOCOSTS_PROCESS.CALCULATEGOODSCOST) AS CALCULATEGOODSCOST,
            MAX(AUTOCOSTS_PROCESS.LOTPROFITABILITY) AS LOTPROFITABILITY,
            MAX(AUTOCOSTS_PROCESS.RECALCULATEWOCOSTS) AS RECALCULATEWOCOSTS,
            MAX(AUTOCOSTS_PROCESS.GETSALES) AS GETSALES 
    FROM AUTOCOSTS_PROCESS
    INNER JOIN ITESTO
    	ON AUTOCOSTS_PROCESS.LITITENO = ITESTO.ISTLITNO
    INNER JOIN DELTOIST
      ON DELTOIST.DISISTRECNO = ITESTO.ISTRECNO
    WHERE NOT EXISTS(SELECT * FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.DPRRECNO = DELTOIST.DISDPRRECNO)
    GROUP BY DELTOIST.DISDPRRECNO;  
    
    CURSOR PREPACK_LOTS_CUR
    IS
    SELECT  MIN(AUTOCOSTS_PROCESS.AUTOCOSTREC) AS AUTOCOSTREC,
            PREPALINOUTSALES.DELPRCRECNO AS DPRRECNO,
            MAX(AUTOCOSTS_PROCESS.WRITEPREPALINOUT) AS WRITEPREPALINOUT,
            MAX(AUTOCOSTS_PROCESS.DOAUTCOSTADHOCCHGS) AS DOAUTCOSTADHOCCHGS,
            MAX(AUTOCOSTS_PROCESS.TRANSFERATCOST) AS TRANSFERATCOST,
            MAX(AUTOCOSTS_PROCESS.CALCSALESCOSTDPRTABLE) AS CALCSALESCOSTDPRTABLE,
            MAX(AUTOCOSTS_PROCESS.TRANSFERADDCHGSAPP) AS TRANSFERADDCHGSAPP,
            MAX(AUTOCOSTS_PROCESS.CALCULATEGOODSCOST) AS CALCULATEGOODSCOST,
            MAX(AUTOCOSTS_PROCESS.LOTPROFITABILITY) AS LOTPROFITABILITY,
            MAX(AUTOCOSTS_PROCESS.RECALCULATEWOCOSTS) AS RECALCULATEWOCOSTS,
            MAX(AUTOCOSTS_PROCESS.GETSALES) AS GETSALES
    FROM AUTOCOSTS_PROCESS
    INNER JOIN ITESTO ITESTO
      ON AUTOCOSTS_PROCESS.LITITENO = ITESTO.ISTLITNO
    INNER JOIN PREPALINOUT
      ON ITESTO.ISTRECNO = PREPALINOUT.PALINBULKISTREC
    INNER JOIN PREPALINOUTSALES
      ON PREPALINOUT.PREPALRECNO = PREPALINOUTSALES.PREPALINOUTRECNO
    WHERE NOT EXISTS(SELECT * FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.DPRRECNO = PREPALINOUTSALES.DELPRCRECNO)
    GROUP BY PREPALINOUTSALES.DELPRCRECNO;    
  BEGIN   
    FOR AUTOCOST_ITR IN BULK_LOTS_CUR LOOP
      AUTOCOSTS_PROCESS_REC := NULL;
      AUTOCOSTS_PROCESS_REC.AUTOCOSTREC := AUTOCOST_ITR.AUTOCOSTREC;
      AUTOCOSTS_PROCESS_REC.DPRRECNO := AUTOCOST_ITR.DPRRECNO;
      AUTOCOSTS_PROCESS_REC.WRITEPREPALINOUT := AUTOCOST_ITR.WRITEPREPALINOUT;
      AUTOCOSTS_PROCESS_REC.DOAUTCOSTADHOCCHGS := AUTOCOST_ITR.DOAUTCOSTADHOCCHGS;
      AUTOCOSTS_PROCESS_REC.TRANSFERATCOST := AUTOCOST_ITR.TRANSFERATCOST;
      AUTOCOSTS_PROCESS_REC.CALCSALESCOSTDPRTABLE := AUTOCOST_ITR.CALCSALESCOSTDPRTABLE;
      AUTOCOSTS_PROCESS_REC.TRANSFERADDCHGSAPP := AUTOCOST_ITR.TRANSFERADDCHGSAPP;
      AUTOCOSTS_PROCESS_REC.CALCULATEGOODSCOST := AUTOCOST_ITR.CALCULATEGOODSCOST;
      AUTOCOSTS_PROCESS_REC.LOTPROFITABILITY := AUTOCOST_ITR.LOTPROFITABILITY;
      AUTOCOSTS_PROCESS_REC.RECALCULATEWOCOSTS := AUTOCOST_ITR.RECALCULATEWOCOSTS;
      AUTOCOSTS_PROCESS_REC.GETSALES := AUTOCOST_ITR.GETSALES;      
      
      INSERT INTO AUTOCOSTS_PROCESS
      VALUES AUTOCOSTS_PROCESS_REC;
      COMMIT;      
      
      FT_PK_DGP.ENQUEUE_DGPDPRSTODO(AUTOCOST_ITR.DPRRECNO);
    END LOOP;
     
    FOR AUTOCOST_ITR IN PREPACK_LOTS_CUR LOOP
      AUTOCOSTS_PROCESS_REC := NULL;
      AUTOCOSTS_PROCESS_REC.AUTOCOSTREC := AUTOCOST_ITR.AUTOCOSTREC;
      AUTOCOSTS_PROCESS_REC.DPRRECNO := AUTOCOST_ITR.DPRRECNO;
      AUTOCOSTS_PROCESS_REC.WRITEPREPALINOUT := AUTOCOST_ITR.WRITEPREPALINOUT;
      AUTOCOSTS_PROCESS_REC.DOAUTCOSTADHOCCHGS := AUTOCOST_ITR.DOAUTCOSTADHOCCHGS;
      AUTOCOSTS_PROCESS_REC.TRANSFERATCOST := AUTOCOST_ITR.TRANSFERATCOST;
      AUTOCOSTS_PROCESS_REC.CALCSALESCOSTDPRTABLE := AUTOCOST_ITR.CALCSALESCOSTDPRTABLE;
      AUTOCOSTS_PROCESS_REC.TRANSFERADDCHGSAPP := AUTOCOST_ITR.TRANSFERADDCHGSAPP;
      AUTOCOSTS_PROCESS_REC.CALCULATEGOODSCOST := AUTOCOST_ITR.CALCULATEGOODSCOST;
      AUTOCOSTS_PROCESS_REC.LOTPROFITABILITY := AUTOCOST_ITR.LOTPROFITABILITY;
      AUTOCOSTS_PROCESS_REC.RECALCULATEWOCOSTS := AUTOCOST_ITR.RECALCULATEWOCOSTS;
      AUTOCOSTS_PROCESS_REC.GETSALES := AUTOCOST_ITR.GETSALES;      
      
      INSERT INTO AUTOCOSTS_PROCESS
      VALUES AUTOCOSTS_PROCESS_REC;
      COMMIT;      
      
      FT_PK_DGP.ENQUEUE_DGPDPRSTODO(AUTOCOST_ITR.DPRRECNO);
    END LOOP;    
       
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;     
  END TRANSFORM_LOTS_TO_DPR;
  
  PROCEDURE INCLUDE_ALL_LOTS
  IS
    AUTOCOSTS_PROCESS_REC     AUTOCOSTS_PROCESS%ROWTYPE;
    
    CURSOR BULK_LOTS_CUR
    IS
    SELECT  MIN(AUTOCOSTS_PROCESS.AUTOCOSTREC) AS AUTOCOSTREC,
            ITESTO.ISTLITNO AS LITITENO,
            MAX(AUTOCOSTS_PROCESS.WRITEPREPALINOUT) AS WRITEPREPALINOUT,
            MAX(AUTOCOSTS_PROCESS.DOAUTCOSTADHOCCHGS) AS DOAUTCOSTADHOCCHGS,
            MAX(AUTOCOSTS_PROCESS.TRANSFERATCOST) AS TRANSFERATCOST,
            MAX(AUTOCOSTS_PROCESS.CALCSALESCOSTDPRTABLE) AS CALCSALESCOSTDPRTABLE,
            MAX(AUTOCOSTS_PROCESS.TRANSFERADDCHGSAPP) AS TRANSFERADDCHGSAPP,
            MAX(AUTOCOSTS_PROCESS.CALCULATEGOODSCOST) AS CALCULATEGOODSCOST,
            MAX(AUTOCOSTS_PROCESS.LOTPROFITABILITY) AS LOTPROFITABILITY,
            MAX(AUTOCOSTS_PROCESS.RECALCULATEWOCOSTS) AS RECALCULATEWOCOSTS,
            MAX(AUTOCOSTS_PROCESS.GETSALES) AS GETSALES
    FROM AUTOCOSTS_PROCESS
    INNER JOIN DELTOIST
      ON AUTOCOSTS_PROCESS.DPRRECNO = DELTOIST.DISDPRRECNO
    INNER JOIN ITESTO
      ON DELTOIST.DISISTRECNO = ITESTO.ISTRECNO
    WHERE NOT EXISTS(SELECT * FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.LITITENO = ITESTO.ISTLITNO)
      AND ITESTO.ISTPONO IS NOT NULL
    GROUP BY ITESTO.ISTLITNO;
    
    CURSOR PREPACK_LOTS_CUR
    IS
    SELECT	MIN(AUTOCOSTS_PROCESS.AUTOCOSTREC) AS AUTOCOSTREC,
            ITESTO.ISTLITNO AS LITITENO,
            MAX(AUTOCOSTS_PROCESS.WRITEPREPALINOUT) AS WRITEPREPALINOUT,
            MAX(AUTOCOSTS_PROCESS.DOAUTCOSTADHOCCHGS) AS DOAUTCOSTADHOCCHGS,
            MAX(AUTOCOSTS_PROCESS.TRANSFERATCOST) AS TRANSFERATCOST,
            MAX(AUTOCOSTS_PROCESS.CALCSALESCOSTDPRTABLE) AS CALCSALESCOSTDPRTABLE,
            MAX(AUTOCOSTS_PROCESS.TRANSFERADDCHGSAPP) AS TRANSFERADDCHGSAPP,
            MAX(AUTOCOSTS_PROCESS.CALCULATEGOODSCOST) AS CALCULATEGOODSCOST,
            MAX(AUTOCOSTS_PROCESS.LOTPROFITABILITY) AS LOTPROFITABILITY,
            MAX(AUTOCOSTS_PROCESS.RECALCULATEWOCOSTS) AS RECALCULATEWOCOSTS,
            MAX(AUTOCOSTS_PROCESS.GETSALES) AS GETSALES
    FROM AUTOCOSTS_PROCESS
    INNER JOIN PREPALINOUTSALES
      ON AUTOCOSTS_PROCESS.DPRRECNO = PREPALINOUTSALES.DELPRCRECNO
    INNER JOIN PREPALINOUT
      ON PREPALINOUTSALES.PREPALINOUTRECNO = PREPALINOUT.PREPALRECNO
    INNER JOIN ITESTO 
      ON PREPALINOUT.PALINBULKISTREC = ITESTO.ISTRECNO
    WHERE NOT EXISTS(SELECT * FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.LITITENO = ITESTO.ISTLITNO)
    GROUP BY ITESTO.ISTLITNO;
  BEGIN
    FOR AUTOCOST_ITR IN BULK_LOTS_CUR LOOP
      AUTOCOSTS_PROCESS_REC := NULL;
      AUTOCOSTS_PROCESS_REC.AUTOCOSTREC := AUTOCOST_ITR.AUTOCOSTREC;
      AUTOCOSTS_PROCESS_REC.LITITENO := AUTOCOST_ITR.LITITENO;
      AUTOCOSTS_PROCESS_REC.WRITEPREPALINOUT := AUTOCOST_ITR.WRITEPREPALINOUT;
      AUTOCOSTS_PROCESS_REC.DOAUTCOSTADHOCCHGS := AUTOCOST_ITR.DOAUTCOSTADHOCCHGS;
      AUTOCOSTS_PROCESS_REC.TRANSFERATCOST := AUTOCOST_ITR.TRANSFERATCOST;
      AUTOCOSTS_PROCESS_REC.CALCSALESCOSTDPRTABLE := AUTOCOST_ITR.CALCSALESCOSTDPRTABLE;
      AUTOCOSTS_PROCESS_REC.TRANSFERADDCHGSAPP := AUTOCOST_ITR.TRANSFERADDCHGSAPP;
      AUTOCOSTS_PROCESS_REC.CALCULATEGOODSCOST := AUTOCOST_ITR.CALCULATEGOODSCOST;
      AUTOCOSTS_PROCESS_REC.LOTPROFITABILITY := AUTOCOST_ITR.LOTPROFITABILITY;
      AUTOCOSTS_PROCESS_REC.RECALCULATEWOCOSTS := AUTOCOST_ITR.RECALCULATEWOCOSTS;
      AUTOCOSTS_PROCESS_REC.GETSALES := AUTOCOST_ITR.GETSALES;      
      
      INSERT INTO AUTOCOSTS_PROCESS
      VALUES AUTOCOSTS_PROCESS_REC;
      COMMIT;      
    END LOOP;

    FOR AUTOCOST_ITR IN PREPACK_LOTS_CUR LOOP
      AUTOCOSTS_PROCESS_REC := NULL;
      AUTOCOSTS_PROCESS_REC.AUTOCOSTREC := AUTOCOST_ITR.AUTOCOSTREC;
      AUTOCOSTS_PROCESS_REC.LITITENO := AUTOCOST_ITR.LITITENO;
      AUTOCOSTS_PROCESS_REC.WRITEPREPALINOUT := AUTOCOST_ITR.WRITEPREPALINOUT;
      AUTOCOSTS_PROCESS_REC.DOAUTCOSTADHOCCHGS := AUTOCOST_ITR.DOAUTCOSTADHOCCHGS;
      AUTOCOSTS_PROCESS_REC.TRANSFERATCOST := AUTOCOST_ITR.TRANSFERATCOST;
      AUTOCOSTS_PROCESS_REC.CALCSALESCOSTDPRTABLE := AUTOCOST_ITR.CALCSALESCOSTDPRTABLE;
      AUTOCOSTS_PROCESS_REC.TRANSFERADDCHGSAPP := AUTOCOST_ITR.TRANSFERADDCHGSAPP;
      AUTOCOSTS_PROCESS_REC.CALCULATEGOODSCOST := AUTOCOST_ITR.CALCULATEGOODSCOST;
      AUTOCOSTS_PROCESS_REC.LOTPROFITABILITY := AUTOCOST_ITR.LOTPROFITABILITY;
      AUTOCOSTS_PROCESS_REC.RECALCULATEWOCOSTS := AUTOCOST_ITR.RECALCULATEWOCOSTS;
      AUTOCOSTS_PROCESS_REC.GETSALES := AUTOCOST_ITR.GETSALES;      
      
      INSERT INTO AUTOCOSTS_PROCESS
      VALUES AUTOCOSTS_PROCESS_REC;
      COMMIT;      
    END LOOP;    
		   
   EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;     
  END INCLUDE_ALL_LOTS;

  -- Used when another session is taking too long to process my remaining records
  PROCEDURE OVERRIDE_SESSION
  IS
    AUTOCOSTS_PROCESS_REC     AUTOCOSTS_PROCESS%ROWTYPE;
    
    CURSOR RECORDS_TO_PROCESS_CUR
    IS
    SELECT  AUTOCOSTSTODO.AUTOCOSTREC,
            AUTOCOSTSTODO.LITITENO,
            AUTOCOSTSTODO.DPRRECNO,
            AUTOCOSTSTODO.WRITEPREPALINOUT,
            AUTOCOSTSTODO.DOAUTCOSTADHOCCHGS,
            AUTOCOSTSTODO.TRANSFERATCOST,
            AUTOCOSTSTODO.CALCSALESCOSTDPRTABLE,
            AUTOCOSTSTODO.TRANSFERADDCHGSAPP,
            AUTOCOSTSTODO.CALCULATEGOODSCOST,
            AUTOCOSTSTODO.LOTPROFITABILITY,
            AUTOCOSTSTODO.RECALCULATEWOCOSTS,
            AUTOCOSTSTODO.GETSALES
    FROM AUTOCOSTSTODO
    INNER JOIN AUTOCOSTS_PEND
      ON AUTOCOSTS_PEND.AUTOCOSTREC = AUTOCOSTSTODO.AUTOCOSTREC;
  BEGIN
    EMPTY_AUTOCOSTS_PROCESS();
    
    FOR AUTOCOST_ITR IN RECORDS_TO_PROCESS_CUR LOOP
      AUTOCOSTS_PROCESS_REC := NULL;
      AUTOCOSTS_PROCESS_REC.AUTOCOSTREC := AUTOCOST_ITR.AUTOCOSTREC;
      AUTOCOSTS_PROCESS_REC.LITITENO := AUTOCOST_ITR.LITITENO;
      AUTOCOSTS_PROCESS_REC.DPRRECNO := AUTOCOST_ITR.DPRRECNO;
      AUTOCOSTS_PROCESS_REC.WRITEPREPALINOUT := AUTOCOST_ITR.WRITEPREPALINOUT;
      AUTOCOSTS_PROCESS_REC.DOAUTCOSTADHOCCHGS := AUTOCOST_ITR.DOAUTCOSTADHOCCHGS;
      AUTOCOSTS_PROCESS_REC.TRANSFERATCOST := AUTOCOST_ITR.TRANSFERATCOST;
      AUTOCOSTS_PROCESS_REC.CALCSALESCOSTDPRTABLE := AUTOCOST_ITR.CALCSALESCOSTDPRTABLE;
      AUTOCOSTS_PROCESS_REC.TRANSFERADDCHGSAPP := AUTOCOST_ITR.TRANSFERADDCHGSAPP;
      AUTOCOSTS_PROCESS_REC.CALCULATEGOODSCOST := AUTOCOST_ITR.CALCULATEGOODSCOST;
      AUTOCOSTS_PROCESS_REC.LOTPROFITABILITY := AUTOCOST_ITR.LOTPROFITABILITY;
      AUTOCOSTS_PROCESS_REC.RECALCULATEWOCOSTS := AUTOCOST_ITR.RECALCULATEWOCOSTS;
      AUTOCOSTS_PROCESS_REC.GETSALES := AUTOCOST_ITR.GETSALES;

      INSERT INTO AUTOCOSTS_PROCESS
      VALUES AUTOCOSTS_PROCESS_REC;
      COMMIT;
      
      FT_PK_DGP.ENQUEUE_DGPDPRSTODO(AUTOCOST_ITR.DPRRECNO);
    END LOOP;    
    
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;  
  END OVERRIDE_SESSION;
            
END FT_PK_AUTOCOSTING ;
/
