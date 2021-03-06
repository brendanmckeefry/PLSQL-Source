CREATE OR REPLACE PACKAGE BODY FT_PK_ERRORS AS

  cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number
  
  C_DELIMTERCHAR          CHAR(1) := '#';

  FUNCTION CURRENTVERSION RETURN VARCHAR2
  IS
  BEGIN
     RETURN cVersionControlNo;
  END CURRENTVERSION;

  FUNCTION STRIP_FT_ERROR_NO(FTERRMSG_INOUT IN OUT FT_ERROR_CODES.FTERRORMSG%TYPE) RETURN FT_ERROR_CODES.FTERRORNO%TYPE
  IS
    L_ORAMSG      FT_ERROR_CODES.FTERRORMSG%TYPE := FTERRMSG_INOUT;
    L_FTERRNO     FT_ERROR_CODES.FTERRORNO%TYPE  := FT_PK_ERRNUMS.FT_NO_ERROR;
    L_START_POS   INTEGER;
    L_FINISH_POS  INTEGER;
  BEGIN
      BEGIN
        L_START_POS := INSTR(L_ORAMSG, C_DELIMTERCHAR, 1, 1);
        L_FINISH_POS := INSTR(L_ORAMSG, C_DELIMTERCHAR, 1, 2);

        IF L_START_POS > 0 AND L_FINISH_POS > 0 THEN
          L_FTERRNO := TO_NUMBER(SUBSTR(L_ORAMSG, L_START_POS+1, (L_FINISH_POS - L_START_POS)-1));
          L_ORAMSG := SUBSTR(L_ORAMSG, L_FINISH_POS+1);
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          L_FTERRNO := FT_PK_ERRNUMS.FT_UNKNOWN;
      END;

      FTERRMSG_INOUT := L_ORAMSG;

      RETURN L_FTERRNO;
  END STRIP_FT_ERROR_NO;

  PROCEDURE LOGERROR
  IS
  PRAGMA AUTONOMOUS_TRANSACTION;
    L_ORACODE INTEGER := SQLCODE;
    L_ORAMSG  VARCHAR2(2000) := SQLERRM;
    L_FTERRNO FT_ERROR_LOG.FTERRORNO%TYPE;
  BEGIN
    L_FTERRNO := STRIP_FT_ERROR_NO(L_ORAMSG);

    INSERT INTO FT_ERROR_LOG( FTERRORNO,
                              ORAERRNO,
                              ORAERRMSG,
                              ERRTRACE,
                              ERRCALLSTACK,
                              ERRDATE,
                              ERRUSER)
    VALUES( L_FTERRNO,
            L_ORACODE,
            L_ORAMSG,
            SYS.DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            SYS.DBMS_UTILITY.FORMAT_CALL_STACK,
            SYSDATE,
            SYS_CONTEXT('USERENV', 'OS_USER'));

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE FT_PK_ERRNUMS.EXC_UNHANDLED_ERROR;
      ROLLBACK;
  END LOGERROR;

  PROCEDURE LOG_AND_STOP
  IS
  BEGIN
    LOGERROR();
    RAISE FT_PK_ERRNUMS.EXC_UNHANDLED_ERROR;
  END LOG_AND_STOP;

  PROCEDURE LOG_AND_CONTINUE
  IS
  BEGIN
    LOGERROR();
  END LOG_AND_CONTINUE;

  PROCEDURE RAISE_ERROR(FTERR_IN IN FT_ERROR_CODES.FTERRORNO%TYPE,
                        FTERRMSG_IN IN FT_ERROR_CODES.FTERRORMSG%TYPE,
                        TOKEN_LIST_IN IN FT_PK_STRING_UTILS.TYPE_STRING_TOKENS)
  IS
    REC_FT_ERROR_CODES      FT_ERROR_CODES%ROWTYPE;
    L_ORAERRNO              FT_ERROR_CODES.ORAERRNO%TYPE := FT_PK_ERRNUMS.EN_GENERAL_ERROR;
    L_ERRMSG                FT_ERROR_CODES.FTERRORMSG%TYPE;
  BEGIN
    L_ERRMSG := FTERRMSG_IN;

    BEGIN
      SELECT *
      INTO REC_FT_ERROR_CODES
      FROM FT_ERROR_CODES
      WHERE FTERRORNO = FTERR_IN;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        REC_FT_ERROR_CODES.FTERRORNO := FT_PK_ERRNUMS.FT_UNKNOWN;
        REC_FT_ERROR_CODES.FTERRORCODE := FT_PK_ERRNUMS.FT_UNKNOWN_CODE;
        REC_FT_ERROR_CODES.FTERRORMSG := FT_PK_ERRNUMS.FT_UNKNOWN_MSG;
        REC_FT_ERROR_CODES.ORAERRNO := FT_PK_ERRNUMS.FT_UNKNOWN_ORAERRNO;
      WHEN OTHERS THEN
        LOG_AND_STOP();
    END;

    L_ORAERRNO := REC_FT_ERROR_CODES.ORAERRNO;
    L_ERRMSG := NVL(FTERRMSG_IN, REC_FT_ERROR_CODES.FTERRORMSG);
    FT_PK_STRING_UTILS.REPLACETOKENS(L_ERRMSG, TOKEN_LIST_IN);
    FT_PK_STRING_UTILS.STRIPOUTCHAR(L_ERRMSG, C_DELIMTERCHAR);
    L_ERRMSG := C_DELIMTERCHAR || TO_CHAR(REC_FT_ERROR_CODES.FTERRORNO) || C_DELIMTERCHAR || L_ERRMSG;

    RAISE_APPLICATION_ERROR(L_ORAERRNO, L_ERRMSG);
  END RAISE_ERROR;

  PROCEDURE RAISE_ERROR(FTERR_IN IN FT_ERROR_CODES.FTERRORNO%TYPE)
  IS
    EMPTY_TOKEN_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    RAISE_ERROR(FTERR_IN, NULL, EMPTY_TOKEN_LIST);
  END RAISE_ERROR;

  PROCEDURE RAISE_ERROR(FTERR_IN IN FT_ERROR_CODES.FTERRORNO%TYPE,
                        FTERRMSG_IN IN FT_ERROR_CODES.FTERRORMSG%TYPE)
  IS
    EMPTY_TOKEN_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    RAISE_ERROR(FTERR_IN, FTERRMSG_IN, EMPTY_TOKEN_LIST);
  END RAISE_ERROR;

  PROCEDURE RAISE_ERROR(FTERR_IN IN FT_ERROR_CODES.FTERRORNO%TYPE, TOKEN_LIST_IN IN FT_PK_STRING_UTILS.TYPE_STRING_TOKENS)
  IS
  BEGIN
    RAISE_ERROR(FTERR_IN, NULL, TOKEN_LIST_IN);
  END RAISE_ERROR;

  FUNCTION RETURN_FT_ERROR RETURN FT_ERROR_CODES.FTERRORNO%TYPE
  IS
    RET_FT_ERROR  FT_ERROR_CODES.FTERRORNO%TYPE := FT_PK_ERRNUMS.FT_NO_ERROR;
    L_ORAMSG      VARCHAR2(2000) := SQLERRM;
  BEGIN
    RET_FT_ERROR := STRIP_FT_ERROR_NO(L_ORAMSG);

    RETURN RET_FT_ERROR ;
  END RETURN_FT_ERROR;

END FT_PK_ERRORS;
/
