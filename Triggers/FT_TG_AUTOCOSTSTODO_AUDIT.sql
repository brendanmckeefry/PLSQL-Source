
drop trigger "AUTOCOSTSTODO_AUDIT";

CREATE OR REPLACE	TRIGGER "FT_TG_AUTOCOSTSTODO_AUDIT" 
BEFORE INSERT OR DELETE ON AUTOCOSTSTODO 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
DECLARE PRAGMA AUTONOMOUS_TRANSACTION;
   CVERSIONCONTROLNO   VARCHAR2(12) := '1.0.1'; -- Current Version Number
BEGIN 
  IF INSERTING THEN
    INSERT     INTO AUTOCOSTSAUDIT
      (
        AUTOCOSTREC,
        LITITENO,
        DPRRECNO,
        SESSIONNO,
        SALOFFNO,
        WRITEPREPALINOUT,
        DOAUTCOSTADHOCCHGS,
        TRANSFERATCOST,
        CALCSALESCOSTDPRTABLE,
        TRANSFERADDCHGSAPP,
        CALCULATEGOODSCOST,
        LOTPROFITABILITY,
        RECALCULATEWOCOSTS,
        INSERTTIME,
        INSERTORACLEAUDSID, 
        FORMNO
      )
      VALUES
      (
        :NEW.AUTOCOSTREC,
        :NEW.LITITENO,
        :NEW.DPRRECNO,
        :NEW.SESSIONNO,
        :NEW.SALOFFNO,
        :NEW.WRITEPREPALINOUT,
        :NEW.DOAUTCOSTADHOCCHGS,
        :NEW.TRANSFERATCOST,
        :NEW.CALCSALESCOSTDPRTABLE,
        :NEW.TRANSFERADDCHGSAPP,
        :NEW.CALCULATEGOODSCOST,
        :NEW.LOTPROFITABILITY,
        :NEW.RECALCULATEWOCOSTS,
        SYSDATE,
        USERENV('SESSIONID'),
        :NEW.FORMNO
      );
  END IF;
  IF DELETING THEN
    UPDATE AUTOCOSTSAUDIT
    SET DELETETIME    = SYSDATE
    WHERE AUTOCOSTREC = :OLD.AUTOCOSTREC;
  END IF;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  FT_PK_ERRORS.LOG_AND_CONTINUE;
END;