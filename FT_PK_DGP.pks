create or replace PACKAGE FT_PK_DGP AS 

  cSpecVersionControlNo VARCHAR2(12) := '1.0.0';

  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2;
  
  PROCEDURE ENQUEUE_DGPDPRSTODO(DPRRECNO_IN DELPRICE.DPRRECNO%TYPE);

END FT_PK_DGP;