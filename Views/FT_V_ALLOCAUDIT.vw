--########################################################################################################
-- View for ALLOCAUDITS    
--########################################################################################################


CREATE OR REPLACE FORCE VIEW FT_V_ALLOCAUDIT
(
   RECNO,
   ALLOCNO,
   AUDITBY,
   AUDDATE,
   AUDTIME,
   TYP,
   DESCRIPTION,
   AUDFROM,
   AUDTO,
   FORMNAME
   
)
AS

SELECT ALLAUDRECNO, ALLAUDALLOCNO, TRIM(ALLAUDBY), ALLAUDDATE, ALLAUDTIME,
ALLAUDTYP, 
(CASE ALLAUDTYP WHEN 'A' THEN  'Allocated'
                WHEN 'E' THEN  'Expected' 
                WHEN 'P' THEN  'Physical' 
                WHEN 'NP' THEN  'Physical [New]' 
                WHEN 'NE' THEN  'Expected [New]' 
        ELSE '??'                                            
        END) DESCRIPTION,
 
ALLAUDFROM, ALLAUDTO, FORMNAME
FROM ALLOCAUD
ORDER BY ALLAUDRECNO
;


COMMENT ON TABLE FT_V_ALLOCAUDIT IS '1.0.0';

