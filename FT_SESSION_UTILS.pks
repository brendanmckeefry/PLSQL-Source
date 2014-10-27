--########################################################################################################
-- FT_SESSION_UTILS  (Package) 
-- 
-- Methods related retrieving session related information
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_SESSION_UTILS AS

  FUNCTION GET_FT_LOGONNO RETURN LOGONS.LOGONNO%TYPE;
  FUNCTION GET_SID RETURN INTEGER;

END FT_SESSION_UTILS;
/
