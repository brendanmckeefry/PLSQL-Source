CREATE OR REPLACE TRIGGER FT_TG_PERFMON_ORACLESESSRECNO  BEFORE INSERT ON FT_PERFMON
FOR EACH ROW
DECLARE PRAGMA AUTONOMOUS_TRANSACTION;
  CVERSIONCONTROLNO   VARCHAR2(12) := '1.0.1'; -- Current Version Number
BEGIN
  <<ORACLESESSRECNO>>
  BEGIN
    SELECT USERENV('SESSIONID') INTO :NEW.ORACLESESSRECNO FROM DUAL;
  END ORACLESESSRECNO;
END;

