SET DEFINE OFF;
-- ************************************************************
-- PLEASE DO NOT USE THIS GOING FORWARD -- USE FT_PK_ACCOUNTS
-- ************************************************************

CREATE OR REPLACE PACKAGE BODY BSDL_PKAGE_ACCOUNTS
AS

FUNCTION  GETACCCODE(  In_ClaRecNo     IN NUMBER,
                       In_SalOffNo     IN NUMBER       )
                                                                --RETURN ACCCLASS.CLAACCCODE%TYPE IS V_ACCCODE ACCCLASS.CLAACCCODE%TYPE :=NULL ;
                                                                RETURN VARCHAR2  IS V_ACCCODE VARCHAR2(8)  :=NULL ;
    BEGIN

        V_ACCCODE := FT_PK_ACCOUNTS.GETACCCODE(In_ClaRecNo, In_SalOffNo);

    RETURN V_ACCCODE;



END GETACCCODE;

FUNCTION GETEXCLRECOVFLAG(CLARECNO_IN ACCCLASS.CLARECNO%TYPE) RETURN BOOLEAN
IS
  RET_EXCLFROMPL      BOOLEAN := FALSE;  
    BEGIN

        RET_EXCLFROMPL := FT_PK_ACCOUNTS.GETEXCLRECOVFLAG(CLARECNO_IN);

	RETURN RET_EXCLFROMPL;
  
    EXCEPTION

    WHEN OTHERS THEN
        FT_ERRORS.LOG_AND_STOP;

END GETEXCLRECOVFLAG;

END BSDL_PKAGE_ACCOUNTS;
/
