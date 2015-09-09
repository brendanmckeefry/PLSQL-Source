create or replace PACKAGE BODY FT_PK_DGP AS
  
  cVersionControlNo   VARCHAR2(12) := '1.0.2'; -- Current Version Number
  SYS_LDODGPREPORTS   BOOLEAN := TO_BOOLEAN(FT_PK_UTILS.GET_SYSPREF('LDODGPREPORTS'));

  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE  
      RETURN cVersionControlNo;
    END IF;                
  END CURRENTVERSION;

  PROCEDURE ENQUEUE_DGPDPRSTODO(DPRRECNO_IN DELPRICE.DPRRECNO%TYPE)
  IS
  BEGIN
    IF SYS_LDODGPREPORTS THEN
      IF DPRRECNO_IN > 0 THEN
        INSERT INTO DGPDPRSTODO(DGPDPRRECNO,DGPDLVORDNO)
        SELECT DELPRICE.DPRRECNO, DELDET.DELDLVORDNO
        FROM DELPRICE DELPRICE
        INNER JOIN DELDET DELDET
        ON DELDET.DELRECNO = DELPRICE.DPRDELRECNO
        WHERE DELPRICE.DPRRECNO = DPRRECNO_IN 
          AND NOT EXISTS(SELECT * FROM DGPDPRSTODO WHERE DGPDPRRECNO = DELPRICE.DPRRECNO); 
          
        COMMIT;
      END IF;
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      NULL; --Ignore for small proportion of key violations  
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_CONTINUE;
  END ENQUEUE_DGPDPRSTODO;
  
END FT_PK_DGP;
/
