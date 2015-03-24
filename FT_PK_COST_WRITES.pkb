CREATE OR REPLACE PACKAGE BODY FT_PK_COST_WRITES AS

  cVersionControlNo   VARCHAR2(12) := '1.0.1'; -- Current Version Number

  CURSOR APPORTION_PO_RECS(EXCCHAREC_IN EXPCHA.EXCCHAREC%TYPE) IS
    SELECT  PO_VIEW.LITITENO, PO_VIEW.LITRCVCOMPLETE, PO_VIEW.LITORGEXP, PO_VIEW.LITQTYRCV, PO_VIEW.LITNETTWGT, PO_VIEW.LITPALQTY, PO_VIEW.DUTYWGT,
            COST_VIEW.ICHRECNO, NVL(COST_VIEW.ICHSPETO, NOT_FIXED) AS ICHSPETO, COST_VIEW.ICHAUTHAMM, COST_VIEW.ICHRAWAUTHAMM
    FROM FT_V_PO PO_VIEW
    LEFT OUTER JOIN FT_V_COSTS COST_VIEW
      ON PO_VIEW.LITITENO = COST_VIEW.LITRECNO AND COST_VIEW.EXCCHAREC = EXCCHAREC_IN
    WHERE (PO_VIEW.PORRECNO, PO_VIEW.LHERECNO) IN (SELECT EXPCHA.EXCPORRECNO, NVL(EXPCHA.EXCLHERECNO, PO_VIEW.LHERECNO) FROM EXPCHA WHERE EXPCHA.EXCCHAREC = EXCCHAREC_IN);

  FUNCTION CURRENTVERSION RETURN VARCHAR2
  IS
  BEGIN
     RETURN cVersionControlNo;
  END CURRENTVERSION;

  -- Order of updates to avoid deadlock ITECHG, EXPCHA, LOTITE
  
  FUNCTION RETURN_UNIT_PRICE_EXT(LITITENO_IN LOTITE.LITITENO%TYPE) RETURN FLOAT
  IS
    RET_UNIT_EXTENSION      FLOAT;
    LOTITE_REC              LOTITE%ROWTYPE;
  BEGIN    
    SELECT * INTO LOTITE_REC FROM LOTITE WHERE LOTITE.LITITENO = LITITENO_IN;
  
    IF LOTITE_REC.LITRCVCOMPLETE = CONST.C_YES THEN
      RET_UNIT_EXTENSION := LOTITE_REC.LITQTYRCV;
    ELSE
      RET_UNIT_EXTENSION := LOTITE_REC.LITORGEXP;
    END IF;

    IF LOTITE_REC.LITPURBYTYP > CONST.PERBOX AND LOTITE_REC.LITSTANDNOOF IS NOT NULL THEN
      RET_UNIT_EXTENSION := RET_UNIT_EXTENSION * LOTITE_REC.LITSTANDNOOF;
    END IF;

    IF ABS(RET_UNIT_EXTENSION) < 0.0001 THEN
      RET_UNIT_EXTENSION := NULL;
    END IF;
    
    RETURN RET_UNIT_EXTENSION;
  END RETURN_UNIT_PRICE_EXT;


  FUNCTION GET_UNIT_PRICE(LITITENO_IN LOTITE.LITITENO%TYPE, GOODS_AMT_RAW_IN FLOAT) RETURN LOTITE.LITUNICOST%TYPE
  IS
    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    LOTITE_REC          LOTITE%ROWTYPE;
    L_RNDPLACES         INTEGER;
    UNITCOST_DIVISOR    FLOAT;
    RET_UNIT_PRICE      LOTITE.LITUNICOST%TYPE;
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;
 
    IF GOODS_AMT_RAW_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'GOODS_AMT_RAW_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(GOODS_AMT_RAW_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF; 
    
    SELECT * INTO LOTITE_REC FROM LOTITE WHERE LOTITE.LITITENO = LITITENO_IN;
    
    UNITCOST_DIVISOR := RETURN_UNIT_PRICE_EXT(LITITENO_IN);

    IF LOTITE_REC.LITPURBYTYP > CONST.PERBOX THEN
      L_RNDPLACES := 4;
    ELSE
      L_RNDPLACES := 2;
    END IF;

    RET_UNIT_PRICE := ROUND(GOODS_AMT_RAW_IN / UNITCOST_DIVISOR, L_RNDPLACES);
    
    RETURN RET_UNIT_PRICE;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP();    
  END GET_UNIT_PRICE;
  
  FUNCTION GET_GOODS_AMT(LITITENO_IN LOTITE.LITITENO%TYPE, UNIT_PRICE_RAW_IN LOTITE.LITUNICOST%TYPE) RETURN FLOAT
  IS
    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    UNITCOST_MULTIP     FLOAT;
    RET_GOODS_AMT_RAW   FLOAT;    
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;
  
    IF UNIT_PRICE_RAW_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'UNIT_PRICE_RAW_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(UNIT_PRICE_RAW_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF; 
    
    UNITCOST_MULTIP := RETURN_UNIT_PRICE_EXT(LITITENO_IN); 
    
    RET_GOODS_AMT_RAW := ROUND(UNIT_PRICE_RAW_IN * UNITCOST_MULTIP, 2);
    
    RETURN RET_GOODS_AMT_RAW;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP();      
  END;

  PROCEDURE INSERT_POAUDFIL(POAUDFIL_INOUT IN OUT POAUDFIL%ROWTYPE)
  IS
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    IF POAUDFIL_INOUT.PADCTYNO IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'PADCTYNO';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(POAUDFIL_INOUT.PADCTYNO);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF POAUDFIL_INOUT.PADLITNO IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'PADLITNO';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(POAUDFIL_INOUT.PADLITNO);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF POAUDFIL_INOUT.PADICHNO IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'PADICHNO';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(POAUDFIL_INOUT.PADICHNO);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    POAUDFIL_INOUT.PADRECNO := SP_WIZGETCONTROL('ContPadNo', 1, 'INSERT_POAUDFIL');
    POAUDFIL_INOUT.PADCHADONEIN := 752; -- Temporary form number DOCOST_ACCRUALS
    POAUDFIL_INOUT.PADDATE := SYSDATE;
    POAUDFIL_INOUT.PADTIME := TO_CHAR(SYSDATE, 'HH24:MI');
    POAUDFIL_INOUT.POAUDPERSON := FT_PK_SESSION_UTILS.GET_FT_LOGONNO();
    POAUDFIL_INOUT.COMMITED := 1;
    POAUDFIL_INOUT.POAUDDAYENDED := 0;

    IF POAUDFIL_INOUT.PADTYPENO IS NULL THEN
      POAUDFIL_INOUT.PADTYPENO := PADTYPE_COSTCHNG;
    END IF;

    INSERT INTO POAUDFIL
    VALUES POAUDFIL_INOUT;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP();
  END INSERT_POAUDFIL;

  PROCEDURE UPDATE_LOTCOST(LITITENO_IN LOTITE.LITITENO%TYPE)
  IS
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    LOTITE_REC        LOTITE%ROWTYPE;
    NEWLITPRDCOST     LOTITE.LITPRDCOST%TYPE;
    L_UNIT_PRICE      LOTITE.LITUNICOST%TYPE;
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    SELECT * INTO LOTITE_REC FROM LOTITE WHERE LOTITE.LITITENO = LITITENO_IN;

    UPDATE LOTITE
    SET LITPRDCOST = NVL((SELECT SUM(ITECHG.ICHAPPAMT) FROM ITECHG WHERE ITECHG.LITRECNO = LOTITE.LITITENO AND ITECHG.CTYNO = CONST.CTYGOODS AND ITECHG.ICHISTRECNO IS NULL), 0.0),
        LITDELCOST = NVL((SELECT SUM(ITECHG.ICHAPPAMT) FROM ITECHG WHERE ITECHG.LITRECNO = LOTITE.LITITENO AND ITECHG.ICHISTRECNO IS NULL), 0.0)
    WHERE LITITENO = LITITENO_IN
    RETURNING LITPRDCOST
    INTO NEWLITPRDCOST;

    IF ABS(NEWLITPRDCOST - NVL(LOTITE_REC.LITPRDCOST, 0.0)) > 0.009 THEN
    
      L_UNIT_PRICE := GET_UNIT_PRICE(LITITENO_IN, NEWLITPRDCOST);
    
      UPDATE LOTITE
      SET LITUNICOST = L_UNIT_PRICE
      WHERE LOTITE.LITITENO = LOTITE_REC.LITITENO;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP();
  END UPDATE_LOTCOST;

  PROCEDURE UPDATE_ITECHG(ITECHG_INOUT IN OUT ITECHG%ROWTYPE, EXPCHA_INOUT IN OUT EXPCHA%ROWTYPE)
  IS
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    V_COSTS_REC       FT_V_COSTS%ROWTYPE;
    ITECHG_REC        ITECHG%ROWTYPE;
    EXPCHA_REC        EXPCHA%ROWTYPE;
    POAUDFIL_REC      POAUDFIL%ROWTYPE;
    APP_CHNG          BOOLEAN := FALSE;
    AUTH_CHNG         BOOLEAN := FALSE;
  BEGIN
    IF ITECHG_INOUT.ICHRECNO IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'ICHRECNO';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(ITECHG_INOUT.ICHRECNO);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    SELECT * INTO V_COSTS_REC FROM FT_V_COSTS COSTS WHERE COSTS.ICHRECNO = ITECHG_INOUT.ICHRECNO;

    IF NVL(V_COSTS_REC.EXCTOBASERATE, 0.0) < 0.000001 THEN
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_DATA);
    END IF;

    SELECT * INTO ITECHG_REC FROM ITECHG WHERE ITECHG.ICHRECNO = ITECHG_INOUT.ICHRECNO;

    IF ABS(ITECHG_INOUT.ICHAPPAMT - ITECHG_REC.ICHAPPAMT) > 0.009 THEN --Ignores NULLs
      ITECHG_REC.ICHAPPAMT := ROUND(ITECHG_INOUT.ICHAPPAMT, 2);
      ITECHG_REC.ICHRAWAPPAMT := ROUND(ITECHG_REC.ICHAPPAMT / V_COSTS_REC.EXCTOBASERATE, 2);
      APP_CHNG := TRUE;
    ELSIF ABS(ITECHG_INOUT.ICHRAWAPPAMT - ITECHG_REC.ICHRAWAPPAMT) > 0.009 THEN --Ignores NULLs
      ITECHG_REC.ICHRAWAPPAMT := ROUND(ITECHG_INOUT.ICHRAWAPPAMT, 2);
      ITECHG_REC.ICHAPPAMT := ROUND(ITECHG_REC.ICHRAWAPPAMT * V_COSTS_REC.EXCTOBASERATE, 2);
      APP_CHNG := TRUE;
    END IF;

    IF ABS(ITECHG_INOUT.ICHAUTHAMM - NVL(ITECHG_REC.ICHAUTHAMM, 0.0)) > 0.009 THEN --Ignores NULLs
      ITECHG_REC.ICHAUTHAMM := ROUND(ITECHG_INOUT.ICHAUTHAMM, 2);
      ITECHG_REC.ICHRAWAUTHAMM := ROUND(ITECHG_REC.ICHAUTHAMM / V_COSTS_REC.EXCTOBASERATE, 2);
      AUTH_CHNG := TRUE;
    ELSIF ABS(ITECHG_INOUT.ICHRAWAUTHAMM - NVL(ITECHG_REC.ICHRAWAUTHAMM, 0.0)) > 0.009 THEN --Ignores NULLs
      ITECHG_REC.ICHRAWAUTHAMM := ROUND(ITECHG_INOUT.ICHRAWAUTHAMM, 2);
      ITECHG_REC.ICHAUTHAMM := ROUND(ITECHG_REC.ICHRAWAUTHAMM * V_COSTS_REC.EXCTOBASERATE, 2);
      AUTH_CHNG := TRUE;
    END IF;

    IF ITECHG_INOUT.ICHSPETO IS NOT NULL THEN
      ITECHG_REC.ICHSPETO := ITECHG_INOUT.ICHSPETO;
    END IF;
    IF ITECHG_INOUT.ICHAPPFAC IS NOT NULL THEN
      ITECHG_REC.ICHAPPFAC := ITECHG_INOUT.ICHAPPFAC;
    END IF;
    IF ITECHG_INOUT.ICHCHGFOR IS NOT NULL THEN
      ITECHG_REC.ICHCHGFOR := ITECHG_INOUT.ICHCHGFOR;
    END IF;
    IF ITECHG_INOUT.ICHACRRECNO IS NOT NULL THEN
      ITECHG_REC.ICHACRRECNO := ITECHG_INOUT.ICHACRRECNO;
    END IF;
    IF ITECHG_INOUT.ICHORGAPPAMT IS NOT NULL THEN
      ITECHG_REC.ICHORGAPPAMT := ITECHG_INOUT.ICHORGAPPAMT;
    END IF;
    IF ABS(ITECHG_REC.ICHRAWAPPAMT - ITECHG_REC.ICHORGAPPAMT) > 0.009 THEN
      ITECHG_REC.ICHCHNGDBYUSER := CONST.C_TRUE;
    ELSE
      ITECHG_REC.ICHCHNGDBYUSER := CONST.C_FALSE;
    END IF;
    IF ITECHG_INOUT.ICHPCNTORRATE IS NOT NULL THEN
      ITECHG_REC.ICHPCNTORRATE := ITECHG_INOUT.ICHPCNTORRATE;
    END IF;

    UPDATE ITECHG
    SET ROW = ITECHG_REC
    WHERE ICHRECNO = ITECHG_REC.ICHRECNO;

    IF APP_CHNG THEN
      UPDATE EXPCHA
      SET (EXCCONAMM, EXCRAWAMM, EXCEUROAMM) = (SELECT SUM(ITECHG.ICHAPPAMT), SUM(ITECHG.ICHRAWAPPAMT), ROUND(SUM(ITECHG.ICHRAWAPPAMT) * V_COSTS_REC.EXCTOEUROEXCRATE, 2)
                                                FROM ITECHG
                                                WHERE ITECHG.EXCRECNO = EXPCHA.EXCCHAREC)
      WHERE EXCCHAREC = ITECHG_REC.EXCRECNO;
    END IF;

    IF AUTH_CHNG THEN
      UPDATE EXPCHA
      SET (EXCAUTHCONAMM, EXCAUTHRAWAMM, EXCAUTHEUROAMM) = (SELECT SUM(ITECHG.ICHAUTHAMM), SUM(ITECHG.ICHRAWAUTHAMM), ROUND(SUM(ITECHG.ICHRAWAUTHAMM) * V_COSTS_REC.EXCTOEUROEXCRATE, 2)
                                                            FROM ITECHG
                                                            WHERE ITECHG.EXCRECNO = EXPCHA.EXCCHAREC)
      WHERE EXCCHAREC = ITECHG_REC.EXCRECNO;
    END IF;

    IF APP_CHNG OR AUTH_CHNG THEN
      UPDATE EXPCHA
      SET EXCFULLYAUTH = CASE WHEN ABS(EXCCONAMM - EXCAUTHCONAMM) < 0.01 THEN CLOSED_ACCRUAL ELSE OPEN_ACCRUAL END
      WHERE EXPCHA.EXCCHAREC = ITECHG_REC.EXCRECNO;

      IF NVL(V_COSTS_REC.LITRECNO , 0) > 0 THEN
        POAUDFIL_REC.PADCTYNO := ITECHG_REC.CTYNO;
        POAUDFIL_REC.PADLITNO := ITECHG_REC.LITRECNO;
        POAUDFIL_REC.PADICHNO := ITECHG_REC.ICHRECNO;
        IF APP_CHNG THEN
          POAUDFIL_REC.PADTYPENO := PADTYPE_COSTCHNG;
          POAUDFIL_REC.PADORIGVALUE := V_COSTS_REC.ICHAPPAMT;
          POAUDFIL_REC.PADNEWVALUE := ITECHG_REC.ICHAPPAMT;
          INSERT_POAUDFIL(POAUDFIL_REC);

          UPDATE_LOTCOST(ITECHG_REC.LITRECNO);
        END IF;

        IF AUTH_CHNG THEN
          POAUDFIL_REC.PADTYPENO := PADTYPE_AUTHCHNG;
          POAUDFIL_REC.PADORIGVALUE := V_COSTS_REC.ICHAUTHAMM;
          POAUDFIL_REC.PADNEWVALUE := ITECHG_REC.ICHAUTHAMM;
          INSERT_POAUDFIL(POAUDFIL_REC);
        END IF;
      END IF;
    END IF;

    SELECT * INTO EXPCHA_REC FROM EXPCHA WHERE EXPCHA.EXCCHAREC = ITECHG_REC.EXCRECNO;
    EXPCHA_INOUT := EXPCHA_REC;
    ITECHG_INOUT := ITECHG_REC;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PARAMETER_LIST('#PARAMNAME') := 'ICHRECNO';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(ITECHG_INOUT.ICHRECNO);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP();
  END UPDATE_ITECHG;

  PROCEDURE UPDATE_ITECHG(ITECHG_INOUT IN OUT ITECHG%ROWTYPE)
  IS
    EXPCHA_REC    EXPCHA%ROWTYPE;
  BEGIN
    UPDATE_ITECHG(ITECHG_INOUT, EXPCHA_REC);
  END;

  PROCEDURE UPDATE_ICHAPPAMT(ICHRECNO_IN ITECHG.ICHRECNO%TYPE, ICHAPPAMT_IN ITECHG.ICHAPPAMT%TYPE)
  IS
    ITECHG_REC      ITECHG%ROWTYPE;
  BEGIN
    ITECHG_REC.ICHRECNO := ICHRECNO_IN;
    ITECHG_REC.ICHAPPAMT := ICHAPPAMT_IN;

    UPDATE_ITECHG(ITECHG_REC);
  END UPDATE_ICHAPPAMT;

  PROCEDURE UPDATE_ICHRAWAPPAMT(ICHRECNO_IN ITECHG.ICHRECNO%TYPE, ICHRAWAPPAMT_IN ITECHG.ICHRAWAPPAMT%TYPE)
  IS
    ITECHG_REC      ITECHG%ROWTYPE;
    EXCPHA_REQD     BOOLEAN := TRUE;
    L_EXCCHAREC     EXPCHA.EXCCHAREC%TYPE;
  BEGIN
    ITECHG_REC.ICHRECNO := ICHRECNO_IN;
    ITECHG_REC.ICHRAWAPPAMT := ICHRAWAPPAMT_IN;

    UPDATE_ITECHG(ITECHG_REC);
  END UPDATE_ICHRAWAPPAMT;

  PROCEDURE INSERT_ITECHG(ITECHG_INOUT IN OUT ITECHG%ROWTYPE, EXPCHA_INOUT IN OUT EXPCHA%ROWTYPE)
  IS
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    SQL_STMT          VARCHAR2(1000);
    BIND_VAR          INTEGER;
    ITECHG_REC        ITECHG%ROWTYPE;
    EXPCHA_REC        EXPCHA%ROWTYPE;
    POAUDFIL_REC      POAUDFIL%ROWTYPE;
    L_RATUSEFOR       INTEGER;
    L_SALOFFNO        INTEGER;
    L_NEWEXPCHA       BOOLEAN := FALSE;
  BEGIN
    IF ITECHG_INOUT.LITRECNO IS NULL AND ITECHG_INOUT.DELRECNO IS NULL AND ITECHG_INOUT.DPRRECNO IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'FOREIGN KEY';
      PARAMETER_LIST('#PARAMVALUE') := 'NULL';
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF ITECHG_INOUT.CTYNO IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'CTYNO';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(ITECHG_INOUT.CTYNO);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF ITECHG_INOUT.ICHAPPFAC IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'ICHAPPFAC';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(ITECHG_INOUT.ICHAPPFAC);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF ITECHG_INOUT.ICHAPPAMT IS NULL AND ITECHG_INOUT.ICHRAWAPPAMT IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'ICHAPPAMT';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(ITECHG_INOUT.ICHAPPAMT);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF ITECHG_INOUT.EXCRECNO IS NULL THEN
      SQL_STMT := CASE
                    WHEN ITECHG_INOUT.LITRECNO IS NOT NULL THEN 'SELECT EXPCHA.* FROM EXPCHA INNER JOIN FT_V_PO PO_VIEW ON PO_VIEW.LHERECNO = EXPCHA.EXCLHERECNO WHERE PO_VIEW.LITITENO = :LITITENO'
                    WHEN ITECHG_INOUT.DELRECNO IS NOT NULL THEN 'SELECT EXPCHA.* FROM EXPCHA INNER JOIN FT_V_RTE RTE_VIEW ON RTE_VIEW.RTHNO = EXPCHA.EXCRTHNO WHERE RTE_VIEW.RTDDELDETRECNO = :DELRECNO'
                    WHEN ITECHG_INOUT.DPRRECNO IS NOT NULL THEN 'SELECT EXPCHA.* FROM EXPCHA INNER JOIN FT_V_DLV DLV_VIEW ON DLV_VIEW.DLVORDNO = EXPCHA.EXCDLVORDNO WHERE DLV_VIEW.DPRRECNO = :DPRRECNO'
                  END;

      BIND_VAR := CASE
                    WHEN ITECHG_INOUT.LITRECNO IS NOT NULL THEN ITECHG_INOUT.LITRECNO
                    WHEN ITECHG_INOUT.DELRECNO IS NOT NULL THEN ITECHG_INOUT.DELRECNO
                    WHEN ITECHG_INOUT.DPRRECNO IS NOT NULL THEN ITECHG_INOUT.DPRRECNO
                  END;

      SQL_STMT := SQL_STMT || ' AND EXPCHA.EXCCTYNO = ' || ITECHG_INOUT.CTYNO;

      IF EXPCHA_INOUT.EXCSENCODE IS NOT NULL THEN
        SQL_STMT := SQL_STMT || ' AND EXPCHA.EXCSENCODE = ' || EXPCHA_INOUT.EXCSENCODE;
      END IF;

      BEGIN
        EXECUTE IMMEDIATE SQL_STMT INTO EXPCHA_REC USING BIND_VAR;
        ITECHG_INOUT.EXCRECNO := EXPCHA_REC.EXCCHAREC;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;
      END;
    END IF;

    IF ITECHG_INOUT.EXCRECNO IS NULL THEN
      L_NEWEXPCHA := TRUE;
      CASE
      WHEN ITECHG_INOUT.LITRECNO IS NOT NULL THEN
        L_RATUSEFOR := CONST.C_PURCHASES;
        IF EXPCHA_INOUT.EXCPORRECNO IS NULL THEN
          SELECT PO_VIEW.PORRECNO, PO_VIEW.LHERECNO, PO_VIEW.PORSALOFF INTO EXPCHA_REC.EXCPORRECNO, EXPCHA_REC.EXCLHERECNO, L_SALOFFNO FROM FT_V_PO PO_VIEW WHERE PO_VIEW.LITITENO = ITECHG_INOUT.LITRECNO;
        END IF;
      WHEN ITECHG_INOUT.DELRECNO IS NOT NULL THEN
        L_RATUSEFOR := CONST.C_SALES;
        SELECT RTE_VIEW.RTHNO, RTE_VIEW.RTHSALOFFNO INTO EXPCHA_REC.EXCRTHNO, L_SALOFFNO FROM FT_V_RTE RTE_VIEW WHERE RTE_VIEW.RTDDELDETRECNO = ITECHG_INOUT.DELRECNO;
      WHEN ITECHG_INOUT.DPRRECNO IS NOT NULL THEN
        L_RATUSEFOR := CONST.C_SALES;
        SELECT DLV_VIEW.DLVORDNO, DLV_VIEW.DLVSALOFFNO INTO EXPCHA_REC.EXCDLVORDNO, L_SALOFFNO FROM FT_V_DLV DLV_VIEW WHERE DLV_VIEW.DPRRECNO = ITECHG_INOUT.DPRRECNO;
      END CASE;

      IF EXPCHA_INOUT.EXCSENCODE IS NULL THEN
        EXPCHA_REC.EXCCURRNO := CONST.CURBASE;
      ELSE
        SELECT ACCCLASS.CLACURRNO INTO EXPCHA_REC.EXCCURRNO FROM ACCCLASS WHERE ACCCLASS.CLARECNO = EXPCHA_INOUT.EXCSENCODE;
      END IF;

      EXPCHA_REC.EXCCHAREC := SP_WIZGETCONTROL('ContExcChaNo', 1, 'INSERT_ITECHG');
      EXPCHA_REC.EXCCTYNO := ITECHG_INOUT.CTYNO;
      EXPCHA_REC.EXCAPPTYPE := ITECHG_INOUT.ICHAPPFAC;
      EXPCHA_REC.EXCSENCODE := EXPCHA_INOUT.EXCSENCODE;
      SELECT ACCCURRRATE.RATRATETOEURO, ACCCURRRATE.RATRATETOBASE INTO EXPCHA_REC.EXCTOEUROEXCRATE, EXPCHA_REC.EXCTOBASERATE  FROM ACCCURRRATE WHERE RATCURNO = EXPCHA_REC.EXCCURRNO AND RATUSEFOR = L_RATUSEFOR;
      EXPCHA_REC.EXCCHGCALC := 1;
      EXPCHA_REC.TRIANGULATED := CONST.C_FALSE;
      EXPCHA_REC.EXCRECOVFROMPL := EXPCHA_INOUT.EXCRECOVFROMPL;

      IF EXPCHA_INOUT.EXCSALOFF IS NOT NULL THEN
        EXPCHA_REC.EXCSALOFF := EXPCHA_INOUT.EXCSALOFF;
      ELSE
        EXPCHA_REC.EXCSALOFF := L_SALOFFNO;
      END IF;

      ITECHG_INOUT.EXCRECNO := EXPCHA_REC.EXCCHAREC;
    END IF;

    ITECHG_REC.ICHRECNO :=  SP_WIZGETCONTROL('ContIchNo', 1, 'INSERT_ITECHG');
    ITECHG_REC.EXCRECNO := ITECHG_INOUT.EXCRECNO;
    ITECHG_REC.CTYNO := ITECHG_INOUT.CTYNO;
    ITECHG_REC.LITRECNO := ITECHG_INOUT.LITRECNO;
    ITECHG_REC.DELRECNO := ITECHG_INOUT.DELRECNO;
    ITECHG_REC.DPRRECNO := ITECHG_INOUT.DPRRECNO;
    ITECHG_REC.ICHISTRECNO := ITECHG_INOUT.ICHISTRECNO;
    ITECHG_REC.ICHAPPFAC := ITECHG_INOUT.ICHAPPFAC;
    ITECHG_REC.ICHCHGFOR := ITECHG_INOUT.ICHCHGFOR;
    ITECHG_REC.ICHCHACALC := 1;
    ITECHG_REC.ICHSPETO := ITECHG_INOUT.ICHSPETO;
    ITECHG_REC.ICHACRRECNO := ITECHG_INOUT.ICHACRRECNO;
    ITECHG_REC.ICHORGAPPAMT := ITECHG_INOUT.ICHORGAPPAMT;
    IF ITECHG_INOUT.ICHCHNGDBYUSER IS NOT NULL THEN
       ITECHG_REC.ICHCHNGDBYUSER := ITECHG_INOUT.ICHCHNGDBYUSER;
    END IF;   
    ITECHG_REC.ICHPCNTORRATE := ITECHG_INOUT.ICHPCNTORRATE;

    IF ITECHG_REC.ICHACRRECNO IS NOT NULL THEN
      ITECHG_REC.ICHISANAUTO := CONST.C_TRUE;
    END IF;

    IF ITECHG_INOUT.ICHAPPAMT IS NOT NULL THEN
      ITECHG_REC.ICHAPPAMT := ROUND(ITECHG_INOUT.ICHAPPAMT, 2);
      ITECHG_REC.ICHRAWAPPAMT := ROUND(ITECHG_REC.ICHAPPAMT / EXPCHA_REC.EXCTOBASERATE, 2);
    ELSE
      ITECHG_REC.ICHRAWAPPAMT := ROUND(ITECHG_INOUT.ICHRAWAPPAMT, 2);
      ITECHG_REC.ICHAPPAMT := ROUND(ITECHG_REC.ICHRAWAPPAMT * EXPCHA_REC.EXCTOBASERATE, 2);
    END IF;

    ITECHG_REC.ICHAUTHAMM := 0.0;

    INSERT INTO ITECHG
    VALUES ITECHG_REC;

    SELECT SUM(ITECHG.ICHAPPAMT), SUM(ITECHG.ICHRAWAPPAMT), ROUND(SUM(ITECHG.ICHRAWAPPAMT) * EXPCHA_REC.EXCTOEUROEXCRATE, 2)
    INTO EXPCHA_REC.EXCCONAMM, EXPCHA_REC.EXCRAWAMM, EXPCHA_REC.EXCEUROAMM
    FROM ITECHG
    WHERE ITECHG.EXCRECNO =  ITECHG_REC.EXCRECNO;

    EXPCHA_REC.EXCFULLYAUTH := CASE WHEN ABS(EXPCHA_REC.EXCCONAMM) < 0.01 THEN CLOSED_ACCRUAL ELSE OPEN_ACCRUAL END;

    IF L_NEWEXPCHA THEN
      INSERT INTO EXPCHA
      VALUES EXPCHA_REC;
    ELSE
      UPDATE EXPCHA
      SET ROW =  EXPCHA_REC
      WHERE EXCCHAREC = EXPCHA_REC.EXCCHAREC;
    END IF;

    IF NVL(ITECHG_REC.LITRECNO , 0) > 0 THEN
        POAUDFIL_REC.PADCTYNO := ITECHG_REC.CTYNO;
        POAUDFIL_REC.PADLITNO := ITECHG_REC.LITRECNO;
        POAUDFIL_REC.PADICHNO := ITECHG_REC.ICHRECNO;
        POAUDFIL_REC.PADTYPENO := PADTYPE_COSTCHNG;
        POAUDFIL_REC.PADORIGVALUE := 0.0;
        POAUDFIL_REC.PADNEWVALUE := ITECHG_REC.ICHAPPAMT;

        INSERT_POAUDFIL(POAUDFIL_REC);

        UPDATE_LOTCOST(ITECHG_REC.LITRECNO);
    END IF;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP;
  END INSERT_ITECHG;

  PROCEDURE INSERT_ITECHG(ITECHG_INOUT IN OUT ITECHG%ROWTYPE)
  IS
    EXPCHA_REC      EXPCHA%ROWTYPE;
  BEGIN
    INSERT_ITECHG(ITECHG_INOUT, EXPCHA_REC);
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END INSERT_ITECHG;

  FUNCTION GET_PO_APP_DIVISOR(APPORT_PO_REC_IN APPORTION_PO_RECS%ROWTYPE, EXCAPPTYPE_IN EXPCHA.EXCAPPTYPE%TYPE, IGNORE_FIXED BOOLEAN, ALLOW_NEW_ITE BOOLEAN) RETURN FLOAT
  IS
    L_DIVISOR         FLOAT := 0.0;
    L_REQD_REC        BOOLEAN := TRUE;
  BEGIN
    IF NOT IGNORE_FIXED AND APPORT_PO_REC_IN.ICHSPETO = POCOST_FIXED THEN
      L_REQD_REC := FALSE;
    END IF;
    IF NOT ALLOW_NEW_ITE AND APPORT_PO_REC_IN.ICHRECNO IS NULL THEN
      L_REQD_REC := FALSE;
    END IF;
    IF L_REQD_REC THEN
      IF EXCAPPTYPE_IN = CONST.C_APP_BOX OR EXCAPPTYPE_IN = CONST.C_APP_CONTAINER THEN
        IF APPORT_PO_REC_IN.LITRCVCOMPLETE = CONST.C_YES THEN
          L_DIVISOR := APPORT_PO_REC_IN.LITQTYRCV;
        ELSE
          L_DIVISOR := APPORT_PO_REC_IN.LITORGEXP;
        END IF;
      ELSIF EXCAPPTYPE_IN = CONST.C_APP_WGT THEN
        L_DIVISOR := APPORT_PO_REC_IN.LITNETTWGT;
      ELSIF EXCAPPTYPE_IN = CONST.C_APP_PAL THEN
        L_DIVISOR := APPORT_PO_REC_IN.LITPALQTY;
      ELSIF EXCAPPTYPE_IN = CONST.C_APP_DUTYWGT THEN
        L_DIVISOR := APPORT_PO_REC_IN.DUTYWGT;
      END IF;
    END IF;
    RETURN L_DIVISOR;
  END GET_PO_APP_DIVISOR;

  FUNCTION GET_PO_APP_TOTAL(EXCCHAREC_IN EXPCHA.EXCCHAREC%TYPE, EXCAPPTYPE_IN EXPCHA.EXCAPPTYPE%TYPE, IGNORE_FIXED BOOLEAN, ALLOW_NEW_ITE BOOLEAN) RETURN FLOAT
  IS
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    L_DIVISOR         FLOAT := 0.0;
  BEGIN
    IF EXCCHAREC_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'EXCCHAREC_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(EXCCHAREC_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF EXCAPPTYPE_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'EXCAPPTYPE_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(EXCAPPTYPE_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    FOR ITR_REC IN APPORTION_PO_RECS(EXCCHAREC_IN) LOOP
      L_DIVISOR := L_DIVISOR + GET_PO_APP_DIVISOR(ITR_REC, EXCAPPTYPE_IN, IGNORE_FIXED, ALLOW_NEW_ITE);
    END LOOP;

    RETURN L_DIVISOR;
  EXCEPTION
     WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END GET_PO_APP_TOTAL;

  FUNCTION CAN_APPORT_PO(EXCCHAREC_IN EXPCHA.EXCCHAREC%TYPE, EXCAPPTYPE_IN EXPCHA.EXCAPPTYPE%TYPE, IGNORE_FIXED BOOLEAN, ALLOW_NEW_ITE BOOLEAN) RETURN BOOLEAN
  IS
    CAN_APPORT        BOOLEAN := TRUE;
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    L_DIVISOR         FLOAT := 0.0;
  BEGIN
    IF EXCCHAREC_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'EXCCHAREC_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(EXCCHAREC_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF EXCAPPTYPE_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'EXCAPPTYPE_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(EXCAPPTYPE_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    L_DIVISOR := GET_PO_APP_TOTAL(EXCCHAREC_IN, EXCAPPTYPE_IN, IGNORE_FIXED, ALLOW_NEW_ITE);

    IF ABS(L_DIVISOR) < 0.0001 THEN
      CAN_APPORT := FALSE;
    END IF;

    RETURN CAN_APPORT;
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END CAN_APPORT_PO;

  PROCEDURE APPORTION_PO_COST(EXCCHAREC_IN EXPCHA.EXCCHAREC%TYPE, NEWRAWAMM_IN EXPCHA.EXCRAWAMM%TYPE, IGNORE_FIXED BOOLEAN, ALLOW_NEW_ITE BOOLEAN)
  IS
    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    EXPCHA_REC          EXPCHA%ROWTYPE;
    L_DIVIDEND          FLOAT;
    L_DIVISOR           FLOAT;
    ITECHGS_TO_WRITE    FT_PK_COST_WRITES.ITECHG_RECS := FT_PK_COST_WRITES.ITECHG_RECS();
    L_AMTLEFTTOAPP      FLOAT;
    L_THISREC           INTEGER;
    L_THISAMT           FLOAT;
    L_RAWAMT            FLOAT;
  BEGIN
    IF EXCCHAREC_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'EXCCHAREC_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(EXCCHAREC_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    IF NEWRAWAMM_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'NEWRAWAMM_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(NEWRAWAMM_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    L_RAWAMT := ROUND(NEWRAWAMM_IN, 2);

    SELECT * INTO EXPCHA_REC FROM EXPCHA WHERE EXPCHA.EXCCHAREC = EXCCHAREC_IN;

    IF ABS(L_RAWAMT) < 0.0 THEN
      IF EXPCHA_REC.EXCAUTHRAWAMM < L_RAWAMT THEN
        FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_APPORTCOST);
      END IF;
    ELSE
      IF EXPCHA_REC.EXCAUTHRAWAMM > L_RAWAMT THEN
        FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_APPORTCOST);
      END IF;
    END IF;

    L_DIVISOR := GET_PO_APP_TOTAL(EXPCHA_REC.EXCCHAREC, EXPCHA_REC.EXCAPPTYPE, IGNORE_FIXED, ALLOW_NEW_ITE);

    IF ABS(L_RAWAMT) > 0.009 THEN
      IF ABS(L_DIVISOR) < 0.0001 THEN
        FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_APPORTCOST);
      END IF;
    END IF;

    L_AMTLEFTTOAPP := L_RAWAMT;
    FOR ITR_REC IN APPORTION_PO_RECS(EXCCHAREC_IN) LOOP
      L_DIVIDEND := GET_PO_APP_DIVISOR(ITR_REC, EXPCHA_REC.EXCAPPTYPE, IGNORE_FIXED, ALLOW_NEW_ITE);
      IF NOT IGNORE_FIXED AND ITR_REC.ICHSPETO = POCOST_FIXED THEN
        CONTINUE;
      END IF;
      IF NOT ALLOW_NEW_ITE AND ITR_REC.ICHRECNO IS NULL THEN
        CONTINUE;
      END IF;
      ITECHGS_TO_WRITE.EXTEND(1);
      L_THISREC := ITECHGS_TO_WRITE.COUNT;
      IF ABS(L_RAWAMT) < 0.01 THEN
        L_THISAMT := 0.0;
      ELSE
        L_THISAMT := ROUND(L_RAWAMT * (L_DIVIDEND / L_DIVISOR), 2);
      END IF;
      IF ITR_REC.ICHRAWAUTHAMM < -0.009 THEN
        IF L_THISAMT > ITR_REC.ICHRAWAUTHAMM THEN
          L_THISAMT := ITR_REC.ICHRAWAUTHAMM;
        END IF;
      ELSE
        IF ITR_REC.ICHRAWAUTHAMM > 0.009 THEN
          IF L_THISAMT < ITR_REC.ICHRAWAUTHAMM THEN
            L_THISAMT := ITR_REC.ICHRAWAUTHAMM;
          END IF;
        END IF;
      END IF;
      IF L_RAWAMT < 0.0 THEN
        L_AMTLEFTTOAPP := L_AMTLEFTTOAPP + L_THISAMT;
      ELSE
        L_AMTLEFTTOAPP := L_AMTLEFTTOAPP - L_THISAMT;
      END IF;
      IF ITR_REC.ICHRECNO IS NOT NULL THEN
        ITECHGS_TO_WRITE(L_THISREC).ICHRECNO := ITR_REC.ICHRECNO;
      ELSE
        ITECHGS_TO_WRITE(L_THISREC).EXCRECNO  := EXPCHA_REC.EXCCHAREC;
        ITECHGS_TO_WRITE(L_THISREC).CTYNO     := EXPCHA_REC.EXCCTYNO;
        ITECHGS_TO_WRITE(L_THISREC).LITRECNO  := ITR_REC.LITITENO;
        ITECHGS_TO_WRITE(L_THISREC).ICHAPPFAC := EXPCHA_REC.EXCAPPTYPE;
        ITECHGS_TO_WRITE(L_THISREC).ICHCHGFOR := CONST.C_FOR_PO;
        ITECHGS_TO_WRITE(L_THISREC).ICHCHNGDBYUSER := CONST.C_FALSE;
      END IF;
      ITECHGS_TO_WRITE(L_THISREC).ICHRAWAPPAMT := L_THISAMT;
      ITECHGS_TO_WRITE(L_THISREC).ICHRAWAUTHAMM := ITR_REC.ICHRAWAUTHAMM;
    END LOOP;

    FOR ITR IN ITECHGS_TO_WRITE.FIRST..ITECHGS_TO_WRITE.LAST LOOP
      IF ABS(L_AMTLEFTTOAPP) > 0.009 THEN
        IF L_RAWAMT < 0.0 THEN
          IF (ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT + L_AMTLEFTTOAPP) <  ITECHGS_TO_WRITE(ITR).ICHRAWAUTHAMM THEN
            ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT := ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT + L_AMTLEFTTOAPP;
            L_AMTLEFTTOAPP := 0.0;
          ELSE
            ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT := ITECHGS_TO_WRITE(ITR).ICHRAWAUTHAMM;
            L_AMTLEFTTOAPP := ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT - ITECHGS_TO_WRITE(ITR).ICHRAWAUTHAMM;
          END IF;
        ELSE
          IF (ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT + L_AMTLEFTTOAPP) > ITECHGS_TO_WRITE(ITR).ICHRAWAUTHAMM THEN
            ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT := ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT + L_AMTLEFTTOAPP;
            L_AMTLEFTTOAPP := 0.0;
          ELSE
            ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT := ITECHGS_TO_WRITE(ITR).ICHRAWAUTHAMM;
            L_AMTLEFTTOAPP := ITECHGS_TO_WRITE(ITR).ICHRAWAPPAMT - ITECHGS_TO_WRITE(ITR).ICHRAWAUTHAMM;
          END IF;
        END IF;
      END IF;
    END LOOP;

    FOR ITR IN ITECHGS_TO_WRITE.FIRST..ITECHGS_TO_WRITE.LAST LOOP
      IF ITECHGS_TO_WRITE(ITR).ICHRECNO IS NOT NULL THEN
        UPDATE_ITECHG(ITECHGS_TO_WRITE(ITR));
      ELSE
        INSERT_ITECHG(ITECHGS_TO_WRITE(ITR));
      END IF;
    END LOOP;
  EXCEPTION
    WHEN FT_PK_ERRNUMS.EXC_NONCRITICAL_ERROR THEN
      PARAMETER_LIST('#EXCCHAREC') := TO_CHAR(EXCCHAREC_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_APPORTCOST, PARAMETER_LIST);
    WHEN NO_DATA_FOUND THEN
      PARAMETER_LIST('#PARAMNAME') := 'EXCCHAREC_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(EXCCHAREC_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END APPORTION_PO_COST;

  PROCEDURE UPDATE_EXPCHA(EXPCHA_INOUT IN OUT EXPCHA%ROWTYPE)
  IS
    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    EXPCHA_REC          EXPCHA%ROWTYPE;
  BEGIN
    IF EXPCHA_INOUT.EXCCHAREC IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'EXCCHAREC';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(EXPCHA_INOUT.EXCCHAREC);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    SELECT * INTO EXPCHA_REC FROM EXPCHA WHERE EXPCHA.EXCCHAREC = EXPCHA_INOUT.EXCCHAREC;

    EXPCHA_REC.EXCCHAPERRATE := EXPCHA_INOUT.EXCCHAPERRATE;

    UPDATE EXPCHA
    SET ROW = EXPCHA_REC
    WHERE EXPCHA.EXCCHAREC = EXPCHA_REC.EXCCHAREC;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      PARAMETER_LIST('#PARAMNAME') := 'EXCCHAREC';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(EXPCHA_INOUT.EXCCHAREC);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END;

END FT_PK_COST_WRITES;
/
