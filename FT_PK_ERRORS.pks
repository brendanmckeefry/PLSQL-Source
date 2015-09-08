CREATE OR REPLACE PACKAGE FT_PK_ERRORS AS

  --cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number
  
  FUNCTION CURRENTVERSION RETURN VARCHAR2;

  PROCEDURE LOG_AND_STOP;

  PROCEDURE LOG_AND_CONTINUE;

  PROCEDURE RAISE_ERROR(
      FTERR_IN IN FT_ERROR_CODES.FTERRORNO%TYPE);

  PROCEDURE RAISE_ERROR(
      FTERR_IN      IN FT_ERROR_CODES.FTERRORNO%TYPE,
      TOKEN_LIST_IN IN FT_PK_STRING_UTILS.TYPE_STRING_TOKENS);

  PROCEDURE RAISE_ERROR(
      FTERR_IN    IN FT_ERROR_CODES.FTERRORNO%TYPE,
      FTERRMSG_IN IN FT_ERROR_CODES.FTERRORMSG%TYPE);

  PROCEDURE RAISE_ERROR(
      FTERR_IN      IN FT_ERROR_CODES.FTERRORNO%TYPE,
      FTERRMSG_IN   IN FT_ERROR_CODES.FTERRORMSG%TYPE,
      TOKEN_LIST_IN IN FT_PK_STRING_UTILS.TYPE_STRING_TOKENS);

  FUNCTION RETURN_FT_ERROR
    RETURN FT_ERROR_CODES.FTERRORNO%TYPE;
END FT_PK_ERRORS;
/
