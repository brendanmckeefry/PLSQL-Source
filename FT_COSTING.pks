--########################################################################################################
-- FT_COSTING  (Package) 
-- 
-- Contains methods to calculate costs from the costing module
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_COSTING AS 

  PROCEDURE AUTO_PO_COSTS(LITRECS_IN RECORD_NUMBERS);
  
END FT_COSTING;
/
