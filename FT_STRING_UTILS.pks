--########################################################################################################
-- FT_STRING_UTILS (Package) 
-- 
-- Utility methods relating to strings
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_STRING_UTILS AS 

  TYPE TYPE_STRING_TOKENS IS TABLE OF VARCHAR2(30) INDEX BY VARCHAR2(30);

  PROCEDURE STRIPOUTCHAR(SRCSTR_INOUT IN OUT VARCHAR2, STRIPCHAR_IN IN VARCHAR2);
  PROCEDURE REPLACETOKENS(SRCSTR_INOUT IN OUT VARCHAR2, TOKEN_LIST IN TYPE_STRING_TOKENS);

END FT_STRING_UTILS;
/
