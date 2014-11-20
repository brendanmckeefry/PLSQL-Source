--########################################################################################################
-- FT_UTILS  (Package) 
-- 
-- Generic Freshtrade utility methods
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_UTILS AS 

  TYPE SYS_PREFS IS TABLE OF WIZSYSPREF.SYSPREFVALUE%TYPE INDEX BY VARCHAR2(30);
  
  PROCEDURE GET_SYSPREFS(SYSPREFS_INOUT IN OUT SYS_PREFS);
  FUNCTION GET_SYSPREF(SYSPREFNAME_IN VARCHAR2) RETURN WIZSYSPREF.SYSPREFVALUE%TYPE;

END FT_UTILS;
/
