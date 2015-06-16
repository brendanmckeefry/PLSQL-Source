CREATE OR REPLACE PACKAGE FT_PK_GETSALES AS 

  cSpecVersionControlNo VARCHAR2(12) := '1.0.2';
  
  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2;

  PROCEDURE GETSALES;
  PROCEDURE GETSALES(DPRRECNO_IN DELPRICE.DPRRECNO%TYPE);
  
  PROCEDURE GETLOTS(LITITENO_IN LOTITE.LITITENO%TYPE);

END FT_PK_GETSALES;
/
