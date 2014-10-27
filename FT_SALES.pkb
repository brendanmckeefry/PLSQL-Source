--
-- FT_SALES  (Package Body) 
--
CREATE OR REPLACE PACKAGE BODY FT_SALES AS

  FUNCTION GET_LOT_SOLD_QTY(LITITENO_IN LOTITE.LITITENO%TYPE) RETURN FLOAT
  IS
    RET_SALESQTY      FLOAT := 0.0;
    L_BULKQTY         FLOAT := 0.0;
    L_PREPACKQTY      FLOAT := 0.0;
    PARAMETER_LIST    FT_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_ERRORS.RAISE_ERROR(FT_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
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
      FT_ERRORS.RAISE_ERROR(FT_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    WHEN OTHERS THEN
      FT_ERRORS.LOG_AND_STOP;
  END GET_LOT_SOLD_QTY;

END FT_SALES;
/
