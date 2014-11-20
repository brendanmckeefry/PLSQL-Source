--########################################################################################################
-- FT_STRING_UTILS (Package Body) 
-- 
-- Utility methods relating to strings
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE BODY FT_STRING_UTILS AS

  PROCEDURE STRIPOUTCHAR(SRCSTR_INOUT IN OUT VARCHAR2, STRIPCHAR_IN IN VARCHAR2)
  IS
    L_SRCSTR     VARCHAR2(2000);
    L_STRIPCHAR  VARCHAR2(1);
    L_STRPART1   VARCHAR2(2000);
    L_STRPART2   VARCHAR2(2000);
  BEGIN
    L_SRCSTR := SRCSTR_INOUT;
    L_STRIPCHAR := SUBSTR(STRIPCHAR_IN, 1);
  
    IF (LENGTH(L_SRCSTR) > 0 AND LENGTH(L_STRIPCHAR) = 1) THEN
      BEGIN
        WHILE INSTR(L_SRCSTR, L_STRIPCHAR) > 0 LOOP
          
          IF INSTR(L_SRCSTR, L_STRIPCHAR) = 1 THEN
              L_STRPART1 := '';
              L_STRPART2 := SUBSTR(L_SRCSTR, 2);
          ELSE
              L_STRPART1 := SUBSTR(L_SRCSTR, 1, INSTR(L_SRCSTR, TRIM(L_STRIPCHAR)) - 1);
              L_STRPART2 := SUBSTR(L_SRCSTR, INSTR(L_SRCSTR, TRIM(L_STRIPCHAR)) + 1);
          END IF;
          L_SRCSTR := L_STRPART1 || L_STRPART2;
        END LOOP;
        
        SRCSTR_INOUT := L_SRCSTR;
      END;
    END IF;
  END STRIPOUTCHAR;
  
  PROCEDURE REPLACETOKENS(SRCSTR_INOUT IN OUT VARCHAR2, TOKEN_LIST IN TYPE_STRING_TOKENS)
  IS
    L_SRCSTR      VARCHAR2(2000);
    L_CUR_TOKEN   VARCHAR2(20);
    L_DONESTR     L_SRCSTR%TYPE;
    L_TOCHECKSTR  L_SRCSTR%TYPE;
    L_POSITION    INTEGER := -1;
  BEGIN
    L_SRCSTR := SRCSTR_INOUT;
    L_CUR_TOKEN := TOKEN_LIST.FIRST;
    WHILE L_CUR_TOKEN IS NOT NULL LOOP
       L_SRCSTR := REPLACE(L_SRCSTR, L_CUR_TOKEN, TOKEN_LIST(L_CUR_TOKEN));
       L_CUR_TOKEN := TOKEN_LIST.NEXT(L_CUR_TOKEN);
    END LOOP;
    
    SRCSTR_INOUT := L_SRCSTR;
  END REPLACETOKENS;
    
END FT_STRING_UTILS;
/
