--########################################################################################################
-- FT_DB_UTILS  (Package) 
-- 
-- Contains database related utility methods
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_DB_UTILS AS 
  
  FUNCTION TABLE_EXISTS(TABLE_NAME_IN VARCHAR2) RETURN BOOLEAN;

END FT_DB_UTILS;
/
