create or replace PACKAGE BODY FT_PK_SALES AS

  cVersionControlNo   VARCHAR2(12) := '1.0.5'; -- Current Version Number


  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
         RETURN cSpecVersionControlNo;
    ELSE  
        RETURN cVersionControlNo;
    END IF;        
        
  END CURRENTVERSION;

  PROCEDURE DELPRICE_NETTVALUE(IN_DPRRECNO IN NUMBER) AS

    V_CONT          NUMBER(1) := 1;

  BEGIN
    IF V_CONT =1 THEN
    BEGIN
        UPDATE DELPRICE
        SET DELNETTVALUE = DELPRICE_CALCNETTVALUE(DELPRICE.DPRRECNO)
            WHERE DPRRECNO = IN_DPRRECNO
            AND NVL(DELINVSTATUS,0) < 10   -- not invoiced 
            ;
            COMMIT;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                NULL;
                RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES - DELPRICE_NETTVALUE() - VALUE' ||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);

        END;

    END IF;

    IF V_CONT =1 THEN
    BEGIN
            UPDATE DELPRICE
                SET DELEURONETTVAL = DELNETTVALUE,
                DELBASENETTVAL = DELNETTVALUE,
                DELTOEURORATE   = (SELECT RATRATETOEURO FROM ACCCURRRATE, DELDET, DELHED
                                    WHERE DELPRICE.DPRDELRECNO = DELDET.DELRECNO
                                    AND DELDET.DELDLVORDNO =  DELHED.DLVORDNO
                                    AND DELHED.DLVCURRECNO = ACCCURRRATE.RATCURNO
                                    AND RATUSEFOR =  1),
                DELTOBASERATE = (SELECT RATRATETOBASE FROM ACCCURRRATE, DELDET, DELHED
                                    WHERE DELPRICE.DPRDELRECNO = DELDET.DELRECNO
                                    AND DELDET.DELDLVORDNO =  DELHED.DLVORDNO
                                    AND DELHED.DLVCURRECNO = ACCCURRRATE.RATCURNO
                                    AND RATUSEFOR =  1)
                WHERE DPRRECNO = IN_DPRRECNO;
                COMMIT;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                NULL;
                RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES - DELPRICE_NETTVALUE() - ALT CURRENCIES' ||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);

        END;
        
    END IF;

  END DELPRICE_NETTVALUE;

  
  FUNCTION DELPRICE_CALCNETTVALUE(IN_DPRRECNO IN NUMBER) RETURN DELPRICE.DELNETTVALUE%TYPE AS
  PRAGMA AUTONOMOUS_TRANSACTION;      
    V_CONT              NUMBER(1) := 1;
    V_DELNETTVALUE      DELPRICE.DELNETTVALUE%TYPE NULL;
     
  BEGIN

    IF V_CONT =1 THEN
    BEGIN
        SELECT           
            (
            CASE WHEN NVL(DELFREEOFCHG,0) = 1
            THEN
                NULL
            ELSE
                ROUND(
                    (CASE WHEN (NVL(DPRISPRICEADJONLY, 0) <> 0)                    
                    THEN
                        (CASE WHEN (NVL(ADJBY, 0) > 1)
                        THEN
                            (NVL(DELPRCWEIGHT,0) * NVL(DELPRICE,0))
                         ELSE
                            (NVL(DELPRCQTY,0) * NVL(DELPRICE,0))
                         END)                         
                    ELSE                
                        (CASE WHEN
                            (SELECT NVL(DELPRICEPER,0) FROM DELDET WHERE DELDET.DELRECNO = DELPRICE.DPRDELRECNO) = 1
                            OR 
                            (SELECT NVL(DELPRICEPER,0) -  NVL(DELQTYPER,0) FROM DELDET WHERE DELDET.DELRECNO = DELPRICE.DPRDELRECNO) = 0 -- IF THE PRICE PER AND SELL PER ARE THE SAME WE DO NOT USE THE MULTIPLER AS THE DELPRCQTY IS THE QTY                            
                        THEN
                            (NVL(DELPRCQTY,0) * NVL(DELPRICE,0))
                        ELSE
                            (CASE WHEN
                                (SELECT NVL(DELPRICEPER,0) FROM DELDET WHERE DELDET.DELRECNO = DELPRICE.DPRDELRECNO) = 2
                                AND
                                ABS(NVL(DELPRCWEIGHT,0)) > 0.009
                            THEN
                                (NVL(DELPRICE,0) * NVL(DELPRCWEIGHT,0)) -- ; this was introduced by ash for sites that wanted to do returns at a different weight than the original line
                            ELSE
                                (NVL(DELPRICE,0) * NVL(DELPRCQTY,0)  * NVL((SELECT DELNETTWEIGHT FROM DELDET WHERE DELDET.DELRECNO = DELPRICE.DPRDELRECNO),0))
                            END)
                        END)
                    END)
                ,2)
            END)
            INTO V_DELNETTVALUE 
            FROM DELPRICE 
            WHERE DPRRECNO = IN_DPRRECNO;
        EXCEPTION              
            WHEN NO_DATA_FOUND THEN
                NULL;                                                 
            WHEN OTHERS THEN
                NULL;                
                RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -BSDL_PK_SALES - DELPRICE_CALCNETTVALUE() - VALUE' ||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);
                            
        END;
     
    END IF;
    
    RETURN V_DELNETTVALUE    ;        
           
    
  END DELPRICE_CALCNETTVALUE;

  PROCEDURE DELPRICE_CALCVATFIGURES(IN_DPRRECNO IN NUMBER) AS
        V_CONT          NUMBER(1) := 1;

        V_ACTCSTCODE    ORDERS.ACTCSTCODE%TYPE;
        V_DLVSTKLOC     DELHED.DLVSTKLOC%TYPE;
        V_DLVSALOFFNO   DELHED.DLVSALOFFNO%TYPE;
        V_DELPRCPRDNO   DELDET.DELPRCPRDNO%TYPE;
        V_DLVDLTRECNO   DELHED.DLVDLTRECNO%TYPE;
        V_DELNETTVALUE  DELPRICE.DELNETTVALUE%TYPE;
        V_DISCAMT       FLOAT;
        V_DELFREEOFCHG  DELPRICE.DELFREEOFCHG%TYPE;
        V_ORCSTCODE     ORDERS.ORDCSTCODE%TYPE;
        V_DLVRELINV     DELHED.DLVRELINV%TYPE;
        V_DLVTRANIND    DELHED.DLVTRANIND%TYPE;
        V_DELSTATUS     DELDET.DELSTATUS%TYPE;
        V_DELINVSTATUS  DELPRICE.DELINVSTATUS%TYPE;

        V_VATRECNO    DELPRICE.DELVATRECNO%TYPE := NULL;
        V_VATRATE1    DELPRICE.DELVATRATE%TYPE := NULL;
        V_VATRATE2    DELPRICE.DELVATRATE2%TYPE := NULL;
        V_VATAMOUNT   DELPRICE.DELVATVALUE%TYPE := NULL;

  BEGIN
  -- GET DELIVERY DETAILS
    IF V_CONT = 1 THEN
        BEGIN
            SELECT ORDERS.ACTCSTCODE,  DELHED.DLVSTKLOC, DELHED.DLVSALOFFNO, DELDET.DELPRCPRDNO, DELHED.DLVDLTRECNO, DELPRICE.DELNETTVALUE, DELPRICE.DELFREEOFCHG,
                NVL((SELECT SUM(NVL(ICHAPPAMT,0)) FROM ITECHG WHERE DPRRECNO = DELPRICE.DPRRECNO AND CTYNO = 97),0) DISCAMT,
                ORDERS.ORDCSTCODE, DELHED.DLVRELINV, DELHED.DLVTRANIND, DELDET.DELSTATUS, DELPRICE.DELINVSTATUS
            INTO V_ACTCSTCODE, V_DLVSTKLOC, V_DLVSALOFFNO, V_DELPRCPRDNO,V_DLVDLTRECNO, V_DELNETTVALUE, V_DELFREEOFCHG,
                V_DISCAMT,
                 V_ORCSTCODE, V_DLVRELINV, V_DLVTRANIND, V_DELSTATUS, V_DELINVSTATUS
            FROM ORDERS, DELHED, DELDET, DELPRICE
            WHERE ORDERS.ORDRECNO   =DELHED.DLVORDRECNO
            AND DELHED.DLVORDNO =     DELDET.DELDLVORDNO
            AND DELDET.DELRECNO =  DELPRICE.DPRDELRECNO
            AND DPRRECNO = IN_DPRRECNO;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
                V_CONT := 0;
            WHEN OTHERS THEN
                NULL;
                RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES - DELPRICE_VAT() - GET SALES DETAILS' ||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);
                V_CONT := 0;

        END;
    END IF ;

-- VERIFY THAT THIS IS A DELIVERY THAT WE CAN AMMEND
    IF V_CONT = 1 THEN
    BEGIN
        IF  NVL(V_ORCSTCODE,0) = 0                          -- orders record invoiced
        OR  NVL(V_DLVRELINV,'Blank') IN ('Rel', 'Inv')      -- delhed record released or invoiced
        OR  NVL(V_DLVTRANIND,0) >= 10                       -- delhed record released
        OR  NVL(V_DELSTATUS,'Blank') IN ('Rel', 'Inv')      -- deldet record released or invoiced
        OR  NVL(V_DELINVSTATUS,0) >= 10 THEN                -- delprice record released
        BEGIN
            V_CONT := 0;
        END;
        END IF;

    END;
    END IF;




    IF V_CONT = 1 THEN
    BEGIN
        FT_PK_VAT.CALCDELPRICEVAT( V_ACTCSTCODE,
                        V_DELPRCPRDNO,
                        V_DLVSTKLOC,
                        V_DLVSALOFFNO,
                        V_DLVDLTRECNO,
                        V_DELNETTVALUE - V_DISCAMT,
                        V_VATRECNO,
                        V_VATRATE1,
                        V_VATRATE2,
                        V_VATAMOUNT) ;
    END;
    END IF;


    IF V_CONT = 1 THEN
    BEGIN
    -- TODO - WORK NEEDED HERE FOR THE EURO AND BASE  CALCULATIONS
        UPDATE DELPRICE SET
            DELVATVALUE = V_VATAMOUNT,
            DELEUROVATVALUE = V_VATAMOUNT,
            DELBASEVATVALUE = V_VATAMOUNT,
            DELVATRATE = V_VATRATE1,
            DELVATRECNO =  V_VATRECNO,
            DELVATRATE2 = V_VATRATE2
        WHERE DPRRECNO = IN_DPRRECNO;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
            V_CONT := 0;
        WHEN OTHERS THEN
            NULL;
            RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES - DELPRICE_VAT() - UPDATE DELPRICE'||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);
            V_CONT := 0;

    END;
    END IF;

    END DELPRICE_CALCVATFIGURES;


    PROCEDURE DELTOIST_UPDATEVALUES(IN_DPRRECNO IN NUMBER, VERIFYDELIVERY NUMBER) AS
        V_CONT          NUMBER(1) := 1;

         -- CURSOR TO EXTRACT THE DELTOISTS THAT WE WILL BE WORKING WITH
            CURSOR DELTOIST_DETS_CURSOR(INS_DPRRECNO NUMBER) IS
            (SELECT
                DELPRICE.DPRRECNO, DISISTRECNO, NVL(DELPRICE.DELNETTVALUE,0) DELNETTVALUE, NVL(DELPRICE.DELFREEOFCHG,0) DELFREEOFCHG,
                (SELECT COUNT(DISISTRECNO) FROM DELTOIST DELTOIST1 WHERE DELTOIST1.DISDPRRECNO = DELPRICE.DPRRECNO) AS NOOFISTRECPERDPR,
                ROUND(CASE WHEN NVL(DELPRICE.DELPRCQTY,0) = 0  THEN 0  ELSE (DELPRICE.DELNETTVALUE / CAST(DELPRICE.DELPRCQTY AS FLOAT)) * DELTOIST.DISQTY END,2) APPVALONDELTOIST,
                NVL(DELTOIST.DISNETTVALUE,0) DISNETTVALUE, NVL(DELTOIST.DISVALUE,0) DISVALUE,
                DELHED.DLVRELINV, DELHED.DLVTRANIND, DELDET.DELSTATUS, DELPRICE.DELINVSTATUS

                FROM DELTOIST, DELPRICE, DELDET, DELHED
                WHERE   DELPRICE.DPRRECNO       =   DELTOIST.DISDPRRECNO
                AND     DELPRICE.DPRDELRECNO    =   DELDET.DELRECNO
                AND     DELDET.DELDLVORDNO      =   DELHED.DLVORDNO
                AND     DELPRICE.DPRRECNO  = INS_DPRRECNO);

            DELTOIST_DETS_RECORD DELTOIST_DETS_CURSOR%ROWTYPE;

        v_DelPriceNettValueRem DELPRICE.DELNETTVALUE%TYPE := NULL;
        v_ValueToUpdate     DELTOIST.DISVALUE%TYPE := NULL;
        v_LinesProcessed NUMBER := 0;

  BEGIN

    IF V_CONT = 1 THEN
        IF  NVL(IN_DPRRECNO,0) <=0 THEN
            V_CONT := 0;
        END IF;
    END IF;

-- GET DELIVERY DETAILS
    IF V_CONT = 1 THEN
        BEGIN
            OPEN  DELTOIST_DETS_CURSOR(IN_DPRRECNO);
                LOOP
                    FETCH DELTOIST_DETS_CURSOR INTO DELTOIST_DETS_RECORD;
                    EXIT WHEN DELTOIST_DETS_CURSOR%NOTFOUND;
                    v_LinesProcessed        := v_LinesProcessed + 1;

                    IF DELTOIST_DETS_RECORD.DELNETTVALUE IS NULL THEN
                        V_CONT := 0;
                    END IF;

                    IF V_CONT = 1 THEN
                        -- FOR THE FIRST LINE GET THE DELPRICE NETTVALUE
                        IF v_LinesProcessed = 1 THEN
                            v_DelPriceNettValueRem := DELTOIST_DETS_RECORD.DELNETTVALUE;
                        END IF;
                    END IF;


                    -- VERIFY THAT THIS IS A DELIVERY THAT WE CAN AMMEND
                    IF V_CONT = 1 AND VERIFYDELIVERY > 0 THEN
                    BEGIN
                        IF  NVL(DELTOIST_DETS_RECORD.DLVRELINV,'Blank') IN ('Rel', 'Inv')      -- delhed record released or invoiced
                        OR  NVL(DELTOIST_DETS_RECORD.DLVTRANIND,0) >= 10                       -- delhed record released
                        OR  NVL(DELTOIST_DETS_RECORD.DELSTATUS,'Blank') IN ('Rel', 'Inv')      -- deldet record released or invoiced
                        OR  NVL(DELTOIST_DETS_RECORD.DELINVSTATUS,0) >= 10 THEN                -- delprice record released
                        BEGIN
                            V_CONT := 0;
                        END;
                        END IF;

                    END;
                    END IF;


                    IF V_CONT = 1 THEN
                    BEGIN
                        IF  DELTOIST_DETS_RECORD.DELFREEOFCHG = 1 THEN
                            v_ValueToUpdate         := 0;
                        ELSE
                            v_ValueToUpdate         := DELTOIST_DETS_RECORD.APPVALONDELTOIST;
                            v_DelPriceNettValueRem  := v_DelPriceNettValueRem - v_ValueToUpdate;

                            -- Sort out the rounding by putting it all on to the last DELTOIST
                            IF DELTOIST_DETS_RECORD.NOOFISTRECPERDPR = v_LinesProcessed THEN
                                IF ABS(v_DelPriceNettValueRem) > 0.009 THEN
                                    v_ValueToUpdate         := v_ValueToUpdate + v_DelPriceNettValueRem;
                                    v_DelPriceNettValueRem := 0;
                                END IF;
                            END IF;
                        END IF;
                    END;
                    END IF;

                    EXIT WHEN V_CONT = 0;


                    IF V_CONT = 1 THEN
                    BEGIN
                        IF ABS(DELTOIST_DETS_RECORD.DISNETTVALUE - v_ValueToUpdate) > 0.001
                        OR ABS(DELTOIST_DETS_RECORD.DISVALUE - v_ValueToUpdate) > 0.001 THEN
                            BEGIN
                                UPDATE DELTOIST
                                SET DISNETTVALUE = v_ValueToUpdate,
                                    DISVALUE = v_ValueToUpdate
                                WHERE DISDPRRECNO   = DELTOIST_DETS_RECORD.DPRRECNO
                                AND DISISTRECNO     = DELTOIST_DETS_RECORD.DISISTRECNO;
                                COMMIT;
                            EXCEPTION

                                WHEN OTHERS THEN
                                    NULL;
                                    RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES - DELTOIST_UPDATEVALUES() - UPDATE DELTOIST'||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);
                                    V_CONT := 0;

                            END;
                        END IF;
                    END;
                    END IF;

                END LOOP;
             CLOSE DELTOIST_DETS_CURSOR;
        END;
    END IF ;
    END DELTOIST_UPDATEVALUES;
       
  FUNCTION GET_LOT_SOLD_QTY(LITITENO_IN LOTITE.LITITENO%TYPE) RETURN FLOAT
  IS
    RET_SALESQTY      FLOAT := 0.0;
    L_BULKQTY         FLOAT := 0.0;
    L_PREPACKQTY      FLOAT := 0.0;
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    SELECT  SUM(NVL(ITESTO.ISTSLDQTY, 0))
    INTO L_BULKQTY
    FROM ITESTO
    WHERE ITESTO.ISTLITNO = LITITENO_IN;

    BEGIN
      SELECT SUM(CASE WHEN PREPALINOUT.PPPALOUTQTY = 0 THEN 0 ELSE PREPALINOUT.PPPALINQTY * (PREPALINOUTSALES.DPRQTYTHIS / TO_NUMBER(PREPALINOUT.PPPALOUTQTY)) END)
      INTO L_PREPACKQTY
      FROM ITESTO
      INNER JOIN PREPALINOUT
      ON PREPALINOUT.PALINBULKISTREC = ITESTO.ISTRECNO
      INNER JOIN PREPALINOUTSALES
      ON PREPALINOUTSALES.PREPALINOUTRECNO = PREPALINOUT.PREPALRECNO
      WHERE ITESTO.ISTLITNO = LITITENO_IN;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        L_PREPACKQTY := 0.0;
    END;

    RET_SALESQTY := L_BULKQTY + L_PREPACKQTY;

    RETURN RET_SALESQTY;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END GET_LOT_SOLD_QTY;

 PROCEDURE PROCESS_DELAUDIT_FORAUTOCOST AS
        V_LSTDONEDELAUDRECNO      NUMBER(10) := 0;
        V_CURRENTDELAUDRECNO      number(10) := 0;
    BEGIN

    IF V_USEAUTOCOSTING = 1 THEN
      
      BEGIN
          SELECT SYSPREFVALUE INTO V_LSTDONEDELAUDRECNO FROM WizSysPref WHERE SysPrefName = 'AUTOCOST_LSTDELAUDRECNO';
          SELECT MAX(DELAUDRECNO) INTO V_CURRENTDELAUDRECNO FROM DELAUDIT;
       EXCEPTION
      WHEN OTHERS THEN
        FT_PK_ERRORS.LOG_AND_STOP;      
      END;          
    
      BEGIN                 
        LOOP
          EXIT WHEN V_LSTDONEDELAUDRECNO >= V_CURRENTDELAUDRECNO;
          
          GET_DELAUDIT_FORAUTOCOST(V_LSTDONEDELAUDRECNO, V_CURRENTDELAUDRECNO);
          
          BEGIN
            UPDATE WIZSYSPREF  set SYSPREFVALUE = V_CURRENTDELAUDRECNO where SYSPREFNAME = 'AUTOCOST_LSTDELAUDRECNO';
            COMMIT;
          EXCEPTION
            WHEN OTHERS THEN
            FT_PK_ERRORS.LOG_AND_STOP;      
          END;     
          
          V_LSTDONEDELAUDRECNO := V_CURRENTDELAUDRECNO;
          SELECT MAX(DELAUDRECNO) INTO V_CURRENTDELAUDRECNO FROM DELAUDIT;          
        END LOOP; 
      END;         
    END IF;
      
    END PROCESS_DELAUDIT_FORAUTOCOST;

 PROCEDURE GET_DELAUDIT_FORAUTOCOST(LOWER_DELAUDRECNO DELAUDIT.DELAUDRECNO%TYPE, HIGHER_DELAUDRECNO DELAUDIT.DELAUDRECNO%TYPE) AS
        CURSOR DELAUDIT_TODO_CURSOR(LOWER_DELAUDRECNO DELAUDIT.DELAUDRECNO%TYPE, HIGHER_DELAUDRECNO DELAUDIT.DELAUDRECNO%TYPE) IS      
          (SELECT DELAUDIT.DPRRECNO DPRRECNO, 
            (CASE WHEN DELAUDIT.DELAUDTYP IN (2,3,16,22,23) THEN 1 ELSE 0 END) DODISCOUNT, 
            DELAUDTYPES.COSTCHNGTYPENO COSTCHNGTYPENO
            from DELAUDIT, DELAUDTYPES
            WHERE DELAUDIT.DELAUDTYP =  DELAUDTYPES.DELAUDTYP
            and DELAUDRECNO > LOWER_DELAUDRECNO 
            AND DELAUDRECNO <= HIGHER_DELAUDRECNO
            and NVL(DPRRECNO,0) > 0 
            UNION 
            SELECT delprice.dprrecno DPRRECNO , 
            (CASE WHEN DELAUDIT.DELAUDTYP IN (2,3,16,22,23) THEN 1 ELSE 0 END) DODISCOUNT,             
            delaudtypes.costchngtypeno COSTCHNGTYPENO
            from DELAUDIT, DELAUDTYPES, DELPRICE
            WHERE DELAUDIT.DELAUDTYP =  DELAUDTYPES.DELAUDTYP
            and DELAUDIT.DELAUDDELRECNO = DELPRICE.DPRDELRECNO
            AND DELAUDRECNO > LOWER_DELAUDRECNO 
            and DELAUDRECNO <= HIGHER_DELAUDRECNO
            and NVL(DELAUDIT.DELAUDDELRECNO,0) > 0 
            and NVL(DELAUDIT.DPRRECNO,0) = 0 );
        DELAUDIT_TODO_RECORD DELAUDIT_TODO_CURSOR%ROWTYPE;
        
    BEGIN

      BEGIN                 
        OPEN DELAUDIT_TODO_CURSOR(LOWER_DELAUDRECNO, HIGHER_DELAUDRECNO);
          LOOP
            FETCH DELAUDIT_TODO_CURSOR INTO DELAUDIT_TODO_RECORD;
          EXIT 
          WHEN DELAUDIT_TODO_CURSOR%NOTFOUND;
            
          IF DELAUDIT_TODO_RECORD.COSTCHNGTYPENO > 0 THEN
            FT_PK_AUTOCOSTING.ENQUEUE_DPRRECS(RECORD_NUMBERS(DELAUDIT_TODO_RECORD.DPRRECNO), DELAUDIT_TODO_RECORD.COSTCHNGTYPENO, -9);
          END IF;
          
          /*(DelAudType = "2" or  ;Price change
                   DelAudType = "3" or  ;Quantity change
                   DelAudType = "16" or ;Nett value
                   DelAudType = "22" OR ;CREATE NEW stock credit note
                   DelAudType = "23")  */
          IF DELAUDIT_TODO_RECORD.DODISCOUNT = 1 THEN
            BEGIN
              FT_PK_DISCOUNTS.DO_DISCOUNTS(DELAUDIT_TODO_RECORD.DPRRECNO);
            EXCEPTION
              WHEN OTHERS THEN
              FT_PK_ERRORS.LOG_AND_CONTINUE;      
            END;    
          END IF;       
          
          END LOOP; 
        CLOSE DELAUDIT_TODO_CURSOR;
      END;
      
    END GET_DELAUDIT_FORAUTOCOST;
  
   -- initialisation section
    BEGIN
        BEGIN
            
            SELECT (CASE WHEN UPPER(SYSPREFVALUE) = 'TRUE' THEN 1 ELSE 0 END) lUSEAUTOCOSTING
            INTO V_USEAUTOCOSTING 
            FROM WIZSYSPREF WHERE SYSPREFNAME = 'USEAUTOCOSTING' ;                    
        EXCEPTION
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_CONTINUE;
                V_USEAUTOCOSTING := 0;       
        END;    
         

END FT_PK_SALES ;