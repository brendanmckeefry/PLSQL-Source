SET DEFINE OFF;
CREATE OR REPLACE PACKAGE FT_PK_STOCKDISSECTION 
AS
    cVersionControlNo    VARCHAR2 (12) := '11.1.1'; -- Current Version Number   
    V_USELITPAYTYP   NUMBER(5) := 0;

    -- THIS IS THE PROCEDURE THAT CALLS ALL THE OTHERS
    PROCEDURE MAINRUN_FIRSTSTAGE(V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER);

    PROCEDURE MAINRUN_SNDSTAGE(V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER, V_UPTODATE IN DATE, V_USEDLVDATE IN NUMBER);

    -- THIS IS A FRIG THAT POPUALTES ANY ALLOCLITITENO, ALLOCDPTRECNO VALUES IN ALLOCATE THAT MAY HAVE BEEN MISSED
    PROCEDURE WRITEMISSINGALLOCDETS;

    -- EXTRACTS THE STOCK FIGURES FOR THE PASSED DEPARTMENT
    PROCEDURE EXTRACT_STK_FOR_DPT  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER);
    
    -- EXTRACTS THE OVERSOLD LINES FOR THE PASSED DEPARTMENT
    PROCEDURE EXTRACT_OVERSOLDLOTS  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER);
    
    -- EXTRACTS THE INTER DEPARTMENT TRANSFERS DONE SINCE THE LAST EXTRACT 
    PROCEDURE EXTRACT_INTERDPTTRANSFERS  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER);
    
    -- UPDATES THE SALES OFFICE FOR THE EXTRACTED LOTS AND REMOVES ANY NOT REQUIRED 
    PROCEDURE UPD_SALESOFFICE  (V_HDRRECNO IN NUMBER);
    
    -- gets the specfic acccode (supplier and customer) for the sales office and populates it into the 3 tables   
    PROCEDURE UPD_ACCCODE  (V_HDRRECNO IN NUMBER);

    -- UPDATES THE OPENING QTY FOR THE EXTRACTED LOTS  
    PROCEDURE UPD_OPENINGQTY  (V_HDRRECNO IN NUMBER);
    
    -- EXTRACTS THE ALREADY SOLD FIGURES AND THE VALUE OF THESE
    PROCEDURE EXTRACTALREDYSLD_DETS  (V_HDRRECNO IN NUMBER );

    -- EXTRACTS THE DETAILS OF THE DELIVERIES THAT ARE STILL AGAINST THE ALLOCATE
    PROCEDURE EXTRACTONALLOC_DETS  (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER, V_UPTODATE IN DATE, V_USEDLVDATE IN NUMBER);

    -- EXTRACTS THE DETAILS OF RETURNS AGAINST THE LOTITES THAT ARE ON THIS HEADER
    PROCEDURE EXTRACTRETURN_DETS  (V_HDRRECNO IN NUMBER);

    PROCEDURE FINALCALCS (V_HDRRECNO IN NUMBER);

    -- determines whether an allocate or deltoall is against an overallocated stock line - this does not include expected
    FUNCTION ISALLOCATE_OVERALLOC  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER)      RETURN  NUMBER;
    
    -- determines whether an allocate or deltoall is against an overallocated stock line - this does not include expected
    -- but it does breakdown the ALLOCALLOC by date
    FUNCTION ISALLOCATE_OVERALLOC  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER, V_UPTODATE IN DATE ) RETURN  NUMBER; 
    
    -- determines whether an allocate or deltoall is against an overallocated stock line - this does include expected
    FUNCTION ISALLOCATE_OVERALLOC_INCEXP  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER)      RETURN  NUMBER;
    
    -- determines whether an allocate or deltoall is against an overallocated stock line - this does include expected
    -- but it does breakdown the ALLOCALLOC by date
    FUNCTION ISALLOCATE_OVERALLOC_INCEXP  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER, V_UPTODATE IN DATE )      RETURN  NUMBER;
    
    -- CHKISALLOCATE_OVERALLOC is called by the above 2 functions
    FUNCTION CHKISALLOCATE_OVERALLOC  ( V_ALLOCNO in NUMBER, V_DELTOALL_ID in NUMBER, V_INC_EXPECTED in BOOLEAN, V_UPTODATE IN DATE )      RETURN  NUMBER;
    
    FUNCTION GET_OVERALLOC_DETAILS ( V_ALLOCNO in NUMBER, WHICHFLD in VARCHAR2)           RETURN  NUMBER;
    
    -- REMOVES THE UNCOMMITTED EXTRACTIONS FROM THE TABLES     
    PROCEDURE REMOVEUNCOMMITTED (V_DPTRECNO IN NUMBER, V_HDRRECNO IN NUMBER);
    
    -- REMOVES THE UNCOMMITTED EXTRACTIONS FROM THE TABLES     
    PROCEDURE REMOVEFULLEXTRACT (V_HDRRECNO IN NUMBER);
    
    -- this method includes all non-profitised lots - with a few restrictors passed in 
    PROCEDURE MAINRUN_ALLLOTS_FIRSTSTAGE(V_DPTRECNO IN NUMBER, 
                                         V_HDRRECNO IN NUMBER,
                                         V_PONO     IN NUMBER,
                                         V_LHERECNO IN NUMBER,
                                         V_SUPCLARECNO IN NUMBER,
                                         V_SUPGRPNO IN NUMBER,
                                         V_PAYTYP   IN NUMBER                                        
                                          );
    -- EXTRACTS THE STOCK FIGURES FOR THE PASSED DEPARTMENT, PO, LOT    
    PROCEDURE EXTRACT_STK_FOR_DETAILS  (V_DPTRECNO IN NUMBER, 
                                        V_HDRRECNO IN NUMBER,
                                        V_PONO     IN NUMBER,
                                        V_LHERECNO IN NUMBER,
                                        V_SUPCLARECNO IN NUMBER,
                                        V_SUPGRPNO IN NUMBER);

    -- REMOVES THE LOTS THAT DO NOT HAVE THE PAYMENT TYPE OR PO OR POT THAT WE WANT    
    PROCEDURE REMOVELOTS (V_HDRRECNO IN NUMBER,
                          V_PONO     IN NUMBER,
                          V_LHERECNO IN NUMBER,
                          V_PAYTYP   IN NUMBER                                        
                          );
    
    FUNCTION  CURRENTVERSION RETURN VARCHAR2; 
    
END FT_PK_STOCKDISSECTION;
/
