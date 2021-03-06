CREATE OR REPLACE PACKAGE FT_PK_PRODUCTS AS

  CSPECVERSIONCONTROLNO   VARCHAR2(12) := '1.0.1'; -- Current Version Number For Spec

V_SO_PRODLIMITBYSALOFF      NUMBER(1) := 0;
V_SO_SPECIFIC_PRDSHORTCODE  NUMBER(1) := 0;

/*
THIS PROCEDURE EXTRACTS THE SALES OFFICE SPECIFIC PRODUCT SHORT CODE
THIS IS NORMALLY THE PRDREC.PRCSHORTDESC BUT IF THE SYSPREF PRODSHORTCODEBYSALOFF IS TRUE THEN THIS IS PICKED UP FROM PRDRECTOSO.SOSHORTCODE
*/

FUNCTION GETPRDSHORTCODE(   In_PrcPrdNo     IN NUMBER,
                            In_SalOffNo     IN NUMBER       )
                            --RETURN PRDREC.PRCSHORTDESC%TYPE ;   -- UNABLE TO USE THIS AS THE TRIM DOES NOT WORK AND IT PASSS THE CODE BACK WITH SPACES AT THE END
                            RETURN VARCHAR2;

/*
THIS PROCEDURE WILL FLAG WHETHER A PRODUCT IS FOR A SALES OFFICE OR NOT
IF NOT PRODLIMITBYSALOFF THEN THIS WILL ALWAYS BE 1
IF  In_SalOffNo IS <=0  OR >= 32767 THEN THIS WILL ALWAYS BE 1 AS YOU THE USRE IS OT USING A VALID SALES OFFICE
OTHERWISE IT WILL BE 1 IF IT IS IN THE PRDRECTOSO TABLE ELSE O
*/
FUNCTION ISPRDFORSALESOFFICE(   In_PrcPrdNo     IN NUMBER,
                            In_SalOffNo     IN NUMBER       )
                            --RETURN PRDREC.PRCSHORTDESC%TYPE ;   -- UNABLE TO USE THIS AS THE TRIM DOES NOT WORK AND IT PASSS THE CODE BACK WITH SPACES AT THE END
                            RETURN NUMBER;


FUNCTION GETPRODUCTDESCFORLEVEL(   In_LstLevRecNo     IN NUMBER)
                            RETURN VARCHAR2;

END FT_PK_PRODUCTS;