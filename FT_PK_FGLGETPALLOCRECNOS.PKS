CREATE OR REPLACE PACKAGE FT_PK_FGLGETPALLOCRECNOS  AS
-- PACKAGE CREATED TO MAKE PALLOCRECNOS AVAILABLE FOR FGL WHERE THE PALLOCRECNO SEQUENCE HAS BEEN COMPROMISED  

  cSpecVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number For Spec
  
  FUNCTION CURRENTVERSION (IN_BODYORSPEC IN INTEGER := 1) RETURN VARCHAR2;

  PROCEDURE MAINPROC;
  
  PROCEDURE POPULATEPALLOCRECNOS;  

  PROCEDURE DELETEUSEDPALLOCRECNOS;


END FT_PK_FGLGETPALLOCRECNOS;
/
