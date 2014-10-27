--########################################################################################################
-- BSDL_PKAGE_ACCOUNTS  (Package) 
-- 
-- Utility methods related to Freshtrade accounts
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE BSDL_PKAGE_ACCOUNTS


AS
V_SO_Specific_ACCCode  NUMBER(1) := 0;

/* THIS PROCEDURE EXTRACTS THE ACCOUNT CODE FOR A SALES OFFICES
THIS IS NORMALLY THE ACCOUNTS.ACCCODE & ACCCLASS.CLAACCCODE NUT IF THE SYSPREF SALOFFACCCODE IS TRUE THEN THIS IS PICKED UP FROM ACCTOSALOFF.ACSACCCODE
*/
FUNCTION GETACCCODE(   In_ClaRecNo     IN NUMBER,
                        In_SalOffNo     IN NUMBER       )
                        --RETURN ACCCLASS.CLAACCCODE%TYPE ;   -- UNABLE TO USE THIS AS THE TRIM DOES NOT WORK AND IT PASSS THE CODE BACK WITH SPACES AT THE END
                        RETURN VARCHAR2;
                        
FUNCTION GETEXCLRECOVFLAG(CLARECNO_IN ACCCLASS.CLARECNO%TYPE) RETURN BOOLEAN;

END BSDL_PKAGE_ACCOUNTS;
/
