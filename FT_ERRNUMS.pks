--########################################################################################################
-- FT_ERRNUMS  (Package) 
-- 
-- A list of error numbers to be used instead of hard coding. 
-- Also registers exceptions Freshtrade & Named
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE PACKAGE FT_ERRNUMS AS 

-- ********** Named Oracle Exceptions **********

  -- This exception can be generated by bulk binding (FORALL) statements
  EN_DML_ERRORS CONSTANT INTEGER := -24381;
  EXC_DML_ERRORS EXCEPTION;
  PRAGMA EXCEPTION_INIT(EXC_DML_ERRORS, -24381);

-- ********** Freshtrade User Defined Exceptions **********
  EN_GENERAL_ERROR CONSTANT INTEGER := -20001; 
  EXC_GENERAL_ERROR EXCEPTION; 
  PRAGMA EXCEPTION_INIT(EXC_GENERAL_ERROR, -20001);
  
  EN_UNHANDLED_ERROR CONSTANT INTEGER := -20002; 
  EXC_UNHANDLED_ERROR EXCEPTION; 
  PRAGMA EXCEPTION_INIT(EXC_UNHANDLED_ERROR, -20002);
  
  EN_INVALIDDATA_ERROR CONSTANT INTEGER := -20003; 
  EXC_INVALIDDATA_ERROR EXCEPTION; 
  PRAGMA EXCEPTION_INIT(EXC_INVALIDDATA_ERROR, -20003);

  EN_INVALIDPARAMETER_ERROR CONSTANT INTEGER := -20004; 
  EXC_INVALIDPARAMETER_ERROR EXCEPTION; 
  PRAGMA EXCEPTION_INIT(EXC_INVALIDPARAMETER_ERROR, -20004);
  
  EN_NONCRITICAL_ERROR CONSTANT INTEGER := -20005;
  EXC_NONCRITICAL_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(EXC_NONCRITICAL_ERROR, -20005);
  
-- ********** Freshtrade errors mapped to Oracle Exceptions through FT_ERROR_CODES **********

  FT_NO_ERROR FT_ERROR_CODES.FTERRORNO%TYPE := 0; 

  FT_UNKNOWN FT_ERROR_CODES.FTERRORNO%TYPE := 1; 
  FT_UNKNOWN_CODE FT_ERROR_CODES.FTERRORCODE%TYPE := 'UNKNOWN'; 
  FT_UNKNOWN_MSG FT_ERROR_CODES.FTERRORMSG%TYPE := 'Unknown Freshtrade error'; 
  FT_UNKNOWN_ORAERRNO FT_ERROR_CODES.ORAERRNO%TYPE := -20001; 
  
  FT_GENERAL FT_ERROR_CODES.FTERRORNO%TYPE := 2; 
  FT_DATA FT_ERROR_CODES.FTERRORNO%TYPE := 3; 
  FT_PARAMETER FT_ERROR_CODES.FTERRORNO%TYPE := 4;
  
  FT_ENQUEUE_LIT    FT_ERROR_CODES.FTERRORNO%TYPE := 5;
  FT_ENQUEUE_DPR    FT_ERROR_CODES.FTERRORNO%TYPE := 6;
  FT_PRIORITISE_LIT FT_ERROR_CODES.FTERRORNO%TYPE := 7;
  FT_PRIORITISE_DPR FT_ERROR_CODES.FTERRORNO%TYPE := 8;
  FT_APPORTCOST     FT_ERROR_CODES.FTERRORNO%TYPE := 9;
  
END FT_ERRNUMS;
/
