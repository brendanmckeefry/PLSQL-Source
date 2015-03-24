CREATE OR REPLACE PACKAGE BODY FT_PK_SESSION_UTILS AS

  cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number

  G_SID       INTEGER := SYS_CONTEXT('USERENV','SID');
  G_LOGONNO   LOGONS.LOGONNO%TYPE := 0;

  FUNCTION CURRENTVERSION RETURN VARCHAR2
  IS
  BEGIN
     RETURN cVersionControlNo;
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
      SELECT MIN(LOGONNO) INTO G_LOGONNO FROM USERSESSNO WHERE ORA_SID = G_SID;
    END IF;

    RET_LOGONNO := G_LOGONNO;
    RETURN RET_LOGONNO;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_DATA);
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END GET_FT_LOGONNO;

END FT_PK_SESSION_UTILS;
/
