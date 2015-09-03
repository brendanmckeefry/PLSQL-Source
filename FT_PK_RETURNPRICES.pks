CREATE OR REPLACE PACKAGE FT_PK_RETURNPRICES AS

  --cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number

  PROCEDURE GET_RETURN_PRICES(LITITENO_IN LOTITE.LITITENO%TYPE, RETURNQTY_OUT OUT LOTRETURNPRICES.LOTRETURNQTY%TYPE, RETURNVAL_OUT OUT LOTRETURNPRICES.LOTRETURNVALUE%TYPE);

END FT_PK_RETURNPRICES;
/
