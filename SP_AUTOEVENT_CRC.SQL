create or replace PROCEDURE sp_AutoEvent_CRC
AS
CheckFail   INTEGER;
SQLStr Varchar(1000);
StoO_rowcnt INTEGER;
Quote Char(1);
MailFrom Varchar(40);
MailAddr Varchar(100);
MailSubj Varchar(500);
MailBody Varchar(1000);
EnvironStr Varchar(100);

CURSOR AutoEventCRC_CUR    
IS
  select CRCKEY, CRCDESC, CRCLASTTIME, SALESOFFICE
        from AutomaticEventCRC
        Where CRCKey = 51
        AND sysdate - CRCLastTime > 0.02083   --older than 30 mins
  AND EXISTS (select CRCKey from AutomaticEventCRC A2 Where A2.CRCKey = 50 AND Rtrim(A2.CRCDesc) = '1' ) -- check is active
  AND NOT EXISTS (select CRCKey from AutomaticEventCRC A1 Where A1.CRCKey = 53 and A1.SALESOFFICE = AutomaticEventCRC.SALESOFFICE);  --check not already failed and mailed	

AutoEventCRC_REC       AutoEventCRC_CUR%ROWTYPE;  


--S Rimen. 27/10/2011
--Stored Procedure to check if the Autmatic Event Trigger is executing.
--If it has not run for 30+ minutes, email the sysadmin.
--TV BSDL17411 9Jan17 Added sales office to AutoEventCRC table.  Only used in AutoPrintPikDel.fdl

BEGIN
 BEGIN
  StoO_rowcnt := 0;
  Quote := '''';

   --13861  AET uptime log -- SR 25/02/2015; 14 is the key of when this proc executes; 1 is the key of when AET executes
   insert into AutoEventRunLog (CheckTime, LastAETRunTime)
        Select sysdate,
               ( select Max(CrcLastTime) From
                  (select CrcLastTime from AutomaticEventCRC Where crckey = 1
                   union
                   Select To_Date('01/01/2000', 'dd/mm/yyyy') CrcLastTime from dual)) CrcLastTime
        From Dual;


  delete from AutomaticEventCRC Where crckey = 14;
  Insert into AutomaticEventCRC (CRCKEY, CRCDESC, CRCLastTime) (Select 14, 'SP_AutoEvent_CRC Last Executed', SysDate From Dual);


  --Check for Steve's Print routine Failing
  select 1 as CheckFail
  INTO CheckFail
        from AutomaticEventCRC
        Where CRCKey = 2
        AND sysdate - CRCLastTime > 0.02083   --older than 30 mins
  AND EXISTS (select CRCKey from AutomaticEventCRC Where CRCKey = 10 AND Rtrim(CRCDesc) = '1' ) -- check is active
  AND NOT EXISTS (select CRCKey from AutomaticEventCRC Where CRCKey = 15);  --check not already failed and mailed

  EXCEPTION
   --WHEN TOO_MANY_ROWS THEN
   -- StoO_rowcnt := 2;
   WHEN NO_DATA_FOUND THEN
        StoO_rowcnt := 0;
        DBMS_OUTPUT.PUT_LINE('CRC OK (or mail already sent)') ;
        NULL; -- << the proc must do a statement.

  end;

  begin
  StoO_rowcnt := SQL%ROWCOUNT;

  if StoO_rowcnt = 1 Then
     Begin
        DBMS_OUTPUT.PUT_LINE('CRC FAIL') ;

        --SET FAIL STATUS.
	     SQLStr := 'Delete From AutomaticEventCRC Where CRCKEY = 11';
	     EXECUTE IMMEDIATE SQLStr;
	     COMMIT;

	     SQLStr := 'Insert into AutomaticEventCRC (CRCKEY, CRCDESC) (Select 11,' ||Quote||  '1' ||Quote|| ' From Dual)';
	           EXECUTE IMMEDIATE SQLStr;
	           COMMIT;



	     --RAW (works)
	     --BSDL_EMail('SRIMEN', 'SRIMEN@BeresfordSoftware.com', NULL, NULL, 'TEST SUBJECT 1507', 'TEST MESSAGE', NULL);

	     --RAW as string (Works   must use 'call')
	     --SQLStr := 'call BSDL_EMail(' ||Quote|| 'SRIMEN' ||Quote|| ',' ||Quote|| 'SRIMEN@BeresfordSoftware.com' ||Quote|| ', NULL, NULL,' ||Quote|| 'CRC Check Failed 1513' ||Quote|| ',' ||Quote|| 'TEST MESSAGE' ||Quote|| ', NULL)';
	     --DBMS_OUTPUT.PUT_LINE(SQLStr);
	        --EXECUTE IMMEDIATE SQLStr;
	              --COMMIT;

	     select Rtrim(CRCDesc) CRCDesc
	     --INTO sp_AutoEvent_TEST.MailAddr
       INTO MailAddr
	     from AutomaticEventCRC
	     Where CRCKEY = 12 AND CRCDesc IS NOT NULL;

       SQLStr := 'insert into EmailAlerts (AlertType, EmailSendDate, EMAILAddress) Values(1, sysdate, ' || Quote || rtrim(MailAddr) || Quote || ')';
       EXECUTE IMMEDIATE SQLStr;
	     COMMIT;

       --email failed when this string created in the method.
       select Rtrim(CONTROLFULLDESC) CONTROLFULLDESC
	     INTO MailBody
	     from docdistcontrol
		   Where CONTROLKEY = 'CRC_MESSAGE';
       commit;

       select user
	     INTO EnvironStr
	     from dual;

       MailBody := MailBody || ' (Database Environment ' || EnvironStr || ')';   --<< this does not work

        MailFrom := 'FRESHTRADE_NO_REPLY';    --Gah! this param may not contain spaces
        --MailAddr := 'SRIMEN@BeresfordSoftware.com';
        MailSubj := 'FreshTrade Automated Response.';
        -- MailBody no parameterised.
       -- MailBody := 'The FreshTrade Automated Event Trigger appears to have halted execution.' ||CHR(13)
       --           || 'You are configured to be notified when this happens.' ||CHR(13) || CHR(13)
       --           || 'To Disable or Configure the distribution of these alerts, please use the form Report Archiving Console.';

     --note this call may succeed, but an email may not be sent (or arrive), depending on rules in the mailserver OR your spam filter

	    SQLStr := 'call BSDL_EMail(' ||Quote|| MailFrom ||Quote|| ',' ||Quote|| MailAddr ||Quote|| ', NULL, NULL,' ||Quote|| MailSubj ||Quote|| ',' ||Quote|| MailBody ||Quote|| ', NULL)';
	    DBMS_OUTPUT.PUT_LINE(SQLStr);
	    EXECUTE IMMEDIATE SQLStr;

        --Set Flag to show mail sent, so we do not repeatedly send the same mail.
	    delete from AutomaticEventCRC Where crckey = 15;
        Insert into AutomaticEventCRC (CRCKEY, CRCDESC, CRCLastTime) (Select 15, 'Email Sent', SysDate From Dual);
        COMMIT;

     end;
  end if;


  --Check for Tim's AUTOPICKDEL failing
  --Added SalesOffices TV 9Jan17
    OPEN AutoEventCRC_CUR;
    LOOP
      FETCH AutoEventCRC_CUR INTO AutoEventCRC_REC;
      
      EXIT WHEN AutoEventCRC_CUR%NOTFOUND;
    
      IF AutoEventCRC_CUR%FOUND THEN              
      BEGIN 
         DBMS_OUTPUT.PUT_LINE('PIK FAIL') ;
      
         select Rtrim(CRCDesc) CRCDesc
         INTO MailAddr
         from AutomaticEventCRC
         Where CRCKEY = 52 AND CRCDesc IS NOT NULL;
      
         SQLStr := 'insert into EmailAlerts (AlertType, EmailSendDate, EMAILAddress) Values(1, sysdate, ' || Quote || rtrim(MailAddr) || Quote || ')';
         EXECUTE IMMEDIATE SQLStr;
         COMMIT;
      
         --email failed when this string created in the method.
         select Rtrim(CONTROLFULLDESC) CONTROLFULLDESC
         INTO MailBody
         from docdistcontrol
         Where CONTROLKEY = 'PIK_MESSAGE';
         commit;
      
         select user
         INTO EnvironStr
         from dual;

         MailBody := MailBody || ' (Database Environment ' || EnvironStr || ')';   --<< this does not work

         MailFrom := 'FRESHTRADE_NO_REPLY';    --Gah! this param may not contain spaces
         MailSubj := 'FreshTrade Automated Response - Auto Pick and Delivery Note - Sales Office '||AutoEventCRC_REC.SALESOFFICE;
      
         --note this call may succeed, but an email may not be sent (or arrive), depending on rules in the mailserver OR your spam filter
         SQLStr := 'call BSDL_EMail(' ||Quote|| MailFrom ||Quote|| ',' ||Quote|| MailAddr ||Quote|| ', NULL, NULL,' ||Quote|| MailSubj ||Quote|| ',' ||Quote|| MailBody ||Quote|| ', NULL)';
         DBMS_OUTPUT.PUT_LINE(SQLStr);
         EXECUTE IMMEDIATE SQLStr;
      
         --Set Flag to show mail sent, so we do not repeatedly send the same mail.
         delete from AutomaticEventCRC Where crckey = 53 and SalesOffice = AutoEventCRC_REC.SalesOffice;
         Insert into AutomaticEventCRC (CRCKEY, CRCDESC, CRCLastTime, SalesOffice) VALUES (53, 'Email Sent re AutoPikDel', SysDate, AutoEventCRC_REC.SalesOffice);
         COMMIT;
		
      end;
      end if;
  end loop;
  End;

     
  IF AutoEventCRC_CUR%ISOPEN THEN
     CLOSE AutoEventCRC_CUR;
  END IF;

END sp_AutoEvent_CRC;