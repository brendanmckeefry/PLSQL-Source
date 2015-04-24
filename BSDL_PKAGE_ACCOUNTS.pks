SET DEFINE OFF;
-- ************************************************************
-- PLEASE DO NOT USE THIS GOING FORWARD -- USE FT_PK_ACCOUNTS
-- ************************************************************
CREATE OR REPLACE PACKAGE BSDL_PKAGE_ACCOUNTS
AS
FUNCTION GETACCCODE(   In_ClaRecNo     IN NUMBER,
                        In_SalOffNo     IN NUMBER       )
                        RETURN VARCHAR2;
                        
FUNCTION GETEXCLRECOVFLAG(CLARECNO_IN ACCCLASS.CLARECNO%TYPE) RETURN BOOLEAN;

END BSDL_PKAGE_ACCOUNTS;
/
