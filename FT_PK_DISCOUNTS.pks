CREATE OR REPLACE PACKAGE FT_PK_DISCOUNTS AS

  cSpecVersionControlNo VARCHAR2(12) := '1.0.0';
  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2;
  PROCEDURE DO_DISCOUNTS(IN_DPRRECNO IN DELPRICE.DPRRECNO%TYPE);

END FT_PK_DISCOUNTS;