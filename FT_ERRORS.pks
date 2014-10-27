--########################################################################################################
-- FT_ERRORS  (Package) 
-- 
-- Contains methods to be used for raising and dealing with exceptions
-- Writes to table FT_ERROR_LOG
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_ERRORS
AS
  PROCEDURE LOG_AND_STOP;
  
  PROCEDURE LOG_AND_CONTINUE;
  
  PROCEDURE RAISE_ERROR(
      FTERR_IN IN FT_ERROR_CODES.FTERRORNO%TYPE);
      
  PROCEDURE RAISE_ERROR(
      FTERR_IN      IN FT_ERROR_CODES.FTERRORNO%TYPE,
      TOKEN_LIST_IN IN FT_STRING_UTILS.TYPE_STRING_TOKENS);
      
  PROCEDURE RAISE_ERROR(
      FTERR_IN    IN FT_ERROR_CODES.FTERRORNO%TYPE,
      FTERRMSG_IN IN FT_ERROR_CODES.FTERRORMSG%TYPE);
      
  PROCEDURE RAISE_ERROR(
      FTERR_IN      IN FT_ERROR_CODES.FTERRORNO%TYPE,
      FTERRMSG_IN   IN FT_ERROR_CODES.FTERRORMSG%TYPE,
      TOKEN_LIST_IN IN FT_STRING_UTILS.TYPE_STRING_TOKENS);
      
  FUNCTION RETURN_FT_ERROR
    RETURN FT_ERROR_CODES.FTERRORNO%TYPE;
END FT_ERRORS;
/
