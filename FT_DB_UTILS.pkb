--########################################################################################################
-- FT_DB_UTILS  (Package Body) 
-- 
-- Contains database related utility methods
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE BODY FT_DB_UTILS AS

  FUNCTION TABLE_EXISTS(TABLE_NAME_IN VARCHAR2) RETURN BOOLEAN 
  IS
    L_TBLCNT          INTEGER;
    L_RETTBLEXISTS    BOOLEAN := FALSE;
    PARAMETER_LIST    FT_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    IF TABLE_NAME_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'TABLE_NAME_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(TABLE_NAME_IN);
      FT_ERRORS.RAISE_ERROR(FT_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF; 
  
    SELECT COUNT(*)
    INTO L_TBLCNT
    FROM USER_OBJECTS
    WHERE OBJECT_NAME = TABLE_NAME_IN;

    IF L_TBLCNT > 0 THEN 
      L_RETTBLEXISTS := TRUE;
    END IF;
    
    RETURN L_RETTBLEXISTS;
  END TABLE_EXISTS;

END FT_DB_UTILS;
/
