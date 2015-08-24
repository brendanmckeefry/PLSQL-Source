SET DEFINE OFF;

CREATE OR REPLACE PACKAGE FT_PK_ALLOCATE_CHECK
AS
   CSPECVERSIONCONTROLNO   VARCHAR2(12) := '1.0.0'; -- CURRENT VERSION NUMBER FOR SPEC

  -- THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE ALLOCATE AND RELATED TABLES - DELTOALL 
    PROCEDURE REPAIR_MAIN;
  
  -- THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE ALLOCATE.ALLOCALLOC
    PROCEDURE REPAIR_ALLOCALLOC;
  
    -- THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE DELTOALL
    PROCEDURE REPAIR_DELTOALL_FULL; -- THIS IS A MORE COMPREHENSIVE REPAIR AND CALLS REPAIR_DELTOALL AS PART OF THE PROCEDURE
    PROCEDURE REPAIR_DELTOALL_MIN;  -- THIS DOES THE MINIMUM REPAIRS TO DELTOALL 

        
    FUNCTION CURRENTVERSION (IN_BODYORSPEC IN INTEGER := 1) RETURN VARCHAR2;

END FT_PK_ALLOCATE_CHECK;
