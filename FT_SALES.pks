--########################################################################################################
-- FT_SALES  (Package) 
-- 
-- Methods related sales orders
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_SALES AS 

  FUNCTION GET_LOT_SOLD_QTY(LITITENO_IN LOTITE.LITITENO%TYPE) RETURN FLOAT;

END FT_SALES;
/
