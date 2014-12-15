--########################################################################################################
-- Utility methods related to Freshtrade accounts
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_PK_ACCOUNTS

AS
	cVersionControlNo    VARCHAR2 (12) := '1.0.1'; -- Current Version Number   	    
	V_SO_Specific_ACCCode  NUMBER(1) := 0;

/* THIS PROCEDURE EXTRACTS THE ACCOUNT CODE FOR A SALES OFFICES
THIS IS NORMALLY THE ACCOUNTS.ACCCODE and ACCCLASS.CLAACCCODE NUT IF THE SYSPREF SALOFFACCCODE IS TRUE THEN THIS IS PICKED UP FROM ACCTOSALOFF.ACSACCCODE
*/
    FUNCTION GETACCCODE(   In_ClaRecNo     IN NUMBER,
                            In_SalOffNo     IN NUMBER       )
                            --RETURN ACCCLASS.CLAACCCODE%TYPE ;   -- UNABLE TO USE THIS AS THE TRIM DOES NOT WORK AND IT PASSS THE CODE BACK WITH SPACES AT THE END
                            RETURN VARCHAR2;
                        
    FUNCTION GETEXCLRECOVFLAG(CLARECNO_IN ACCCLASS.CLARECNO%TYPE) RETURN BOOLEAN;

    FUNCTION  CURRENTVERSION RETURN VARCHAR2; 

END FT_PK_ACCOUNTS;
/
