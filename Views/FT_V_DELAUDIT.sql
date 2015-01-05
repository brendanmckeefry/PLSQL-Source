--########################################################################################################
-- View for DELAUDITS    
--########################################################################################################

-- DROP VIEW FT_V_DELAUDIT;

CREATE OR REPLACE FORCE VIEW FT_V_DELAUDIT
(
   DELAUDRECNO,
   DELRECNO,
   DLVNO,
   DELAUDBY,
   AUDDATE,
   AUDTIME,
   TYP,
   DELAUDDESCR,
   DELAUDFROMDESC,
   AUDFROM,
   DELAUDTODESC,
   AUDTO,
   FORMNO,
   FORMNAME,
   DPRRECNO
)
AS
     SELECT   
              DELAUDRECNO,
              DELRECNO,
              DELDET.DELDLVORDNO,
              TRIM (LOGONS.LOGONNAME),
              DELAUDDATE,
              DELAUDTIME,
              DELAUDIT.DELAUDTYP,
              DELAUDDESC,
              DELAUDFROMDESC,
              TRIM (DELAUDFROM),
              DELAUDTODESC,
              TRIM (DELAUDTO),
              DELAUDIT.FORMNO,
              NVL (DELAUDIT.FORMNAME, FRMNAME.FORMNAME) FORMNAME,
              DPRRECNO
              
       FROM   DELAUDIT,
              DELAUDTYPES,
              FRMNAME,
              DELDET,
              LOGONS
      WHERE       DELAUDIT.DELAUDTYP = DELAUDTYPES.DELAUDTYP(+)
              AND DELAUDIT.FORMNO = FRMNAME.FORMNO(+)
              AND DELAUDIT.LOGONNO = LOGONS.LOGONNO
              AND DELAUDIT.DELAUDDELRECNO = DELDET.DELRECNO
   ORDER BY   DELAUDRECNO;

COMMENT ON TABLE FT_V_DELAUDIT IS  '1.0.0'; -- cVersionControlNo 

