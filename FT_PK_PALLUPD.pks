CREATE OR REPLACE PACKAGE FT_PK_PALLUPD  AS

  cSpecVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number For Spec
  
  PROCEDURE LOADTEMPALLOCNEW(IN_TMPTABNAME IN VARCHAR2,
                             --IN_SQLSTRING IN CLOB,   
                             --IN_SQLSTRING2 IN CLOB,
                             IN_DALRECORDTYPE IN DELTOALL.DALRECORDTYPE%TYPE,
                             IN_ISFROMTKTBK IN NUMBER,
                             IN_ALLOCTRANIN IN VARCHAR2,
                             IN_NOTDPTNO IN NUMBER,
                             IN_SMNNO IN NUMBER); 
  

END FT_PK_PALLUPD;
/




