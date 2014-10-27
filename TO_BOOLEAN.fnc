--########################################################################################################
-- TO_BOOLEAN  (Function)
-- 
-- Method used to turn a string logical 'TRUE' / 'FALSE' in to one of the correct type
--
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE FUNCTION TO_BOOLEAN
  ( P_STRING VARCHAR2
  ) RETURN BOOLEAN
IS
BEGIN
  RETURN
    CASE UPPER(TRIM(P_STRING)) 
      WHEN 'TRUE' THEN TRUE
      WHEN 'FALSE' THEN FALSE
      ELSE NULL
      END;
END;
/
