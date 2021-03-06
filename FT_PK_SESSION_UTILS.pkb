CREATE OR REPLACE PACKAGE BODY FT_PK_SESSION_UTILS AS

  cVersionControlNo   VARCHAR2(12) := '1.0.3'; -- Current Version Number

  G_SID       INTEGER := SYS_CONTEXT('USERENV','SID');
  G_AUDSID       INTEGER := SYS_CONTEXT('USERENV','SESSIONID');
  G_LOGONNO   LOGONS.LOGONNO%TYPE := 0;

  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE  
      RETURN cVersionControlNo;
    END IF;                
  END CURRENTVERSION;

  FUNCTION GET_SID RETURN INTEGER
  IS
  BEGIN
    RETURN G_SID ;
  END GET_SID;

  FUNCTION GET_FT_LOGONNO RETURN LOGONS.LOGONNO%TYPE
  IS
    RET_LOGONNO     LOGONS.LOGONNO%TYPE;
  BEGIN
    IF G_LOGONNO = 0 THEN
      SELECT MIN(LOGONNO) INTO G_LOGONNO FROM USERSESSNOLOG WHERE ORACLESESSRECNO = G_AUDSID;       
    END IF;

    RET_LOGONNO := G_LOGONNO;
    RETURN RET_LOGONNO;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_DATA);
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END GET_FT_LOGONNO;

  FUNCTION LIST_ACTIVE_SID RETURN RECORD_NUMBERS
  IS
    RETURN_SIDS       RECORD_NUMBERS := RECORD_NUMBERS();
  BEGIN
    SELECT SID
    BULK COLLECT INTO RETURN_SIDS
    FROM V$SESSION;
    
    RETURN RETURN_SIDS;
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END LIST_ACTIVE_SID;    
    

END FT_PK_SESSION_UTILS;
/
