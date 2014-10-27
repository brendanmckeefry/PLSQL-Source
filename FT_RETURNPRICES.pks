--########################################################################################################
-- FT_RETURNPRICES  (Package) 
-- 
-- Methods related to reporting prices to suppliers
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_RETURNPRICES AS 

  PROCEDURE GET_RETURN_PRICES(LITITENO_IN LOTITE.LITITENO%TYPE, RETURNQTY_OUT OUT LOTRETURNPRICES.LOTRETURNQTY%TYPE, RETURNVAL_OUT OUT LOTRETURNPRICES.LOTRETURNVALUE%TYPE);

END FT_RETURNPRICES;
/
