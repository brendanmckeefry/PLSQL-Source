create or replace PACKAGE FT_PK_SALES  AS

  cSpecVersionControlNo   VARCHAR2(12) := '1.0.3'; -- Current Version Number For Spec
  V_USEAUTOCOSTING   NUMBER(5) := 0;
  
  FUNCTION CURRENTVERSION (IN_BODYORSPEC IN INTEGER := 1) RETURN VARCHAR2;

  PROCEDURE DELPRICE_NETTVALUE(IN_DPRRECNO IN NUMBER );

  FUNCTION DELPRICE_CALCNETTVALUE(IN_DPRRECNO IN NUMBER) RETURN DELPRICE.DELNETTVALUE%TYPE;

  PROCEDURE DELPRICE_CALCVATFIGURES(IN_DPRRECNO IN NUMBER);

  PROCEDURE DELTOIST_UPDATEVALUES(IN_DPRRECNO IN NUMBER, VERIFYDELIVERY NUMBER);
  
  FUNCTION GET_LOT_SOLD_QTY(LITITENO_IN LOTITE.LITITENO%TYPE) RETURN FLOAT;
  
  PROCEDURE PROCESS_DELAUDIT_FORAUTOCOST;
  
  PROCEDURE GET_DELAUDIT_FORAUTOCOST(LOWER_DELAUDRECNO DELAUDIT.DELAUDRECNO%TYPE, HIGHER_DELAUDRECNO DELAUDIT.DELAUDRECNO%TYPE);

END FT_PK_SALES;