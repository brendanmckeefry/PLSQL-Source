--########################################################################################################
--  View for RTEAUDITS    
--########################################################################################################

CREATE OR REPLACE VIEW FT_V_RTEAUDIT
(  RTEAUDRECNO,   RTHNO,   RTDRECNO,   AUDBY, AUDDATE,   AUDTIME, AUDTYP,      
   AUDITDESC,   
   FROMDESCR,   USERFROMDESCR,   AUDFROM,
   TODESCR,   USERTODESCR,   AUDTO,      
   FORMNO,   FORMNAME
)
AS
SELECT RTEAUDRECNO, RTEAUDRTHNO RTHNO, RTEAUDRTDRECNO RTDRECNO, 
 TRIM (RTEAUDBY), RTEAUDDATE, RTEAUDTIME,
              RTEAUDIT.RTEAUDTYP,
              RTEAUDDESC,
              TRIM (RTEAUDFROMDESC),
              TRIM (RTEAUDUSERFROM), 
              TRIM (RTEAUDFROM),
              TRIM (RTEAUDTODESC),
              TRIM (RTEAUDTO),
              TRIM (RTEAUDUSERTO), 
              RTEAUDIT.FORMNO,
              FRMNAME.FORMNAME FORMNAME
FROM RTEAUDIT, RTEAUDTYPES, FRMNAME
      WHERE       RTEAUDIT.RTEAUDTYP = RTEAUDTYPES.RTEAUDTYP (+)
              AND RTEAUDIT.FORMNO = FRMNAME.FORMNO(+)
   ORDER BY   RTEAUDRECNO;



COMMENT ON TABLE FT_V_RTEAUDIT IS '1.0.0';   
   