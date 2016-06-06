CREATE OR REPLACE PACKAGE FT_PK_PALLUPD  AS

  cSpecVersionControlNo   VARCHAR2(12) := '1.0.1'; -- Current Version Number For Spec
  
  PROCEDURE LOADTEMPALLOCNEW(IN_TMPTABNAME IN VARCHAR2,
                             --IN_SQLSTRING IN CLOB,   
                             --IN_SQLSTRING2 IN CLOB,
                             IN_DALRECORDTYPE IN DELTOALL.DALRECORDTYPE%TYPE,
                             IN_ISFROMTKTBK IN NUMBER,
                             IN_ALLOCTRANIN IN VARCHAR2,
                             IN_NOTDPTNO IN NUMBER,
                             IN_SMNNO IN NUMBER,
                             IN_QTYPER IN DELTOALL.QTYPER%TYPE); 
  

END FT_PK_PALLUPD;
/




