--########################################################################################################
-- FT_EMAIL  (Package) 
-- 
-- Contains methods to generate emails to be passed to 
-- standard BSDL routine
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_EMAIL AS 

  PROCEDURE PROCESS_EMAILS;
  
  FUNCTION FT_ERROR_LOG_MSG RETURN CLOB;
  PROCEDURE FT_ERROR_LOG_FLAG(EMAILBATCHNO_IN INTEGER);

END FT_EMAIL;
/
