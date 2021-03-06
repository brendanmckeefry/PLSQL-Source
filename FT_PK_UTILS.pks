CREATE OR REPLACE PACKAGE FT_PK_UTILS AS

  --cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number

  TYPE SYS_PREFS IS TABLE OF WIZSYSPREF.SYSPREFVALUE%TYPE INDEX BY VARCHAR2(30);

  PROCEDURE GET_SYSPREFS(SYSPREFS_INOUT IN OUT SYS_PREFS);
  FUNCTION GET_SYSPREF(SYSPREFNAME_IN VARCHAR2) RETURN WIZSYSPREF.SYSPREFVALUE%TYPE;

END FT_PK_UTILS;
/
