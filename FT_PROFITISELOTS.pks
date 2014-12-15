--########################################################################################################
-- FT_PROFITISELOTS  (Package) 
-- 
-- Methods related to profitising lots
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_PROFITISELOTS AS 

  PROCEDURE LOTPROFITABILITY(REQDISTSTAB_IN VARCHAR2, AUTOSALESTAB_IN VARCHAR2);

END FT_PROFITISELOTS;
/
