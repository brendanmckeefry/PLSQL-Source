CREATE OR REPLACE PACKAGE FT_PK_COSTING AS 

  --cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number
  
  FUNCTION CURRENTVERSION RETURN VARCHAR2;

  PROCEDURE AUTO_PO_COSTS(LITRECS_IN RECORD_NUMBERS);
  PROCEDURE AUTO_PO_COSTS(LITITENO_IN LOTITE.LITITENO%TYPE);
  
END FT_PK_COSTING;
/
