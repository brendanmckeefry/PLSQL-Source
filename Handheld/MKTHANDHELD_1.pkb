create or replace
PACKAGE BODY         MKTHANDHELD_1 as
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
  PROCEDURE test IS
  ConCatResultVar 			VARCHAR(2000)  := '';
  BEGIN
     
    --HTP.P('hello from test');
    HandleOPStr('Result from FreshTrade TEST Webservice.', ConCatResultVar);
    HANDHELDLOG ('UNKNOWN', 'TEST', 'No parameters', 0 , 'Success', ConCatResultVar, 'No LOGON' ) ;
  END;

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

PROCEDURE ServerInfo IS
   ConCatResultVar 			VARCHAR(2000)  := '';   
   VWSName Varchar(30) := '';
   VPSName Varchar(30) := '';
   VCompanyName Varchar(40) := '';
   
   EC Integer := 0 ; -- Error Code
	 ED VarChar2(255) := ''; -- Error Description
   
   Begin
        Begin  
           Select WSName, PSName, (select CompanyName from company Where compGlbRecNo = 1) CompanyName  
           into VWSName, VPSName, VCompanyName
            From (select Owner WSName, Table_Owner PSName from ALL_SYNONYMS Where Owner = (select Username from User_Users) AND TABLE_NAME = 'ACCCLASS');
        
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=	99;
                    ED := ' Error Returning ServerInfo.  Production DB ' ||  SQLERRM;
    
            WHEN OTHERS THEN
                  EC :=  101;
                  ED := 'Unable to Execute Sql to Obtain ServerInfo. SqlErrM=' ||  SQLERRM;
         END; 
         
         if EC = 0 Then
            HandleOPStr('{"WS": "'|| Rtrim(VWSName) || '",', ConCatResultVar);
            HandleOPStr('"PS": "'|| Rtrim(VPSName) || '",', ConCatResultVar);
            HandleOPStr('"CN": "'|| Rtrim(VCompanyName) || '"}', ConCatResultVar);
         end if;
   
    HANDHELDLOG ('UNKNOWN', 'SERVERINFO', 'No parameters', 0 , 'Success', ConCatResultVar, 'No LOGON' ) ;
  END;   
    
--------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------

PROCEDURE SysInfo IS
  ConCatResultVar 			VARCHAR(2000)  := '';
  StrSysdate Varchar(20) := '';
 -- vsysdate Varchar(20);   --Date; 
  vWebServerName Varchar2(30) := ''; 
  VProductionServerName Varchar2(30) := '';
  VUserProdDB Varchar2(30) := '';
  StrTimeStamp Varchar2(8) := '';  
  EC Integer := 0 ; -- Error Code
	ED VarChar2(255) := ''; -- Error Description
  SqlStr 					VARCHAR(32767);
  RefCursorVar				SYS_REFCURSOR;
  vDevID VARCHAR(20);
  vDevName VARCHAR(50);
  vLogProcName VARCHAR(40);
  RecCounter integer := 1;
  vNumRecs integer; 
  
  --never use 'Select user from dual'    use      'Select Username From User_Users'  
  BEGIN    
    StrSysdate := sysdate();    
    HandleOPStr('Result from FreshTrade SysInfo Webservice. ', ConCatResultVar);    
    if EC = 0 Then
        Begin
           --Select Rtrim(user) into VUserProdDB from dual; 
           Select Username, (Select TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS') From Dual)
           into VUserProdDB, StrTimeStamp 
           From User_Users;
        
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=	99;
                    ED := ' Error Returning System information.  Production DB ' ||  SQLERRM;
    
            WHEN OTHERS THEN
                  EC :=  101;
                  ED := 'Unable to Execute Sql to Obtain Device information for SqlErrM=' ||  SQLERRM;
         END;                  
         HandleOPStr('<br>' || 'System Date/Time ' || StrSysdate || '  ' || StrTimeStamp || ': ' , ConCatResultVar);         
    end if;        
    
    if EC = 0 Then
     Begin		  
           select  rtrim(cast(ALL_SYNONYMS.Owner as varchar2(30))), rtrim(cast(ALL_SYNONYMS.TABLE_OWNER as varchar2(30))) --ALL_SYNONYMS.TABLE_OWNER
           into vWebServerName, VProductionServerName     
           FROM ALL_SYNONYMS                   
           Where Rtrim(ALL_SYNONYMS.Owner) =  Rtrim(VUserProdDB)      
           and Rtrim(ALL_SYNONYMS.SYNONYM_Name) = 'ACCCLASS';   --they should all be the same, if the first is right, they should all be
           
	        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=	99;
		            ED := ' Error Returning System information ' ||  SQLERRM;
		        WHEN OTHERS THEN
              EC :=  101;
              ED := 'Unable to Execute Sql to Obtain Device information for SqlErrM=' ||  SQLERRM;
        END;
     end if;   
       
    if EC = 0 Then       
       HandleOPStr('<br>' || 'Webserver Database: ' || vWebServerName 
                || '<br>' || 'Production Server: ' ||  VProductionServerName, ConCatResultVar);
    else
       HandleOPStr(ED ||  '. ' || sysdate , ConCatResultVar);
    end if;

    if EC = 0 Then
       SqlStr := 'select Distinct DEVICELOG.DevID, DevName from DEVICELOG, DeviceName '
              || ' where logdate > sysdate-1 '
              || ' AND DEVICELOG.DEVID = DeviceName.DEVID ' 
              || ' order by 1 desc';
               
       OPEN RefCursorVar FOR SqlStr;
			 LOOP
			   FETCH RefCursorVar INTO vDevID, vDevName;
			   EXIT WHEN RefCursorVar%NOTFOUND;            
			 	  IF RecCounter = 1
				  THEN
				  	  HandleOPStr('<br>' || 'Handheld Devices Used Today...<br>', ConCatResultVar);
				  END IF;
			 	  HandleOPStr('___' || vDevID || '.  (' || vDevName || ')' || '<br>', ConCatResultVar);          				  
		 		  RecCounter := RecCounter + 1;
	    END LOOP;
	    CLOSE RefCursorVar;
    end if;
    
    if EC = 0 Then
      
       SqlStr := 'select ' || Chr(39) || ' [TOTAL]' || Chr(39) || ' as logprocedurename, count(LogRecNo) NumRecs'
              || '   from DEVICELOG '
              || '   where logdate > sysdate-1 '
              || ' UNION'
              || '   select logprocedurename, count(LogRecNo) NumRecs'
              || '   from DEVICELOG '
              || '   where logdate > sysdate-1 '
              || ' Group By logprocedurename'
              || ' order by 1';              
              
        RecCounter := 1; 
        OPEN RefCursorVar FOR SqlStr;
			  LOOP
           FETCH RefCursorVar INTO vLogProcName, vNumRecs;
           EXIT WHEN RefCursorVar%NOTFOUND;            
            IF RecCounter = 1
            THEN
                HandleOPStr('<br>' || 'Webservice Traffic Today...<br> ', ConCatResultVar);
            END IF;
            HandleOPStr('___' || vLogProcName || ' (' || vNumRecs || ')' || '<br>', ConCatResultVar);          				  
            RecCounter := RecCounter + 1;
	      END LOOP;
	      CLOSE RefCursorVar;
     end if;         

    --'<br>'  carraige return character.
    --ConCatResultVar := '[Output String too Big]';
    if EC = 0 Then
       ConCatResultVar := 'WS: ' || vWebServerName || '. PS: ' || VProductionServerName || '.' ;
    end if;
    HANDHELDLOG ('UNKNOWN', 'SYSINFO', 'No parameters', 0 , 'Success', ConCatResultVar, 'No LOGON' ) ;
  END;

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------


  PROCEDURE testparm (UN IN Varchar2) IS
  BEGIN
    HTP.P('hello '||UN);
  END;
  
  --------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

PROCEDURE PublishTktDets (TN IN Varchar2) IS
   ConCatResultVar 			VARCHAR(2000)  := '';
   sttmp 			VARCHAR(2000)  := '';
   EC Integer := 0 ; -- Error Code
   V_DET_CNT integer;
   V_HDR_CNT integer;
   rec_ORDDET		MKTHHELD_ORDDET%ROWTYPE;
   rec_ORDHDR		MKTHHELD_ORDHDR%ROWTYPE;
   
   --note: this should probably be commented out after going live as it could be a backdoor for publishing secure information.
   CURSOR TKTHDR_CURSOR IS
      select FT_SEQNO, DEVRECNO, LOGONNO, SMNNO, DLTRECNO, SALOFFNO, STCRECNO, CLARECNO, TNTTBKRECNO, TNTNO, ORDHDRDATE, ORDERCOMM, ORD_NETTAMT, ORD_VAT1AMT, ORD_VAT2AMT, ORD_GROSSAMT, STATUS, DATE_UPLD, DLVORDNO, LASTAUDIT, DATECREATEDINFT, DATETHISRECORDCREATED,
             LASTEDITBYLOGONNO, LASTEDITDATETIME
      from MKTHHELD_ORDHDR Where tntno = TN; --note! may be duplicates!
   
   CURSOR TKTDETS_CURSOR IS
      Select FT_SEQNO, HDR_FT_SEQNO, LINENO, PRCPRDNO, LINECOMM, DETQTY, QTYPER, PRICE, FOC, ALLOCNO, DET_NETTAMT, DET_VAT1AMT, DET_VAT2AMT, DET_GROSSAMT, DELRECNO
      from MKTHHELD_ORDDET
      Where HDR_FT_SEQNO = (select FT_SEQNO from MKTHHELD_ORDHDR where tntno = TN);
   
  BEGIN    
   
   if TN is NULL then 
      --EC :=  110;
      --ED := 'Unable to Execute Sql to Update DeviceName for '|| MI || ' SqlErrM='||  SQLERRM;
      HandleOPStr('No ticket number passed to PublishTktDets.', ConCatResultVar);
      EC := 1 ; -- Error Code
      V_DET_CNT := 0;
      V_HDR_CNT := 0;
   end if;   
      
   IF EC = 0 THEN
      HandleOPStr('NOTE: These values are from the current ticket upload values ONLY and may not be the same as the live ticket details.' || '<br>' || '<br>', ConCatResultVar);     
   end if;
    
   IF EC = 0 THEN --Header loop (1 record - hopefully)
      OPEN TKTHDR_CURSOR;
      LOOP
	       FETCH TKTHDR_CURSOR INTO rec_ORDHDR;
	          EXIT WHEN TKTHDR_CURSOR%NOTFOUND;
			         V_HDR_CNT := V_HDR_CNT + 1;
               HandleOPStr('Ticket Header Line... ' || '<br>'
                          || ' FT_SEQNO: ' || rec_ORDHDR.FT_SEQNO || ';   '
                          || ' DEVRECNO: ' || rec_ORDHDR.DEVRECNO || ';   '
                          || ' LOGONNO: '  || rec_ORDHDR.LOGONNO || ';   '
                          || ' SMNNO: '    || rec_ORDHDR.SMNNO || ';   '
                          || ' DLTRECNO: ' || rec_ORDHDR.DLTRECNO || ';   '
                          || '<br>'
                          || ' SALOFFNO: ' || rec_ORDHDR.SALOFFNO || ';   '
                          || ' STCRECNO: ' || rec_ORDHDR.STCRECNO || ';   '
                          || ' CLARECNO: ' || rec_ORDHDR.CLARECNO || ';   '
                          || ' TNTTBKRECNO: ' || rec_ORDHDR.TNTTBKRECNO || ';   '
                          || ' TNTNO: ' || rec_ORDHDR.TNTNO || '; '
                          || '<br>'
                          || ' ORDHDRDATE: ' || rec_ORDHDR.ORDHDRDATE || ';   '
                          || ' ORDERCOMM: ' || rec_ORDHDR.ORDERCOMM || ';   '
                          || ' ORD_NETTAMT: ' || rec_ORDHDR.ORD_NETTAMT || ';   '
                          || ' ORD_VAT1AMT: ' || rec_ORDHDR.ORD_VAT1AMT || ';   '
                          || ' ORD_VAT2AMT: ' || rec_ORDHDR.ORD_VAT2AMT || ';   '
                          || '<br>'
                          || ' ORD_GROSSAMT: ' || rec_ORDHDR.ORD_GROSSAMT || ';   '
                          || ' STATUS: ' || rec_ORDHDR.STATUS || ';   '
                          || ' DATE_UPLD: ' || rec_ORDHDR.DATE_UPLD || ';   '
                          || ' DLVORDNO: ' || rec_ORDHDR.DLVORDNO || ';   '
                          || ' LASTAUDIT: ' || rec_ORDHDR.LASTAUDIT || ';   '
                          || '<br>'
                          || ' DATECREATEDINFT: ' || rec_ORDHDR.DATECREATEDINFT || ';   '
                          || ' DATETHISRECORDCREATED: ' || rec_ORDHDR.DATETHISRECORDCREATED || ';   '
                          || '<br>'
                          || '<br>'  || '<br>'
               , ConCatResultVar);           
              --HandleOPStr('aaa', ConCatResultVar);
               
--FT_SEQNO, DEVRECNO, LOGONNO, SMNNO, DLTRECNO, SALOFFNO, STCRECNO, CLARECNO, TNTTBKRECNO, TNTNO, ORDHDRDATE, ORDERCOMM, ORD_NETTAMT, ORD_VAT1AMT, ORD_VAT2AMT, ORD_GROSSAMT, STATUS, DATE_UPLD, DLVORDNO, LASTAUDIT, DATECREATEDINFT, DATETHISRECORDCREATED               
         END LOOP;
	    CLOSE TKTHDR_CURSOR;               
   end if;
   
   IF EC = 0 THEN
		   --If NOT V_ACCOUNTS_CURSOR%ISOPEN
		   --then
	       	  OPEN TKTDETS_CURSOR;
            
		   --END IF;

		   LOOP
	       FETCH TKTDETS_CURSOR INTO rec_ORDDET;
	          EXIT WHEN TKTDETS_CURSOR%NOTFOUND;
			      V_DET_CNT := V_DET_CNT + 1;              
            HandleOPStr('Line: ' || rec_ORDDET.LINENO || '<br>', ConCatResultVar);          
            sttmp := 'FT_SEQNO: ' || rec_ORDDET.FT_SEQNO || ';   HDR_FT_SEQNO: ' || rec_ORDDET.HDR_FT_SEQNO || ';' --  || '<br>'  || '<br>'  ;        
                  || ' PRCPRDNO: ' || rec_ORDDET.PRCPRDNO || '; '
                  || ' LINECOMM: ' || rec_ORDDET.LINECOMM || '; '
                  || ' DETQTY: ' || rec_ORDDET.DETQTY || '; '
                  || ' QTYPER: ' || rec_ORDDET.QTYPER || '; '
                  || '<br>'
                  || ' PRICE: ' || rec_ORDDET.PRICE || '; '
                  || ' FOC: ' || rec_ORDDET.FOC || '; '
                  || ' ALLOCNO: ' || rec_ORDDET.ALLOCNO || '; '
                  || ' DET_NETTAMT: ' || rec_ORDDET.DET_NETTAMT || '; '
                  || '<br>'
                  || ' DET_VAT1AMT: ' || rec_ORDDET.DET_VAT1AMT || '; '
                  || ' DET_VAT2AMT: ' || rec_ORDDET.DET_VAT2AMT || '; '
                  || ' DET_GROSSAMT: ' || rec_ORDDET.DET_GROSSAMT || '; '
                  || ' DELRECNO: ' || rec_ORDDET.DELRECNO || '; '                                  
                  || '<br>'  || '<br>';
            HandleOPStr(sttmp, ConCatResultVar); 
            
            
 --FT_SEQNO, HDR_FT_SEQNO, LINENO, PRCPRDNO, LINECOMM, DETQTY, QTYPER, PRICE, FOC, ALLOCNO, DET_NETTAMT, DET_VAT1AMT, DET_VAT2AMT, DET_GROSSAMT, DELRECNO       
        
        
       END LOOP;

	     CLOSE TKTDETS_CURSOR;  
   end if;    
   
   IF EC = 0 THEN
      if V_DET_CNT = 0 then
         HandleOPStr('No uploaded details for this ticket number.', ConCatResultVar);
         V_DET_CNT := 0;
      end if;
   end if;
      
  -- if EC = 0 then 
   
     	     --  FETCH V_ACCOUNTS_CURSOR INTO V_ACCOUNTS_RECORD;

	        --  EXIT WHEN V_ACCOUNTS_CURSOR%NOTFOUND;
   
    /* BEGIN           
           Select FT_SEQNO, HDR_FT_SEQNO, LINENO, PRCPRDNO, LINECOMM, DETQTY, QTYPER, PRICE, FOC, ALLOCNO, DET_NETTAMT, DET_VAT1AMT, DET_VAT2AMT, DET_GROSSAMT, DELRECNO
           INTO rec_ORDDET
           from MKTHHELD_ORDDET
           Where HDR_FT_SEQNO = (select FT_SEQNO from MKTHHELD_ORDHDR where tntno = TN);
      
     EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    2;
                HandleOPStr('Ticket ' || TN || ' Not found.', ConCatResultVar);                

     WHEN OTHERS THEN
              EC :=  3;
             -- ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
              HandleOPStr('Ticket ' || TN || ' Error = ' || SQLERRM , ConCatResultVar); 
     END;  */
   
      --HandleOPStr('a', ConCatResultVar);
  -- end if;
    
  END;

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------





/*
 PROCEDURE heartbeat_old (MI IN Varchar2 default null, MM IN Varchar2 DEFAULT Null, OS in VarChar2 default null,
                       MS in Varchar2 default null, UN in Varchar2 default null, AP in Varchar2 default null,
					   CV in Number default 0.0) IS

     PROCNAME VARCHAR(40) := 'HEARTBEAT';
	 vSM VarChar2(255); --  System Message
  	 EC Integer := 0 ; -- Error Code
	 ED VarChar2(255) := ''; -- Error Description
	 vMI DeviceName.DevID%TYPE;
	 vAP DeviceApps.DAPNAME%TYPE;
	 vMS DeviceName.DEVLASTSTATUS%TYPE;
	 vMM DeviceName.DEVMACHINEMODEL%TYPE;
	 vOS DeviceName.DEVMACHINEOS%TYPE;
	 vCV DeviceApps.DAPLASTCONTACTVERSION%TYPE;

	 vDevName DeviceName.DevName%TYPE := ''; -- Device Name from query
	 vDeviceApps DeviceApps%ROWTYPE;
   ConCatResultVar 			VARCHAR(2000)  := '';
   VUN VARCHAR2(40)  := '';

  BEGIN
  	 -- Heartbeat function, called at regular intervals by the handheld to check if end to end communications are
	 -- still working

	 -- BSDL7961 TV 9Aug12
  	 -- Input Variables (names are short because they have to be passed in the URL)
  	 -- MI = Machine ID - Unique identifier for machine.  Probably the MAC address.
     -- MM = Machine Model - Machine make and type ie ‘Asus Transformer’
     -- OS = Android O/S - Current machine operating system ie 4.0.1
     -- MS = Machine Status - this is the current machine operating mode ie Logged On, Not Logged On, Charging etc.
     -- UN = User Logon Name - if logged on then the current user name ie ‘TVIVIAN’ etc if not then null
     -- AP = Calling App - currently ‘FruitMarket’ but included to allow the same web service to be used in the future for other apps
     -- CV = Machine App Version - current version of the software running on the device

  --UL not validated as may not be logged in.

  	 IF MI is null then
	 	EC := 100;
		ED := 'You must enter a machine name (MI)';
	 END IF;

	 If EC = 0 then
	 	IF MM is null then
	 	   EC := 101;
		   ED := 'You must enter the Machine Model name (MM)';
	    END IF;
	 End If;

	 If EC = 0 then
	 	IF OS is null then
	 	   EC := 102;
		   ED := 'You must enter the Android Operating System name (OS)';
	    END IF;
	 End If;

	 If EC = 0 then
	 	IF MS is null then
	 	   EC := 103;
		   ED := 'You must enter a Machine Status (MS)';
	    END IF;
	 End If;

	 If EC = 0 then
	 	IF AP is null then
	 	   EC := 104;
		   ED := 'You must enter the calling application name (AP)';
	    END IF;
	 End If;

	 If EC = 0 then
	 	IF CV is null then
	 	   EC := 105;
		   ED := 'You must enter the current application version (CV)';
	    END IF;
	 End If;

     -- got through the inital validation, so now check the database

	 -- check device exists and is active
	 If EC = 0 then
        Begin
		   vMI := Upper(MI);

		   Select DevName
		   INTO vDevName
		   FROM DeviceName
           Where DEVActive = 1
           AND Upper(DevID) = vMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=	106;
		        ED := MI || ' is not a registered active device';

		   WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
	 END IF;

     -- now check that device is registered for the application
	 If EC = 0 then
        Begin
           vAP := Upper(Rtrim(AP));

           Select DeviceApps.*
		   INTO vDeviceApps
		   FROM DeviceName, DeviceApps
           Where DeviceName.DEVActive = 1
           AND upper(Rtrim(DeviceName.DevID)) = UPPER(Rtrim(vMI))
		   AND DeviceName.DEVRECNO = DeviceApps.DAPDEVRECNO
		   AND DeviceApps.DAPACTIVE = 1
		   AND UPPER(Rtrim(DeviceApps.DAPNAME)) = UPPER(Rtrim(vAP));

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=	108;
		            ED := MI || ' is not registered or active for use with App  ' || vAP;

		   WHEN OTHERS THEN
              EC :=  109;
              ED := 'Unable to Execute Sql to Obtain Application information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
	 END IF;


	 --	Finished the validation so now log that the heartbeat has been recieved
	 If EC = 0 then
	    Begin
		   vMS := MS;
		   vMM := MM;
		   vOS := OS;

		   UPDATE DeviceName
		   SET DEVLastContactDate = sysdate,
		   	   DEVLastStatus = vMS,
			   DEVMachineModel = vMM,
			   DEVMachineOS = vOS
		   WHERE DEVRecNo = vDeviceApps.DAPDEvRecNo;

	    EXCEPTION
           WHEN OTHERS THEN
              EC :=  110;
              ED := 'Unable to Execute Sql to Update DeviceName for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
	 End If;


	 -- Now log that the application data has been returned
	 If EC = 0 then
	    Begin
		   vCV := CV;

		   UPDATE DeviceApps
		   SET DAPLastContactDate = sysdate,
		   	   DAPLastContactVersion = vCV,
			   DAPSystemMessageSent = 1
			   --DAPSystemMessage = null This line removed for debugging only
		   WHERE DAPRecNo = vDeviceApps.DAPRecNo;

	    EXCEPTION
           WHEN OTHERS THEN
              EC :=  111;
              ED := 'Unable to Execute Sql to Update DeviceApplications for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
	 End If;

	 IF EC != 0 then
	    -- Error message returned

         HandleOPStr('{"EC": '|| EC || ',"ED": "'|| ED ||'"}', ConCatResultVar);
	 Else
	    -- Valid message returned as JSON
     	--HTP.P('hello from heartbeat '||vDevName);
		vSM := vDeviceApps.DAPSYSTEMMESSAGE;

	 	--HTP.P('{');
        --HTP.P('"MN": "'|| trim(vDevName) || '",');
        
    HandleOPStr('{"MN": "'|| trim(vDevName) || '",', ConCatResultVar);    

		If nvl(vSM, 'null') = 'null'  then
		   --HTP.P('"SM": null,');
       HandleOPStr('"SM": null,', ConCatResultVar);  
		else
		   --HTP.P('"SM": "'|| vSM || '",');
       HandleOPStr('"SM": "'|| Rtrim(vSM) || '",', ConCatResultVar);  
		End if;

		--HTP.P('"LV": '|| vDeviceApps.DAPCURRENTVERSION|| ',');
    HandleOPStr('"LV": '|| vDeviceApps.DAPCURRENTVERSION|| ',', ConCatResultVar);  

		if vDeviceApps.DAPMUSTUPDATE = 1 then
		   --HTP.P('"MU": "Y",');
       HandleOPStr('"MU": "Y",', ConCatResultVar);  
		else
		   --HTP.P('"MU": "N",');
       HandleOPStr('"MU": "N",', ConCatResultVar);  
		End if;

		-- returns UTC data and time, up to the Android device to sort out summer time etc!
		--HTP.P('"SD": "'|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'YYYYMMDD') ||'",');
    --HTP.P('"ST": "'|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'HH24MISS') ||'"');
		--HTP.P('}');
    
    HandleOPStr('"SD": "'|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'YYYYMMDD') ||'",', ConCatResultVar);  
    HandleOPStr('"ST": "'|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'HH24MISS') ||'"}', ConCatResultVar);  

	 End if;

  if UN IS NULL Then
     VUN := '[NOT SUPPLIED]';
  else
     VUN := UN; 
  end if;
	 --Log the transaction
 	 HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' MM=' || MM ||' OS=' || OS || ' MS=' || rtrim(MS) || ' UN=' || UN || ' AP=' || AP || ' CV=' || CV, EC , ED, ConCatResultVar, VUN ) ;


  END; --heartbeat

*/

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

  PROCEDURE heartbeat (MI IN Varchar2 default null, MM IN Varchar2 DEFAULT Null, OS in VarChar2 default null,
                       MS in Varchar2 default null, UN in Varchar2 default null, AP in Varchar2 default null,
					   CV in Number default 0.0) IS

     PROCNAME VARCHAR(40) := 'HEARTBEAT';
	 vSM VarChar2(255); --  System Message
  	 EC Integer := 0 ; -- Error Code
	 ED VarChar2(255) := ''; -- Error Description
	 vMI DeviceName.DevID%TYPE;
	 vAP DeviceApps.DAPNAME%TYPE;
	 vMS DeviceName.DEVLASTSTATUS%TYPE;
	 vMM DeviceName.DEVMACHINEMODEL%TYPE;
	 vOS DeviceName.DEVMACHINEOS%TYPE;
	 vCV DeviceApps.DAPLASTCONTACTVERSION%TYPE;

	 vDevName  DeviceName.DevName%TYPE := ''; -- Device Name from query
   vDevRecNo DeviceName.DevRecNo%TYPE;
   
	 vDeviceApps DeviceApps%ROWTYPE;
   V_UPLDMSG_RECORD  deviceprocesslog%ROWTYPE;
   
   VRefNo1 integer;
   VRefNo2 integer;   
   
   ConCatResultVar 			VARCHAR(2000)  := '';
   VUN VARCHAR2(40)  := '';
   
   V_MSG_CNT integer;
   SecondRecord Boolean := False;
   CommaStr VARCHAR2(1)  := '';
   
   V_LastAccountAudit  integer; 
   V_LastProductAudit  integer;

  CURSOR CURSOR_UPLDMSGS IS   --AtLast() or EOT() equivalent.
        select Count (*) OVER ()  as RecCount, deviceprocesslog.*  
        From deviceprocesslog 
        Where LogDate > (sysdate - 1)  --dont return old messages
        AND MsgTransmittedToDevice = 0
        AND ProcessType > 0  --zero is general message
        AND DevRecNo = vDevRecNo;

  BEGIN
  	 -- Heartbeat function, called at regular intervals by the handheld to check if end to end communications are
	 -- still working

	 -- BSDL7961 TV 9Aug12
  	 -- Input Variables (names are short because they have to be passed in the URL)
  	 -- MI = Machine ID - Unique identifier for machine.  Probably the MAC address.
     -- MM = Machine Model - Machine make and type ie ‘Asus Transformer’
     -- OS = Android O/S - Current machine operating system ie 4.0.1
     -- MS = Machine Status - this is the current machine operating mode ie Logged On, Not Logged On, Charging etc.
     -- UN = User Logon Name - if logged on then the current user name ie ‘TVIVIAN’ etc if not then null
     -- AP = Calling App - currently ‘FruitMarket’ but included to allow the same web service to be used in the future for other apps
     -- CV = Machine App Version - current version of the software running on the device

  --UL not validated as may not be logged in.

  --SR 20140102  return upload messages

  	 IF MI is null then
	 	EC := 100;
		ED := 'You must enter a machine name (MI)';
	 END IF;

	 If EC = 0 then
	 	IF MM is null then
	 	   EC := 101;
		   ED := 'You must enter the Machine Model name (MM)';
	    END IF;
	 End If;

	 If EC = 0 then
	 	IF OS is null then
	 	   EC := 102;
		   ED := 'You must enter the Android Operating System name (OS)';
	    END IF;
	 End If;

	 If EC = 0 then
	 	IF MS is null then
	 	   EC := 103;
		   ED := 'You must enter a Machine Status (MS)';
	    END IF;
	 End If;

	 If EC = 0 then
	 	IF AP is null then
	 	   EC := 104;
		   ED := 'You must enter the calling application name (AP)';
	    END IF;
	 End If;

	 If EC = 0 then
	 	IF CV is null then
	 	   EC := 105;
		   ED := 'You must enter the current application version (CV)';
	    END IF;
	 End If;

     -- got through the inital validation, so now check the database

	 -- check device exists and is active
	 If EC = 0 then
        Begin
		   vMI := Upper(MI);

		   Select DevRecNo, DevName
		   INTO vDevRecNo, vDevName
		   FROM DeviceName
           Where DEVActive = 1
           AND Upper(DevID) = vMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=	106;
		        ED := MI || ' is not a registered active device';

		   WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
	 END IF;

     -- now check that device is registered for the application
	 If EC = 0 then
        Begin
           vAP := Upper(Rtrim(AP));

           Select DeviceApps.*
		   INTO vDeviceApps
		   FROM DeviceName, DeviceApps
           Where DeviceName.DEVActive = 1
           AND upper(Rtrim(DeviceName.DevID)) = UPPER(Rtrim(vMI))
		   AND DeviceName.DEVRECNO = DeviceApps.DAPDEVRECNO
		   AND DeviceApps.DAPACTIVE = 1
		   AND UPPER(Rtrim(DeviceApps.DAPNAME)) = UPPER(Rtrim(vAP));

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=	108;
		            ED := MI || ' is not registered or active for use with App  ' || vAP;

		   WHEN OTHERS THEN
              EC :=  109;
              ED := 'Unable to Execute Sql to Obtain Application information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
	 END IF;


	 --	Finished the validation so now log that the heartbeat has been recieved
	 If EC = 0 then
	    Begin
		   vMS := MS;
		   vMM := MM;
		   vOS := OS;

		   UPDATE DeviceName
		   SET DEVLastContactDate = sysdate,
		   	   DEVLastStatus = vMS,
			   DEVMachineModel = vMM,
			   DEVMachineOS = vOS
		   WHERE DEVRecNo = vDeviceApps.DAPDEvRecNo;

	    EXCEPTION
           WHEN OTHERS THEN
              EC :=  110;
              ED := 'Unable to Execute Sql to Update DeviceName for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
	 End If;


	 -- Now log that the application data has been returned
	 If EC = 0 then
	    Begin
		   vCV := CV;

		   UPDATE DeviceApps
		   SET DAPLastContactDate = sysdate,
		   	   DAPLastContactVersion = vCV,
			   DAPSystemMessageSent = 1
			   --DAPSystemMessage = null This line removed for debugging only
		   WHERE DAPRecNo = vDeviceApps.DAPRecNo;

	    EXCEPTION
           WHEN OTHERS THEN
              EC :=  111;
              ED := 'Unable to Execute Sql to Update DeviceApplications for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
	 End If;

	 IF EC != 0 then
	    -- Error message returned
         HandleOPStr('{"EC": '|| EC || ',"ED": "'|| ED ||'"}', ConCatResultVar);
	 Else
	    -- Valid message returned as JSON
     	--HTP.P('hello from heartbeat '||vDevName);
		vSM := vDeviceApps.DAPSYSTEMMESSAGE;
      
    HandleOPStr('{"MN": "'|| trim(vDevName) || '",', ConCatResultVar);    

		If nvl(vSM, 'null') = 'null'  then
       HandleOPStr('"SM": null,', ConCatResultVar);  
		else
       HandleOPStr('"SM": "'|| Rtrim(vSM) || '",', ConCatResultVar);  
		End if;

    --error if vDeviceApps.DAPCURRENTVERSION = 0.49 .. becomes .49
    --LConvertValue (PASSPROCNAME IN VarChar, TYP IN Varchar, PassValInt IN Number, PassValStr IN VarChar, RetVal IN OUT Varchar, EC IN OUT INTEGER, ED IN OUT Varchar2)
    if vDeviceApps.DAPCURRENTVERSION < 1 Then
       HandleOPStr('"LV": 0'|| vDeviceApps.DAPCURRENTVERSION|| ',', ConCatResultVar);  
    else
       HandleOPStr('"LV": '|| vDeviceApps.DAPCURRENTVERSION|| ',', ConCatResultVar);  
    end if;   

		if vDeviceApps.DAPMUSTUPDATE = 1 then
       HandleOPStr('"MU": "Y",', ConCatResultVar);  
		else
       HandleOPStr('"MU": "N",', ConCatResultVar);  
		End if;

		-- returns UTC data and time, up to the Android device to sort out summer time etc!
    
    HandleOPStr('"SD": "'|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'YYYYMMDD') ||'",', ConCatResultVar);  
    --HandleOPStr('"ST": "'|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'HH24MISS') ||'"}', ConCatResultVar);  
    HandleOPStr('"ST": "'|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'HH24MISS') ||'"', ConCatResultVar);  

   /* CURSOR CURSOR_UPLDMSGS IS
        select * from deviceprocesslog 
        Where LogDate > (sysdate - 1)  --dont return old messages
        AND MsgTransmittedToDevice = 0
        AND ProcessType > 0  --zero is general message
        AND DevRecNo = vDevRecNo;
     */
     
     -- SCAN ALL THE untransmitted messages for this device.
     IF EC = 0 THEN
        V_MSG_CNT := 0;
        SecondRecord := False;
        FOR V_UPLDMSG_RECORD IN CURSOR_UPLDMSGS  LOOP  -- GET ALL THE ACTIVE USERS IN THE SYSTEM
       
          --eg "LOG": [{"LL": 0,"LT": "TICKET","L1": 3577,"L2": 2027,"LM": "Created Ticket: Book/Ticket/Delivery = 2027/3577/195969"},
          --           {"LL": 0,"LT": "TICKET","L1": 3577,"L2": 2027,"LM": "Created Ticket: Book/Ticket/Delivery = 2027/3577/195969"}]}
          -- two msgs comma separated, one msg has no comma.
          -- 1 msg  {};   2 msgs {},{};     3 msgs {},{},{}
       
         --we dont want to add a comma if there is only 1 record OR if there are multiple records and we are on the last record.
         
         
         
          /*If SecondRecord = False then
             CommaStr := '';
          Else
              SecondRecord := True;
              CommaStr := ',';
              
              --if V_MSG_CNT = CURSOR_UPLDMSGS.RowCount Then
              --   CommaStr := '';
              --end If;   
              --HandleOPStr(CommaStr, ConCatResultVar);
	        END IF;*/
       
          IF EC = 0 THEN
                V_MSG_CNT := V_MSG_CNT + 1;
                
                if V_MSG_CNT = V_UPLDMSG_RECORD.RecCount Then
                   --we are on the last record.
                   CommaStr := '';
                else  
                   CommaStr := ',';
                end if;
                
                if V_MSG_CNT = 1 Then
                   HandleOPStr(', "LOG": [', ConCatResultVar); 
                end if;
                
                if V_UPLDMSG_RECORD.Severity = 'Error' Then
                   HandleOPStr('{"LL": 5,', ConCatResultVar);  --0 info  5 error  
                else   
                   HandleOPStr('{"LL": 0,', ConCatResultVar);  --0 info  5 error  
                end if;   
                
                if V_UPLDMSG_RECORD.ProcessType = 1 Then
                   HandleOPStr('"LT": "TICKET",', ConCatResultVar);                  
                end If;
                if V_UPLDMSG_RECORD.ProcessType = 2 Then
                   HandleOPStr('"LT": "PURCHASE",', ConCatResultVar);                  
                end If;
                if V_UPLDMSG_RECORD.ProcessType = 3 Then
                   HandleOPStr('"LT": "PAYMENT",', ConCatResultVar);                  
                end If;
          end if;
          
          IF EC = 0 THEN                
                --
                 BEGIN                  
                      if V_UPLDMSG_RECORD.ProcessType = 1 Then
                         SELECT  Nvl(TntNo, 0), Nvl(TntTbkRecNo, 0)
                         INTO VRefNo1, VRefNo2
                         FROM MKTHHELD_ORDHDR
                         WHERE V_UPLDMSG_RECORD.HDRNO = MKTHHELD_ORDHDR.FT_SEQNO;
                      end if;  
                      
                      if V_UPLDMSG_RECORD.ProcessType = 2 Then
                         SELECT  Nvl(PorNo, 0), NULL
                         INTO VRefNo1, VRefNo2
                         FROM MKTHHELD_POHDR
                         WHERE V_UPLDMSG_RECORD.HDRNO = MKTHHELD_POHDR.FT_SEQNO;
                      end if;
                      
                      if V_UPLDMSG_RECORD.ProcessType = 3 Then
                         SELECT  Nvl(TntNo, 0), Nvl(TntTbkRecNo, 0)
                         INTO VRefNo1, VRefNo2
                         FROM MKTHHELD_PAYMENTS
                         WHERE V_UPLDMSG_RECORD.HDRNO = MKTHHELD_PAYMENTS.FT_SEQNO;
                      end if;
        
                 EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        EC :=    160;
                        ED := MI || ' Cannot find originating record for upload log';
        
                 WHEN OTHERS THEN
                      EC :=  161;
                      ED := 'Unable to Execute Sql '|| MI || ' SqlErrM='||  SQLERRM;
                 END;
          end if;     
          
          IF EC = 0 THEN
             HandleOPStr('"L1": ' || VRefNo1 || ',', ConCatResultVar);
             HandleOPStr('"L2": ' || VRefNo2 || ',', ConCatResultVar);             
          end if;   
                
          IF EC = 0 THEN
             HandleOPStr('"LM": "' || Rtrim(V_UPLDMSG_RECORD.MessageText) || '"}', ConCatResultVar);
          end if;
          
          if CommaStr = ',' Then          
             HandleOPStr(CommaStr, ConCatResultVar);
          end if;
          
          --update log so not re-tranmitted repeatedly.
           IF EC = 0 THEN                                
                 BEGIN   
                    Update DeviceProcessLog Set MsgTransmittedToDevice = 1 Where DevLogNo = V_UPLDMSG_RECORD.DevLogNo;                              
                 EXCEPTION                          
                 WHEN OTHERS THEN
                      EC :=  162;
                      ED := 'Unable to Execute Sql to update DeviceProcessLog.MsgTransmittedToDevice '|| MI || ' SqlErrM='||  SQLERRM;
                 END;
          end if;     
                                               
        end loop;  
        
        if V_MSG_CNT > 0 Then
           HandleOPStr(']', ConCatResultVar);
        end if;   
        --HandleOPStr('}', ConCatResultVar); Master close bracket
                
     end if;           

   
	 End if;
   
  --GET THE MAX AUDIT NUMBERS FOR ACCOUNTS AND PRODUCTS SO WE CAN 'TICKLE FEED' UPDATES. 
  IF EC = 0 THEN
      if V_MSG_CNT = 0 Then --only return the audit numbers if no messages returned (easier to code)
         --
         /* "LOG": [
        {
            "LL": 1,
            "LT": "PAYMENT",
            "L1": 100
        }
    ]*/
    
         If EC = 0 then
            Begin
               Select (select Max(AccAudRecNo) AccAudRecNo from AccAudit), 
                      (select Max(AuditRecordNo) AuditRecordNo from auditRecord where AuditTypeNo in (9017, 9031) )               
                 into V_LastAccountAudit, V_LastProductAudit
               From Dual;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  EC :=	108;
		              ED := MI || ' Cannot get Last audits!  ';
		        WHEN OTHERS THEN
              EC :=  109;
              ED := ' Issue extracting Last audits! '|| MI || ' SqlErrM='||  SQLERRM;
            END;
         end if;   
    
        --Commented out as App is going into offline mode.
         If EC = 0 then
            HandleOPStr(', "LOG": [ { "LL": 1, "LT": "ACCOUNTREC",  "L1": ' || V_LastAccountAudit || '}', ConCatResultVar);          
            HandleOPStr(', { "LL": 1, "LT": "PRODUCTREC",  "L1": ' || V_LastProductAudit || '}]', ConCatResultVar); 
         end if;   

      end If;
  end If;  
  
  IF EC = 0 THEN     
     HandleOPStr('}', ConCatResultVar); --Master close bracket
  end if;   

  if UN IS NULL Then
     VUN := '[NOT SUPPLIED]';
  else
     VUN := UN; 
  end if;
	 --Log the transaction
 	 HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' MM=' || MM ||' OS=' || OS || ' MS=' || rtrim(MS) || ' UN=' || UN || ' AP=' || AP || ' CV=' || CV, EC , ED, ConCatResultVar, VUN ) ;


  END; --heartbeat

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
														

  PROCEDURE USERS (MI IN VARCHAR2 DEFAULT NULL) IS

   	 --V1.0 BMK 17Aug12
	 --Downloads a JSON list of Users, User Preferences, SalesOffices and Departments if a valid Machine ID is sent
	 -- TV 21Jan13 Added code to pick up new encrypted password from the LOGONS table

     EC INTEGER := 0 ; -- ERROR CODE
     ED VARCHAR2(255) := ''; -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'USERS';

     VMI DEVICENAME.DEVID%TYPE;
     VDEVNAME DEVICENAME.DEVNAME%TYPE := ''; -- DEVICE NAME FROM QUERY

     V_MD5PASSWORD      VARCHAR2(32);
     V_MD5PASSWORD1     VARCHAR2(128);
     V_USER_CNT         NUMBER(5) := 0;
     V_PREF_CNT         NUMBER(5) := 0;
     V_SO_CNT           NUMBER(5) := 0;
     V_DPT_CNT           NUMBER(5) := 0;
     V_MNU_CNT         NUMBER(5) := 0;
     V_PRN_CNT         NUMBER(5) := 0;

     ConCatResultVar 			VARCHAR(5000)  := '';
     
     -- USER DETAILS
     CURSOR V_USER_CURSOR IS
       SELECT LOGONNO, TRIM(LOGONNAME) UL, TRIM(HANDHELDPASSWORD) UP, TRIM(USERNAME) UN, LANGNO LC,
       (SELECT MIN(SMN.SMNNO) FROM SMNTOLOGON, SMN
              WHERE SMNTOLOGON.SMNNO = SMN.SMNNO
              AND SMNTOLOGON.LOGONNO = LOGONS.LOGONNO
              AND SMNTYPE = 'Sell' 
              AND SMN.SmnNo In(Select distinct SmnNo From departmentsToSmn ) --dont get smn that dont belong to a dept
              AND SMNTOLOGON.LogOnNo in(SELECT LOGTOSALOFF.LogOnNo FROM LOGTOSALOFF WHERE LOGONNO = LOGONS.LOGONNO AND LOGTOSALOFF.LOGCANSELL = 1) 
              ) SN,
         (SELECT Nvl(MIN(SMN.SMNNO), 0) FROM SMNTOLOGON, SMN
              WHERE SMNTOLOGON.SMNNO = SMN.SMNNO
              AND SMNTOLOGON.LOGONNO = LOGONS.LOGONNO
              AND SMNTYPE = 'Buy' 
              AND SMN.SmnNo In(Select distinct SmnNo From departmentsToSmn ) --dont get smn that dont belong to a dept
              AND SMNTOLOGON.LogOnNo in(SELECT LOGTOSALOFF.LogOnNo FROM LOGTOSALOFF WHERE LOGONNO = LOGONS.LOGONNO AND LOGTOSALOFF.LOGCANSELL = 1) 
              ) BUYER  
        FROM LOGONS WHERE AVAILTOMKTHANDHELD = 1
        AND ACTIVE = 1
        AND NVL(LOGONNO, 0) <> 0
        AND LOGONNAME IS NOT NULL
        AND NVL(LANGNO, 0) <> 0;      
     
      /*SELECT LOGONNO, TRIM(LOGONNAME) UL, TRIM(HANDHELDPASSWORD) UP, TRIM(USERNAME) UN, LANGNO LC,
        (SELECT MIN(SMN.SMNNO) FROM SMNTOLOGON, SMN
        WHERE SMNTOLOGON.SMNNO = SMN.SMNNO
        AND SMNTOLOGON.LOGONNO = LOGONS.LOGONNO
        AND SMNTYPE = 'Sell' 
        AND SMN.SmnNo In(Select distinct SmnNo From departmentsToSmn ) --dont get smn that dont belong to a dept
        ) SN
      FROM LOGONS WHERE AVAILTOMKTHANDHELD = 1
      AND ACTIVE = 1
      AND NVL(LOGONNO, 0) <> 0
      AND LOGONNAME IS NOT NULL
      AND NVL(LANGNO, 0) <> 0
      AND EXISTS (SELECT 1 FROM LOGTOSALOFF WHERE LOGONNO = LOGONS.LOGONNO AND LOGCANSELL = 1) ;*/

     -- USER PREFS
      CURSOR V_PREF_CURSOR (V_LOGONNO NUMBER) IS       (SELECT 'IsAdmin' UP, 'True' UV FROM DUAL ) union (SELECT 'Test1' UP, 'True' UV FROM DUAL );

     --USER SALESOFFICE
      /*CURSOR V_SALESOFFICE_CURSOR (V_LOGONNO NUMBER) IS
        (SELECT SALOFFNO SO FROM LOGTOSALOFF WHERE LOGONNO = V_LOGONNO AND LOGCANSELL = 1 AND SALOFFNO <> -32000
        UNION
        SELECT SALOFFNO FROM SALOFFNO
        WHERE EXISTS (SELECT 1 FROM LOGTOSALOFF WHERE LOGONNO = V_LOGONNO AND LOGCANSELL = 1 AND SALOFFNO = -32000)
        AND SALOFFNO BETWEEN 0 AND 32766);*/
        
      --USER SALESOFFICE (and Stock Locations; SR 16/7/13) 
        CURSOR V_SALESOFFICE_CURSOR (V_LOGONNO NUMBER) IS      
        SELECT sofToStcloc.SALOFFNO SO, StcLoc SL from sofToStcloc,
                        (SELECT SALOFFNO SO FROM LOGTOSALOFF WHERE LOGONNO = V_LOGONNO AND LOGCANSELL = 1 AND SALOFFNO <> -32000
                        UNION
                        SELECT SALOFFNO FROM SALOFFNO
                        WHERE EXISTS (SELECT 1 FROM LOGTOSALOFF WHERE LOGONNO = V_LOGONNO AND LOGCANSELL = 1 AND SALOFFNO = -32000)
                        AND SALOFFNO BETWEEN 0 AND 32766) SoffSubQ
        Where 	SoffSubQ.SO = sofToStcloc.SalOffNo	
        order by 1,2;	

     --USER DEPARTMENTS
      CURSOR V_DEPARTMENTS_CURSOR (V_SMNNO NUMBER) IS
        (SELECT DISTINCT DEPARTMENTSTOSMN.DPTRECNO DC FROM DEPARTMENTSTOSMN
        WHERE DEPARTMENTSTOSMN.SMNNO = V_SMNNO);
        
     --USER PRINTERS       --CURSOR V_DEVICEPRINTERS_CURSOR IS
        CURSOR V_DEVICEPRINTERS_CURSOR (V_LOGONNO NUMBER) IS        
        select DEVICEPRINTERS.PRINTERRECNO, PRINTERNAME, PRINTERADDRESS, PRINTERPORT, PRINTERTYPE, PRINTERUSAGE, PRINTERLOCATION, LOGONNO, LISDEFAULTPRN,
               NVL2(LISDEFAULTPRN, 'true', 'false') LISDEFAULTPRNTEXT 
        from DEVICEPRINTERS, DEVICEPRNTOLOGON
        Where DEVICEPRINTERS.PrinterRecNo = DEVICEPRNTOLOGON.PrinterRecNo
        AND DEVICEPRNTOLOGON.LOGONNO = V_LOGONNO
        order by printerRecNo;
        
        --Menu Items for  user
        CURSOR V_MENUITEMS_CURSOR (V_LOGONNO NUMBER) IS
        select RTrim(ReturnValue) RV from HANDHELDMENUDETS, HANDHELDMENUITEMS
        Where HANDHELDMENUDETS.MenuItemID = HANDHELDMENUITEMS.MenuItemID  
        AND HANDHELDMENUDETS.MenuID in (Select HANDHELDMENUS_MenuID from Logons Where LogonNo = V_LOGONNO AND AvailToMktHandHeld = 1); 

        --select PRINTERRECNO, PRINTERNAME, PRINTERADDRESS, PRINTERPORT, PRINTERTYPE, PRINTERUSAGE, PRINTERLOCATION from DEVICEPRINTERS order by printerRecNo;

  BEGIN
     -- USERS FUNCTION, CALLED AT REGULAR INTERVALS BY THE HANDHELD TO GET LIST OF USERS AND THEIR ASSOCIATED SETUPS AND PREFERENCES

     -- BSDL7962 bmk 15AUG12
     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     IF MI IS NULL THEN
        EC := 100;
        ED := 'You must enter a machine name (MI)';
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT  DEVNAME
           INTO VDEVNAME
           FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

     -- SCAN ALL THE ACTIVE USERS IN THE SYSTEM
     IF EC = 0 THEN
        FOR V_USER_RECORD IN V_USER_CURSOR  LOOP  -- GET ALL THE ACTIVE USERS IN THE SYSTEM
            IF NVL(V_USER_RECORD.SN,0) <> 0 THEN
            BEGIN
                V_USER_CNT := V_USER_CNT + 1;

          		  --Used to encrypt the password on the fly, but now picks up the encrypted password directly
				        --V_MD5PASSWORD1:= DBMS_CRYPTO.HASH (src => utl_i18n.string_to_raw(V_USER_RECORD.UP), typ => DBMS_CRYPTO.hash_MD5 );
				        V_MD5PASSWORD1:= V_USER_RECORD.UP;

                IF V_USER_CNT = 1 THEN
                   HandleOPStr('{', ConCatResultVar);
                   HandleOPStr('"USERS": [', ConCatResultVar);
                ELSE
                   HandleOPStr(',', ConCatResultVar);
                END IF;
                HandleOPStr('{', ConCatResultVar);
                HandleOPStr('"UL": "'|| (V_USER_RECORD.UL) || '",', ConCatResultVar);
                HandleOPStr('"PW": "'|| (V_MD5PASSWORD1) || '",', ConCatResultVar);
				        HandleOPStr('"UN": "'|| (V_USER_RECORD.UN) || '",', ConCatResultVar);
                HandleOPStr('"LC": '|| (V_USER_RECORD.LC) || ',', ConCatResultVar);
                HandleOPStr('"SN": '|| (V_USER_RECORD.SN) || ',', ConCatResultVar);
                
                HandleOPStr('"BY": '|| (V_USER_RECORD.BUYER) || '', ConCatResultVar);
                
                

                -- USER PREFS
                V_PREF_CNT   := 0;
                FOR V_PREF_RECORD IN V_PREF_CURSOR(V_USER_RECORD.LOGONNO)   LOOP  -- GET ALL THE ACTIVE USERS IN THE SYSTEM
                    IF V_PREF_RECORD.UP IS NOT NULL THEN
                    BEGIN

                        V_PREF_CNT := V_PREF_CNT + 1;
                        HandleOPStr(',', ConCatResultVar);
                        IF V_PREF_CNT = 1  THEN
                            HandleOPStr('"USERPREF":[', ConCatResultVar);
                        END IF ;

                        HandleOPStr('{', ConCatResultVar);
                        HandleOPStr('"UP": "'|| (V_PREF_RECORD.UP) || '",', ConCatResultVar);
                        HandleOPStr('"UV": "'|| (V_PREF_RECORD.UV) || '"', ConCatResultVar);
                        HandleOPStr('}', ConCatResultVar);
                        END;
                    END IF;

                END LOOP;

                IF V_PREF_CNT > 0  THEN
                    HandleOPStr(']', ConCatResultVar);
                END IF;

                -- SALES OFFICES
                V_SO_CNT   := 0;
                FOR V_SALESOFFICE_RECORD IN V_SALESOFFICE_CURSOR (V_USER_RECORD.LOGONNO)   LOOP  -- GET ALL THE ACTIVE USERS IN THE SYSTEM
                        V_SO_CNT := V_SO_CNT + 1;
                        HandleOPStr(',', ConCatResultVar);
                        IF V_SO_CNT = 1  THEN
                            HandleOPStr('"SALESOFFICES":[', ConCatResultVar);
                        END IF ;
                        HandleOPStr('{', ConCatResultVar);
                        HandleOPStr('"SO": '|| (V_SALESOFFICE_RECORD.SO) || ',', ConCatResultVar);
                        HandleOPStr('"SL": '|| (V_SALESOFFICE_RECORD.SL) || '', ConCatResultVar);
                        HandleOPStr('}', ConCatResultVar);
                END LOOP;                
                IF V_SO_CNT > 0  THEN
                    HandleOPStr(']', ConCatResultVar);
                END IF;

                -- DEPARTMENTS
                V_DPT_CNT   := 0;
                FOR V_DEPARTMENTS_RECORD IN V_DEPARTMENTS_CURSOR  (V_USER_RECORD.SN)   LOOP  -- GET ALL THE ACTIVE USERS IN THE SYSTEM
                        V_DPT_CNT := V_DPT_CNT + 1;
                        HandleOPStr(',', ConCatResultVar);
                        IF V_DPT_CNT = 1  THEN
                            HandleOPStr('"DEPARTMENTS":[', ConCatResultVar);
                        END IF ;
                        HandleOPStr('{', ConCatResultVar);
                        HandleOPStr('"DC": '|| (V_DEPARTMENTS_RECORD.DC) || '', ConCatResultVar);
                        HandleOPStr('}', ConCatResultVar);
                END LOOP;
                IF V_DPT_CNT > 0  THEN
                    HandleOPStr(']', ConCatResultVar);
                END IF;
                
                -- MENU ITEMS
                V_MNU_CNT   := 0;
                FOR V_MENUITEMS_RECORD IN V_MENUITEMS_CURSOR  (V_USER_RECORD.LOGONNO)   LOOP 
                        V_MNU_CNT := V_MNU_CNT + 1;
                        HandleOPStr(',', ConCatResultVar);
                        IF V_MNU_CNT = 1  THEN
                            HandleOPStr('"MENU":[', ConCatResultVar);
                        END IF ;
                        HandleOPStr('{', ConCatResultVar);
                        HandleOPStr('"MO": "'|| (V_MENUITEMS_RECORD.RV) || '"', ConCatResultVar);
                        HandleOPStr('}', ConCatResultVar);
                END LOOP;
                IF V_MNU_CNT > 0  THEN
                    HandleOPStr(']', ConCatResultVar);
                END IF;

                -- SCAN ALL THE PRINTERS IN THE SYSTEM for the user
                V_PRN_CNT    := 0;
                FOR V_DEVICEPRINTERS_RECORD IN V_DEVICEPRINTERS_CURSOR (V_USER_RECORD.LOGONNO)   LOOP  -- GET ALL THE ACTIVE USERS IN THE SYSTEM
                        V_PRN_CNT  := V_PRN_CNT  + 1;
                        HandleOPStr(',', ConCatResultVar);
                        IF V_PRN_CNT  = 1  THEN
                            HandleOPStr('"PRINTERS":[', ConCatResultVar);
                        END IF ;
                        HandleOPStr('{', ConCatResultVar);                        
                        HandleOPStr('"PN": "'|| (V_DEVICEPRINTERS_RECORD.PRINTERNAME) || '",', ConCatResultVar);
                        HandleOPStr('"PA": "'|| (V_DEVICEPRINTERS_RECORD.PRINTERADDRESS) || '",', ConCatResultVar);
                        HandleOPStr('"PP": ' || (V_DEVICEPRINTERS_RECORD.PRINTERPORT) || ',', ConCatResultVar);  --int
                        HandleOPStr('"PT": "'|| (V_DEVICEPRINTERS_RECORD.PRINTERTYPE) || '",', ConCatResultVar);
                        HandleOPStr('"PU": "'|| (V_DEVICEPRINTERS_RECORD.PRINTERUSAGE) || '",', ConCatResultVar);
                        HandleOPStr('"PD": ' || (V_DEVICEPRINTERS_RECORD.LISDEFAULTPRNTEXT) , ConCatResultVar);    --Bool    
                        HandleOPStr('}', ConCatResultVar);
                END LOOP;                
                IF V_PRN_CNT  > 0  THEN
                    HandleOPStr(']', ConCatResultVar);
                END IF;


                HandleOPStr('}', ConCatResultVar); --Closing Brace for the user
                
            END;
            END IF;

        END LOOP;
     END IF;

     IF V_USER_CNT > 0 THEN
        HandleOPStr(']', ConCatResultVar);
        HandleOPStr('}', ConCatResultVar);
     END IF;

	 --Log the transaction
	HANDHELDLOG (MI, PROCNAME, '?MI='|| MI , EC , ED, ConCatResultVar, '[PRE-LOGON]' ) ;


     IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
     END IF;

  END; --USERS

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
PROCEDURE MarketHandHeldPrefs (MI IN Varchar2 default null) IS

	 --AD 17Aug12  
	 --TV 24Jul13 DeviceSalesOffices added
	 
  	 EC Integer := 0 ; -- Error Code
	 ED VarChar2(255) := ''; -- Error Description
	 PROCNAME VARCHAR(40) := 'MARKETHANDHELDPREFS';
	 Valid	Boolean	  := True;
	 vMachinePref MACHINEPREF%ROWTYPE;
	 vDevRecNo 	  DeviceName.DEVRECNO%TYPE;
	 CountThis SmallInt := 0;
	 vMI DeviceName.DevID%TYPE;
	 vSalOffPref DEVICETOSALOFF%ROWTYPE;
	 vSalOffNo 	 DEVICETOSALOFF.SALOFFNO%TYPE;
	 SalOffStr VarChar(500) := Null;
   ConCatResultVar 			VARCHAR(5000)  := '';
	 
  BEGIN

  	 IF MI is null then
	 	EC := 300;
		ED := 'You must enter a machine name (MI)';
		Valid := False;
	 END IF;

	 If Valid then
        Begin
		   vMI := Upper(MI);

		   Select DevRecNo
		   INTO vDevRecNo
		   FROM DeviceName
           Where DEVActive = 1
           AND Upper(DevID) = vMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=	301;
		        ED := MI || ' is not a registered active device';
				Valid := False;

		   WHEN OTHERS THEN
              EC :=  302;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
			  Valid	:= False;
        END;
	 END IF;
	 
	 
	 --Get the Device to Sales offices		
	 
	 If Valid then 				
	     DECLARE
	     CURSOR SalOffPref_cur IS
  	        Select DeviceToSalOff.* from DeviceName, DeviceToSalOff
            where DeviceName.DevRecNo = DeviceToSalOff.DEVRECNO
            AND Upper(DEVID) = vMI;
	 
	 	 BEGIN
		   IF NOT SalOffPref_cur%ISOPEN
		   then
	       	  OPEN SalOffPref_cur ;
		   END IF;
	 
		   CountThis := 0;
		   LOOP

	          FETCH SalOffPref_cur INTO vSalOffPref;
  
	          EXIT WHEN SalOffPref_cur%NOTFOUND;
	 					 
	 		  If CountThis <> 0 then
			     SalOffStr := SalOffStr || ',';
			  END IF;
			  
	 		  SalOffStr := SalOffStr || vSalOffPref.SalOffNo;
			  
			  CountThis := CountThis + 1;			   
	 	   END LOOP;

	       CLOSE SalOffPref_cur;
	     END; 
		 
     END IF;
	 
	 
	 If Valid then

	   DECLARE
	     CURSOR MachinePref_cur IS
           Select *
		   FROM MACHINEPREF
           WHERE MACHINEPREFNAME IS NOT NULL
		   AND MACHINEPREFVALUE IS NOT NULL
		   AND MACHINEPREF.MACHINEPREFDEVRECNO = vDevRecNo;
	     BEGIN
			   
		   HandleOPStr('{', ConCatResultVar);
		   HandleOPStr('"MACHINEPREF": [', ConCatResultVar);

		   If CountThis > 0 Then
		   	  HandleOPStr('{', ConCatResultVar);
			    HandleOPStr('"MP": "DeviceSalesOffices",', ConCatResultVar);
			    HandleOPStr('"MV": "'|| SalOffStr || '"', ConCatResultVar);
			    HandleOPStr('}', ConCatResultVar);
		   End If;

		   If NOT MachinePref_cur%ISOPEN
		   then
	       	  OPEN MachinePref_cur ;
		   END IF;

		   LOOP

	       FETCH MachinePref_cur INTO vMachinePref;

	          EXIT WHEN MachinePref_cur%NOTFOUND;

			      if CountThis <> 0
			      then
		  	  	    HandleOPStr(',', ConCatResultVar);
	  		    END IF;
		  	    HandleOPStr('{', ConCatResultVar);
		  	    HandleOPStr('"MP": "'|| vMachinePref.MACHINEPREFNAME|| '",', ConCatResultVar);
			      HandleOPStr('"MV": "'|| vMachinePref.MACHINEPREFVALUE|| '"', ConCatResultVar);
			      HandleOPStr('}', ConCatResultVar);
   			    CountThis := CountThis + 1;

		   END LOOP;

	       CLOSE MachinePref_cur;  
		   

		   
		   HandleOPStr(']', ConCatResultVar);
		   HandleOPStr('}', ConCatResultVar);
	     END;
	 ELSE
	 	IF EC != 0 then
	 	  HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
			   }', ConCatResultVar);
		END IF;
	 END IF;

	 --Log the transaction
	 HANDHELDLOG (MI, PROCNAME, '?MI='|| MI, EC , ED, ConCatResultVar, '[PRE-LOGON]' ) ;


  END;  -- MarketHandHeldPrefs


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
 --PROCEDURE ACCOUNTS (SO IN INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL, LA IN INTEGER DEFAULT NULL) IS --No need to change incremental load. if param not supplied it still works.
 PROCEDURE ACCOUNTS (SO IN INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL) IS

     EC INTEGER := 0 ; 	 			 -- ERROR CODE
     ED VARCHAR2(255) := ''; 		 -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'ACCOUNTS';

     VMI DEVICENAME.DEVID%TYPE;
     VDEVNAME DEVICENAME.DEVNAME%TYPE := ''; -- DEVICE NAME FROM QUERY

     V_ACCOUNTS_CNT		NUMBER(5) := 0;		

     ConCatResultVar 			VARCHAR(5000)  := '';
     V_LastAccountAudit integer;

   -- ACCOUNTS DETAILS  
	 -- Added Cash Customer 'CA' boolean TV 19Jul13  And Debugging/Logging Code
   -- Added Account code by sales office TV 23Sep13 
   -- Added comment required using Customer Order Required TV 26Nov13 
		
	 CURSOR V_ACCOUNTS_CURSOR IS
		SELECT	AccClass.CLARECNO,
				AccClass.CLAACCCSTSUP,
				TRIM(AccClass.CLAACCCODE) AS CLAACCCODE,
        (SELECT Rtrim(ACCTOSALOFF.ACSACCCODE) ACSACCCODE FROM AccToSalOff
						WHERE AccToSalOff.ACSSALOFFNO = SO
              AND ACCToSalOff.AcsClaRecNo = AccClass.Clarecno) AS SALOFFClaAccCode,

				REPLACE(REPLACE(TRIM(Accounts.ACCNAME), '\', '\\'), '"', '\"')  AS ACCNAME,
				REPLACE(REPLACE(TRIM(Accounts.ACCADDRESS1), '\', '\\'), '"', '\"') AS ACCADDRESS1,
				REPLACE(REPLACE(TRIM(Accounts.ACCADDRESS2), '\', '\\'), '"', '\"')  AS ACCADDRESS2,
				REPLACE(REPLACE(TRIM(Accounts.ACCADDRESS3), '\', '\\'), '"', '\"') AS ACCADDRESS3,
				REPLACE(REPLACE(TRIM(Accounts.ACCADDRESS4), '\', '\\'), '"', '\"') AS ACCADDRESS4,
				REPLACE(REPLACE(TRIM(Accounts.ACCPOSTCODE), '\', '\\'), '"', '\"') AS ACCPOSTCODE,
  			REPLACE(REPLACE(TRIM(Accounts.ACCVATNO), '\', '\\'), '"', '\"') AS ACCVATNO,
       	REPLACE(REPLACE(TRIM(Accounts.ACCTELNO), '\', '\\'), '"', '\"') AS ACCTELNO,
				Accounts.DefDltRecNo, 
				nvl(Accounts.CashCustomer, 0) as CASHCUSTOMER,
        nvl(Accounts.accCustOrdReq, 0) as COMMENTREQUIRED,
        --(case NVL(AccClass.CLAACTIVE, 0) When 1 then 'true' else 'false' end) CLAACTIVE
        NVL(AccClass.CLAACTIVE, 0) CLAACTIVE
		  FROM	AccClass, Accounts, AccToSalOff
		 WHERE	AccClass.CLAACCNO = Accounts.ACCRECNO
		   AND	AccClass.CLARECNO = AccToSalOff.ACSCLARECNO
		   --AND  AccClass.CLAACTIVE = 1   --taken out because a non-active account can be viewed but NOT put on orders.
       --AND AccClass.ClaAccCstSup in (1,2)
		   AND	EXISTS(SELECT 1
		   				 FROM AccToSalOff SalOff
						WHERE AccToSalOff.ACSSALOFFNO = SalOff.ACSSALOFFNO
						  AND (((SO > 0) AND (SO = SalOff.ACSSALOFFNO)) OR (SO <= 0)));
              
       /*AND (NVL(LA, 0) = 0 OR
            Accounts.AccRecNo In(select distinct AudAccRecNo from AccAudit Where AccAudRecNo > LA)
           );*/ -- 13614

	 V_ACCOUNTS_RECORD V_ACCOUNTS_CURSOR%ROWTYPE;
  BEGIN
     -- ACCOUNTS FUNCTION, CALLED AT REGULAR INTERVALS BY THE HANDHELD TO GET LIST OF CUSTOMER/SUPPLIER ACCOUNTS

     -- LOG 7969 DCYRUS 20-AUG-2012
     -- SO = Sales Office Required
     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     IF MI IS NULL THEN
        EC := 100;
        ED := 'You must enter a machine name (MI)';
     END IF;

     IF SO IS NULL THEN
        EC := 700;
        ED := 'You must enter a S/O (SO)';
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT DEVNAME
             INTO VDEVNAME
             FROM DEVICENAME
            WHERE DEVACTIVE = 1
              AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

   If EC = 0 then
      Begin
         Select (select Max(AccAudRecNo) AccAudRecNo from AccAudit) into V_LastAccountAudit From Dual;
         EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  EC :=	108;
		              ED := MI || ' Cannot get Last Account audit!  ';
		     WHEN OTHERS THEN
              EC :=  109;
              ED := ' Issue extracting Last audit! '|| MI || ' SqlErrM='||  SQLERRM;
      END;
   end if;


   -- IF EC = 0 THEN --now we always return something. the HA (highest audit).
       HandleOPStr('{', ConCatResultVar); --13614  
       --HandleOPStr('{"HA":' || V_LastAccountAudit || ', ', ConCatResultVar); --13614       
    --end if;   

     -- SCAN ALL THE ACTIVE ACCOUNTS IN THE SYSTEM

     IF EC = 0 THEN
		   If NOT V_ACCOUNTS_CURSOR%ISOPEN
		   then
	       	  OPEN V_ACCOUNTS_CURSOR;
		   END IF;

		   LOOP

	       FETCH V_ACCOUNTS_CURSOR INTO V_ACCOUNTS_RECORD;

	          EXIT WHEN V_ACCOUNTS_CURSOR%NOTFOUND;

			  V_ACCOUNTS_CNT := V_ACCOUNTS_CNT + 1;
              IF V_ACCOUNTS_CNT = 1 THEN	 
                -- HandleOPStr('{', ConCatResultVar);
                 HandleOPStr('"ACCOUNTS": [', ConCatResultVar);
              ELSE
                 HandleOPStr(',', ConCatResultVar);
              END IF;
              HandleOPStr('{', ConCatResultVar);
              HandleOPStr('"CL": '|| (V_ACCOUNTS_RECORD.CLARECNO) || ',', ConCatResultVar);
              HandleOPStr('"CS": '|| (V_ACCOUNTS_RECORD.CLAACCCSTSUP) || ',', ConCatResultVar);
              
              if V_ACCOUNTS_RECORD.SALOFFClaAccCode IS NOT NULL THEN
        	       HandleOPStr('"AC": "'|| (V_ACCOUNTS_RECORD.SALOFFCLAACCCODE) || '",', ConCatResultVar);
              ELSE   
   			         HandleOPStr('"AC": "'|| (V_ACCOUNTS_RECORD.CLAACCCODE) || '",', ConCatResultVar);
              END IF;
              
              HandleOPStr('"AN": "'|| (V_ACCOUNTS_RECORD.ACCNAME) || '",', ConCatResultVar);
              HandleOPStr('"A1": "'|| (V_ACCOUNTS_RECORD.ACCADDRESS1) || '",', ConCatResultVar);
              HandleOPStr('"A2": "'|| (V_ACCOUNTS_RECORD.ACCADDRESS2) || '",', ConCatResultVar);
              HandleOPStr('"A3": "'|| (V_ACCOUNTS_RECORD.ACCADDRESS3) || '",', ConCatResultVar);
              HandleOPStr('"A4": "'|| (V_ACCOUNTS_RECORD.ACCADDRESS4) || '",', ConCatResultVar);
              HandleOPStr('"PC": "'|| (V_ACCOUNTS_RECORD.ACCPOSTCODE) || '",', ConCatResultVar);
              HandleOPStr('"AV": "'|| (V_ACCOUNTS_RECORD.ACCVATNO) || '",', ConCatResultVar);
              HandleOPStr('"AT": "'|| (V_ACCOUNTS_RECORD.ACCTELNO) || '",', ConCatResultVar);

			  IF V_ACCOUNTS_RECORD.DefDltRecNo IS NULL THEN
			  	 HandleOPStr('"ST": null,', ConCatResultVar);
			  ELSE
			  	 HandleOPStr('"ST": '|| (V_ACCOUNTS_RECORD.DefDltRecNo) || ',', ConCatResultVar);
			  END IF;
						
			  
			  IF V_ACCOUNTS_RECORD.CASHCUSTOMER = 1 THEN
			  	 HandleOPStr('"CA": true,', ConCatResultVar);
			  ELSE
			  	 HandleOPStr('"CA": false,', ConCatResultVar);
			  END IF;
			  
        --NB this field sometimes has a 2 in it. This is still false!        
        IF V_ACCOUNTS_RECORD.COMMENTREQUIRED = 1 THEN
			  	 --HandleOPStr('"CR": true,', ConCatResultVar);
           HandleOPStr('"CR": true', ConCatResultVar);
			  ELSE
			  	 --HandleOPStr('"CR": false,', ConCatResultVar);
           HandleOPStr('"CR": false', ConCatResultVar);
			  END IF;
        
        /*IF V_ACCOUNTS_RECORD.CLAACTIVE = 1 THEN --12319_13614
			  	 HandleOPStr('"AA": true', ConCatResultVar);
			  ELSE
			  	 HandleOPStr('"AA": false', ConCatResultVar);
			  END IF;*/
        
        HandleOPStr('}', ConCatResultVar);

		   END LOOP;

	       CLOSE V_ACCOUNTS_CURSOR;

		   IF V_ACCOUNTS_CNT > 0 THEN
			   HandleOPStr(']', ConCatResultVar);
			   --HandleOPStr('}', ConCatResultVar);
		   END IF;
       
       HandleOPStr('}', ConCatResultVar);

      --now they have the power to chose which accounts to see
      --...i.e. if lastaudit > 10000...
      --then we cant show an error if none returned.
		   --IF V_ACCOUNTS_CNT = 0 THEN
			  -- EC := 701;
			  -- ED := 'No ACCOUNTS found for S/O (SO)';
		   --END IF;
	 END IF;

     IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
     END IF;

	 --Log the transaction
	 HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' SO=' || SO, EC , ED, ConCatResultVar, '[PRE-LOGON]' ) ;


  END; --ACCOUNTS

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

/*
  PROCEDURE PRODUCTS (SO IN INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL) IS

     EC INTEGER := 0 ; 	 			 -- ERROR CODE
     ED VARCHAR2(255) := ''; 		 -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'PRODUCTS';

     VMI DEVICENAME.DEVID%TYPE;
     VDEVNAME DEVICENAME.DEVNAME%TYPE := ''; -- DEVICE NAME FROM QUERY

     -- PRODUCTS DETAILS

     V_PRODUCTS_CNT		NUMBER(5) := 0;

	 CURSOR V_PRODUCTS_CURSOR IS
		SELECT	PrdRec.PrcPrdNo,
				TRIM(PrdRec.PrcPrdRef) AS PrcPrdRef,
				REPLACE(REPLACE(TRIM(PrdRec.PrcDescription), '\', '\\'), '"', '\"') AS PrcDescription,
				REPLACE(REPLACE(TRIM(P1.ALLPDESC), '\', '\\'), '"', '\"') AS P1,
				REPLACE(REPLACE(TRIM(P2.ALLPDESC), '\', '\\'), '"', '\"') AS P2,
				REPLACE(REPLACE(TRIM(P3.ALLPDESC), '\', '\\'), '"', '\"') AS P3,
				REPLACE(REPLACE(TRIM(P4.ALLPDESC), '\', '\\'), '"', '\"') AS P4,
				REPLACE(REPLACE(TRIM(P5.ALLPDESC), '\', '\\'), '"', '\"') AS P5,
				REPLACE(REPLACE(TRIM(P6.ALLPDESC), '\', '\\'), '"', '\"') AS P6,
				PrdRec.PRCWEIGHT,
				PrdRec.INNERQTY,
				PrdRec.PRCBOXQTY,
				CASE NVL(PrdRec.PRCSALBYWGT, 0)
					 WHEN 0 THEN 'N'
					 ELSE 'Y'
				END AS SellByWeight,
				CASE NVL(PrdRec.PRCSALBYWGT, 0)
					 WHEN 0 THEN 'N'
					 ELSE 'Y'
				END AS SellByInner,
				CASE NVL(PrdRec.PRCSALBYWGT, 0)
					 WHEN 0 THEN 'N'
					 ELSE 'Y'
				END AS SellByEach
		  FROM	PrdRec
		  		LEFT OUTER JOIN PrdAllDescs P1 ON (P1.ALLPREFNO = PrdRec.PRCREF1 AND P1.ALLPLEVNO = 1)
		  		LEFT OUTER JOIN PrdAllDescs P2 ON (P2.ALLPREFNO = PrdRec.PRCREF2 AND P2.ALLPLEVNO = 2)
		  		LEFT OUTER JOIN PrdAllDescs P3 ON (P3.ALLPREFNO = PrdRec.PRCREF3 AND P3.ALLPLEVNO = 3)
		  		LEFT OUTER JOIN PrdAllDescs P4 ON (P4.ALLPREFNO = PrdRec.PRCREF4 AND P4.ALLPLEVNO = 4)
		  		LEFT OUTER JOIN PrdAllDescs P5 ON (P5.ALLPREFNO = PrdRec.PRCREF5 AND P5.ALLPLEVNO = 5)
		  		LEFT OUTER JOIN PrdAllDescs P6 ON (P6.ALLPREFNO = PrdRec.PRCREF6 AND P6.ALLPLEVNO = 6)
		 WHERE	EXISTS(SELECT 1
		   				 FROM PRDRECTOSO
						WHERE PRDRECTOSO.PRCPRDNO = PrdRec.PRCPRDNO
						  AND (((SO > 0) AND (SO = PRDRECTOSO.SALOFFNO)) OR (SO <= 0)));

	 V_PRODUCTS_RECORD V_PRODUCTS_CURSOR%ROWTYPE;

     -- PRDRECTOSO DETAILS

     V_PRDRECTOSO_CNT		NUMBER(5) := 0;

	 CURSOR V_PRDRECTOSO_CURSOR (V_PRCPRDNO NUMBER) IS
	   (SELECT  TRIM(PRDREC.PRCSHORTDESC) AS PRCSHORTDESC,
				PRDRECTOSO.SALOFFNO
		  FROM  PRDRECTOSO, PRDREC
		 WHERE	PRDRECTOSO.PRCPRDNO = PRDREC.PRCPRDNO
		   AND  PRDRECTOSO.PRCPRDNO = V_PRCPRDNO
		   AND  (((SO > 0) AND (SO = PRDRECTOSO.SALOFFNO)) OR (SO <= 0)) );

	 V_PRDRECTOSO_RECORD V_PRDRECTOSO_CURSOR%ROWTYPE;
  BEGIN
     -- PRODUCTS FUNCTION, CALLED AT REGULAR INTERVALS BY THE HANDHELD TO GET LIST OF PRODUCTS AND THEIR ASSOCIATED SHORT CODES BY SALES OFFICES

     -- LOG 7969 DCYRUS 20-AUG-2012
     -- SO = Sales Office Required
     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     IF MI IS NULL THEN
        EC := 100;
        ED := 'You must enter a machine name (MI)';
     END IF;

     IF SO IS NULL THEN
        EC := 600;
        ED := 'You must enter a S/O (SO)';
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT DEVNAME
             INTO VDEVNAME
             FROM DEVICENAME
            WHERE DEVACTIVE = 1
              AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

     -- SCAN ALL THE ACTIVE PRODUCTS IN THE SYSTEM

     IF EC = 0 THEN
		   If NOT V_PRODUCTS_CURSOR%ISOPEN
		   then
	       	  OPEN V_PRODUCTS_CURSOR;
		   END IF;

		   LOOP

	       FETCH V_PRODUCTS_CURSOR INTO V_PRODUCTS_RECORD;

	          EXIT WHEN V_PRODUCTS_CURSOR%NOTFOUND;

			  V_PRODUCTS_CNT := V_PRODUCTS_CNT + 1;
              IF V_PRODUCTS_CNT = 1 THEN
                 HTP.P('{');
                 HTP.P('"PRODUCTS": [');
              ELSE
                 HTP.P(',');
              END IF;
              HTP.P('{');
              HTP.P('"PR": "'|| (V_PRODUCTS_RECORD.PRCPRDNO) || '",');
              HTP.P('"PC": "'|| (V_PRODUCTS_RECORD.PRCPRDREF) || '",');
              HTP.P('"PD": "'|| (V_PRODUCTS_RECORD.PRCDESCRIPTION) || '",');
              HTP.P('"P1": "'|| (V_PRODUCTS_RECORD.P1) || '",');
              HTP.P('"P2": "'|| (V_PRODUCTS_RECORD.P2) || '",');
              HTP.P('"P3": "'|| (V_PRODUCTS_RECORD.P3) || '",');
              HTP.P('"P4": "'|| (V_PRODUCTS_RECORD.P4) || '",');
              HTP.P('"P5": "'|| (V_PRODUCTS_RECORD.P5) || '",');
              HTP.P('"P6": "'|| (V_PRODUCTS_RECORD.P6) || '",');
              HTP.P('"KG": "'|| (V_PRODUCTS_RECORD.PRCWEIGHT) || '",');
              HTP.P('"IN": "'|| (V_PRODUCTS_RECORD.INNERQTY) || '",');
              HTP.P('"EA": "'|| (V_PRODUCTS_RECORD.PRCBOXQTY) || '",');
              HTP.P('"SK": "'|| (V_PRODUCTS_RECORD.SellByWeight) || '",');
              HTP.P('"SI": "'|| (V_PRODUCTS_RECORD.SellByInner) || '",');
              HTP.P('"SE": "'|| (V_PRODUCTS_RECORD.SellByEach) || '",');
              HTP.P('"V1": "'|| (V_PRODUCTS_RECORD.SellByEach) || '",');
              HTP.P('"V2": "'|| (V_PRODUCTS_RECORD.SellByEach) || '"');

			    -- SCAN ALL THE ACTIVE PRODUCTS BY SALES OFFICE IN THE SYSTEM

			  IF EC = 0 THEN
				 V_PRDRECTOSO_CNT := 0;
			     FOR V_PRDRECTOSO_RECORD IN V_PRDRECTOSO_CURSOR (V_PRODUCTS_RECORD.PRCPRDNO) LOOP

					V_PRDRECTOSO_CNT := V_PRDRECTOSO_CNT + 1;

					HTP.P(',');
					IF V_PRDRECTOSO_CNT = 1 THEN
					   HTP.P('"SHORTCODE":[');
					END IF;
					HTP.P('{');
					HTP.P('"SO": "'|| (V_PRDRECTOSO_RECORD.SALOFFNO) || '",');
					HTP.P('"PS": "'|| (V_PRDRECTOSO_RECORD.PRCSHORTDESC) || '"');
					HTP.P('}');

				 END LOOP;

--			     CLOSE V_PRDRECTOSO_CURSOR;
			 END IF;

			 IF V_PRDRECTOSO_CNT > 0 THEN
			   HTP.P(']');
			   HTP.P('}');
			 END IF;

--             HTP.P('}');

		   END LOOP;

	       CLOSE V_PRODUCTS_CURSOR;

	     IF V_PRODUCTS_CNT > 0 THEN
	        HTP.P(']');
	        HTP.P('}');
	     END IF;

		 IF V_PRODUCTS_CNT = 0 THEN
	        EC := 601;
	        ED := 'No PRODUCTS found for S/O';
		 END IF;

	 END IF;

     IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HTP.P('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }');
     END IF;

	  --Log the transaction
	 HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || '. SO=' || SO, EC , ED ) ;

  END; --PRODUCTS
*/


  --PROCEDURE PRODUCTS (SO IN INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL, LA IN INTEGER DEFAULT NULL) IS --13614
PROCEDURE PRODUCTS (SO IN INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL) IS --, LA IN INTEGER DEFAULT NULL) IS

     EC INTEGER := 0 ; 	 			 -- ERROR CODE
     ED VARCHAR2(255) := ''; 		 -- ERROR DESCRIPTION
	   PROCNAME VARCHAR(40) := 'PRODUCTS';

     VMI DEVICENAME.DEVID%TYPE;
     VDEVNAME DEVICENAME.DEVNAME%TYPE := ''; -- DEVICE NAME FROM QUERY
     ConCatResultVar 			VARCHAR(5000)  := '';
	
     -- PRODUCTS DETAILS
     -- 25Jul13 added DefaultProduct (DP) TV
     -- 7Jan14 changed all products to allow each,inner and kg (SK, SI,SE) but code to 
     -- look at prdrec left in incase they go back to wanting it TV 

     V_PRODUCTS_CNT		NUMBER(5) := 0;
     V_LastProductAudit integer;

	 CURSOR V_PRODUCTS_CURSOR IS
		SELECT	PrdRec.PrcPrdNo,
				TRIM(PrdRec.PrcPrdRef) AS PrcPrdRef,
				REPLACE(REPLACE(TRIM(PrdRec.PrcDescription), '\', '\\'), '"', '\"') AS PrcDescription,
				REPLACE(REPLACE(TRIM(P1.ALLPDESC), '\', '\\'), '"', '\"') AS P1,
				REPLACE(REPLACE(TRIM(P2.ALLPDESC), '\', '\\'), '"', '\"') AS P2,
				REPLACE(REPLACE(TRIM(P3.ALLPDESC), '\', '\\'), '"', '\"') AS P3,
				REPLACE(REPLACE(TRIM(P4.ALLPDESC), '\', '\\'), '"', '\"') AS P4,
				REPLACE(REPLACE(TRIM(P5.ALLPDESC), '\', '\\'), '"', '\"') AS P5,
				REPLACE(REPLACE(TRIM(P6.ALLPDESC), '\', '\\'), '"', '\"') AS P6,
				PrdRec.PRCWEIGHT,
				PrdRec.INNERQTY,
				PrdRec.PRCBOXQTY,
        NVL (PrdRec.DefaultPrd, 0) as DEFAULTPRD,
				CASE NVL(PrdRec.PRCSALBYWGT, 0)
					 WHEN 0 THEN 'N'
					 ELSE 'Y'
				END AS SellByWeight,
				CASE NVL(PrdRec.PRCSALBYWGT, 0)
					 WHEN 0 THEN 'N'
					 ELSE 'Y'
				END AS SellByInner,
				CASE NVL(PrdRec.PRCSALBYWGT, 0)
					 WHEN 0 THEN 'N'
					 ELSE 'Y'
				END AS SellByEach,
        PrdRec.Active
		  FROM	PrdRec
		  		LEFT OUTER JOIN PrdAllDescs P1 ON (P1.ALLPREFNO = PrdRec.PRCREF1 AND P1.ALLPLEVNO = 1)
		  		LEFT OUTER JOIN PrdAllDescs P2 ON (P2.ALLPREFNO = PrdRec.PRCREF2 AND P2.ALLPLEVNO = 2)
		  		LEFT OUTER JOIN PrdAllDescs P3 ON (P3.ALLPREFNO = PrdRec.PRCREF3 AND P3.ALLPLEVNO = 3)
		  		LEFT OUTER JOIN PrdAllDescs P4 ON (P4.ALLPREFNO = PrdRec.PRCREF4 AND P4.ALLPLEVNO = 4)
		  		LEFT OUTER JOIN PrdAllDescs P5 ON (P5.ALLPREFNO = PrdRec.PRCREF5 AND P5.ALLPLEVNO = 5)
		  		LEFT OUTER JOIN PrdAllDescs P6 ON (P6.ALLPREFNO = PrdRec.PRCREF6 AND P6.ALLPLEVNO = 6)
		 WHERE	EXISTS(SELECT 1 FROM PRDRECTOSO
						       WHERE PRDRECTOSO.PRCPRDNO = PrdRec.PRCPRDNO
						       AND (((SO > 0) AND (SO = PRDRECTOSO.SALOFFNO)) OR (SO <= 0)));
                   
    /* AND ( (NVL(LA, 0) = 0) --All products
         OR --Products since last audit...
           (PrdRec.PRCPRDNO in(Select distinct AuditLinkRecNo1 From auditRecord where AuditTypeNo = 9017 and AuditRecordNo > LA
				                       UNION		  
				                       select distinct AuditLinkRecNo2 from auditRecord where AuditTypeNo = 9031 and AuditRecordNo > LA)	   	
           ));*/               
                   
	 V_PRODUCTS_RECORD V_PRODUCTS_CURSOR%ROWTYPE;

     -- PRDRECTOSO DETAILS

     V_PRDRECTOSO_CNT		NUMBER(5) := 0;

	 CURSOR V_PRDRECTOSO_CURSOR (V_PRCPRDNO NUMBER) IS
	   (SELECT  TRIM(PRDREC.PRCSHORTDESC) AS PRCSHORTDESC,
				PRDRECTOSO.SALOFFNO
		  FROM  PRDRECTOSO, PRDREC
		 WHERE	PRDRECTOSO.PRCPRDNO = PRDREC.PRCPRDNO
		   AND  PRDRECTOSO.PRCPRDNO = V_PRCPRDNO
		   AND  (((SO > 0) AND (SO = PRDRECTOSO.SALOFFNO)) OR (SO <= 0)) );

	 V_PRDRECTOSO_RECORD V_PRDRECTOSO_CURSOR%ROWTYPE;
  BEGIN
     -- PRODUCTS FUNCTION, CALLED AT REGULAR INTERVALS BY THE HANDHELD TO GET LIST OF PRODUCTS AND THEIR ASSOCIATED SHORT CODES BY SALES OFFICES

     -- LOG 7969 DCYRUS 20-AUG-2012
     -- SO = Sales Office Required
     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     IF MI IS NULL THEN
        EC := 100;
        ED := 'You must enter a machine name (MI)';
     END IF;

     IF SO IS NULL THEN
        EC := 600;
        ED := 'You must enter a S/O (SO)';
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT DEVNAME
             INTO VDEVNAME
             FROM DEVICENAME
            WHERE DEVACTIVE = 1
              AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

     -- SCAN ALL THE ACTIVE PRODUCTS IN THE SYSTEM

     IF EC = 0 THEN
		   If NOT V_PRODUCTS_CURSOR%ISOPEN
		   then
	       	  OPEN V_PRODUCTS_CURSOR;
		   END IF;

		   LOOP

	       FETCH V_PRODUCTS_CURSOR INTO V_PRODUCTS_RECORD;

	          EXIT WHEN V_PRODUCTS_CURSOR%NOTFOUND;
			        V_PRODUCTS_CNT := V_PRODUCTS_CNT + 1;
              
              IF V_PRODUCTS_CNT = 1 THEN --Get the HA Highest audit.
                  If EC = 0 then                  
                      Begin                      
                         Select Max(AuditRecordNo) into  V_LastProductAudit from auditRecord where AuditTypeNo in (9017, 9031) ; -- From Dual;
                         EXCEPTION
                               WHEN NO_DATA_FOUND THEN
                                  EC :=	108;
                                  ED := MI || ' Cannot get Last product audit!  ';
                         WHEN OTHERS THEN
                              EC :=  109;
                              ED := ' Issue extracting Last product audit! '|| MI || ' SqlErrM='||  SQLERRM;
                      END;
                   end if;   
              end if;
                
              
              IF V_PRODUCTS_CNT = 1 THEN                 
                 HandleOPStr('{', ConCatResultVar); --13614 12319
                 --HandleOPStr('{"HA": ' || V_LastProductAudit ||',', ConCatResultVar); --13614 12319
                 HandleOPStr('"PRODUCTS": [', ConCatResultVar);
              ELSE
                 HandleOPStr(',', ConCatResultVar);
              END IF;
              HandleOPStr('{', ConCatResultVar);
              HandleOPStr('"PR": "'|| (V_PRODUCTS_RECORD.PRCPRDNO) || '",', ConCatResultVar);
              HandleOPStr('"PC": "'|| (V_PRODUCTS_RECORD.PRCPRDREF) || '",', ConCatResultVar);
              HandleOPStr('"PD": "'|| (V_PRODUCTS_RECORD.PRCDESCRIPTION) || '",', ConCatResultVar);
              HandleOPStr('"P1": "'|| (V_PRODUCTS_RECORD.P1) || '",', ConCatResultVar);
              HandleOPStr('"P2": "'|| (V_PRODUCTS_RECORD.P2) || '",', ConCatResultVar);
              HandleOPStr('"P3": "'|| (V_PRODUCTS_RECORD.P3) || '",', ConCatResultVar);
              HandleOPStr('"P4": "'|| (V_PRODUCTS_RECORD.P4) || '",', ConCatResultVar);
              HandleOPStr('"P5": "'|| (V_PRODUCTS_RECORD.P5) || '",', ConCatResultVar);
              HandleOPStr('"P6": "'|| (V_PRODUCTS_RECORD.P6) || '",', ConCatResultVar);
              HandleOPStr('"KG": "'|| (V_PRODUCTS_RECORD.PRCWEIGHT) || '",', ConCatResultVar);
              HandleOPStr('"IN": "'|| (V_PRODUCTS_RECORD.INNERQTY) || '",', ConCatResultVar);
              HandleOPStr('"EA": "'|| (V_PRODUCTS_RECORD.PRCBOXQTY) || '",', ConCatResultVar);
              --HandleOPStr('"SK": "'|| (V_PRODUCTS_RECORD.SellByWeight) || '",', ConCatResultVar);
              --HandleOPStr('"SI": "'|| (V_PRODUCTS_RECORD.SellByInner) || '",', ConCatResultVar);
              --HandleOPStr('"SE": "'|| (V_PRODUCTS_RECORD.SellByEach) || '",', ConCatResultVar);
              HandleOPStr('"SK": "'|| 'Y' || '",', ConCatResultVar);
              HandleOPStr('"SI": "'|| 'Y' || '",', ConCatResultVar);
              HandleOPStr('"SE": "'|| 'Y' || '",', ConCatResultVar);
              HandleOPStr('"V1": "'|| (V_PRODUCTS_RECORD.SellByEach) || '",', ConCatResultVar);
              HandleOPStr('"V2": "'|| (V_PRODUCTS_RECORD.SellByEach) || '",', ConCatResultVar);

              IF V_PRODUCTS_RECORD.DefaultPrd = 1 
              THEN
                 HandleOPStr('"DP": true', ConCatResultVar);
              ELSE
                 HandleOPStr('"DP": false', ConCatResultVar);
              END IF;
              
             /* IF V_PRODUCTS_RECORD.Active = 1  --SR 12319 13614 send active flag AP = 'Active' product.
              THEN
                 HandleOPStr('"AP": true', ConCatResultVar);
              ELSE
                 HandleOPStr('"AP": false', ConCatResultVar);
              END IF;              */
                 
			    -- SCAN ALL THE ACTIVE PRODUCTS BY SALES OFFICE IN THE SYSTEM

			  IF EC = 0 THEN
				 V_PRDRECTOSO_CNT := 0;
			     FOR V_PRDRECTOSO_RECORD IN V_PRDRECTOSO_CURSOR (V_PRODUCTS_RECORD.PRCPRDNO) LOOP

					V_PRDRECTOSO_CNT := V_PRDRECTOSO_CNT + 1;

					HandleOPStr(',', ConCatResultVar);
					IF V_PRDRECTOSO_CNT = 1 THEN
					   HandleOPStr('"SHORTCODE":[', ConCatResultVar);
					END IF;
					HandleOPStr('{', ConCatResultVar);
					HandleOPStr('"SO": "'|| (V_PRDRECTOSO_RECORD.SALOFFNO) || '",', ConCatResultVar);
					HandleOPStr('"PS": "'|| (V_PRDRECTOSO_RECORD.PRCSHORTDESC) || '"', ConCatResultVar);
					HandleOPStr('}', ConCatResultVar);

				 END LOOP;

--			     CLOSE V_PRDRECTOSO_CURSOR;
			 END IF;

			 IF V_PRDRECTOSO_CNT > 0 THEN
			   HandleOPStr(']', ConCatResultVar);
			   HandleOPStr('}', ConCatResultVar);
			 END IF;

--             HandleOPStr('}', ConCatResultVar);

		   END LOOP;

	       CLOSE V_PRODUCTS_CURSOR;

	     IF V_PRODUCTS_CNT > 0 THEN
	        HandleOPStr(']', ConCatResultVar);
	        HandleOPStr('}', ConCatResultVar);
	     END IF;

		 IF V_PRODUCTS_CNT = 0 THEN
	        EC := 601;
	        ED := 'No PRODUCTS found for S/O';
		 END IF;

	 END IF;

     IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
     END IF;

	  --Log the transaction
	 HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || '. SO=' || SO, EC , ED, ConCatResultVar, '[PRE-LOGON]' ) ;

  END; --PRODUCTS

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
  PROCEDURE SHORTCODES (SO IN INTEGER DEFAULT 0, MI IN VARCHAR2 DEFAULT NULL) IS
     -- Product Short Code Details TV 25Jul13

     EC INTEGER := 0 ; 	 			 -- ERROR CODE
     ED VARCHAR2(255) := ''; 	 -- ERROR DESCRIPTION
	   PROCNAME VARCHAR(40) := 'SHORTCODES';

     VMI DEVICENAME.DEVID%TYPE;
     VDEVNAME DEVICENAME.DEVNAME%TYPE := ''; -- DEVICE NAME FROM QUERY
     ConCatResultVar 			VARCHAR(5000)  := '';
     
     V_SHORTCODE_CNT		NUMBER(5) := 0;
     
     V_DevRecNo integer := 0;
     
	    CURSOR V_SHORTCODE_CURSOR IS
			    SELECT SHORTCODEDEFAULT.SALESOFFICE, RTRIM(SHORTCODEDEFAULT.SHORTCODE) AS SHORTCODE, 
          RTRIM(SHORTCODEDEFAULT.SHORTCODEDESCRIPTION) AS  SHORTCODEDESCRIPTION, NVL(SHORTCODEDEFAULT.DEFAULTPRCPRDNO, -1) AS DEFAULTPRCPRDNO
      FROM SHORTCODEDEFAULT
      WHERE (((SO > 0) AND (SO = SHORTCODEDEFAULT.SALESOFFICE)) OR (SO <= 0));

	 V_SHORTCODE_RECORD V_SHORTCODE_CURSOR%ROWTYPE;

  BEGIN
     IF MI IS NULL THEN
        EC := 100;
        ED := 'You must enter a machine name (MI)';
     END IF;

     IF SO IS NULL THEN
        EC := 600;
        ED := 'You must enter a S/O (SO)';
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     --MachineIDValidate(MI, EC, ED);
     MachineIDValidate(MI, EC, ED, V_DevRecNo);

     -- SCAN ALL THE SHORTCODES IN THE SYSTEM

     IF EC = 0 THEN
		   If NOT V_SHORTCODE_CURSOR%ISOPEN
		   then
	       	  OPEN V_SHORTCODE_CURSOR;
		   END IF;

		   LOOP

	       FETCH V_SHORTCODE_CURSOR INTO V_SHORTCODE_RECORD;

	          EXIT WHEN V_SHORTCODE_CURSOR%NOTFOUND;

			        V_SHORTCODE_CNT := V_SHORTCODE_CNT + 1;
              IF V_SHORTCODE_CNT = 1 THEN
                HandleOPStr('{', ConCatResultVar);
                HandleOPStr('"SHORTCODES": [', ConCatResultVar);
              ELSE
                 HandleOPStr('},', ConCatResultVar);
              END IF;
              HandleOPStr('{', ConCatResultVar);
              HandleOPStr('"SO": ' || (V_SHORTCODE_RECORD.SALESOFFICE) || ',', ConCatResultVar);
              HandleOPStr('"PS": "'|| (V_SHORTCODE_RECORD.SHORTCODE) || '",', ConCatResultVar);
              HandleOPStr('"PD": "'|| (V_SHORTCODE_RECORD.SHORTCODEDESCRIPTION) || '",', ConCatResultVar);
              
              IF V_SHORTCODE_RECORD.DEFAULTPRCPRDNO <= 0 
              THEN
                 HandleOPStr('"PR": null', ConCatResultVar);
              ELSE
                 HandleOPStr('"PR": '|| (V_SHORTCODE_RECORD.DEFAULTPRCPRDNO) || '', ConCatResultVar);
              END IF;
              
     	   END LOOP;

	     CLOSE V_SHORTCODE_CURSOR;

	     IF V_SHORTCODE_CNT > 0 THEN
	        HandleOPStr('}', ConCatResultVar);
	        HandleOPStr(']', ConCatResultVar);
	        HandleOPStr('}', ConCatResultVar);
	     END IF;

		 IF V_SHORTCODE_CNT = 0 THEN
	        EC := 601;
	        ED := 'No ShortCodes found for S/O';
		 END IF;

	 END IF;

     IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
     END IF;

	  --Log the transaction
	 HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || '. SO=' || SO, EC , ED, ConCatResultVar, '[PRE-LOGON]' ) ;

  END; --SHORTCODES


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

PROCEDURE DOWNLOADVAT(MI IN VARCHAR2,
		  			  SO IN INTEGER,
					  SL IN INTEGER,
					  CL IN INTEGER,
					  PR IN INTEGER,
					  EP IN OUT FLOAT) AS

canproc				  BOOLEAN DEFAULT true;
EC					  INTEGER DEFAULT 0;
ED					  VARCHAR2(255);
PROCNAME VARCHAR(40) := 'DOWNLOADVAT';

vMI 				  DEVICENAME.DEVID%TYPE;
vDevRecNo			  DEVICENAME.DEVRECNO%TYPE;
VatRecNo_out 		  VATRATES.VATRECNO%TYPE;
VeaRecNo_out 		  VATEXEMPT.VEARECNO%TYPE;
VatAmount1_out 		  FLOAT;
VatAmount2_out 		  FLOAT;
ConCatResultVar 			VARCHAR(2000)  := '';

TYPE vat_output_rec IS RECORD (
	 EP				VARCHAR2(2000) DEFAULT 'null',
	 V1				VARCHAR2(2000) DEFAULT 'null',
	 V2				VARCHAR2(2000) DEFAULT 'null',
	 T1				VARCHAR2(2000) DEFAULT 'null',
	 T2				VARCHAR2(2000) DEFAULT 'null',
	 GT				VARCHAR2(2000) DEFAULT 'null',
	 VT				VARCHAR2(2000) DEFAULT 'null');

vat_output			vat_output_rec;
rec_VatRates		VATRATES%ROWTYPE;
vVatExempt			VATEXEMPT.VeaShortDesc%TYPE;

BEGIN
	IF canproc
	THEN
		IF MI IS NULL
		THEN
			EC := 1201;
		 	ED := 'You must enter a machine name (MI)';
			canproc := false;
		END IF;
	END IF;

	IF canproc
	THEN
		BEGIN
			  vMI := UPPER(MI);

		   	  SELECT DevRecNo
		   	  INTO vDevRecNo
		   	  FROM DeviceName
           	  WHERE DEVActive = 1
           	  	AND UPPER(DevID) = vMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC := 1202;
		        ED := MI || ' is not a registered active device.';
				canproc := false;

		   WHEN OTHERS THEN
              EC :=  1203;
              ED := 'Unable to execute SQL to obtain device information for '|| MI || ' SqlErrM='||  SQLERRM;
			  canproc := false;
        END;

	END IF;

	IF canproc
	THEN
		BEGIN
			  VAT_PKG.CALCSALESVAT(	CL,
                      				PR,
                      				SL,
                      				SO,
                      				NULL,
									EP,
									VatRecNo_out,
                      				VeaRecNo_out,
									VatAmount1_out,
									VatAmount2_out) ;
		EXCEPTION
				 WHEN OTHERS THEN
				 	  EC := 1204;
					  ED := 'Unable to retrieve VAT details for '|| MI || '.';
					  canproc := false;
		END;
	END IF;

	IF canproc
	THEN
		BEGIN
			SELECT vatrates.*
			INTO rec_VatRates
			FROM VATRATES vatrates
			WHERE vatrates.VatRecNo = VatRecNo_out;
		EXCEPTION
				 WHEN OTHERS THEN
				 	  EC := 1205;
					  ED := 'Unable to retrieve VAT details for '|| MI || '.';
					  canproc := false;
		END;
	END IF;

	IF canproc
	THEN
		BEGIN
			SELECT vatexempt.VeaShortDesc
			INTO vVatExempt
			FROM VATEXEMPT vatexempt
			WHERE vatexempt.VeaRecNo = VeaRecNo_out;
		EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  vVatExempt := 'NULL';
				 WHEN OTHERS THEN
				 	  EC := 1205;
					  ED := 'Unable to retrieve VAT details for '|| MI || '.';
					  canproc := false;
		END;
	END IF;

	IF canproc
	THEN
		vat_output.EP := TO_CHAR(EP);
		vat_output.V1 := TO_CHAR(VatAmount1_out);
		vat_output.T1 := '"' || TO_CHAR(rec_VatRates.VatRate) || '%"';
		vat_output.GT := TO_CHAR(TO_NUMBER(EP + VatAmount1_out));

		IF VatAmount2_out IS NOT NULL
		THEN
			vat_output.V1 := TO_CHAR(VatAmount2_out);
			vat_output.T1 := '"' || TO_CHAR(rec_VatRates.VatRate2) || '%"';
			vat_output.GT := TO_CHAR(TO_NUMBER(EP + VatAmount1_out + VatAmount2_out));
		END IF;

		vat_output.VT := '"' || TRIM(vVatExempt) || '"';

		/*HTP.P('{');
		HTP.P('"EP":' || vat_output.EP || ',');
		HTP.P('"V1":' || vat_output.V1 || ',');
		HTP.P('"V2":' || vat_output.V2 || ',');
		HTP.P('"T1":' || vat_output.T1 || ',');
		HTP.P('"T2":' || vat_output.T2 || ',');
		HTP.P('"GT":' || vat_output.GT || ',');
		HTP.P('"VT":' || vat_output.VT);
		HTP.P('}');*/
    
    HandleOPStr('{"EP":' || vat_output.EP || ',', ConCatResultVar);
    HandleOPStr('"V1":' || vat_output.V1 || ',', ConCatResultVar);
    HandleOPStr('"V2":' || vat_output.V2 || ',', ConCatResultVar);
    HandleOPStr('"T1":' || vat_output.T1 || ',', ConCatResultVar);
    HandleOPStr('"T2":' || vat_output.T2 || ',', ConCatResultVar);
    HandleOPStr('"GT":' || vat_output.GT || ',', ConCatResultVar);
    HandleOPStr('"VT":' || vat_output.VT || '}', ConCatResultVar);
	ELSE
		--HTP.P('{');
		--HTP.P('"EC":' || TO_CHAR(EC));
		--HTP.P('"ED":"' || TO_CHAR(ED) || '"');
		--HTP.P('}');
    
    HandleOPStr('{"EC":' || TO_CHAR(EC), ConCatResultVar);
    HandleOPStr('"ED":"' || TO_CHAR(ED) || '"}', ConCatResultVar);
    
	END IF;
  
  --HandleOPStr(, ConCatResultVar);

    --Log the transaction
    HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' SO=' || SO || ' SL=' || SL || ' CL=' ||CL || ' PR=' ||PR || ' EP=' || EP, EC , ED , ConCatResultVar, '[N/A]') ;

END;



--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

 PROCEDURE TICKET_DLVRELINV_GETSTATUS (TB IN INTEGER, TN IN INTEGER, MI IN VARCHAR2 DEFAULT NULL) IS

     -- procedure to get the status of a ticket.
     -- LOG 7973 SRIMEN 21-AUG-2012
     -- TB = Ticket Book Number
	 -- TN = Ticket Number
     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     EC INTEGER := 0 ; 	 			 -- ERROR CODE
     ED VARCHAR2(255) := ''; 		 -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'TICKET_DLVRELINV_GETSTATUS';
     VMI DEVICENAME.DEVID%TYPE;
     VDEVNAME DEVICENAME.DEVNAME%TYPE := ''; -- DEVICE NAME FROM QUERY
     V_DLVRELINV_CNT		NUMBER(5) := 0;     
     ConCatResultVar 			VARCHAR(2000)  := '';


--BEGIN
     CURSOR V_DLVRELINV_CURSOR IS

	 Select tntTbkRecNo, tntno, TntDlvOrdNo, DlvRelInv,
	        SIAmendmentStatus, LkUpAmendStatusDesc.LkUpDesc AmendStatusDesc,
			SITicketStatus,    LkUpTicketStatusDesc.LkUpDesc TktStatusDesc
     From ( select tktnt.tntTbkRecNo,
       tktnt.tntno,
	   tktnt.TntDlvOrdNo,
	   Nvl(DELHED.ISOPENFORMORE, 0) ISOPENFORMORE,
	   (Case TntDlvOrdNo When -1 Then 'Does Not Exist' else NVL(DelHed.DlvRelInv, 'NONE')  end) as DlvRelInv,
        --*****(A) Amendment Status*************
		(Case When (DELHED.DLVRELINV in ('Rel', 'Inv'))                                       Then 2
		      When (TNTDLVORDNO = -1)                                                         Then 2
			  When (DELHED.DLVRELINV in (NULL, 'Dlv')) AND (NVL(DELHED.ISOPENFORMORE, 0) < 2) Then 1
			  When ((TNTDLVORDNO = 0)       AND (NVL(DELHED.ISOPENFORMORE, 0) < 2))           Then 0
			  When ((TNTDLVORDNO > 0)       AND (NVL(DELHED.ISOPENFORMORE, 0) < 2))           Then 0
		      When ((TNTDLVORDNO = 0)       AND (NVL(DELHED.ISOPENFORMORE, 0) = 2))           Then 2
			  When ((TNTDLVORDNO > 0)       AND (NVL(DELHED.ISOPENFORMORE, 0) > 1))           Then 2
			  When ((TNTDLVORDNO > 0) AND DELHED.DLVRELINV in ('', 'Dlv'))                    Then 1
			  When (DELHED.DLVRELINV not in ('', 'Dlv'))                                      Then 2
			  else                                                                                -1 --error
		      End ) SIAmendmentStatus,

        --*****(B) Ticket Status*************
		(Case When (TNTDLVORDNO = -1)                                         Then 7
		      When (TNTDLVORDNO = 0)                                          Then 8  --order not yet created
		      When Nvl(DELHED.ISOPENFORMORE, 0) > 1                           Then 6
			  When DELHED.DLVRELINV IS NULL AND DELHED.ISOPENFORMORE <  2     Then 1
		      When DELHED.DLVRELINV IS NULL AND DELHED.ISOPENFORMORE >= 2     Then 2
			  When DELHED.DLVRELINV in ('Dlv')                                Then 3
			  When DELHED.DLVRELINV in ('Inv')                                Then 4
			  When DELHED.DLVRELINV in ('Rel')                                Then 5
			  else                                                                -1
		      End ) SITicketStatus

		From tktnt
		   	 Left Outer Join DelHed on (tktnt.TNTDLVORDNO > 0  AND tktnt.TNTDLVORDNO = DelHed.DlvOrdNo)
		WHERE tktnt.tntTbkRecNo = TB --926
		AND   tktnt.tntno       = TN --408016

	) TicketResult,
	  (select LkUpNo, LkUpDesc from Lookups Where lkuptable = 'MARKET' AND LkUpFieldName = '01_TKTAMENDSTATUS' order by LkUpNo) LkUpAmendStatusDesc,
	  (select LkUpNo, LkUpDesc from Lookups Where lkuptable = 'MARKET' AND LkUpFieldName = '02_TKTSTOCKSTATUS' order by LkUpNo) LkUpTicketStatusDesc
	WHERE TicketResult.SIAmendmentStatus = LkUpAmendStatusDesc.LkUpNo
	AND   TicketResult.SITicketStatus    = LkUpTicketStatusDesc.LkUpNo;


	   /*select tktnt.tntTbkRecNo,
       tktnt.tntno,
	   tktnt.TntDlvOrdNo,
	   Nvl(DELHED.ISOPENFORMORE, 0) ISOPENFORMORE,
	   (Case TntDlvOrdNo When -1 Then 'Does Not Exist' else NVL(DelHed.DlvRelInv, 'NONE')  end) as DlvRelInv,
        --*****(A) Amendment Status*************
		(Case When (DELHED.DLVRELINV in ('Rel', 'Inv'))                             Then 3
		      When (TNTDLVORDNO = -1)                                               Then 3
			  When ((TNTDLVORDNO = 0)       AND (NVL(DELHED.ISOPENFORMORE, 0) < 2)) Then 1
		      When ((TNTDLVORDNO = 0)       AND (NVL(DELHED.ISOPENFORMORE, 0) = 2)) Then 3
			  When ((TNTDLVORDNO > 0) AND DELHED.DLVRELINV in ('', 'Dlv'))          Then 2
			  When (DELHED.DLVRELINV not in ('', 'Dlv'))                            Then 3
			  else                                                                      -1 --error
		      End ) SIAmendmentStatus,

		(Case When (DELHED.DLVRELINV in ('Rel', 'Inv'))                             Then 'No Changes Allowed'
		      When (TNTDLVORDNO = -1)                                               Then 'No Changes Allowed'
			  When ((TNTDLVORDNO = 0)       AND (NVL(DELHED.ISOPENFORMORE, 0) < 2)) Then 'All Changes Allowed'
		      When ((TNTDLVORDNO = 0)       AND (NVL(DELHED.ISOPENFORMORE, 0) = 2)) Then 'No Changes Allowed'
			  When ((TNTDLVORDNO > 0) AND DELHED.DLVRELINV in ('', 'Dlv'))          Then 'Price Changes Only'
			  When (DELHED.DLVRELINV not in ('', 'Dlv'))                            Then 'No Changes Allowed'
			  else                                                                       '(Error)' --error
		      End ) StrAmendmentStatus,

        --*****(B) Ticket Status*************
		(Case When (TNTDLVORDNO = -1)                                         Then 7
		      When (TNTDLVORDNO = 0)                                          Then 1
		      When Nvl(DELHED.ISOPENFORMORE, 0) > 1                           Then 6
		      When DELHED.DLVRELINV in ('') AND DELHED.ISOPENFORMORE >= 2     Then 2
			  When DELHED.DLVRELINV in ('Dlv')                                Then 3
			  When DELHED.DLVRELINV in ('Inv')                                Then 4
			  When DELHED.DLVRELINV in ('Rel')                                Then 5
			  else                                                                -1
		      End ) SITicketStatus,

		(Case When (TNTDLVORDNO = -1)                                         Then 'Order Cancelled'
		      When (TNTDLVORDNO = 0)                                          Then 'Order Not Processed Yet'
		      When Nvl(DELHED.ISOPENFORMORE, 0) > 1                           Then 'Order Completed'
		      When DELHED.DLVRELINV in ('') AND DELHED.ISOPENFORMORE >= 2     Then 'Stock Dissected'
			  When DELHED.DLVRELINV in ('Dlv')                                Then 'Stock Updated'
			  When DELHED.DLVRELINV in ('Inv')                                Then 'Order Invoiced'
			  When DELHED.DLVRELINV in ('Rel')                                Then 'Order Released'
			  else                                                                 '(Error)'
		      End ) StrTicketStatus
		From tktnt
		Left Outer Join DelHed on (tktnt.TNTDLVORDNO > 0  AND tktnt.TNTDLVORDNO = DelHed.DlvOrdNo)
		WHERE tktnt.tntTbkRecNo = TB
		AND   tktnt.tntno       = TN; */


		--version 1
		/*CURSOR V_DLVRELINV_CURSOR IS
	 	select NVL(DelHed.DlvRelInv, '') as DlvRelInv,
		 (Case DlvRelInv When NULL Then 'No Status!'
                 		 When 'Dlv' Then 'Order Delivered'
                 		 When 'Rel' Then 'Order Released'
                 		 When 'Inv' Then 'Order Invoiced'
				 		 When ''    Then 'Order Entered' --does not work hence else
				 		 else            'Order Ready'
				 		 end) as TicketStatus,
		 (Case DlvRelInv When ''    Then '0'
		                 When 'Dlv' Then '1'
		                 When 'Rel' Then '2'
		                 When 'Inv' Then '2'
						 else            '0'
						 end) as AmendmentStatusInd,
		 (Case DlvRelInv When ''    Then 'All'
		                 When 'Dlv' Then 'Price Only'
		                 When 'Rel' Then 'None Allowed'
		                 When 'Inv' Then 'None Allowed'
						 else            'All'
				 		 end) as AmendmentStatus
		From tktnt, DelHed
		Where tktnt.TNTDLVORDNO = DelHed.DlvOrdNo
		AND tktnt.tntno = TB;
*/


	 V_DLVRELINV_RECORD V_DLVRELINV_CURSOR%ROWTYPE;


  --EXCEPTION
	 --WHEN NO_DATA_FOUND THEN
	 --IF NO_DATA_FOUND THEN


  BEGIN

  	 /*IF V_DLVRELINV_RECORD = NULL THEN
	    EC := 1101;
        ED := 'Bad Ticket or Ticket Book Specified';
	 END IF;*/


     IF MI IS NULL THEN
        EC := 1102;
        ED := 'You must enter a machine name (MI)';
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT DEVNAME
             INTO VDEVNAME
             FROM DEVICENAME
            WHERE DEVACTIVE = 1
              AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    1103;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  1103;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

     IF EC = 0 THEN
		   If NOT V_DLVRELINV_CURSOR%ISOPEN
		   then
	       	  OPEN V_DLVRELINV_CURSOR;
		   END IF;

		   LOOP

	       FETCH V_DLVRELINV_CURSOR INTO V_DLVRELINV_RECORD;

	          EXIT WHEN V_DLVRELINV_CURSOR%NOTFOUND;

			  V_DLVRELINV_CNT := V_DLVRELINV_CNT + 1;
              IF V_DLVRELINV_CNT = 1 THEN
				        --HTP.P('{');
                --HTP.P('"TS": "'|| (V_DLVRELINV_RECORD.TktStatusDesc) || '",');   --String
                --HTP.P('"AS": '|| (V_DLVRELINV_RECORD.SiAmendmentStatus) || '');  --Integer (1,2,3)
                --HTP.P('}');
                
              --xxELSE
              --xx   HTP.P(',');
              
                HandleOPStr('{"TS": "'|| (V_DLVRELINV_RECORD.TktStatusDesc) || '",', ConCatResultVar);
                HandleOPStr('"AS": '|| (V_DLVRELINV_RECORD.SiAmendmentStatus) || '}', ConCatResultVar);
              END IF;


		   END LOOP;

	    CLOSE V_DLVRELINV_CURSOR;
	 END IF;

     IF V_DLVRELINV_CNT = 0 THEN
	      EC := 1101;
        ED := 'Bad Ticket or Ticket Book Specified (No Results)';
	 END IF;

     --This result set return only one row.  if there are multiple rows, the extremities of the JSON string must be formatted properly.
     /*IF V_ACCOUNTS_CNT > 0 THEN
        HTP.P(']');
        HTP.P('}');
     END IF;  */

     IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HTP.P('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }');
               
               HandleOPStr('{"EC": '|| EC || ',' || '"ED": "' || ED || '"}', ConCatResultVar);
     END IF;

     --Log the transaction
     HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' TB=' || TB || ' TN=' || TN , EC , ED, ConCatResultVar, '[PRE-LOGON]' ) ;


  END; --ACCOUNTS


--------------------------------------------------------------------------------
--  AD 20th Sep 12
--------------------------------------------------------------------------------

PROCEDURE AccountBalances(MI IN Varchar2,
		  				  SO IN Integer,
						  CL IN Integer,
						  UL IN VarChar2,
						  HT IN VarChar2,
              TB IN Varchar2 DEFAULT NULL,
              TN IN VarChar2 DEFAULT NULL
) AS
 -- Originally AD
 -- TV 7May14 added TB and TN so one ticket cash taken can be found
 -- NB this is not the amount paid on the ticket, merely the amount
 -- paid at the same time as the ticket.
  	 vMI VarChar2(255);
     EC INTEGER := 0 ; 	 			 -- ERROR CODE
	 ED VarChar2(255) := '';         -- Error Description
	 PROCNAME VARCHAR(40) := 'ACCOUNTBALANCES';

	 Valid	Boolean	  := True;
	 CountThis SmallInt := 0;
	 AccCredTermsSi SmallInt := 0;
	 AccBalInSideTerm Float := 0;
	 AccBalOutSideTerm Float := 0;
	 AccStopLo		   CHAR(5) := 'false';
	 vSO			   Integer;
	 vCL			   Integer;
	 vUL			   VarChar2(255);
	 vHT 	           VarChar2(255);
	 V_MD5PASSWORD1	 VarChar2(255);
	 v_PasswordToChk VarChar2(255);
	 vCreditBySOStr	 VarChar2(255);
	 vCreditBySO	 Boolean;
	 vDevRecNo		 DeviceName.DevRecNo%TYPE;
	 VSalOffNo		 SalOffNo.SalOffNo%TYPE;
	 vHANDHELDPASSWORD LOGONS.HANDHELDPASSWORD%TYPE;
	 ClaRecNoLi		 Number(10);
	 CreditLimitNu	 FLOAT ;
   ConCatResultVar 			VARCHAR(2000)  := '';

	CURSOR Account_Cur(vClaRecNo INTEGER)
	IS
	Select *
	FROM AccClass, Accounts
	      Where AccClass.ClaAccNo = Accounts.AccRecNo
	AND AccClass.ClaRecNo = vClaRecNo;

	vCustAccDet 		   Account_Cur%ROWTYPE;
  BEGIN


  	 IF MI is null then
	    EC := 801;
		ED := 'You must enter a machine name (MI)';
		Valid := False;
	 END IF;

	 If Valid then
        BEGIN
		   vMI := Upper(MI);

		   Select DevRecNo
		   INTO vDevRecNo
		   FROM DeviceName
           Where DEVActive = 1
           AND Upper(Rtrim(DevID)) = vMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
    	        EC := 802;
              ED := MI || ' is not a registered active device';
              Valid := False;

		   WHEN OTHERS THEN
  	   	      EC := 803;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
              Valid	:= False;
        END;
	 END IF;

	 IF Valid then
	 	IF SO is null then
    	    EC := 804;
          ED := 'You must provide a sales office No (SO)';
		      Valid := False;
		END IF;
	 END IF;

	 If Valid then
        Begin
		   vSO := SO;

		   Select SalOffNo.SalOffNo
		   INTO VSalOffNo
		   FROM SalOffNo
           Where SalOffNo.SalOffNo = vSO;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
			        EC := 805;
		          ED := MI || ' is not a a valid Sales Office';
				      Valid := False;

		   WHEN OTHERS THEN
		          EC := 806;
              ED := 'Unable to Execute Sql to Obtain Sales office for '|| SO || ' SqlErrM='||  SQLERRM;
			  Valid	:= False;
        END;
	 END IF;

	 IF Valid then
	 	IF CL is null then
		   EC := 807;
		   ED := 'You must provide a customer id number';
		   Valid := False;
		END IF;
	 END IF;

	 IF Valid THEN
		   vCL := CL;

		   BEGIN
		   		OPEN Account_Cur(vCL);


				FETCH Account_Cur INTO vCustAccDet;
				IF Account_Cur%NOTFOUND
				THEN
					RAISE NO_DATA_FOUND;
				END IF;

				CLOSE Account_Cur;

			EXCEPTION
            	WHEN NO_DATA_FOUND THEN
				     EC := 808;
		        	 ED := CL || ' is not a valid customer id number';
					 Valid := False;

		   		WHEN OTHERS THEN
				     EC := 809;
              		 ED := 'Unable to Execute Sql to Obtain customer code for '|| CL || ' SqlErrM='||  SQLERRM;
			  		 Valid	:= False;

		   END;
	 END IF;

	 IF Valid then
	 	IF UL is null then
		   EC := 810;
		   ED := 'Please provide user name';
		   Valid := False;
		END IF;
	 END IF;

	 If Valid then
		--changed TV 31Jan13 to collect the user password for the encryption hash total
        Begin
		   vUL := UL;

		   Select HANDHELDPASSWORD
		   INTO vHANDHELDPASSWORD
		   from logons
		   Where UPPER(Rtrim(LOGONNAME)) = UPPER(vUL)
		   AND AVAILTOMKTHANDHELD = 1;

        EXCEPTION
           WHEN NO_DATA_FOUND THEN
		        EC := 811;
		        ED := vUL || ' is not a valid user';
				Valid := False;

		   WHEN OTHERS THEN
		      EC := 812;
              ED := 'Unable to Execute Sql to Obtain user id for '|| UL || ' SqlErrM='||  SQLERRM;
			  Valid	:= False;
        END;
	 END IF;

	 IF Valid then
	 	IF HT is null then
		   EC := 813;
		   ED := 'Please provide a hash total value';
		   Valid := False;
		else
		   vHT := HT;
		END IF;
	 END IF;

	 if Valid then
	 	Begin
		     --changed TV 31Jan13 to encrypt encrypted password
			 v_PasswordToChk := rtrim(vHANDHELDPASSWORD) || rTrim(vCustAccDet.AccCode);

			 V_MD5PASSWORD1:= DBMS_CRYPTO.HASH (src => utl_i18n.string_to_raw(v_PasswordToChk), typ => DBMS_CRYPTO.hash_MD5 );

			 if V_MD5PASSWORD1 <> vHT then
			     EC := 814;
			 	 ED := 'Hash total does not equal encrypted password .' || V_MD5PASSWORD1 || '. .>>' || v_PasswordToChk || '<<';
				 Valid := False;
			 end if;
		End;
	 end if;


	 If Valid then
        BEGIN

	 	SELECT SYSPREFVALUE
		INTO vCreditBySOStr
  		FROM WizSysPref
  		WHERE UPPER(SysPrefName) = 'USECDTCNTRLSO';

		IF UPPER(Rtrim(vCreditBySOStr)) = 'TRUE' THEN
		   vCreditBySO := True;
		ELSE
		   vCreditBySO := False;
		END IF;

        EXCEPTION
           WHEN NO_DATA_FOUND THEN
		   		vCreditBySO := False ;
		   WHEN OTHERS THEN
		      EC := 815;
              ED := 'Unable to Execute Sql to Obtain user id for '|| UL || ' SqlErrM='||  SQLERRM;
			  Valid	:= False;
        END;

	 END IF;

	--Get hofcst, Get Credit Limt
	IF Valid THEN
	    IF vCustAccDet.AccHofRecNo is NOT NULL THEN

		   DECLARE
		   CURSOR Hof_Cursor
		   IS
		   SELECT AccClass.ClaRecNo, Hofcst.SALOFFNO, Accounts.ACCARCREDITLIMIT, Accounts.ACCARCREDITTERMS, AccClass.CLAACTIVE
		   FROM Hofcst, AccClass, Accounts
		   WHERE HofCst.HOFRECNO = vCustAccDet.AccHofRecNo
		   AND HofCst.CURRENCYCODE = vCustAccDet.CLACURRNO
		   AND HofCst.HOFINVTOCSTCODE = AccClass.CLARECNO
		   AND ACCCLASS.CLAACCNO = ACCOUNTS.ACCRECNO
		   AND (HofCst.SalOffNo = -32000 or HofCst.SalOffNo = vSO)
		   ORDER BY SalOffNo DESC;

		   HofCstRowTyp		 Hof_Cursor%ROWTYPE;

		   BEGIN

			   If NOT Hof_Cursor%ISOPEN
			   then
		       	  OPEN Hof_Cursor;
			   END IF;

		       FETCH Hof_Cursor INTO HofCstRowTyp;

			   IF Hof_Cursor%NOTFOUND
			   THEN
					RAISE NO_DATA_FOUND;
			   END IF;

			   ClaRecNoLi := HofCstRowTyp.ClaRecNo;
			   AccCredTermsSi := HofCstRowTyp.ACCARCREDITTERMS;

			   IF NOT vCreditBySO
			   THEN
			   	   CreditLimitNu := HofCstRowTyp.ACCARCREDITLIMIT;
			   END IF;

		       CLOSE Hof_Cursor;

			EXCEPTION

			WHEN NO_DATA_FOUND THEN
			    EC := 816;
		        ED := 'Cannot locate Head Office id for ' || vCustAccDet.ClaAccCode;
				Valid := False;


		   END;
		ELSE
			ClaRecNoLi := vCustAccDet.ClaRecNo;
			AccCredTermsSi := vCustAccDet.ACCARCREDITTERMS;

			IF NOT vCreditBySO
		    THEN
		   		CreditLimitNu := vCustAccDet.ACCARCREDITLIMIT;
		    END IF;
		END IF;
	END IF;

	IF Valid
	THEN
		IF vCreditBySO
		THEN
			SELECT SUM(ACSARCREDITLIMIT) ACSARCREDITLIMIT
			INTO CreditLimitNu
			FROM AccToSalOff
			WHERE  AccToSalOff.ACSCLARECNO = ClaRecNoLi
			AND AccToSalOff.ACSSALOFFNO = vSO;
		END IF;
	END IF;

	IF Valid
	THEN
    -- added TV 6Mar14 to return just the ticket unallocated cash if a ticket number is entered
    -- todo ???
   	   DECLARE
 
   	   CURSOR TICKETDEBT_CURSOR
		   IS
		      select 'Tkt Cash' as PSTDESC, TO_CHAR(ATRPSTDATE, 'YYYYMMDD') DOCDATE,
          TO_DATE(ATRPSTDATE, 'DD/MM/YYYY') REALDATE, 
          ATRREF INVREF1, ATRREF2 INVREF2, 
         acctrnfil.AtrBalance * (acctrnfil.AtrBaseAmount / acctrnfil.AtrAmount) as Balance,
          acctrnfil.AtrBalance * (acctrnfil.AtrBaseAmount / acctrnfil.AtrAmount) as PaidAmt 
          from cashtikalloc , cashtikpay,  acctrnfil
          where CashTikAlloc.cshticketno = TN
         and CashTikAlloc.CshTikAllocBatRec = CashTikPay.CshTikPayBatRecNo
          and CashTikPay.CshTikPayAtrRec = AccTrnFil.AtrRecNo 
		      and AccTrnFil.AtrStatInd = 100
		      and AccTrnFil.AtrBalance >0;     
       
 		   CURSOR DEBT_CURSOR
		   IS
		   SELECT 'UnInvoiced' PSTDESC, NULL DOCDATE, NULL REALDATE,NULL INVREF1,TO_CHAR(DLVORDNO) INVREF2,
					SUM(NVL(delprice.DelBaseNettVal, 0.0)) + SUM(NVL(delprice.DelBaseVatValue, 0.0)) Balance, 0 as PAIDAMNT
		    FROM DELPRICE delprice,
				DELDET deldet,
				DELHED delhed,
				ORDERS orders
		   WHERE delprice.DprDelRecNo = deldet.DelRecNo
			 AND deldet.DelDlvOrdNo = delhed.DlvOrdNo
			 AND delhed.DlvOrdRecNo = orders.OrdRecNo
			 AND NVL(delprice.delprice, 0.0) > 0
			 AND delhed.DlvTransShip IS NULL
			 AND delprice.DelInvRecNo IS NULL
			 AND NVL(delhed.DlvRelInv, 'Ent') <> 'Inv'
			 AND (EXISTS (SELECT *
					    FROM ACCCLASS, ACCOUNTS, HOFCST
						WHERE orders.OrdCstCode = accclass.ClaRecNo
						AND ACCCLASS.CLAACCNO = ACCOUNTS.ACCRECNO
						AND ACCOUNTS.ACCHOFRECNO = HOFCST.HOFRECNO
						AND HOFCST.HOFINVTOCSTCODE = ClaRecNoLi) or orders.OrdCstCode = ClaRecNoLi)
			 AND DLVSALOFFNO = vSO
		  GROUP BY DLVORDNO
		  UNION
		  SELECT  PSTDESC, TO_CHAR(ATRPSTDATE, 'YYYYMMDD') DOCDATE,  TO_DATE(ATRPSTDATE, 'DD/MM/YYYY') REALDATE, ATRREF INVREF1,ATRREF2 INVREF2,
		  SUM (NVL(CASE WHEN posttype.DbtCdtNo = 2
							  THEN acctrnfil.AtrBalance * (acctrnfil.AtrBaseAmount / acctrnfil.AtrAmount) * -1
							  ELSE acctrnfil.AtrBalance * (acctrnfil.AtrBaseAmount / acctrnfil.AtrAmount)
							  END, 0.0)) Balance,
							  SUM(CASE WHEN posttype.DbtCdtNo = 2
							  		   THEN NVL(ATRAMOUNT,0) * -1
									   ELSE NVL(ATRAMOUNT,0) END)
							  - SUM (NVL(CASE WHEN posttype.DbtCdtNo = 2
							  THEN acctrnfil.AtrBalance * (acctrnfil.AtrBaseAmount / acctrnfil.AtrAmount) * -1
							  ELSE acctrnfil.AtrBalance * (acctrnfil.AtrBaseAmount / acctrnfil.AtrAmount)
							  END, 0.0)) PAIDAMNT
		  FROM ACCTRNFIL acctrnfil,
				ACCCLASS accclass,
				ACCOUNTS accounts,
				POSTTYPE posttype
		  WHERE  acctrnfil.AtrClaRecNo = accclass.ClaRecNo
			AND accclass.ClaAccCode = accounts.AccCode
			AND acctrnfil.AtrPstTyp = posttype.PstRecNo
			AND acctrnfil.AtrDbType = 1
			AND ABS(acctrnfil.AtrBalance) > 0.001
			AND ABS(acctrnfil.AtrAmount) > 0.001
			AND acctrnfil.AtrStatInd = 100
			AND accclass.ClaRecNo = ClaRecNoLi
		   AND ATRSALOFFNO = vSO
		   GROUP BY PSTDESC, ATRPSTDATE , ATRREF ,ATRREF2;
    
    vDEBTBALANCES DEBT_CURSOR%ROWTYPE;

		BEGIN
			 --HTP.P('{');
		   --HTP.P('"DOCUMENTS": [');
         
       HandleOPStr('{"DOCUMENTS": [', ConCatResultVar);

       IF TN IS NULL THEN
          IF NOT DEBT_CURSOR%ISOPEN THEN
             OPEN DEBT_CURSOR ;
          END IF;
       ELSE
          IF NOT TICKETDEBT_CURSOR%ISOPEN THEN
             OPEN TICKETDEBT_CURSOR ;
          END IF;
       END IF;

			 LOOP

         IF TN is null
         then
  	        FETCH DEBT_CURSOR INTO vDEBTBALANCES;
            EXIT WHEN DEBT_CURSOR%NOTFOUND;
         else
            FETCH TICKETDEBT_CURSOR INTO vDEBTBALANCES;
            EXIT WHEN TICKETDEBT_CURSOR%NOTFOUND;
         end if;
       
				 IF COUNTTHIS <> 0
				 THEN
				  	 --HTP.P(',');
             HandleOPStr(',', ConCatResultVar);
				 END IF;

				 /*HTP.P('{');
				 HTP.P('"DT": "'|| RTrim(vDEBTBALANCES.PSTDESC)|| '",');
				 HTP.P('"DD": "'|| RTrim(vDEBTBALANCES.DOCDATE)|| '",');
				 HTP.P('"D1": "'|| RTrim(vDEBTBALANCES.INVREF1)|| '",');
				 HTP.P('"D2": "'|| RTrim(vDEBTBALANCES.INVREF2)|| '",');
				 HTP.P('"DA": ' || vDEBTBALANCES.Balance|| ',');
				 HTP.P('"DP": ' || vDEBTBALANCES.PAIDAMNT|| '');
				 HTP.P('}');*/
         
         HandleOPStr('{"DT": "'|| RTrim(vDEBTBALANCES.PSTDESC)|| '",', ConCatResultVar);
         HandleOPStr('"DD": "'|| RTrim(vDEBTBALANCES.DOCDATE)|| '",', ConCatResultVar);
         HandleOPStr('"D1": "'|| RTrim(vDEBTBALANCES.INVREF1)|| '",', ConCatResultVar);
         HandleOPStr('"D2": "'|| RTrim(vDEBTBALANCES.INVREF2)|| '",', ConCatResultVar);
         HandleOPStr('"DA": ' || vDEBTBALANCES.Balance|| ',', ConCatResultVar);
         HandleOPStr('"DP": ' || vDEBTBALANCES.PAIDAMNT|| '}', ConCatResultVar);

		  		 COUNTTHIS := COUNTTHIS + 1;

				IF vDEBTBALANCES.REALDATE IS NOT NULL
				THEN
					 IF (vDEBTBALANCES.REALDATE + AccCredTermsSi + 1) > SYSDATE()
					 THEN
					 	 AccBalOutSideTerm := AccBalOutSideTerm + vDEBTBALANCES.Balance;
					 ELSE
					 	 AccBalInSideTerm := AccBalInSideTerm + vDEBTBALANCES.Balance;
				 	 END IF;
				ELSE
					AccBalInSideTerm := AccBalInSideTerm + vDEBTBALANCES.Balance;
				END IF;

			 END LOOP;

       IF TN is null
       then
          CLOSE DEBT_CURSOR;
       else
          CLOSE TICKETDEBT_CURSOR;
       end if;
		 

			 IF CreditLimitNu <= AccBalOutSideTerm
			 THEN
			 	 AccStopLo := 'true';
			 END IF;

			 --HTP.P('],');
       HandleOPStr('],', ConCatResultVar);

			 if CreditLimitNu is null
			 then
			    --HTP.P('"AC": null,');
          HandleOPStr('"AC": null,', ConCatResultVar);
			 else
			    --HTP.P('"AC": '|| CreditLimitNu|| ',');
          HandleOPStr('"AC": '|| CreditLimitNu|| ',', ConCatResultVar);
			 end if;

			/*HTP.P('"AT": '|| AccBalInSideTerm|| ',');
			 HTP.P('"AO": '|| AccBalOutSideTerm|| ',');
			 HTP.P('"TE": "'|| AccCredTermsSi || ' day",');
			 HTP.P('"AS": '|| AccStopLo|| '');
			 HTP.P('}');*/
       
       HandleOPStr('"AT": '|| AccBalInSideTerm|| ',', ConCatResultVar);
       HandleOPStr('"AO": '|| AccBalOutSideTerm|| ',', ConCatResultVar);
       HandleOPStr('"TE": "'|| AccCredTermsSi || ' day",', ConCatResultVar);
       HandleOPStr('"AS": '|| AccStopLo|| '}', ConCatResultVar);

		END;

	END IF;

	IF NOT Valid
	THEN
       --  HTP.P('{
       --     "EC": '|| EC || ',
       --     "ED": "'|| ED ||'"
        --       }');
               
         HandleOPStr('{"EC": '|| EC ||',"ED": "'|| ED || '}', ConCatResultVar);      
	END IF;

    --Log the transaction	.
    --HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' SO=' || SO || ' CL=' || CL || ' UL=' || UL || ' HT=' || HT , EC , ED ) ;
    
    HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' SO=' || SO || ' CL=' || CL || ' UL=' || UL || ' HT=' || HT , EC , ED, ConCatResultVar, UL ) ;

--Rtrim(V_LogOnName)
  END;


--------------------------------------------------------------------------------
--  BMK 20th Sep 12 TICKETBOOK
--------------------------------------------------------------------------------
PROCEDURE  TICKETBOOK (MI IN VARCHAR2 DEFAULT NULL, TB IN INTEGER) IS

     --V1.0 BMK 18Sept12
     -- TICKET BOOK FUNCTION, CALLED WHENEVER ?? TO GET LIST AVAILABLE TICKETBOOKS AND TICKET NUMBERS

     --  Downloads any available  ticket books for the valid Machine ID that has been sent

     EC INTEGER := 0 ; -- ERROR CODE
     ED VARCHAR2(255) := ''; -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'TICKETBOOK';


     VMI DEVICENAME.DEVID%TYPE;
     V_DEVRECNO DEVICENAME.DEVRECNO%TYPE := ''; -- DEVICE NAME FROM QUERY

     V_TKTBK_CNT         NUMBER(5) := 0;
     V_DEVRECNO_STR      NUMBER(5) := 0;

     TYPE V_LIST_OF_DEV IS TABLE OF DEVICENAME.DEVRECNO%TYPE
        INDEX BY PLS_INTEGER;
     DEVICELIST  V_LIST_OF_DEV;
     l_DEVICEROW PLS_INTEGER;
     
     ConCatResultVar 			VARCHAR(2000)  := '';

     -- TICKET BOOKS
     -- this cursor return the lowest availaule ticket number and then the number of available tickets available after that
     -- if a ticket has been used somewhere in the middle of this ticket book then only numbers above that will be avaiable

     CURSOR V_TKTBK_CURSOR(IN_DEVRECNO NUMBER) IS
        (SELECT  TBKRECNO,
            (SELECT  MIN(TNTNO) FROM TKTNT WHERE TNTTBKRECNO = TKTBK.TBKRECNO AND NOT EXISTS ( SELECT 1 FROM TKTNT CHK_TKTNT WHERE CHK_TKTNT.TNTTBKRECNO = TKTNT.TNTTBKRECNO AND CHK_TKTNT.TNTDLVORDNO <> 0 AND   TKTNT.TNTNO < CHK_TKTNT.TNTNO) AND TNTDLVORDNO = 0) FST_TNTNO,
            (SELECT  COUNT(*)   FROM TKTNT WHERE TNTTBKRECNO = TKTBK.TBKRECNO AND NOT EXISTS ( SELECT 1 FROM TKTNT CHK_TKTNT WHERE CHK_TKTNT.TNTTBKRECNO = TKTNT.TNTTBKRECNO AND CHK_TKTNT.TNTDLVORDNO <> 0 AND   TKTNT.TNTNO < CHK_TKTNT.TNTNO) AND TNTDLVORDNO = 0) CNT_TNTNO
        FROM TKTBK
        WHERE TBKSMNNO = IN_DEVRECNO
        AND TBKUSEDFOR  = 2      -- MOBILE
        AND TBKCOMPLETE = 0      -- STILL OPEN
        AND AVAILTOSEND = 1) ;    -- AVAILABLE TO SEND ;


  BEGIN

     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     IF MI IS NULL THEN
        EC := 100;
        ED := 'You must enter a machine name (MI)';
     END IF;

     -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     -- & GET THE DEVICE NUMBER
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT  DEVRECNO
           INTO V_DEVRECNO
           FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

     -- GET A LIST OF THE ACTIVE TICKET BOOKS FOR THIS DEVICE
     IF EC = 0 THEN
        FOR V_TKTBK_RECORD IN V_TKTBK_CURSOR(V_DEVRECNO)  LOOP
            IF NVL(V_TKTBK_RECORD.CNT_TNTNO,0) > 0 THEN
            BEGIN
                V_TKTBK_CNT := V_TKTBK_CNT + 1;

                IF V_TKTBK_CNT = 1 THEN
                   --HTP.P('{');
                   --HTP.P('"TKTBOOK": [');
                   
                   HandleOPStr('{"TKTBOOK": [', ConCatResultVar);
                ELSE
                   --HTP.P(',');
                   HandleOPStr(',', ConCatResultVar);
                END IF;
                --HTP.P('{');
                --HTP.P('"NT": '|| (V_TKTBK_RECORD.TBKRECNO) || ',');
                --HTP.P('"TF": '|| (V_TKTBK_RECORD.FST_TNTNO) || ',');
                --HTP.P('"TL": '|| (V_TKTBK_RECORD.CNT_TNTNO) ||'');
                --HTP.P('}');
                
                HandleOPStr('{', ConCatResultVar);
                HandleOPStr('"NT": '|| (V_TKTBK_RECORD.TBKRECNO) || ',', ConCatResultVar);
                HandleOPStr('"TF": '|| (V_TKTBK_RECORD.FST_TNTNO) || ',', ConCatResultVar);
                HandleOPStr('"TL": '|| (V_TKTBK_RECORD.CNT_TNTNO) ||'}', ConCatResultVar);                

                DEVICELIST(V_TKTBK_RECORD.TBKRECNO) :=V_TKTBK_RECORD.TBKRECNO;

            END;
            END IF;

        END LOOP;
     END IF;

     IF V_TKTBK_CNT > 0 THEN
        --HTP.P(']');
        --HTP.P('}');
        
        HandleOPStr(']}', ConCatResultVar); 
     END IF;

	 IF V_TKTBK_CNT = 0 THEN
        EC := 111;
        ED := 'No ticket book numbers to download for this device';
     END IF;

     IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
        -- HTP.P('{
        --    "EC": '|| EC || ',
        --    "ED": "'|| ED ||'"
        --       }');
               
        HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);        
    ELSE

        BEGIN
            l_DEVICEROW :=  DEVICELIST.FIRST;

            WHILE  (l_DEVICEROW IS NOT NULL) AND EC =  0
            LOOP
                BEGIN
                    UPDATE TKTBK SET AVAILTOSEND = 0 WHERE TBKRECNO = DEVICELIST(l_DEVICEROW);
                    COMMIT;

                EXCEPTION
                    WHEN OTHERS THEN
                        EC :=  110;
                        ED := 'Unable to Execute Sql to Update TKTBK.AVAILTOSEND for '|| MI || ' SqlErrM='||  SQLERRM;

                END;
		l_DEVICEROW := DEVICELIST.NEXT(l_DEVICEROW);
           END LOOP;
       END;

     END IF;

     --Log the transaction	.
     HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' TB=' || TB , EC , ED, ConCatResultVar, '[N/A]' ) ;


  END; --TICKETBOOK

--------------------------------------------------------------------------------
--  BMK 20th Sep 12  DEBUG and Testing Only
--------------------------------------------------------------------------------

PROCEDURE  RESET_TICKETBOOK  IS

     --V1.0 BMK 18Sept12
     
     --Why do we need this?
     --initially all the tickets are sent to the device and avaltosend becomes 0.
     --then a new version of the app becomes available, when installed it trashes the existing data and starts again.
     --when live running on a stable version, this proc must be renamed.

     EC INTEGER := 0 ; -- ERROR CODE
     ED VARCHAR2(255) := ''; -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'RESET_TICKETBOOK';



  BEGIN

                BEGIN
                    UPDATE TKTBK SET AVAILTOSEND = 1 WHERE AVAILTOSEND  =0;
                    COMMIT;

                EXCEPTION
                    WHEN OTHERS THEN
                        EC :=  110;
                        ED := 'Unable to Execute Sql to RESET_TICKETBOOK for SqlErrM='||  SQLERRM;

                END;

       --Log the transaction	.
       HANDHELDLOG ('<UNKNOWN>', PROCNAME, '<NONE>' , EC , ED, '(No Result)', '[N/A]' ) ;


  END; --RESET_TICKETBOOK 
  
  
--------------------------------------------------------------------------------
--  RESET_MY_TICKETBOOK  Can be left for live running
--------------------------------------------------------------------------------
  
		
  PROCEDURE RESET_MY_TICKETBOOK (MI IN VARCHAR2 DEFAULT NULL) IS

     --TV 21Oct13 Taken from 1.0 BMK 18Sept12

     --Why do we need this?
     --initially all the tickets are sent to the device and avaltosend becomes 0.
     --then a new version of the app becomes available, when installed it trashes the existing data and starts again.
     --This version is changed to be a little more friendy to the system, You can only request one device at a time
	 --and it will only reset ticketbooks where the last ticket is still unallocated.  

     EC INTEGER := 0 ; -- ERROR CODE
     ED VARCHAR2(255) := 'Success'; -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'RESET_MY_TICKETBOOK';
	 vMI DeviceName.DevID%TYPE;	   
	 vDEVRECNO VARCHAR2(255);	
     ConCatResultVar 			VARCHAR(2000)  := '';
 


  BEGIN			  
  	 --Check that the MI Machine code is correct
	 
     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.
     IF MI IS NULL THEN
        EC := 100;
        ED := 'You must enter a machine name (MI)';
     END IF;

     -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     -- & GET THE DEVICE NUMBER
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(TRIM(MI));

           SELECT  DEVRECNO
		   INTO VDEVRECNO
           FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;
  
  
	 IF EC = 0 THEN
	    BEGIN
	  	   Update TKTBK
           Set AvailToSend = 1
           Where TBKRECNO in 
		   (  Select TktBk.TBKRECNO
              from TKTBK, DEVICENAME, TKTNT
              Where TKTBK.TbkUsedFor = 2 
              AND TKTBK.TbkComplete = 0  
              AND TKTBK.AvailToSend = 0  
              AND DEVICENAME.DEVRECNO = TKTBK.TBKSMNNO  
              AND TKTNT.TNTTBKRECNO = TKTBK.TBKRECNO 
              AND TKTNT.TNTNO = TKTBK.TBKENDNO 
			  AND TKTNT.TNTDLVORDNO = 0 
			  AND DeviceName.DEVID = vMI);
					
           COMMIT;

        EXCEPTION 
  	       WHEN NO_DATA_FOUND THEN
              EC :=    111;
              ED := MI || 'No Tickets to reset.';			
				
           WHEN OTHERS THEN
              EC :=  110;
              ED := 'Unable to Execute Sql to RESET_MY_TICKETBOOK for SqlErrM='||  SQLERRM;
       END;
	END IF;
    				 
				
	-- ERROR MESSAGE RETURNED
    HandleOPStr('{
               "EC": '|| EC || ',
               "ED": "'|| ED ||'"
                 }', ConCatResultVar);

    
	--Log the transaction	.
    HANDHELDLOG (MI, PROCNAME, '?MI='|| MI , EC , ED, ConCatResultVar, '[N/A]' ) ;


  END; --RESET_MY_TICKETBOOK 
    
  
--------------------------------------------------------------------------------
--  BMK 20th Sep 12
--------------------------------------------------------------------------------
PROCEDURE STOCK_LEVELS (MI IN VARCHAR2 DEFAULT NULL,        -- Machine ID
                        UL IN VARCHAR2 DEFAULT NULL,        -- User Logon
                        SO IN INTEGER  DEFAULT 0,           -- Sales Office
                        SL IN INTEGER  DEFAULT 0,           -- Stock Location
                        PR IN INTEGER  DEFAULT 0,           -- Product Internal Code
                        DE IN INTEGER  DEFAULT 0,           -- Department Code
                        HT IN VARCHAR2 DEFAULT NULL)        -- Hash Total   IS
                        IS

     --V1.0 BMK 19Sept12
     -- GET LIST OF STOCK LEVELS AVAILABLE
 	   -- removed hard coded user and changed to include new debugging routines TV 17Jul13
     -- Added Suggested selling prices (PB,PK,PI and PE) TV 25Jul13
	 --TV Added code to prevent blanks being sent instead of zeros

     EC INTEGER := 0 ; -- ERROR CODE
     ED VARCHAR2(255) := ''; -- ERROR DESCRIPTION
	   PROCNAME VARCHAR(40) := 'STOCK_LEVELS';
     ConCatResultVar 			VARCHAR(5000)  := '';


     VMI DEVICENAME.DEVID%TYPE;
     VDEVNAME DEVICENAME.DEVNAME%TYPE  ; -- DEVICE NAME FROM QUERY
     V_LOGONNO LOGONS.LOGONNO%TYPE;

     V_SALOFFNO SALOFFNO.SALOFFNO%TYPE  := -1;
     V_STCRECNO STOCLOC.STCRECNO%TYPE   := -1 ;
     V_PRCPRDNO PRDREC.PRCPRDNO%TYPE    := -1 ;
     V_DPTNO DEPARTMENTS.DPTRECNO%TYPE  := -1 ;


     V_NOOF NUMBER(5) ;
     V_use_sales_office Number(1) := 0 ;   -- THIS WILL BE ZERO IF THE SYSTEM IS NOT USING SALES OFFICES
     V_user_can_see_all_supp LOGONS.CANSEEALLSUPS%TYPE := 0 ;   -- THIS WILL BE ZERO IF THE USER IS NOT ALLOWED TO VIEW ALL SUPPLIERS REGARDLESS OF

     V_Allocate_req         NUMBER(1) := 1 ;
     V_STK_CNT              NUMBER(5) := 0;
     V_SO_CNT               NUMBER(5) := 0;

     GUIDEPRICEBOX   FLOAT := 0.00;
     GUIDEPRICEKILO  FLOAT := 0.00;
     GUIDEPRICEINNER FLOAT := 0.00;
     GUIDEPRICEEACH  FLOAT := 0.00;

-- STOCK DETAILS
     CURSOR V_STOCK_CURSOR (IN_STCLOC NUMBER) IS
    SELECT
    ALLOCATE.ALLOCPRDNO PR,
    ALLOCATE.ALLOCNO AN,
    ALLOCATE.ALLOCSENCODE CL,
    (SELECT LOTITE.LITRCVDATE FROM LOTITE WHERE LITITENO = ALLOCATE.ALLOCLITITENO) PD, --.    PURCHASE DATE
    (CASE WHEN NVL(ALLOCISPREPPACK, 0)  = 1 THEN 'WO'||ALLOCPONO ELSE 'PO'||ALLOCPONO END) PO,
    (SELECT LOTITE.LITID FROM LOTITE WHERE LITITENO = ALLOCATE.ALLOCLITITENO) LN, -- LOT NUMBER
    (SELECT LOTITE.LITID2 FROM LOTITE WHERE LITITENO = ALLOCATE.ALLOCLITITENO) LD,
    -- Guide Price - by LitPerByTyp
    (SELECT NVL(LOTITE.LITGUIDEPRICE,0) FROM LOTITE WHERE LITITENO = ALLOCATE.ALLOCLITITENO) GUIDEPRICE,
    (SELECT NVL(LOTITE.LITPURBYTYP,1) FROM LOTITE WHERE LITITENO = ALLOCATE.ALLOCLITITENO) PURBYTYP,
    NVL (PRDREC.PRCWEIGHT,1) PRCWEIGHT, NVL(PRDREC.INNERQTY,1) INNERQTY, NVL(PRDREC.PRCBOXQTY,1)PRCBOXQTY,
        -- box  added nvl TV 7Aug13
    nvl(ALLOCEXP,0) EB,  nvl(ALLOCQTY,0) RB, nvl(ALLOCALLOC,0) AB,
    -- kilos added nvl TV 7Aug13
    nvl((ALLOCEXP *     FLOOR(PRDREC.PRCWEIGHT)),0) EK,
    nvl((ALLOCQTY *     FLOOR(PRDREC.PRCWEIGHT)),0) RK,
    nvl((ALLOCALLOC *   FLOOR(PRDREC.PRCWEIGHT)),0) AK,
    -- inners added nvl TV 7Aug13
    nvl((ALLOCEXP *     (PRDREC.INNERQTY)),0) EI,
    nvl((ALLOCQTY *     (PRDREC.INNERQTY)),0) RI,
    nvl((ALLOCALLOC *   (PRDREC.INNERQTY)),0) AI,
    -- each TV 25Jul WAS INNERQTY, same as inners added nvl TV 7Aug13
    nvl((ALLOCEXP *     (PRDREC.PRCBOXQTY)),0) EE,
    nvl((ALLOCQTY *     (PRDREC.PRCBOXQTY)),0) RE,
    nvl((ALLOCALLOC *   (PRDREC.PRCBOXQTY)),0) AE,
    ALLOCCOLCODE QC,
    (SELECT QCNARRATIVE FROM PALQCNAR WHERE QCNARRECNO = ALLOCATE.ALLOCQCCLASS) NA,
    ALLOCATE.ALLOCDPTRECNO DE,
    ALLOCATE.ALLOCSALOFFNO
    FROM ALLOCATE, PRDREC
    WHERE ALLOCATE.ALLOCPRDNO =  PRDREC.PRCPRDNO
    AND ALLOCATE.ALLOCSTCLOC = IN_STCLOC ;

-- LIST OF SALES OFFICES ALLOWED FOR THIS LOCATION
     CURSOR V_STK_ALLOWEDSO_CURSOR (IN_STCLOC NUMBER) IS
        SELECT DISTINCT SOFTOSTCLOC.SALOFFNO SALOFFNO FROM SOFTOSTCLOC WHERE SOFTOSTCLOC.STCLOC =  IN_STCLOC AND NVL(SOFTOSTCLOC.CANSELL, 0) = 1;

-- LIST OF SALES OFFICES ALLOWED FOR THIS LOCATION & SUPPLIER
    CURSOR V_STKSUPP_ALLOWEDSO_CURSOR (IN_STCLOC NUMBER, IN_CLARECNO NUMBER) IS
        SELECT DISTINCT SOFTOSTCLOC.SALOFFNO SALOFFNO FROM SOFTOSTCLOC WHERE SOFTOSTCLOC.STCLOC =  IN_STCLOC AND NVL(SOFTOSTCLOC.CANSELL, 0) = 1
        UNION
        SELECT DISTINCT ACCTOSALOFF.ACSSALOFFNO SALOFFNO FROM ACCTOSALOFF WHERE ACSCLARECNO = IN_CLARECNO AND NVL(ACCTOSALOFF.ACSCANNOTVIEW, 0) <> 1;

	  V_STOCK_RECORD  V_STOCK_CURSOR%ROWTYPE;

  BEGIN


    IF EC = 0 THEN
        BEGIN
           SELECT COUNT(*) INTO V_use_sales_office  FROM WIZSYSPREF where sysprefname = 'USESALESOFFICE' AND UPPER(TRIM(SYSPREFVALUE)) = 'TRUE';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;



     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     IF EC = 0 THEN
         IF MI IS NULL THEN
            EC := 100;
            ED := 'You must enter a machine name (MI)';
         END IF;
     END IF;

     -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT  DEVNAME
           INTO VDEVNAME
           FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

  -- CHECK THE DATABASE to see if USER EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        IF UL IS NULL THEN
            EC := 401;
            ED := 'You must enter a user logon name (UL)';
        END IF;
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if LOGONS EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
            SELECT LOGONNO, CANSEEALLSUPS INTO V_LOGONNO, V_user_can_see_all_supp
            FROM LOGONS
            WHERE TRIM(LOGONNAME) = UPPER(UL)
            AND AVAILTOMKTHANDHELD = 1
            AND ACTIVE = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    402;
                ED := UL || ' is not a registered active logon';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain LOGONS information for '|| UL || ' SqlErrM='||  SQLERRM;
        END;
     END IF;


  -- CHECK THE DATABASE to see if SALESOFFICE EXISTS AND IS ALLOWED FOR THIS USER
  -- TV 17Jul13 Taken out hard coded user 39!

     IF EC = 0 THEN
        V_SALOFFNO := -1;
        IF SO > 0 THEN
            BEGIN
                SELECT COUNT(*) INTO V_NOOF FROM SALOFFNO
                WHERE SALOFFNO = SO
                AND (EXISTS (SELECT * FROM LOGTOSALOFF WHERE LOGTOSALOFF.SALOFFNO = -32000 AND LOGONNO = V_LOGONNO)
                     OR  EXISTS (SELECT * FROM LOGTOSALOFF WHERE LOGTOSALOFF.SALOFFNO =saloffno.saloffno AND LOGONNO = V_LOGONNO));

                IF V_NOOF <> 1 THEN
                    EC :=    403;
                    ED := SO || ' is not a valid Sales Office';
                ELSE
                    V_SALOFFNO := SO;
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=    403;
                    ED := SO || ' is not a valid Sales Office';

                WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to valid Sales Office information for '|| SO || ' SqlErrM='||  SQLERRM;

            END;
        END IF;
     END IF;

      -- CHECK THE DATABASE to see if USER EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        IF NVL(SL, 0) <= 0 THEN
            EC := 404;
            ED := 'You must enter a valid Stock Location (SL)';
        ELSE
            V_STCRECNO := SL;
        END IF;
     END IF;

-- CHECK THE DATABASE to see if STOCK LOCATION EXISTS
     IF EC = 0 THEN
        V_NOOF := 0;
            BEGIN
                SELECT COUNT(*) INTO V_NOOF FROM STOCLOC
                WHERE STCRECNO = V_STCRECNO ;

                IF V_NOOF <> 1 THEN
                    EC :=    404;
                    ED := V_STCRECNO || ' is not a valid Stock Location';
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=    404;
                    ED := V_STCRECNO || ' is not a valid Stock Location';

                WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to valid Stock Location information for '|| V_STCRECNO || ' SqlErrM='||  SQLERRM;


        END;
    END IF;


-- CHECK THE DATABASE to see if PRDREC EXISTS
     IF EC = 0 THEN
        V_PRCPRDNO := -1;
        V_NOOF := 0;
        IF PR > 0 THEN
            BEGIN
                SELECT COUNT(*) INTO V_NOOF FROM PRDREC
                WHERE PRCPRDNO = PR ;

                IF V_NOOF <> 1 THEN
                    EC :=    405;
                    ED := PR || ' is not a valid Product';
                ELSE
                    V_PRCPRDNO := PR;
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=    405;
                    ED := PR || ' is not a valid Product';

                WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to valid Product information for '|| PR || ' SqlErrM='||  SQLERRM;

            END;
        END IF;
    END IF;


-- CHECK THE DATABASE to see if DEPARTMENT EXISTS
     IF EC = 0 THEN
        V_DPTNO := -1;
        V_NOOF := 0;
        IF DE > 0 THEN
            BEGIN
                SELECT COUNT(*) INTO V_NOOF FROM DEPARTMENTS
                WHERE DPTRECNO = DE ;

                IF V_NOOF <> 1 THEN
                    EC :=    405;
                    ED := DE || ' is not a valid Department';
                ELSE
                    V_DPTNO := DE;
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=    405;
                    ED := DE || ' is not a valid Department';

                WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to valid Department for '|| DE || ' SqlErrM='||  SQLERRM;

            END;
        END IF;
    END IF;


-- GET THE STOCK DETAILS
     IF EC = 0 THEN
        FOR V_STOCK_RECORD IN V_STOCK_CURSOR(V_STCRECNO)  LOOP  -- GET ALL THE STOCK IN THE SYSTEM
            BEGIN
                V_Allocate_req := 1;

                 -- IF A PRODUCT VALUE HAS BEEN PASSSED IN THEN CHECK THIS AGAINST THE ALLOCATE LINE
                IF V_Allocate_req = 1 THEN
                    IF V_PRCPRDNO > 0 THEN
                        IF NVL(V_STOCK_RECORD.PR,0) <> V_PRCPRDNO THEN
                            V_Allocate_req := 0;
                        END IF;
                    END IF;
                END IF;
                 -- IF A DEPARTMENT VALUE HAS BEEN PASSSED IN THEN CHECK THIS AGAINST THE ALLOCATE LINE
                IF V_Allocate_req = 1 THEN
                    IF V_DPTNO > 0 THEN
                        IF NVL(V_STOCK_RECORD.DE,0) <> V_DPTNO THEN
                            V_Allocate_req := 0;
                        END IF;
                    END IF;
                END IF;

                 -- IF THE SYSTEM IS USING SALES OFFICES, IS A SALES OFFICE VALUE HAS BEEN PASSSED IN AND IF THE ALLOCATE HAS A POPULATED SALES OFFICE
                 -- THEN CHECK THE ONE PASSED IN IS ALLOWED TO SEE THIS ALLOCATE  LINE
                IF V_Allocate_req = 1 THEN
                    IF V_SALOFFNO > 0 AND V_use_sales_office  = 0 THEN
                        IF NVL(V_STOCK_RECORD.ALLOCSALOFFNO,0) > 0 THEN
                            IF NVL(V_STOCK_RECORD.ALLOCSALOFFNO,0) <> V_SALOFFNO THEN
                                V_Allocate_req := 0;
                            END IF;
                        END IF;
                    END IF;
                END IF;

                -- THE SYSTEM IS USING SALES OFFICES, A SALES OFFICE VALUE HAS BEEN PASSSED IN AND THE ALLOCATE HAS NOT A POPULATED SALES OFFICE
                 -- SO WE NEED TO CHECK THE LOCATION AND SUPPLIER
                IF V_Allocate_req = 1 THEN
                    IF V_SALOFFNO > 0
                    AND V_use_sales_office  = 1 THEN -- IF THE SYSTEM IS USING SALES OFFICES THEN CHECK THE ONE PASSED IN IS ALLOWED TO SEE THIS LINE
                    BEGIN
                        IF V_user_can_see_all_supp = 1
                        OR NVL(V_STOCK_RECORD.CL, 0) = 0 THEN
                            -- WE DO NOT NEED TO CHECK THE  ACCTOSALOFF AS THE USER IS ALLOWED TO SEE ALL SUPPLIERS OR THE SUPPLIER IS BLANK
                            V_Allocate_req := 0;
                            BEGIN
                                FOR V_ALLOWEDSO_RECORD IN V_STK_ALLOWEDSO_CURSOR(V_STCRECNO)  LOOP  -- GET ALL THE STOCK IN THE SYSTEM
                                    BEGIN
                                        IF  V_ALLOWEDSO_RECORD.SALOFFNO =   V_SALOFFNO THEN
                                            V_Allocate_req := 1;
                                        END IF;
                                    END;
                                END LOOP;
                            END;
                        ELSE
                            --  THE USER IS NOT ALLOWED TO SEE ALL SUPPLIERS SO WE NEED TO CHECK THE ACCTOSALOFF TABLE & THE
                            --  THE ALLOCATE RECORD HAS A SUPPLIER AND SO WE NEED TO CHECK THE ACCTOSALOFF TABLE & THE SOFTOSTCLOC TABLE
                            V_Allocate_req := 0;
                            BEGIN
                                FOR V_ALLOWEDSO_RECORD IN V_STKSUPP_ALLOWEDSO_CURSOR(V_STCRECNO, V_STOCK_RECORD.CL)  LOOP  -- GET ALL THE STOCK IN THE SYSTEM
                                    BEGIN
                                        IF  V_ALLOWEDSO_RECORD.SALOFFNO =   V_SALOFFNO THEN
                                            V_Allocate_req := 1;
                                        END IF;
                                    END;
                                END LOOP;
                            END;
                        END IF;
                    END;
                    END IF;
                END IF;

                IF V_Allocate_req = 1 THEN
                BEGIN
                    V_STK_CNT := V_STK_CNT + 1;

                    IF V_STK_CNT = 1 THEN
                       HandleOPStr('{', ConCatResultVar);
                       HandleOPStr('"STOCKLEVEL": [', ConCatResultVar);
                    ELSE
                       HandleOPStr(',', ConCatResultVar);
                    END IF;
                    HandleOPStr('{', ConCatResultVar);
                    HandleOPStr('"PR": '|| (V_STOCK_RECORD.PR) || ',', ConCatResultVar);
                    HandleOPStr('"AN": '|| (V_STOCK_RECORD.AN) || ',', ConCatResultVar);
                    --TV 12Mar14 Added NVL for WOs 
                    if (NVL(V_STOCK_RECORD.CL,0) = 0) 
                    then
                       HandleOPStr('"CL": '|| 'null' || ',', ConCatResultVar);
                    else
                       HandleOPStr('"CL": '|| V_STOCK_RECORD.CL || ',', ConCatResultVar);
                    end if;

					if V_STOCK_RECORD.PD = null
					then
             HandleOPStr('"PD": null,', ConCatResultVar);
          else
             HandleOPStr('"PD": "'|| TO_CHAR(V_STOCK_RECORD.PD,'YYYYMMDD') || '",', ConCatResultVar);
   				End if;

                    HandleOPStr('"PO": "'|| (V_STOCK_RECORD.PO) || '",',ConCatResultVar);
                    HandleOPStr('"LN": "'|| RTrim(V_STOCK_RECORD.LN) || '",',ConCatResultVar);
                    HandleOPStr('"LD": "'|| (V_STOCK_RECORD.LD) || '",',ConCatResultVar);
                    HandleOPStr('"EK": '|| (V_STOCK_RECORD.EK) || ',',ConCatResultVar);
                    HandleOPStr('"RK": '|| (V_STOCK_RECORD.RK) || ',',ConCatResultVar);
                    HandleOPStr('"AK": '|| (V_STOCK_RECORD.AK) || ',',ConCatResultVar);
                    HandleOPStr('"EB": '|| (V_STOCK_RECORD.EB) || ',',ConCatResultVar);
                    HandleOPStr('"RB": '|| (V_STOCK_RECORD.RB) || ',',ConCatResultVar);
                    HandleOPStr('"AB": '|| (V_STOCK_RECORD.AB) || ',',ConCatResultVar);
                    HandleOPStr('"EI": '|| (V_STOCK_RECORD.EI) || ',',ConCatResultVar);
                    HandleOPStr('"RI": '|| (V_STOCK_RECORD.RI) || ',',ConCatResultVar);
                    HandleOPStr('"AI": '|| (V_STOCK_RECORD.AI) || ',',ConCatResultVar);
                    HandleOPStr('"EE": '|| (V_STOCK_RECORD.EE) || ',',ConCatResultVar);
                    HandleOPStr('"RE": '|| (V_STOCK_RECORD.RE) || ',',ConCatResultVar);
                    HandleOPStr('"AE": '|| (V_STOCK_RECORD.AE) || ',',ConCatResultVar);

                    --Calculate the guide prices
                    IF V_STOCK_RECORD.GuidePrice <= 0 THEN
                       GUIDEPRICEBOX   := 0.00;
                       GUIDEPRICEKILO  := 0.00;
                       GUIDEPRICEINNER := 0.00;
                       GUIDEPRICEEACH  := 0.00;
                    ELSE
                       -- Find out the UoM of the Guide Price and convert to the rest
                       --???
                       CASE (V_STOCK_RECORD.PurByTyp)
                          WHEN 1 THEN
                             --Per Box
                             GUIDEPRICEBOX   := V_STOCK_RECORD.GuidePrice;
                             GUIDEPRICEKILO  := ROUND(GUIDEPRICEBOX / V_STOCK_RECORD.PRCWEIGHT ,2);
                             GUIDEPRICEINNER := ROUND(GUIDEPRICEBOX / V_STOCK_RECORD.INNERQTY  ,2);
                             GUIDEPRICEEACH  := ROUND(GUIDEPRICEBOX / V_STOCK_RECORD.PRCBOXQTY ,2);
                          WHEN 2 THEN
                             -- Per Kg
                             GUIDEPRICEKILO  := V_STOCK_RECORD.GuidePrice;
                             GUIDEPRICEBOX   := GUIDEPRICEKILO * V_STOCK_RECORD.PRCWEIGHT ;
                             GUIDEPRICEINNER := GUIDEPRICEBOX / V_STOCK_RECORD.INNERQTY ;
                             GUIDEPRICEEACH  := GUIDEPRICEBOX / V_STOCK_RECORD.PRCBOXQTY ;
                          WHEN 3 THEN
                             -- Per Each
                             GUIDEPRICEEACH  := V_STOCK_RECORD.GuidePrice;
                             GUIDEPRICEBOX   := GUIDEPRICEEACH * V_STOCK_RECORD.PRCBOXQTY ;
                             GUIDEPRICEKILO  := GUIDEPRICEBOX / V_STOCK_RECORD.PRCWEIGHT;
                             GUIDEPRICEINNER := GUIDEPRICEBOX / V_STOCK_RECORD.INNERQTY;
                          WHEN 4 THEN
                             -- Per Inner
                             GUIDEPRICEINNER := V_STOCK_RECORD.GuidePrice;
                             GUIDEPRICEBOX   := GUIDEPRICEINNER * V_STOCK_RECORD.INNERQTY ;
                             GUIDEPRICEKILO  := GUIDEPRICEBOX / V_STOCK_RECORD.PRCWEIGHT;
                             GUIDEPRICEEACH  := GUIDEPRICEBOX / V_STOCK_RECORD.PRCBOXQTY ;
                          ELSE
                          -- Invalid so set all to zero
                             GUIDEPRICEBOX   := -1;
                             GUIDEPRICEKILO  := -1;
                             GUIDEPRICEINNER := -1;
                             GUIDEPRICEEACH  := -1;
                          END CASE;
                         -- ???
                          GUIDEPRICEBOX   := ROUND (GUIDEPRICEBOX, 2);
                          GUIDEPRICEKILO  := ROUND(GUIDEPRICEKILO,2);
                          GUIDEPRICEINNER := ROUND (GUIDEPRICEINNER, 2);
                          GUIDEPRICEEACH  := ROUND (GUIDEPRICEEACH, 2);

                    END IF;

                    HandleOPStr('"PB": '|| TO_CHAR(GUIDEPRICEBOX, '9999999990D99')  || ',',ConCatResultVar);
                    HandleOPStr('"PK": '|| TO_CHAR(GUIDEPRICEKILO, '9999999990D99') || ',',ConCatResultVar);
                    HandleOPStr('"PI": '|| TO_CHAR(GUIDEPRICEINNER, '9999999990D99')|| ',',ConCatResultVar);
                    HandleOPStr('"PE": '|| TO_CHAR(GUIDEPRICEEACH, '9999999990D99') || ',',ConCatResultVar);


                    HandleOPStr('"QC": "'|| RTRIM(V_STOCK_RECORD.QC) || '",',ConCatResultVar);
                    HandleOPStr('"NA": "'|| (V_STOCK_RECORD.NA) || '",',ConCatResultVar);
                    
                    --TV 12Mar14 Added NVL for blank departments and set to department 1 
                    if NVL(V_STOCK_RECORD.DE,0) = 0
                    then
                       HandleOPStr('"DE": '|| '1' || '',ConCatResultVar);
                    else
                       HandleOPStr('"DE": '|| (V_STOCK_RECORD.DE) || '',ConCatResultVar);
                    end if;

                    -- GET LIST OF ALLOWED SALES OFFICES
                    V_SO_CNT := 0;
                    IF V_use_sales_office  = 0 THEN
                    BEGIN
                        -- IF THE SYSTEM IS NOT USING SALES OFFICES THEN PASS BACK -32000
                        V_SO_CNT := V_SO_CNT + 1;
                       HandleOPStr(',',ConCatResultVar);
                        IF V_SO_CNT = 1  THEN
                           HandleOPStr('"SALESOFFICE":[', ConCatResultVar);
                        END IF ;

                        HandleOPStr('{',ConCatResultVar);
                        HandleOPStr('"SO": "-32000"',ConCatResultVar);
                        HandleOPStr('}',ConCatResultVar);

                    END;

                    ELSE
                    -- IF THE SYSTEM IS USING SALES OFFICES THEN GET A LIST OF THE ONES ALLOWED TO SEE THIS LINE
                    BEGIN
                        IF V_user_can_see_all_supp = 1
                        OR NVL(V_STOCK_RECORD.CL, 0) = 0 THEN
                            -- WE DO NOT NEED TO CHECK THE  ACCTOSALOFF AS THE USER IS ALLOWED TO SEE ALL SUPPLIERS OR THE SUPPLIER IS BLANK

                            BEGIN
                                FOR V_ALLOWEDSO_RECORD IN V_STK_ALLOWEDSO_CURSOR(V_STCRECNO)  LOOP  -- GET ALL THE STOCK IN THE SYSTEM
                                    BEGIN
                                        V_SO_CNT := V_SO_CNT + 1;
                                        HandleOpStr(',',ConCatResultVar);
                                        IF V_SO_CNT = 1  THEN
                                            HandleOpStr('"SALESOFFICE":[',ConCatResultVar);
                                        END IF ;

                                        HandleOpStr('{',ConCatResultVar);
                                        HandleOpStr('"SO": '|| (V_ALLOWEDSO_RECORD.SALOFFNO) || '',ConCatResultVar);
                                        HandleOpStr('}',ConCatResultVar);

                                    END;
                                END LOOP;
                            END;
                        ELSE
                            --  THE USER IS NOT ALLOWED TO SEE ALL SUPPLIERS SO WE NEED TO CHECK THE ACCTOSALOFF TABLE & THE
                            --  THE ALLOCATE RECORD HAS A SUPPLIER AND SO WE NEED TO CHECK THE ACCTOSALOFF TABLE & THE SOFTOSTCLOC TABLE
                            V_Allocate_req := 0;
                            BEGIN
                                FOR V_ALLOWEDSO_RECORD IN V_STKSUPP_ALLOWEDSO_CURSOR(V_STCRECNO, V_STOCK_RECORD.CL)  LOOP  -- GET ALL THE STOCK IN THE SYSTEM
                                    BEGIN
                                        V_SO_CNT := V_SO_CNT + 1;
                                        HandleOpStr(',',ConCatResultVar);
                                        IF V_SO_CNT = 1  THEN
                                            HandleOpStr('"SALESOFFICE":[',ConCatResultVar);
                                        END IF ;

                                        HandleOpStr('{',ConCatResultVar);
                                        HandleOpStr('"SO": '|| (V_ALLOWEDSO_RECORD.SALOFFNO) || '',ConCatResultVar);
                                        HandleOpStr('}',ConCatResultVar);
                                    END;
                                END LOOP;
                            END;
                        END IF;

                    END;
                    END IF;

                    IF V_SO_CNT > 0  THEN
                          HandleOpStr(']',ConCatResultVar);
                    END IF;
                    HandleOpStr('}',ConCatResultVar);
                END ;
                END IF;



            END;

       END LOOP;
     END IF;

    IF EC = 0 THEN
       IF V_STK_CNT > 0 THEN
          HandleOpStr(']',ConCatResultVar);
          HandleOpStr('}',ConCatResultVar);
       ELSE
          EC :=   410;
          ED := 'No stock was found';
       END IF;
    END IF;

    --Log the transaction
    HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' SO=' || SO || ' UL=' || UL || ' SL=' || SL || ' PR=' || PR || ' DE=' || DE || ' HT=' || HT, EC , ED, ConCatResultVar, UL ) ;


    IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
        HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);

    END IF;
END;



--------------------------------------------------------------------------------
-- PH 21Sep12 Lookups
--------------------------------------------------------------------------------

PROCEDURE GetLookUps(MI IN VARCHAR2 DEFAULT NULL)
IS
  ContinueVar 	  			BOOLEAN;
  PalLocRecNoVar 			NUMBER(10);
  SqlStr 					VARCHAR(32767);
  DispFieldNameVar 			VARCHAR(30);
  TCNameVar					VARCHAR(30);
  RangeSet1Var 				VARCHAR(20);
  RangeSet2Var 				VARCHAR(20);
  SubSCFieldVar				VARCHAR(30);
  DispFieldVar				VARCHAR(30);
  ListInAlphaVar			NUMBER(5);
  RefCursorVar				SYS_REFCURSOR;
  ValueNumberVar			VARCHAR(20);
  ValueDescVar				VARCHAR(250);
  WhereStringVar			VARCHAR2(4000);
  DevRecNoVar			    NUMBER(10) := -1;
  DapNameVar			    VARCHAR2(50) := NULL;
  LookUpsCountVar			NUMBER(10) := 0;
  LookUpsSubCountVar		NUMBER(10) := 0;
  
  ConCatParamsVar 			VARCHAR(500);
  ConCatResultVar 			VARCHAR(5000)  := '';

  EC INTEGER := 0 ; -- ERROR CODE
  ED VARCHAR2(255) := ''; -- ERROR DESCRIPTION
  PROCNAME VARCHAR(40) := 'GETLOOKUPS';


  VMI DEVICENAME.DEVID%TYPE;
  VDEVNAME DEVICENAME.DEVNAME%TYPE  ; -- DEVICE NAME FROM QUERY

  CURSOR FormListFieldRecs_Cur IS
	SELECT DISPFIELDNAME, TCNAME, RANGESET1, RANGESET2,
		   SUBSCFIELD, DISPFIELD,
		   LISTINALPHAORDER, WHERESTRING
	FROM FrmListField
	WHERE RTRIM(UPPER(FormName)) = RTRIM(UPPER(DapNameVar));

BEGIN

	 ContinueVar := True;
	 SqlStr := '';

     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     IF EC = 0 THEN
         IF MI IS NULL THEN
            EC := 100;
            ED := 'You must enter a machine name (MI)';
			ContinueVar := False;
         END IF;
     END IF;

     -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
	 IF ContinueVar
	 THEN
	 BEGIN
	    IF EC = 0 THEN
	       BEGIN
	          VMI := UPPER(MI);

	          SELECT  DEVNAME, DevRecNo
	          INTO VDEVNAME, DevRecNoVar
	          FROM DEVICENAME
	          WHERE DEVACTIVE = 1
	          AND RTRIM(UPPER(DEVID)) = RTRIM(UPPER(VMI));

	       EXCEPTION
	           WHEN NO_DATA_FOUND THEN
	               EC :=    106;
	               ED := MI || ' is not a registered active device';
				   ContinueVar := False;

	          WHEN OTHERS THEN
	             EC :=  107;
	             ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
			  	 ContinueVar := False;
	       END;
	    END IF;
	 END;
	 END IF;

	 IF ContinueVar
	 THEN
	 BEGIN
	 	  SELECT DapName
		  INTO DapNameVar
		  FROM DeviceApps
		  WHERE DeviceApps.DapDevRecNo = DevRecNoVar
      AND Nvl(DeviceApps.DapActive, 0) = 1;
      --AND Nvl(DeviceApps.DevActive, 0) = 1;

     EXCEPTION
          WHEN NO_DATA_FOUND THEN
              EC :=    106;
              ED := MI || ' device is not configured for App use';
		      ContinueVar := False;

          WHEN OTHERS THEN
            EC :=  107;
            ED := 'Unable to Execute Sql to return application for '|| MI || ' SqlErrM='||  SQLERRM;
	  	    ContinueVar := False;

	 END;
	 END IF;

	 IF ContinueVar
	 THEN
	 BEGIN

        OPEN FormListFieldRecs_Cur;
        LOOP

		FETCH FormListFieldRecs_Cur
		INTO DispFieldNameVar, TCNameVar, RangeSet1Var, RangeSet2Var, SubSCFieldVar, DispFieldVar, ListInAlphaVar, WhereStringVar;

		EXIT WHEN FormListFieldRecs_Cur%NOTFOUND;

		IF ContinueVar
		THEN
		BEGIN

			 IF LookupsCountVar = 0
			 THEN
         HandleOPStr('{', ConCatResultVar);
         HandleOPStr('"LOOKUPS": [', ConCatResultVar);
			 	 --HTP.P('{');
				 --HTP.P('"LOOKUPS": [');
			 ELSE
				-- HTP.P(',');
          HandleOPStr(',', ConCatResultVar);
			 END IF;

			 LookupsCountVar := LookupsCountVar + 1;

			 SqlStr := 'SELECT '|| RTRIM(SubSCFieldVar) || ' AS ValueNumber, ' || RTRIM(DispFieldVar) || ' AS VALUEDESC ' ;
			 SqlStr := SqlStr || ' FROM ' || RTRIM(TCNameVar) || ' ';
		 	 SqlStr := SqlStr || RTRIM(UPPER(WhereStringVar));

			 IF ListInAlphaVar > 0
			 THEN
			 	 SqlStr := SqlStr || ' ' || 'ORDER BY ' || RTRIM(SubSCFieldVar);
			 END IF;

		 	 LookUpsSubCountVar := 0;

			 OPEN RefCursorVar FOR SqlStr;
			 LOOP




			 FETCH RefCursorVar
			 INTO ValueNumberVar, ValueDescVar;

			 EXIT WHEN RefCursorVar%NOTFOUND;

			 	  IF LookUpsSubCountVar > 0
				  THEN
				  	  HandleOPStr(',', ConCatResultVar);
				  END IF;

			 	  HandleOPStr('{', ConCatResultVar);
				  HandleOPStr('"LP": "'|| (RTRIM(DispFieldNameVar)) || '",', ConCatResultVar);
				  HandleOPStr('"LC": "'|| (RTRIM(ValueNumberVar)) || '",', ConCatResultVar);
				  HandleOPStr('"LV": "'|| (RTRIM(ValueDescVar))|| '"', ConCatResultVar);
			 	  HandleOPStr('}', ConCatResultVar);

		 		  LookUpsSubCountVar := LookUpsSubCountVar + 1;


	         END LOOP;
	         CLOSE RefCursorVar;

		END;
		END IF;

        END LOOP;
        CLOSE FormListFieldRecs_Cur;


		IF LookupsCountVar > 0
		THEN
			HandleOPStr(']', ConCatResultVar);
		  HandleOPStr('}', ConCatResultVar);
		END IF;


	 END;
	 END IF;

     IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
     END IF;

    --Log the transaction
    ConCatParamsVar := '?MI='|| MI;
    HANDHELDLOG (MI, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, '[PRE-LOGON]' ) ;

END GetLookUps;

PROCEDURE ValidateJSONString (OJ IN VARCHAR2) IS
  Jsonobj             JSON;
  JSONObjectIsValid BOOLEAN := True;
BEGIN
   --HTP.P('hello');
   JSONObjectIsValid := True;
   -- validate the JSON
    BEGIN
         Jsonobj := json(OJ);
    EXCEPTION
        WHEN OTHERS THEN
          JSONObjectIsValid := False;
           --EC := 401;
           --ED := 'INVALID JSON FILE OJ='||  UTL_URL.ESCAPE(OJ);
    END;
    
    if JSONObjectIsValid Then
       HTP.P('JSON string: VALID');
    else
       HTP.P('JSON string: NOT VALID');
    end if;
   
END ValidateJSONString;  
  
PROCEDURE UPLOAD_ORDER (OJ IN VARCHAR2) IS
--Upload a new order from the device to the table MKTHHELD_ORDER & MKTHHELD_ORDDET
     EC INTEGER := 0 ;          -- ERROR CODE
     ED VARCHAR2(255) := '';    -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'UPLOAD_ORDER';
	 --vNewHeader BOOLEAN := False;
   vNewTkt BOOLEAN := False;
	 vNewLine   BOOLEAN := False;
   LTktEdit BOOLEAN := False;
   VTktToEditIsFTCreated BOOLEAN := False;
   LHaveUploadData       BOOLEAN := False;
   FTTktNeedsUpldDets    BOOLEAN := False;
   v_IsTheDevThatCrtdTheTktMe BOOLEAN := False;
   V_DevRecNoCheck       integer := 0;
   StoreTktHdr_FT_SeqNo  integer := 0;
   VStatusToSet integer;
   V_LiveDlvOrdNo integer;
   V_LiveTntTbkRecNo integer;
   V_LiveTntNo integer;


   ConCatResultVar 			VARCHAR(5000)  := '';


    Order_Jsonobj             JSON;
    Detail_lines              JSON_LIST;
    Detail_Jsonobj            JSON;

-- HEADER VARIABLES
    V_HDR_FT_SEQNO      MKTHHELD_ORDHDR.FT_SEQNO%TYPE;
    V_MachineID         DEVICENAME.DEVID%TYPE;
    V_DevRecNo          DEVICENAME.DEVRECNO%TYPE  ; -- DEVICE NAME FROM QUERY
    V_LogOnNo           MKTHHELD_ORDHDR.LOGONNO%TYPE;
    V_LogOnName         LOGONS.LOGONNAME%TYPE;
    V_EncrHash          VARCHAR2(128);
    V_SmnNo             MKTHHELD_ORDHDR.SMNNO%TYPE;
    V_SalesType         MKTHHELD_ORDHDR.DLTRECNO%TYPE;  -- DLVTYPE delivery type
    V_SalOffNo          MKTHHELD_ORDHDR.SALOFFNO%TYPE;
    V_StcRecNo          MKTHHELD_ORDHDR.STCRECNO%TYPE;
    V_ClaRecNo          MKTHHELD_ORDHDR.CLARECNO%TYPE;
    V_TktNo             MKTHHELD_ORDHDR.TNTNO%TYPE;
	  V_TktBookNo         MKTHHELD_ORDHDR.TNTTBKRECNO%TYPE;
    V_Date              MKTHHELD_ORDHDR.ORDHDRDATE%TYPE;
    V_OrderComm         MKTHHELD_ORDHDR.ORDERCOMM%TYPE;
    V_NettAmt           MKTHHELD_ORDHDR.ORD_NETTAMT%TYPE;
    V_VAT1Amt           MKTHHELD_ORDHDR.ORD_VAT1AMT%TYPE;
    V_VAT2Amt           MKTHHELD_ORDHDR.ORD_VAT2AMT%TYPE;
    V_GrossAmt          MKTHHELD_ORDHDR.ORD_GROSSAMT%TYPE;
    V_LastAudit         MKTHHELD_ORDHDR.LASTAUDIT%TYPE;


	V_ORDHDR_ROW    	    MKTHHELD_ORDHDR%ROWTYPE;
  V_tktnt_Row           TKTNT%ROWTYPE;

-- DETAIL VARIABLES
    V_LineNo            MKTHHELD_ORDDET.LINENO%TYPE;
    V_PrcPrdNo          MKTHHELD_ORDDET.PRCPRDNO%TYPE;
    V_LineComm          MKTHHELD_ORDDET.LINECOMM%TYPE;
    V_DetQty            MKTHHELD_ORDDET.DETQTY%TYPE;
    V_QtyPer            MKTHHELD_ORDDET.QTYPER%TYPE;
    V_Price             MKTHHELD_ORDDET.PRICE%TYPE;
    V_FOC               MKTHHELD_ORDDET.FOC%TYPE;
    V_Allocno           MKTHHELD_ORDDET.ALLOCNO%TYPE;
    V_Det_NettAmt       MKTHHELD_ORDDET.DET_NETTAMT%TYPE;
    V_Det_VAT1Amt       MKTHHELD_ORDDET.DET_VAT1AMT%TYPE;
    V_Det_VAT2Amt       MKTHHELD_ORDDET.DET_VAT2AMT%TYPE;
    V_Det_GrossAmt      MKTHHELD_ORDDET.DET_GROSSAMT%TYPE;

	V_ORDDET_ROW		MKTHHELD_ORDDET%ROWTYPE;


BEGIN

 -- validate the JSON
    BEGIN
         Order_Jsonobj := json(OJ);
    EXCEPTION
        WHEN OTHERS THEN
           EC := 401;
           ED := 'INVALID JSON FILE OJ='||  UTL_URL.ESCAPE(OJ);
    END;


	-- validate the JSON lines
    -- Split into two parts TV 25Feb13
	  BEGIN
         Detail_lines   := json_list(Order_Jsonobj.get('LINES'));
    EXCEPTION
        WHEN OTHERS THEN
           EC := 401;
           ED := 'INVALID JSON FILE (LINES) OJ='||  UTL_URL.ESCAPE(OJ);
    END;

  --ach! Note: if issue = eg. UL not supplied, then the Machine ID is not verified and so log record is for blank devide id/name.
  --Could verify, validate and assign one at a time, but ultimately the WS does return the correct result UL is blank.

 -- ENSURE THE MAIN ELEMENTS EXIST
    IF EC = 0 THEN
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'MI', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'UL', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'EH', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'SN', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'ST', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'SO', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'SL', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'CL', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'TB', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'OD', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'OC', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'NT', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'V1', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'V2', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'GT', EC, ED);
        DoesJSONElemExist (PROCNAME, Order_Jsonobj, 'LA', EC, ED);
    END IF;

 -- VALIDATE THAT THESE ELEMENTS ARE INTEGERS, NUMBERS, DATES
    IF EC = 0 THEN
        IsJSONElemAnInt(Order_Jsonobj, 'SN', EC, ED);
        IsJSONElemAnInt(Order_Jsonobj, 'ST', EC, ED);
        IsJSONElemAnInt(Order_Jsonobj, 'SO', EC, ED);
        IsJSONElemAnInt(Order_Jsonobj, 'SL', EC, ED);
        IsJSONElemAnInt(Order_Jsonobj, 'CL', EC, ED);
        IsJSONElemAnInt(Order_Jsonobj, 'TB', EC, ED);

        IsJSONElemANumber(Order_Jsonobj, 'NT', EC, ED);
        IsJSONElemANumber(Order_Jsonobj, 'V1', EC, ED);
        IsJSONElemANumber(Order_Jsonobj, 'V2', EC, ED);
        IsJSONElemANumber(Order_Jsonobj, 'GT', EC, ED);

        IsJSONElemADate (Order_Jsonobj, 'OD', EC, ED);

        IsJSONElemAnInt (Order_Jsonobj, 'LA', EC, ED); -- .Last Audit Record Number
    END IF;

 -- PUT THE HEADER JSON VARIABLES INTO OUR VARIABLES
 -- THIS SHOULD TRAP ANY OTHER ISSUES WITH THE VARIABLES eg a number (5) having 6 digits
    IF EC = 0 THEN
        BEGIN
            V_MachineID         := Order_Jsonobj.get('MI').get_string;
            V_LogOnName         := Order_Jsonobj.get('UL').get_string;
            V_EncrHash          := Order_Jsonobj.get('EH').get_string;
            V_SmnNo             := Order_Jsonobj.get('SN').get_number;
            V_SalesType         := Order_Jsonobj.get('ST').get_number;
            V_SalOffNo          := Order_Jsonobj.get('SO').get_number;
            V_StcRecNo          := Order_Jsonobj.get('SL').get_number;
            V_ClaRecNo          := Order_Jsonobj.get('CL').get_number;
            V_TktNo             := Order_Jsonobj.get('TB').get_number;
			      V_TktBookNo         := Order_Jsonobj.get('BT').get_number;
            V_Date              := json_ext.to_date2(Order_Jsonobj.get('OD'));
            V_OrderComm         := Order_Jsonobj.get('OC').get_string;
            V_NettAmt           := Order_Jsonobj.get('NT').get_number;
            V_VAT1Amt           := Order_Jsonobj.get('V1').get_number;
            V_VAT2Amt           := Order_Jsonobj.get('V2').get_number;
            V_GrossAmt          := Order_Jsonobj.get('GT').get_number;
            V_LastAudit         := Order_Jsonobj.get('LA').get_number;
        EXCEPTION
            WHEN OTHERS THEN
                 EC := 401;
                 ED := 'Invalid JSON File : SqlErrM='||  SQLERRM;
        END;
    END IF;

     -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
    IF EC = 0 THEN
         --IF V_MachineID IS NULL THEN
         --   EC := 100;
         --   ED := 'You must enter a machine name (MI)';
         --END IF;
         MachineIDValidate(V_MachineID, EC, ED, V_DevRecNoCheck);
    END IF;

    IF EC = 0 THEN
        BEGIN
		   --Upper added to V_MachineID 28Jan13 TV
           SELECT  DEVRECNO  INTO V_DevRecNo FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = UPPER(V_MachineID);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := V_MachineID || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| V_MachineID || ' SqlErrM='||  SQLERRM;
        END;
    END IF;


     -- CHECK THE DATABASE to see if USER EXISTS AND IS ACTIVE
    IF EC = 0 THEN
        IF V_LogOnName IS NULL THEN
            EC := 401;
            ED := 'You must enter a user logon name (UL)';
        END IF;
    END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if LOGONS EXISTS AND IS ACTIVE
    IF EC = 0 THEN
        BEGIN
            SELECT LOGONNO INTO V_LogOnNo
            FROM LOGONS
            WHERE TRIM(LOGONNAME) = TRIM(UPPER(V_LogOnName))
            AND AVAILTOMKTHANDHELD = 1
            AND ACTIVE = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    402;
                ED := V_LogOnName || ' is not a registered active logon';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain LOGONS information for '|| V_LogOnName || ' SqlErrM='||  SQLERRM;
        END;
    END IF;

---------!!!INPUT PARAMETER VALIDATION DONE (HEADER)!!! --Now check where we are with existing data, and what we need to do...



-- *****************Check statuses are ok for Uploading and editing.*********************
--Pass in Ticket&Book                 -1                >0
--vNewTkt                             True              False
--v_TktToEditIsFTCreated              False             (Check)
--v_HaveUploadData                    (will be none)    if MKT Tkt, True.   LHaveUploadData
--v_IsTheDeviceThatCreatedThePOMe     N/A               (Check)
--V_LastAudit
--FTTktNeedsUpldDets                  (populate upld table if uploading to another device)
--The Tkt must be at status 1 'complete' to be edited. (UNLESS it is edited by the same handheld and it has not yet been created; status 0)
--VStatusToSet Freshtrade indicator for 'we have new details' or 'we have edited details'

	   -- Check to see if the ticket is already uploaded TV 8Jul13
     --What if the ticket exists / created on another device?	 TV 28Oct13 ... then we had better find out!
	 
     --A) uploading new order; B) editing existing order FT created; C) editing existing order NOT FT created;
     
     --1) do we have upload data
	   LHaveUploadData := True;
     If EC = 0 then
        Begin
		       Select *
		       INTO V_ORDHDR_ROW
		       FROM MKTHHELD_ORDHDR	
			   WHERE FT_SEQNO = (Select MAX(FT_SEQNO) 
			                     from MKTHHELD_ORDHDR
		                         WHERE TNTTBKRECNO = V_TktBookNo
                                 AND TNTNO = V_TktNo);
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
		       LHaveUploadData := False;
		    WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Header information for ticket '|| V_TktNo || ' SqlErrM='||  SQLERRM;
        END;
     END IF;
     
     --2) do we have live data
      If EC = 0 then
        V_LiveDlvOrdNo := 0;
        VTktToEditIsFTCreated := False;  --this var could be called TktIsLive
        Begin        
           select TntTbkRecNo, tntno, Nvl(delhed.DlvOrdNo, 0) DlvOrdNo
           INTO V_LiveTntTbkRecNo, V_LiveTntNo, V_LiveDlvOrdNo
           from tktnt
           Left Outer Join delhed ON (tktnt.TntDlvOrdNo = delhed.DlvOrdNo)
           Where tntno = V_TktNo and TntTbkRecNo = V_TktBookNo;       
        
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
		       VTktToEditIsFTCreated := False;
		    WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Live information for ticket '|| V_TktNo || ' SqlErrM='||  SQLERRM;
        END;
        
        --If EC = 0 then
          if V_LiveDlvOrdNo > 0 Then
             VTktToEditIsFTCreated := True;
          end if;
           
        --end if;   
        
     END IF;
     
     If EC = 0 then  --v_HaveUploadData
        if LHaveUploadData = True OR VTktToEditIsFTCreated = True Then
          LTktEdit := True;
          vNewTkt  := False;        
        else
          LTktEdit := False;        
          vNewTkt  := True;        
        end if;
     end if;
     
     /*If EC = 0 then
        --if vNewTkt = True Then
        --   LHaveUploadData := False;  -- LHaveUploadData = do we have 'upload' data in the upload table.
        --else
           LHaveUploadData := True;
           Begin
            Select * --tntrecno, tntno, tntbkrecno, tntdlvordno
            into V_tktnt_Row
            from tktnt
            where tntno = V_TktNo
            and tnttbkrecno = V_TktBookNo;
           EXCEPTION
            When NO_DATA_FOUND Then
               LHaveUploadData := False;
            When OTHERS THEN
               EC := 401;
               ED := 'INVALID HEADER SEQ NO ';
            end;
        --end if;
     end if;*/
     
    

     If EC = 0 then
        LTktEdit := False;
        if vNewTkt = false Then
           if Nvl(V_ORDHDR_ROW.DlvOrdNo, 0) = 0 Then
              LTktEdit := False;  --uploaded, but not created. (amend upload tables)
              --VTktToEditIsFTCreated := False;
          else
              LTktEdit := True; --we have a delivery number created for the upload. We are here to change the live delivery.
              --VTktToEditIsFTCreated := True;
           end if;
        end if;
     end if;

     If EC = 0 then
         if vNewTkt = true Then
            if V_LastAudit <> -1 Then
               EC :=  430;
               ED := 'New Ticket '|| V_TktNo || ' must have an initial value of -1';
            end If;
         end if;
     end if;


	 -- Check to see if the ticket is in a status that can be edited
	 If EC = 0 then
	    Begin
	 	     If V_ORDHDR_ROW.Status = -2 then
			         --Order is being uploaded by Freshtrade at present (-2), so cannot upload a new version
               EC :=  402;
               ED := 'Ticket '|| V_TktNo || ' is being uploaded to Freshtrade.  Try again in a couple of seconds';
		     End if;

         --this is giving an error but should be correct???

        /* If EC = 0 then
            If V_ORDHDR_ROW.Status = 0 then --status for a new order
               if (vNewTkt = False OR VTktToEditIsFTCreated = True) Then
                     EC :=  405;
                     ED := 'Ticket '|| V_TktNo || ' upload status mismatch (Ready to upload)';
               end if;
            end If;
         end if;
         If EC = 0 then
            If V_ORDHDR_ROW.Status = 2 then --status for a 'amendments pending'
               if (vNewTkt = True OR LTktEdit = False) Then
                  EC :=  406;
                  ED := 'Ticket '|| V_TktNo || ' upload status mismatch (amendments pending)';
               end if;
            end If;
         end if;*/
		  End;
	 End If;
   
   /*If EC = 0 then --check that the ticket is still for the original customer (do not allow customer change)
      if LTktEdit = True Then
         if V_ORDHDR_ROW.ClaRecNo <> V_ClaRecNo Then
             --Note: this is now allowed. closed/completed tickets cannot get to this stage.
              --EC :=  407;
              --ED := 'Ticket '|| V_TktNo || ' has been re-submitted with a different customer. (not allowed)'; --at this stage...
         end if;
      end if;
   end if;   */

   /*If EC = 0 then
      if vNewTkt = True Then
         LHaveUploadData := False;  -- LHaveUploadData = do we have 'upload' data in the upload table.
      else
         LHaveUploadData := True;
         Begin
            Select * --tntrecno, tntno, tntbkrecno, tntdlvordno
            into V_tktnt_Row
            from tktnt
            where tntno = V_TktNo
            and tnttbkrecno = V_TktBookNo;
         EXCEPTION
            When NO_DATA_FOUND Then
               LHaveUploadData := False;
            When OTHERS THEN
               EC := 401;
               ED := 'INVALID HEADER SEQ NO ';
         end;
      end if;
   end if;*/

  --if we dont have upload data, lets have upload data.
  --we will not have upload data if we have downloaded, and resending edits for a FT created tkt.
  -- if v_TktToEditIsCreated = true AND v_HaveUploadData = False  then this is a FT created tkt. There is Not currently and data in the Upload Table.
  If EC = 0 then
     FTTktNeedsUpldDets := False;
     if VTktToEditIsFTCreated = true AND LHaveUploadData = False  then
        FTTktNeedsUpldDets := True; --we are not creating the Tkt but we are writing the details to the upload tables for the first time.
     end if;
  end if;

  If EC = 0 then
     if LHaveUploadData = False Then
        v_IsTheDevThatCrtdTheTktMe := False;
     else
        if V_ORDHDR_ROW.DevRecNo = V_DevRecNoCheck Then
           v_IsTheDevThatCrtdTheTktMe := True;
        else
           v_IsTheDevThatCrtdTheTktMe := False;
        end If;
     end If;
  end if;


    If EC = 0 then  --if the Ticket IS pending (NOT created) it can only be edited by the device that created it.
     if LTktEdit Then --I want to edit a PO
        if LHaveUploadData Then
           if v_IsTheDevThatCrtdTheTktMe = True Then
              if V_ORDHDR_ROW.Status <> 0 AND V_ORDHDR_ROW.Status <> 1 AND V_ORDHDR_ROW.Status <> 2 Then
                 EC := 125;
                 ED := 'Cannot edit a Ticket at this status.';
              else
                 StoreTktHdr_FT_SeqNo := V_ORDHDR_ROW.FT_SeqNo;
              end if;
           else
              if V_ORDHDR_ROW.Status = 0 Then
                 EC := 126;
                 ED := 'Cannot edit another users Ticket before it is created.';
              end if;
           end if;
        end If;
     end if;
  end If;

  If EC = 0 then --Check for interrim changes : user changed Tkt since download was done.
     --Note that Tkt date changes may have been Monday but we check delivery line changed Wednesday - must be at detail level.
     if LHaveUploadData Then
        if V_LastAudit > V_ORDHDR_ROW.LastAudit Then
           EC := 114;
           ED := 'Cannot Amend! - ticket has been edited since ticket download was executed. Audit Number Passed: ' || V_LastAudit || ';  Last ticket Audit: ' || V_ORDHDR_ROW.LastAudit || ';';
        end if;
     end If;
  end If;


   -----------------!!!VALIDATION DONE!!! ---------Start the upload.
   If EC = 0 then
      Begin
	 	     If (vNewTkt = True OR FTTktNeedsUpldDets = True) then
		         BEGIN
                 -- New Header
                  IF EC = 0 THEN
                     BEGIN
                         V_HDR_FT_SEQNO       := MKTHANDHELD_ORDHDR_FT_SEQNO.NEXTVAL;
                     EXCEPTION
                             WHEN OTHERS THEN
                                EC := 401;
                                ED := 'INVALID HEADER SEQ NO ';
                     END;
                  END IF;

                  -- WRITE THE HEADER RECORD AT THIS STAGE WITH A STATUS OF -1 - WHICH MEANS THAT IT HAS NOT SUCCESSFULLY UPLOADED YET
                 IF EC = 0 THEN
                     BEGIN
                         INSERT INTO MKTHHELD_ORDHDR (FT_SEQNO, DEVRECNO, LOGONNO, SMNNO,DLTRECNO, SALOFFNO, STCRECNO,
                                                     CLARECNO, TNTNO, TNTTBKRECNO, ORDHDRDATE, ORDERCOMM, ORD_NETTAMT, ORD_VAT1AMT,ORD_VAT2AMT, ORD_GROSSAMT, STATUS, DATE_UPLD, LASTAUDIT,
                                                     DATETHISRECORDCREATED, LastEditByLogonNo) --
                         VALUES(
                             V_HDR_FT_SEQNO, V_DevRecNo, V_LogOnNo, V_SmnNo, V_SalesType, V_SalOffNo, V_StcRecNo,
                             V_ClaRecNo, V_TktNo, V_TktBookNo, V_Date, V_OrderComm, V_NettAmt, V_VAT1Amt, V_VAT2Amt, V_GrossAmt, -1, SYSDATE(), V_LastAudit,  --last audit  =-1 (no audits yet)
                             SYSDATE(), V_LogOnNo);   -- <= this date should never change
                             --V_LogOnNo
                             if FTTktNeedsUpldDets = True Then 
                                Update MKTHHELD_ORDHDR set DlvOrdNo = V_LiveDlvOrdNo Where FT_SEQNO = V_HDR_FT_SEQNO;
                             end if;   
                     COMMIT;
                     EXCEPTION
                          WHEN OTHERS THEN
                             EC :=  107;
                             ED := 'Unable to Execute Sql to INSERT INTO MKTHHELD_ORDHDR  SqlErrM='||  SQLERRM;

                     END;
                 END IF;
		         END;
         ELSE --Not vNewTkt
		         --Else here for update of existing record
		         V_HDR_FT_SEQNO := V_ORDHDR_ROW.FT_SEQNO;
	 	         BEGIN
	                UPDATE MKTHHELD_ORDHDR SET
                  --LOGONNO      = V_LogOnNo, --when editing we dont update the creator (see LastEditByLogonNo)
                  SMNNO        = V_SmnNo,
                  DLTRECNO     = V_SalesType,
                  SALOFFNO     = V_SalOffNo,
                  STCRECNO     = V_StcRecNo,
                  CLARECNO     = V_ClaRecNo,
                  ORDHDRDATE   = V_Date,
                  ORDERCOMM    = V_OrderComm,
                  ORD_NETTAMT  = V_NettAmt,
                  ORD_VAT1AMT  = V_VAT1Amt,
                  ORD_VAT2AMT  = V_VAT2Amt,
                  ORD_GROSSAMT = V_GrossAmt,
                  STATUS       = -1,
                  --DATE_UPLD    = SYSDATE(), dont update this, we dont want to show created at 10:01, created at 10:05. (get edit date from audits)
                  LASTAUDIT    = V_LastAudit,   
				  -- Not sure what we decided to do about a second upload from a different device
				  --this will re-use the same record, but we might decide to create a second one
				  --TV28Oct13 
				  DEVRECNO     = V_DevRecNo,
          LastEditByLogonNo = V_LogOnNo,
          LASTEDITDATETIME    = SYSDATE()
				  
                  WHERE FT_SEQNO = V_ORDHDR_ROW.FT_SEQNO;
                    COMMIT;
             EXCEPTION
                       WHEN OTHERS THEN
                          EC :=  107;
                          ED := 'Unable to Execute Sql to UPDATE INTO MKTHHELD_ORDHDR  SqlErrM='||  SQLERRM;

             END;
		     END IF;
      END;
   END IF;

-- SCAN THROUGH THE DETAILS, VALIDATE THEM  AND UPLOAD THEM
-- NOTE THE HEADER FLAG IS NOT WRITTEN AT THIS STAGE

    IF EC = 0 THEN
        FOR i in 1..Detail_lines.count LOOP
            BEGIN
                Detail_Jsonobj :=  json(Detail_lines.get(i));
            EXCEPTION
                WHEN OTHERS THEN
                   EC := 401;
                   ED := 'INVALID DETAILS IN JSON FILE ';
            END;
             -- ENSURE THE DETAIL ELEMENTS EXIST
            IF EC = 0 THEN
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'LN', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'PR', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'LC', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'LQ', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'UM', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'PU', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'FC', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'EP', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'AN', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'V1', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'V2', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'GP', EC, ED);
            END IF;

             -- VALIDATE THAT THESE ELEMENTS ARE INTEGERS, NUMBERS, DATES
            IF EC = 0 THEN
                IsJSONElemAnInt(Detail_Jsonobj, 'LN', EC, ED);
                IsJSONElemAnInt(Detail_Jsonobj, 'PR', EC, ED);
                IsJSONElemAnInt(Detail_Jsonobj, 'UM', EC, ED);
                IsJSONElemAnInt(Detail_Jsonobj, 'AN', EC, ED);
                --DEBUG  This needs changing to a boolean TV 28Jan13
				        --IsJSONElemAnInt(Detail_Jsonobj, 'FC', EC, ED);
                
                --TV Quantity at present should be an integer in order to match the FT Market Order Entry 7Jan14
                --IsJSONElemANumber(Detail_Jsonobj, 'LQ', EC, ED);
                IsJSONElemAnInt(Detail_Jsonobj, 'LQ', EC, ED);
                
                IsJSONElemANumber(Detail_Jsonobj, 'PU', EC, ED);
                IsJSONElemANumber(Detail_Jsonobj, 'EP', EC, ED);
                IsJSONElemANumber(Detail_Jsonobj, 'V1', EC, ED);
                IsJSONElemANumber(Detail_Jsonobj, 'V2', EC, ED);
                IsJSONElemANumber(Detail_Jsonobj, 'GP', EC, ED);
            END IF;

           -- PUT THE DETAIL JSON VARIABLES INTO OUR VARIABLES
           -- THIS SHOULD TRAP ANY OTHER ISSUES WITH THE VARIABLES eg a number (5) having 6 digits
            IF EC = 0 THEN
                BEGIN
                    V_LineNo            := Detail_Jsonobj.get('LN').get_number;
                    V_PrcPrdNo          := Detail_Jsonobj.get('PR').get_number;
                    V_LineComm          := Detail_Jsonobj.get('LC').get_string;
                    V_DetQty            := Detail_Jsonobj.get('LQ').get_number;
                    V_QtyPer            := Detail_Jsonobj.get('UM').get_number;
                    V_Price             := Detail_Jsonobj.get('PU').get_number;
                    -- TODO TV Needs fixing to make the FOC flag an integer
					          --V_FOC               := Detail_Jsonobj.get('FC').get_number;
					          V_FOC := 0;
					          --TV 20thFeb13 Fields being written the wrong way round AN = AllocNo EP=NettPrice
                    V_Allocno           := Detail_Jsonobj.get('AN').get_number;
                    V_Det_NettAmt       := Detail_Jsonobj.get('EP').get_number;
                    V_Det_VAT1Amt       := Detail_Jsonobj.get('V1').get_number;
                    V_Det_VAT2Amt       := Detail_Jsonobj.get('V2').get_number;
                    V_Det_GrossAmt      := Detail_Jsonobj.get('GP').get_number;
                EXCEPTION
                    WHEN OTHERS THEN
                        EC := 401;
                        ED := 'Invalid Details on JSON File : SqlErrM='||  SQLERRM;
                END;
            END IF;
                        
            --Do validation here...eg user entered 1 billion boxes.
            --....
            IF EC = 0 THEN
               if V_PrcPrdNo = 0 Then
                  EC :=  194;
                  ED := 'Ticket '|| V_TktNo || '. Zero value product identifier (unknown product) transmitted to FreshTrade [Webservice UPLOAD_ORDER]';
               end if;
            end if;    

			      vNewLine := True;
            --IF ((EC = 0) AND (vNewTkt = false)) THEN
            --IF ((EC = 0) AND (vNewTkt = False)) THEN  --?
            IF ((EC = 0) AND (LHaveUploadData = true)) Then
               BEGIN
                  -- Check to see if there are existing details
                  vNewLine := False;
                  Select *
                  INTO V_ORDDET_ROW
                  FROM MKTHHELD_ORDDET
                    WHERE HDR_FT_SEQNO = V_ORDHDR_ROW.FT_SEQNO --V_HDR_FT_SEQNO
                        AND LINENO = V_LineNo;
                        --AND ROWNUM = 1;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                        vNewLine := True;
                  WHEN OTHERS THEN
                        EC :=  107;
                        ED := 'Unable to Execute Sql to Obtain Line information for ticket '|| V_TktNo || ' Line No='|| v_LineNo || ' SqlErrM='||  SQLERRM;
               END;
            END IF;

            if FTTktNeedsUpldDets Then
               vNewLine := true;
            end If;

            IF EC = 0 THEN
                If vNewLine THEN
                   BEGIN
                           INSERT INTO MKTHHELD_ORDDET (
                               FT_SEQNO, HDR_FT_SEQNO, LINENO,PRCPRDNO, LINECOMM, DETQTY, QTYPER, PRICE, FOC,
                               ALLOCNO, DET_NETTAMT, DET_VAT1AMT, DET_VAT2AMT, DET_GROSSAMT)
                           VALUES (
                               MKTHANDHELD_ORDDET_FT_SEQNO.NEXTVAL, V_HDR_FT_SEQNO,
                               V_LineNo, V_PrcPrdNo, V_LineComm, V_DetQty, V_QtyPer, V_Price, V_FOC,
                               V_Allocno, V_Det_NettAmt, V_Det_VAT1Amt, V_Det_VAT2Amt, V_Det_GrossAmt);
                           COMMIT;
                   EXCEPTION
                           WHEN OTHERS THEN
                              EC :=  107;
                              ED := 'Unable to INSERT INTO MKTHHELD_ORDDET ('||  SQLERRM || ')';

                   END;
               ELSE --Not newline.
                  BEGIN
                      UPDATE MKTHHELD_ORDDET
                      SET PRCPRDNO = V_PrcPrdNo,
                      LINECOMM = V_LineComm,
                      DETQTY   = V_DetQty,
                      QTYPER   = V_QtyPer,
                      PRICE    = V_Price,
                      FOC      = V_FOC,
                      ALLOCNO  = V_Allocno,
                      DET_NETTAMT = V_Det_NettAmt,
                      DET_VAT1AMT = V_Det_VAT1Amt,
                      DET_VAT2AMT = V_Det_VAT2Amt,
                      DET_GROSSAMT = V_Det_GrossAmt
                      WHERE FT_SEQNO = V_ORDDET_ROW.FT_SEQNO;
                             COMMIT;
                  EXCEPTION
                           WHEN OTHERS THEN
                              EC :=  107;
                              ED := 'Unable to Execute Sql to UPDATE MKTHHELD_ORDDET  SqlErrM='||  SQLERRM;
                  END;
               END IF;
            END IF; --ec = 0
      END LOOP;
   END IF;

    IF EC = 0 THEN
       --if vNewTkt Then  --it is still 'ready' if its never FT created!
       if VTktToEditIsFTCreated = False Then
          VStatusToSet := 0; --Ready to upload
       else
          VStatusToSet := 2; --Amendments Pending (edit ready to upload)
       end if;

       BEGIN
            UPDATE MKTHHELD_ORDHDR SET STATUS = VStatusToSet WHERE FT_SEQNO = V_HDR_FT_SEQNO;  --0 = ready to upload.
            COMMIT;
       EXCEPTION
             WHEN OTHERS THEN
                EC :=  107;
                ED := 'Unable to Execute update Sql MKTHHELD_ORDHDR -STATUS = 0 - SqlErrM='||  SQLERRM;
       END;
    END IF;


    IF EC = 0 THEN        -- SUCCESS RETURNED
		-- returns UTC data and time, up to the Android device to sort out summer time etc!
        HandleOPStr('{
            "DU": '|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'YYYYMMDD') || ',
            "DT": "'|| TO_CHAR(sys_extract_utc(SYSTIMESTAMP),'HH24MISS') ||'"
               }', ConCatResultVar);

    ELSE   -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
    END IF;

  --if UL supplied is null, see if we at least have the offending user. (so log shown is better)
   if V_MachineID IS NULL Then
         BEGIN
            V_MachineID         := Order_Jsonobj.get('MI').get_string;
         EXCEPTION
             WHEN OTHERS THEN
                EC :=  109;
                --ED := 'Unable to Execute update Sql MKTHHELD_ORDHDR -STATUS = 0 - SqlErrM='||  SQLERRM;
         END;
   end if;

    --Log the transaction
    HANDHELDLOG (V_MachineID , PROCNAME, '?OJ='|| OJ, EC , ED, ConCatResultVar, V_LogOnName) ;

  END; --UPLOAD_ORDER END;

  
  
  
  
--DOESJSONELEMEXIST (ELEM IN VARCHAR2)
  PROCEDURE DoesJSONElemExist (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2) IS
  BEGIN
    if not IN_JSON.exist(ELEM) then
       IN_ERRCODE := 401;
       IF LENGTH(NVL(IN_ERRDESC, ' ')) < 200 THEN -- ASSUMING THE BELOW STRING IS ABOUT 50
            --IN_ERRDESC := IN_ERRDESC ||'<br>' || ELEM || ' does not exist in  JSON File ';
            IN_ERRDESC := IN_ERRDESC ||'  ' || ELEM || ' Parameter missing from JSON Script ';
       END IF;
    end if;
  END;
  --DOESJSONELEMEXIST (ELEM IN VARCHAR2)
  
PROCEDURE DoesJSONElemExist (ProcName IN VARCHAR2, IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2) IS
  BEGIN
    if not IN_JSON.exist(ELEM) then
       IN_ERRCODE := 401;
       IF LENGTH(NVL(IN_ERRDESC, ' ')) < 200 THEN -- ASSUMING THE BELOW STRING IS ABOUT 50
            --IN_ERRDESC := IN_ERRDESC ||'<br>' || ELEM || ' does not exist in  JSON File ';
            IN_ERRDESC := IN_ERRDESC ||'  ' || ELEM || ' Parameter missing from JSON Script. \nWebservice: ' || ProcName;
       END IF;
    end if;
  END;

  -- IsJSONElemAnInt (ELEM IN VARCHAR2)
  PROCEDURE IsJSONElemAnInt (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2)
  IS
  BEGIN
       IF NOT (json_ext.is_integer(IN_JSON.get(ELEM))) THEN
           IN_ERRCODE  := 401;
           IF LENGTH(NVL(IN_ERRDESC, ' ')) < 200 THEN -- ASSUMING THE BELOW STRING IS ABOUT 50
                IN_ERRDESC := IN_ERRDESC ||'<br>' || ELEM || ' is not a valid integer<'||  IN_JSON.get(ELEM).get_string||'>';
           END IF;
       END IF;
  END;
  -- IsJSONElemAnInt (ELEM IN VARCHAR2)

  -- IsJSONElemANumber
  PROCEDURE IsJSONElemANumber (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2)
  IS
  BEGIN
       IF NOT (IN_JSON.get(ELEM).is_number) THEN
           IN_ERRCODE  := 401;
           IF LENGTH(NVL(IN_ERRDESC, ' ')) < 200 THEN -- ASSUMING THE BELOW STRING IS ABOUT 50
                IN_ERRDESC := IN_ERRDESC ||'<br>' || ELEM || ' is not a valid number<'||  IN_JSON.get(ELEM).get_string||'>';
           END IF;
       END IF;
  END;
  -- IsJSONElemANumber
-- IsJSONElemADate
  PROCEDURE IsJSONElemADate (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2)
  IS
  BEGIN

       IF NOT (json_ext.is_date(IN_JSON.get(ELEM))) THEN
           IN_ERRCODE  := 401;
           IF LENGTH(NVL(IN_ERRDESC, ' ')) < 200 THEN -- ASSUMING THE BELOW STRING IS ABOUT 50
                IN_ERRDESC := IN_ERRDESC ||'<br>' || ELEM || ' is not a valid Date<'||  IN_JSON.get(ELEM).get_string||'>';
           END IF;
       END IF;
  END;
  -- IsJSONElemADate

  -- IsJSONElemABool (ELEM IN VARCHAR2)
  PROCEDURE IsJSONElemABool (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2)
  IS
  BEGIN
       IF NOT (IN_JSON.get(ELEM).is_bool) THEN
           IN_ERRCODE  := 401;
           IF LENGTH(NVL(IN_ERRDESC, ' ')) < 200 THEN -- ASSUMING THE BELOW STRING IS ABOUT 50
                IN_ERRDESC := IN_ERRDESC ||' ' || ELEM || ' is not a valid true/false value <'||  IN_JSON.get(ELEM).get_string||'>';
           END IF;
       END IF;
  END;
  -- IsJSONElemABool (ELEM IN VARCHAR2)

PROCEDURE LValidateValue (PASSVALIDATETYPE IN VarChar, PASSVALIDATEFORMAT IN Varchar, LAllowNull IN Boolean, PASSVALIDATEVALUE IN Varchar, CallingProcName IN Varchar, CallingParamName IN Varchar, LIsValid IN OUT Boolean, EC IN OUT INTEGER, ED IN OUT Varchar2) IS
   vTestValidInteger integer;
Begin
   --rough and incomplete equivalent of paradox CheckInput()
   --eg params   'DATE', 'CCYYMMDD', False, EF, LDateIsValid, EC, ED   
   if PASSVALIDATETYPE <> 'DATE' Then
      EC := 900;
      ED := 'Unknown type passed to LValidateValue:' || PASSVALIDATETYPE;
   else
      if PASSVALIDATEFORMAT <> 'CCYYMMDD' Then
         EC := 901;
         ED := 'Bad format passed to LValidateValue:' || PASSVALIDATEFORMAT;
      end if;
   end if;
   
   IF EC = 0 THEN
      if PASSVALIDATETYPE = 'DATE' AND PASSVALIDATEFORMAT = 'CCYYMMDD' Then
         if PASSVALIDATEVALUE IS NULL AND LAllowNull = False Then
            EC := 902;
            ED := 'Null Date passed to LValidateValue: (Cannot be Null)';
         end if;
      end if;
   end if;
   
   IF EC = 0 THEN
      if PASSVALIDATEVALUE IS NOT NULL Then
         if PASSVALIDATETYPE = 'DATE' AND PASSVALIDATEFORMAT = 'CCYYMMDD' Then
            if Length(PASSVALIDATEVALUE) <> 8 Then
               EC := 903;
               ED := 'Bad Date passed to LValidateValue. Expecting ' || PASSVALIDATEFORMAT || ' got ' || PASSVALIDATEVALUE ;
            end If;
            
            IF EC = 0 THEN 
               Begin
                  select Cast(PASSVALIDATEVALUE as integer) into vTestValidInteger From Dual;
                  --EC := 904;
               EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                      EC :=    905;
                      ED := 'Bad Date passed to LValidateValue. Expecting ' || PASSVALIDATEFORMAT || ' got ' || PASSVALIDATEVALUE ;        
                   WHEN OTHERS THEN
                          EC := 906;
                          ED := 'Bad Date passed to LValidateValue. Expecting ' || PASSVALIDATEFORMAT || ' got ' || PASSVALIDATEVALUE ;
               end;
            end if;
            
         end if;
      end if;   
   end if; 
   
   IF EC <> 0 THEN
      ED := ED || '  [Procedure: ' || CallingProcName || ';  Parameter: ' || CallingParamName || ']';    --CallingProcName IN Varchar, CallingParamName
   end if;
   
end;

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
PROCEDURE HandleOpStr (PASSOPSTR IN VARCHAR2 DEFAULT NULL, CONCATRESULTVAR IN OUT VARCHAR2) IS
  --Handle Output String: if browser output HTP, else string. Store built String for logging.
  --Steve Rimen 15/07/2013
  --
  DebugMode Boolean := false; --True = messages in SQL Developer message window. False = Test from browser.
  stTmp VarChar(2000) := '';
  strTotLen VarChar(10) := '';
  TmpTotResultStrLength integer := 0;
BEGIN

  --You must use this method if you want to see the return value out on devicelog.LogReturnStr.
  --declare...    ConCatResultVar 			VARCHAR(2000)  := '';
  --in a procedure, replace instances of...
  --HTP.P('"blah blah stome string": '|| somevar || ',');
  --...with...
  --HandleOPStr('"blah blah stome string": '|| somevar || ',', ConCatResultVar);
  -- at the end...
  -- HANDHELDLOG (V_MachineID, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar ) ;

  --Check if we are debbugging, and if we are, dont do this line...
  IF DebugMode THEN
     dbms_output.put_line(PASSOPSTR);
  ELSE   
     HTP.P(PASSOPSTR);
  END IF;
  
  if ConCatResultVar IS NULL THEN
     ConCatResultVar := ' ';
  end if;
  
  TmpTotResultStrLength := TO_NUMBER(Length(ConCatResultVar) + Length(Rtrim(PASSOPSTR)));
  --CAST(123 As Varchar(10))
  --strTotLen := CAST(TmpTotResultStrLength As Varchar(10));
  strTotLen := CAST(TmpTotResultStrLength As Varchar);
  
  
  stTmp := strTotLen || '.' || PASSOPSTR || Length(Rtrim(PASSOPSTR)  );
  dbms_output.put_line(stTmp);
  
  --if Length(Rtrim(ConCatResultVar)) + Length(Rtrim(PASSOPSTR)) < 2000 then
  if TmpTotResultStrLength < 2000 THEN
     ConCatResultVar := ConCatResultVar || PASSOPSTR;
  end If;   
END;

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
PROCEDURE HANDHELDLOG (DEVICEID IN VARCHAR2 DEFAULT NULL, PROCNAME IN VARCHAR2 DEFAULT NULL, PARAMETERS IN VARCHAR2 DEFAULT NULL, 
   ERRORINT IN INTEGER DEFAULT 0, ERRORSTR IN VARCHAR2 DEFAULT NULL, PASSRESULTSTR  IN VARCHAR2 DEFAULT NULL   --) IS
   , PASSLOGONNAME IN VARCHAR2 DEFAULT NULL) IS
     EC INTEGER := 0 ;          -- ERROR CODE
     ED VARCHAR2(255) := '';    -- ERROR DESCRIPTION

     V_NXT_LOGRECNO      DEVICELOG.LOGRECNO%TYPE;
     V_MachineID         DEVICELOG.DEVID%TYPE;
     VarResultToWrite    VARCHAR(5000)  := '';

  BEGIN
	 --Log the input from the device.
	 --This is a first version which will need refining TV 3Jul13
	 -- Get the next key value
     BEGIN
        V_NXT_LOGRECNO := HANDHELD_DEVICELOG_LOGRECNO.NEXTVAL;
     EXCEPTION
        WHEN OTHERS THEN
             EC := 1;
             ED := 'INVALID DEVICE SEQ NO ';
     END;
     
     --??Determine here wither to log the result based on PROCNAME AND ...user (at some point in the future)
     
	 -- Write the log record
	 IF EC = 0 THEN --This is the error code for this proc, not the one passed in (ERRORINT).
     BEGIN
     
        IF ERRORINT <> 0 THEN 
        BEGIN
           VarResultToWrite := SUBSTR(ERRORSTR, 1,2000);
        END;   
        ELSE
        BEGIN
           VarResultToWrite := SUBSTR(PASSRESULTSTR, 1,2000); --PASSRESULTSTR;
        END;
        END IF;
     
        INSERT INTO DEVICELOG (LOGRECNO, DEVID, LOGDATE, LOGPROCEDURENAME, LOGPARMS, LOGRETURNINT, LOGRETURNSTR)
           VALUES(
                  --V_NXT_LOGRECNO, DEVICEID, SYSDATE(), PROCNAME, SUBSTR(PARAMETERS, 1, 2000), ERRORINT, SUBSTR(ERRORSTR, 1,2000)
                  --V_NXT_LOGRECNO, DEVICEID, SYSDATE(), PROCNAME, SUBSTR(PARAMETERS, 1, 2000), ERRORINT, VarResultToWrite                  
                  V_NXT_LOGRECNO, DEVICEID, SYSDATE, PROCNAME, SUBSTR(PARAMETERS, 1, 2000), ERRORINT, VarResultToWrite                  
                 );
        COMMIT;
        EXCEPTION
           WHEN OTHERS THEN
              EC :=  2;
              ED := 'Unable to Execute Sql to INSERT INTO DEVICELOG ='||  SQLERRM;
              
              --Try this (so can see future errors quicker.
              Begin 
                INSERT INTO DEVICELOG (LOGRECNO, LOGDATE, LOGPROCEDURENAME, LOGPARMS) Values(V_NXT_LOGRECNO, SYSDATE, PROCNAME, 'Error Writing Log!!!');
                Commit;
              EXCEPTION
              WHEN OTHERS THEN
                 EC :=  3;
                 ED := 'Unable to update DEVICELOG: '||  SQLERRM;
              END;
              
        END;
        
        if PASSLOGONNAME IS NOT NULL Then
           Begin
                   update DEVICELOG set USERNAME = Rtrim(PASSLOGONNAME)  where LOGRECNO = V_NXT_LOGRECNO;
           EXCEPTION
              WHEN OTHERS THEN
                 EC :=  3;
                 ED := 'Unable to update DEVICELOG: '||  SQLERRM;
           END;        
        end if;
        
     END IF;
  END; -- HandHeldLog



--------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
PROCEDURE UserLogonValidate (UL IN Varchar2 default null, EC IN OUT INTEGER, ED IN OUT Varchar2) IS
  --Validate the User Logon
  --Steve Rimen 16/07/2013
  --if Validation fails, the results are returned in EC and ED
V_LOGONNO LOGONS.LOGONNO%TYPE;
V_user_can_see_all_supp LOGONS.CANSEEALLSUPS%TYPE := 0 ;   -- THIS WILL BE ZERO IF THE USER IS NOT ALLOWED TO VIEW ALL SUPPLIERS REGARDLESS OF
BEGIN
   --HTP.P('BBB');
   
   -- CHECK THE DATABASE to see if USER EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        IF UL IS NULL THEN
            EC := 401;
            ED := 'You must enter a user logon name (UL)';
        END IF;
     END IF;
   
     -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if LOGONS EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
            SELECT LOGONNO, CANSEEALLSUPS INTO V_LOGONNO, V_user_can_see_all_supp
            FROM LOGONS
            WHERE TRIM(LOGONNAME) = UPPER(UL)
            AND AVAILTOMKTHANDHELD = 1
            AND ACTIVE = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    402;
                ED := UL || ' is not a registered active logon';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain LOGONS information for '|| UL || ' SqlErrM='||  SQLERRM;
        END;
     END IF;
   
End;
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
PROCEDURE MachineIDValidate (MI IN Varchar2 default null, EC IN OUT INTEGER, ED IN OUT Varchar2) IS
  --Validate the Machine ID
  --Steve Rimen 16/07/2013
  --if Validation fails, the results are returned in EC and ED
  
  VMI DEVICENAME.DEVID%TYPE;
  VDEVNAME DEVICENAME.DEVNAME%TYPE := ''; -- DEVICE NAME FROM QUERY
BEGIN
  --HTP.P('BBB');
  
   IF MI is null then
	 	EC := 100;
		ED := 'You must enter a machine name (MI)';
	 END IF;
   
    
   -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT  DEVNAME
           INTO VDEVNAME
           FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;
     
     /*IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
     END IF;*/

END;


--------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
PROCEDURE GetLogonNo (UL IN Varchar2 default null, LN IN OUT Integer, EC IN OUT INTEGER, ED IN OUT Varchar2) IS
BEGIN
   --HTP.P('GetLogonNo');
   
   -- CHECK THE DATABASE to see if USER EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        IF UL IS NULL THEN
            EC := 401;
            ED := 'No logon name passed to GetLogonNo()';
        END IF;
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if LOGONS EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
            SELECT LOGONNO INTO LN
            FROM LOGONS
            WHERE TRIM(LOGONNAME) = TRIM(UPPER(UL))    --WHERE TRIM(LOGONNAME) = TRIM(UPPER(V_LogOnName))
            AND AVAILTOMKTHANDHELD = 1
            AND ACTIVE = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    402;
                ED := UL || ' is not a registered active logon. GetLogonNo()';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain LOGONS information for GetLogonNo()'|| UL || ' SqlErrM='||  SQLERRM;
        END;
     END IF;
   
END;

--------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
PROCEDURE SalesOfficeValidate (SO IN Integer default null, UL IN Varchar2 default null, EC IN OUT INTEGER, ED IN OUT Varchar2) IS
  --Validate the Sales Office
  --Steve Rimen 17/07/2013
  --if Validation fails, the results are returned in EC and ED
  V_SALOFFNO SALOFFNO.SALOFFNO%TYPE  := -1;
  V_NOOF NUMBER(5) ;
  V_LOGONNO LOGONS.LOGONNO%TYPE  := -1;
BEGIN
   --HTP.P('BBB');
   
   IF SO is null then
	 	EC := 100;
		ED := 'You must enter a Sales Office (SO)';
	 END IF;
   
   IF EC = 0 THEN
     --need to get the logon number for the logonName
     GetLogonNo(UL, V_LOGONNO, EC, ED);
   end if;  
   
   -- CHECK THE DATABASE to see if SALESOFFICE EXISTS AND IS ALLOWED FOR THIS USER
     IF EC = 0 THEN
        V_SALOFFNO := -1;
        IF SO > 0 THEN
            BEGIN
                SELECT COUNT(*) INTO V_NOOF FROM SALOFFNO
                WHERE SALOFFNO = SO
                AND (EXISTS (SELECT * FROM LOGTOSALOFF WHERE LOGTOSALOFF.SALOFFNO = -32000 AND LOGONNO = V_LOGONNO)
                     OR  EXISTS (SELECT * FROM LOGTOSALOFF WHERE LOGTOSALOFF.SALOFFNO =saloffno.saloffno AND LOGONNO = V_LOGONNO));

                IF V_NOOF <> 1 THEN
                    EC :=    403;
                    ED := SO || ' is not a valid Sales Office';
                ELSE
                    V_SALOFFNO := SO;
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=    403;
                    ED := SO || ' is not a valid Sales Office';

                WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to valid Sales Office information for '|| SO || ' SqlErrM='||  SQLERRM;
            END;
        END IF;
     END IF;
   
End;
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------



PROCEDURE StockLocationValidate (SL IN Integer default null, EC IN OUT INTEGER, ED IN OUT Varchar2) IS
  --Validate the Stock Location
  --Steve Rimen 17/07/2013
  --if Validation fails, the results are returned in EC and ED
  V_NOOF NUMBER(5) ;
  V_StcRecNo          MKTHHELD_ORDHDR.STCRECNO%TYPE;
BEGIN
   --HTP.P('BBB');
  
       IF EC = 0 THEN
        IF NVL(SL, 0) <= 0 THEN
            EC := 404;
            ED := 'You must enter a valid Stock Location (SL)';
        ELSE
            V_STCRECNO := SL;
        END IF;
     END IF;

-- CHECK THE DATABASE to see if STOCK LOCATION EXISTS
     IF EC = 0 THEN
        V_NOOF := 0;
            BEGIN
                SELECT COUNT(*) INTO V_NOOF FROM STOCLOC
                WHERE STCRECNO = V_STCRECNO ;

                IF V_NOOF <> 1 THEN
                    EC :=    404;
                    ED := V_STCRECNO || ' is not a valid Stock Location';
                END IF;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=    404;
                    ED := V_STCRECNO || ' is not a valid Stock Location';

                WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to validate Stock Location information for '|| V_STCRECNO || ' SqlErrM='||  SQLERRM;


        END;
    END IF;   
End;

PROCEDURE LConvertValue (PASSPROCNAME IN VarChar, TYP IN Varchar, PassValInt IN Number, PassValStr IN VarChar, RetVal IN OUT Varchar, EC IN OUT INTEGER, ED IN OUT Varchar2) is
   Sttmp VARCHAR(100);
   NumFmt Varchar(30) := '0D99';
BEGIN
  RetVal := -1;
  --I cant work out the number formatting for returning a leading zero, when float val is between 1 and zero AND keeping the size; eg 0.54 auto converts to .54.
  --This is NOT an exact equivalent for the PDX lconvertvalue
  
  if TYP != 'FLOAT' then
     EC := 904;
     ED := 'Unhandled TYPE passed to LConvertValue() from ' || 'PASSPROCNAME' || ' = ' || TYP;
  end if;
  
  if EC = 0 Then 
     if TYP = 'FLOAT' then
        if PassValInt is NULL then
           EC := 905;
           ED := 'NULL Number passed to LConvertValue() from ' || PASSPROCNAME;
        end if;
       
        --VDFLTNUMBER := 1234.54;
        --Sttmp := TO_CHAR(VDFLTNUMBER, '0D99');
       
        if EC = 0 Then
           if PassValInt > 1.0 OR PassValInt < 0.0001 Then --lunacy
              --RetVal := 555.5;
             -- RetVal := RTrim( 0 || TO_CHAR(PassValInt, Varchar(10)));
             Sttmp := TO_CHAR(PassValInt);
             RetVal := Sttmp;
           else
              --RetVal := 555.53;
              --RetVal := RTrim(TO_CHAR(PassValInt, Varchar(10)));
              --RetVal := TO_CHAR(PassValInt, Varchar(10));
              --RetVal := Cast(PassValInt, '0D99');
              --Sttmp := TO_CHAR(PassValInt, '0D99');
              Sttmp := TO_CHAR(PassValInt, NumFmt);  --Sttmp := TO_CHAR(PassValInt, NumFmt);
              RetVal := Sttmp; 
              --Sttmp := TO_CHAR(VDFLTNUMBER, '0D99');
           end If;
        end if;
    
     end if;
  end if;  
end;

PROCEDURE GetHandHeldPassword(UL IN Varchar2, PW IN OUT Varchar2, EC IN OUT INTEGER, ED IN OUT Varchar2) IS
vHANDHELDPASSWORD LOGONS.HANDHELDPASSWORD%TYPE;
BEGIN

   Begin
		   Select HANDHELDPASSWORD
		   INTO vHANDHELDPASSWORD
		   from logons
		   Where UPPER(Rtrim(LOGONNAME)) = UPPER(UL)
		   AND AVAILTOMKTHANDHELD = 1;

       EXCEPTION
           WHEN NO_DATA_FOUND THEN
		        EC := 811;
		        ED := UL || ' is not a valid user';

		   WHEN OTHERS THEN
		      EC := 812;
          ED := 'Unable to Execute Sql to Obtain user id for '|| UL || ' SqlErrM='||  SQLERRM;
        END;
        
   if EC = 0 then
      PW := vHANDHELDPASSWORD;
   end if;
END;


----------------------------------------------------------------------
PROCEDURE DOWNLOAD_ORDER (MI IN Varchar2 default null,      --Machine ID
                          UL IN Varchar2 default null,      --User Logon
                          EH IN Varchar2 default null,      --Encryped Hash Password + ticket MD5
                          SO IN INTEGER default 0,          --Sales Office
                          SL IN INTEGER default 0,          --Stock Location
                          TB IN INTEGER default 0,           --Ticket Number
                          BT IN INTEGER default 0) IS        --Ticket Book (Optional)
    --Steve Rimen 15/07/2013  --Allows a user to input a ticket and return it.
    --ticket book is NOT mandatory - this is to allow searching tickets in old ticket books.
    --This will return 1 DELHED and x DELDETS	 
	-- TV changed some string outputs to number, corrected TotalNetPrice calculation for multi-lines
  EC Integer := 0 ; -- Error Code
  ED VarChar2(255) := ''; -- Error Description
  PROCNAME VARCHAR(40) := 'DOWNLOAD_ORDER';
  ConCatParamsVar 			VARCHAR(500);
  ConCatResultVar 			VARCHAR(2000)  := '';

  V_LOOPCOUNT integer := 0;
  TmpDateStr VARCHAR(8)  := '';
  V_NOOF NUMBER(5) ;
  Sttmp VARCHAR(100);
  RetVal Varchar(50) := 0;
  V_TktBookNO number := NULL;

  v_PasswordToChk VarChar2(255);
  vHANDHELDPASSWORD LOGONS.HANDHELDPASSWORD%TYPE;

  VDFLTNUMBER FLOAT; -- DELPRICE%DELPRICE := '';
  V_MD5PASSWORD1	 VarChar2(255);

  V_DevRecNo integer := 0;
  
  vStatusDescription      LOOKUPS.LKUPDESC%TYPE;
  vStatusSi               LOOKUPS.LKUPNO%TYPE;

  --CURSOR DNLDORDER_CURSOR (V_TN NUMBER) IS
  CURSOR DNLDORDER_CURSOR  IS

  --select * from TKTNT where TKTNT.TNTNO = 621633;

        select deldet.delrecno, Orders.OrdSmnNo, nvl(DelHed.DlvDltRecNo,0) as DlvDltRecNo,
             (Select DeliveryCondition from DlvType Where DlvType.DltRecNo = DelHed.DlvDltRecNo) DeliveryCondition,
             DelHed.DlvSalOffNo, DelHed.DlvStkLoc,
             --BSDL_PKAGE_ACCOUNTS.GETACCCODE(Orders.ActCstCode, DelHed.DlvSalOffNo) ClaAccCode,
             Orders.ActCstCode,
           tktnt.TntNo, tktnt.TNTTBKRECNO, DelHed.DlvDelDate, --TO_CHAR(DelHed.DlvDelDate, 'YYYYMMDD'),
           (Select Max(deldet.delrecno)  From Deldet Where deldet.DelDlvOrdNo = delhed.DlvOrdNo) MaxDelRecNo,
           (Select DelComm from delComms Where delComms.DelCommTypRecNo = DelHed.DlvOrdNo  AND delComms.DelTyp = 3) DelComm,
           (Select Sum(Nvl(DelPrice.DelNettValue, 0)) From DelPrice Where DelPrice.DprDelRecNo in (Select Delrecno from DelDet where deldlvordno = delhed.DlvOrdNo)) DlvNettValue,
           (Select Sum(Nvl(DelPrice.DelNettValue, 0)) + Sum(Nvl(DelPrice.DelVatValue, 0)) From DelPrice Where DelPrice.DprDelRecNo in (Select Delrecno from DelDet where deldlvordno = delhed.DlvOrdNo)) DlvGrossValue,
           (select SUM(DelVatValue - ROUND(DelNettValue * NVL(DelVatRate2, 0) / 100.0, 2)) From DelPrice, deldet Where DelPrice.DprDelRecNo = DelDet.DelRecNo and deldet.DelDlvOrdNo = delhed.DlvOrdNo)  DlvVatExtended,
           (select SUM(ROUND(DelNettValue * NVL(DelVatRate2, 0) / 100.0, 2)) From DelPrice, deldet Where DelPrice.DprDelRecNo = DelDet.DelRecNo and deldet.DelDlvOrdNo = delhed.DlvOrdNo)  DlvVat2Extended,
           (select Max(DelAudRecNo) From delaudit Where DelAudDelRecNo = (Select Max(DD.DelRecNo) From DelDet DD Where DD.DELDLVORDNO = delhed.DlvOrdNo)) Max_DelAudRecNo,
           --'Detail' As Details,
           (select Cast( SUM(DelVatValue - ROUND(DelNettValue * NVL(DelVatRate2, 0) / 100.0, 2)) As number) From DelPrice Where DelPrice.DprDelRecNo = DelDet.DelRecNo)  Vat1Extended,
           (select SUM(ROUND(DelNettValue * NVL(DelVatRate2, 0) / 100.0, 2))               From DelPrice Where DelPrice.DprDelRecNo = DelDet.DelRecNo)  Vat2Extended,
           (select Nvl(DalAllocNo, 0) from deltoall Where DalRecordType = 1 AND DalTypeRecNo = DelDet.DelRecNo) AllocNo,
           --'XX' as lineNo, --	   RowNum cannot be relied on.
           DelPrcPrdNo,
           (Select DelComm from delComms Where delComms.DelCommTypRecNo = DelDet.DelrecNo  AND delComms.DelTyp = 4) DelDetComm,
           DelQty, DelQtyPer, InlineQTYPER.LkUpDesc, (select Nvl(DelPrice.DelPrice, 0) From DelPrice Where DelPrice.DprDelRecNo = DelDet.DelRecNo) UnitPrice,
           (select NVL2(DelPrice.DelFreeOfChg, 'false', 'true') From DelPrice Where DelPrice.DprDelRecNo = DelDet.DelRecNo) Foc,
           (select DelNettValue From DelPrice Where DelPrice.DprDelRecNo = DelDet.DelRecNo) DelNettValue,
           (select DelPrice.DelNettValue + DelVatValue From DelPrice Where DelPrice.DprDelRecNo = DelDet.DelRecNo)  GrossExtendedDet
      FROM  tktnt, tktbk, Orders, delhed, DelDet,
            (select LkUpNo, LkUpDesc from lookups
                  Where LkUpTable = 'MARKETDELDETS'
                  AND LkUpFieldName = 'QTYPER'
                  order by LkUpNo) InlineQTYPER
            where tktnt.TNTTBKRECNO = tktbk.TBKRECNO
            AND tktnt.TNTDlvOrdNo = delhed.DLVORDNO
            AND Orders.OrdRecNo = DelHed.DlvOrdRecNo
            AND DelHed.DlvOrdNo = DelDet.DelDlvOrdNo
            AND DelDet.DelQtyPer = InlineQTYPER.LkUpNo
            --AND TKTBK.TBKCOMPLETE = 0 -- Ticket book is open
            --AND TKTBK.TBKSALOFFNO = 2 -- Sales office
            --AND TKTBK.TBKSTCLOC = 2   -- Stock Location
            AND TKTNT.TNTNO = TB -- 621633  -- Ticket Number
            -- AND TKTNT.TNTTBKRECNO = 2
            --AND (TKTBK.TBKCOMPLETE = 0 OR TKTBK.TBKCOMPLETE > 0 AND  TKTNT.TNTTBKRECNO = V_TktBookNO) --open book, or specified number of closed book

            AND (    (TKTBK.TBKCOMPLETE = 0 AND NVL(BT, 0) = 0 ) --tktbk passed is Open, no tktbk passed (optional variable)
                  OR (TKTBK.TBKCOMPLETE = 0 AND NVL(BT, 0) = TKTNT.TNTTBKRECNO ) --tktbk passed is Open, tktbk passed anyway
			            OR (TKTBK.TBKCOMPLETE > 0 AND NVL(BT, 0) = TKTNT.TNTTBKRECNO )) --tktbk passed is Closed

      order by DelDet.delrecno;


BEGIN
   --MachineIDValidate(MI, EC, ED);
   MachineIDValidate(MI, EC, ED, V_DevRecNo);  --  V_DevRecNo integer := 0;

   IF EC = 0 THEN
      UserLogonValidate(UL, EC, ED);
   end if;

   IF EC = 0 THEN
      SalesOfficeValidate(SO, UL, EC, ED);  -- check DeviceToSalOff?
   end if;

   --StockLocationValidate()
   --this could be tricky as there are multiple rules and more may be added.
   --if they are all catered for the proced
   -- will be too inflexible.
   --so 'just' pass in a dynarray.
   --would have to be only locations for the sales office. (SofToStcloc)
   IF EC = 0 THEN
      StockLocationValidate(SL, EC, ED);  -- check DeviceToSalOff?
   end if;

   IF EC = 0 THEN
      IF NVL(TB, 0) <= 0 THEN
         EC := 901;
         ED := 'Bad Ticket Number Specified';
      END IF;
   END IF;

   --EH Encrypted Hash (handheld password + ticket number)

   IF EC = 0 THEN
      IF EH is null then
		     EC := 907;
		     ED := 'No Hash Total parameter specified';
      end if;
   end if;

   IF EC = 0 THEN
      GetHandHeldPassword(UL, vHANDHELDPASSWORD, EC, ED);
     -- HTP.P(vHANDHELDPASSWORD);
   end if;

   IF EC = 0 THEN
      v_PasswordToChk := rtrim(vHANDHELDPASSWORD) || TB;
      --v_PasswordToChk := 'A' || TN;

      V_MD5PASSWORD1 := DBMS_CRYPTO.HASH (src => utl_i18n.string_to_raw(v_PasswordToChk), typ => DBMS_CRYPTO.hash_MD5 );

      if EH <> '666' Then --MUST take out after testing!!!!!!!!!!!!
         if V_MD5PASSWORD1 <> EH then
            EC := 909;
            ED := 'Hash total does not equal encrypted password . Passed: ' || EH || '. .>>' || V_MD5PASSWORD1 || '<<';        --V_MD5PASSWORD1
         end if;
      end if;

   end if;

  if BT > 0 Then  --optional parameter, pass in tktbkno for searching closed books, or just ticket for current book
     V_TktBookNO := BT;
  else
     V_TktBookNO := 0;
  end if;


   --do another check - dont allow edit of ticket if other edit is already pending.  
   --(Problem - we need to do this check first so that we dont output the info before the error)
   if EC = 0 Then
      Begin
                     --select mkthheld_OrdHdr.*, StatusDescs.LkUpDesc StatusDescription  
                     SELECT StatusDescs.LkUpNo, StatusDescs.LkUpDesc StatusDescription  
                     INTO vStatusSi, vStatusDescription
                      from mkthheld_OrdHdr, (select LkUpNo, LkUpDesc from lookups Where LKUPTABLE = 'MKTHHELD_ORDHDR' AND LKUPFIELDNAME = 'STATUS' order by LkUpNo ) StatusDescs 
                      where tntno = TB
                      AND tnttBkRecNo = BT
                      AND  mkthheld_OrdHdr.Status = StatusDescs.LkUpNo;
           EXCEPTION
               WHEN NO_DATA_FOUND THEN	
                  EC := 903;
		              ED := ED || ' \n <No Uploaded ticket found (2)>';

               WHEN OTHERS THEN		 
                  EC := 904;
                  ED :=  ED || '\n Unable to Execute Sql to find uploaded ticket '|| UL || ' SqlErrM='||  SQLERRM;
      END;
      if EC = 0 Then
                  if vStatusSi = 2 Then
                      EC := 905;
                      ED :=  'Ticket ' || TB || ' is being amended;  Please wait for 10 seconds before attempting to edit.';
                  end if;
      end if;
   end if;



  V_LOOPCOUNT := 0;

  IF EC = 0 THEN
    FOR V_DNLDORDER_RECORD IN DNLDORDER_CURSOR  LOOP   --  FOR V_STOCK_RECORD IN DNLDORDER_CURSOR (V_STCRECNO)  LOOP

      --SELECT COUNT(*) INTO V_NOOF FROM SALOFFNO
      --SELECT COUNT(*) INTO V_NOOF FROM DNLDORDER_CURSOR;
      --V_NOOF := DNLDORDER_CURSOR.Count;
     -- V_NOOF := DNLDORDER_CURSOR%ROWCOUNT;
      --V_NOOF := V_DNLDORDER_RECORD.tot_rows; --eot()

     
      --IF NVL(V_DNLDORDER_RECORD.DelRecNo,0) = 0 THEN
      --   EC := 902;
      --   ED := 'No Results for Ticket Number ' || TN;
      --END IF;

      IF EC = 0 THEN
         IF V_LOOPCOUNT = 0 THEN  --Output Order Header
            TmpDateStr := TO_CHAR(V_DNLDORDER_RECORD.DlvDelDate, 'YYYYMMDD'); --TO_DATE(ATRPSTDATE, 'DD/MM/YYYY')
            HandleOPStr('{"SN": '|| (V_DNLDORDER_RECORD.OrdSmnNo) || ',', ConCatResultVar);                 --SN Salesman
            HandleOPStr('"ST": '|| (V_DNLDORDER_RECORD.DlvDltRecNo) || ',', ConCatResultVar);         --ST Sale Type
            HandleOPStr('"SO": '|| (V_DNLDORDER_RECORD.DlvSalOffNo) || ',', ConCatResultVar);               --SO Sales Office
            HandleOPStr('"SL": '|| (V_DNLDORDER_RECORD.DlvStkLoc) || ',', ConCatResultVar);                 --SL Stock Location
            HandleOPStr('"CL": '|| (V_DNLDORDER_RECORD.ActCstCode) || ',', ConCatResultVar);                --CL Clarecno
            HandleOPStr('"TN": '|| (V_DNLDORDER_RECORD.TntNo) || ',', ConCatResultVar);                     --TN Ticket Number
            HandleOPStr('"TB": '|| (V_DNLDORDER_RECORD.TNTTBKRECNO) || ',', ConCatResultVar);               --TB Ticket Book
            HandleOPStr('"OD": "'|| TmpDateStr || '",', ConCatResultVar);                                     --OD Order Date
            HandleOPStr('"OC": "'|| (V_DNLDORDER_RECORD.DelComm) || '",', ConCatResultVar);                   --OC Order Comment
            HandleOPStr('"NT": '|| (V_DNLDORDER_RECORD.DlvNettValue) || ',', ConCatResultVar);              --NT Nett Total
            HandleOPStr('"V1": '|| (V_DNLDORDER_RECORD.DlvVatExtended) || ',', ConCatResultVar);            --V1 Vat 1 Total
            HandleOPStr('"V2": '|| (V_DNLDORDER_RECORD.DlvVat2Extended) || ',', ConCatResultVar);           --V2 Vat 2 Total
            HandleOPStr('"GT": '|| (V_DNLDORDER_RECORD.DlvGrossValue) || ',', ConCatResultVar);             --GT Gross Total
            HandleOPStr('"LA": '|| (V_DNLDORDER_RECORD.Max_DelAudRecNo) || ',', ConCatResultVar);           --LA Last Audit Number
            HandleOPStr('"LINES":[', ConCatResultVar);
         END IF;

         HandleOPStr('{"LN":'|| (V_LOOPCOUNT + 1) || ',', ConCatResultVar);                         --LN Line Number
         HandleOPStr('"PR": '|| (V_DNLDORDER_RECORD.DelPrcPrdNo) || ',', ConCatResultVar);      --PR Product Internal Code
         HandleOPStr('"LC": "'|| (V_DNLDORDER_RECORD.DelDetComm) || '",', ConCatResultVar);     --LC Line Comment
         HandleOPStr('"LQ": '|| (V_DNLDORDER_RECORD.DelQty) || ',', ConCatResultVar);           --LQ Line Qty
         HandleOPStr('"UM": '|| (V_DNLDORDER_RECORD.DelQtyPer) || ',', ConCatResultVar);        --UM Unit of Measure
         HandleOPStr('"PU": '|| (V_DNLDORDER_RECORD.UnitPrice) || ',', ConCatResultVar);        --PU Price per Unit
         HandleOPStr('"FC": '|| (V_DNLDORDER_RECORD.Foc) || ',', ConCatResultVar);              --FC Free of Charge
         HandleOPStr('"EP": '|| (V_DNLDORDER_RECORD.DelNettValue) || ',', ConCatResultVar);     --EP Extended Price
         HandleOPStr('"AN": '|| (NVL(V_DNLDORDER_RECORD.AllocNo, 0)) || ',', ConCatResultVar);          --AN Allocation Number
         LConvertValue (PROCNAME, 'FLOAT', V_DNLDORDER_RECORD.Vat1Extended, NULL, Sttmp, EC, ED);  -- 0.5 becomes .5 (JSON error)
         HandleOPStr('"V1": '|| (Sttmp) || ',', ConCatResultVar);     --V1 Vat 1 Extended
         LConvertValue (PROCNAME, 'FLOAT', V_DNLDORDER_RECORD.Vat2Extended, NULL, Sttmp, EC, ED);
         HandleOPStr('"V2": '|| (sttmp) || ',', ConCatResultVar);     --V2 Vat 2 Extended
         HandleOPStr('"GP": '|| (V_DNLDORDER_RECORD.GrossExtendedDet) || '}', ConCatResultVar); --GP Gross Extended Price

         IF V_DNLDORDER_RECORD.DelRecNo < V_DNLDORDER_RECORD.MaxDelRecNo THEN  --at eot()
            HandleOPStr(',' , ConCatResultVar);  --end of current detail seperator.
         ELSE
            HandleOPStr(']}' , ConCatResultVar);
         END IF;

      END IF;
	  
	  --TV Linecount begins at Zero, so put here 
      V_LOOPCOUNT := V_LOOPCOUNT + 1;

     END LOOP;
   END IF;

   IF EC = 0 THEN
     --ONLY DO THIS CHECK IF NO DATA FOUND!!!
       IF V_LOOPCOUNT = 0 THEN
          EC := 902;
          ED := 'No Results for Ticket Number ' || TB;
          if Nvl(BT, 0) > 0 then
             ED := ED || ' / Ticket Book ' || BT  || '\n(Not Created in Live System)' ;
          end if;
          
          --if this happens lets point them in the right direction          
           Begin
                     --select mkthheld_OrdHdr.*, StatusDescs.LkUpDesc StatusDescription  
                     SELECT StatusDescs.LkUpNo, StatusDescs.LkUpDesc StatusDescription  
                     INTO vStatusSi, vStatusDescription
                      from mkthheld_OrdHdr, (select LkUpNo, LkUpDesc from lookups Where LKUPTABLE = 'MKTHHELD_ORDHDR' AND LKUPFIELDNAME = 'STATUS' order by LkUpNo ) StatusDescs 
                      where tntno = TB
                      AND tnttBkRecNo = BT
                      AND  mkthheld_OrdHdr.Status = StatusDescs.LkUpNo;

           EXCEPTION
               WHEN NO_DATA_FOUND THEN	
                  EC := 903;
		              ED := ED || ' \n <No Uploaded ticket found>';

               WHEN OTHERS THEN		 
                  EC := 904;
                  ED :=  ED || '\n Unable to Execute Sql to find uploaded ticket '|| UL || ' SqlErrM='||  SQLERRM;
           END;
           
           if EC = 902 Then
              ED := ED || '  \n<Uploaded ticket status = ' || rtrim(vStatusDescription) || '>';
           end if;
           
           
          
          /*select mkthheld_OrdHdr.*, StatusDescs.LkUpDesc StatusDescription  
from mkthheld_OrdHdr, (select LkUpNo, LkUpDesc from lookups Where LKUPTABLE = 'MKTHHELD_ORDHDR' AND LKUPFIELDNAME = 'STATUS' order by LkUpNo ) StatusDescs 
where tntno = 637
AND tnttBkRecNo = 1997
AND  mkthheld_OrdHdr.Status = StatusDescs.LkUpNo*/
          
      END IF;
   END IF;
   
   
       
   

   --LOG THE TRANSACTION
   ConCatParamsVar := '?MI='|| MI || '.  UL=' ||UL || '.  SO= ' || SO || '.  SL=' || SL  || '.  TB(ticket number) = ' || TB || '.  BT(Book)= ' || BT ;
   
   
	 HANDHELDLOG (MI, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, UL ) ;
   --IF EC != 0 THEN        -- ERROR MESSAGE RETURNED TO SCREEN/INTERFACE
   IF EC > 0 THEN
     -- ConCatResultVar := ''; --clear the built string - the error takes precedence.
      HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);
   END IF;

END; -- END DOWNLOAD_ORDER


PROCEDURE SEARCH_ORDERS (MI IN Varchar2 default null,        --Machine ID
                          UL IN Varchar2 default null,      --User Logon
                          EH IN Varchar2 default null,      --Encryped Hash Password + ticket MD5
                          SO IN INTEGER default 0,          --Sales Office
                          SL IN INTEGER default 0,          --Stock Location
                          TB IN INTEGER default 0,          --Ticket Number (Optional)
                          SU IN varchar2 default null,      --Search User Name (Optional)
                          EF IN varchar2 default TO_CHAR (sysdate - 14, 'YYYYMMDD'),      --Search Date From (Optional)(YYYYMMDD)
                          ET IN varchar2 default TO_CHAR (sysdate + 14, 'YYYYMMDD'),      --Search Date To (Optional)(YYYYMMDD)
                          CL IN Integer default 0,          --Customer Number (Optional) 
                          PO IN Integer default 0,          --Lot Number, PO (Optional)
                          PR IN Integer default 0,          --Product (Optional)
                          SS IN Integer default 0,          --Search Status (Optional)
                          MR IN Integer default -1,         --Max Records (-1 = all)(Optional)
                          PS IN Varchar2 default null) IS   --Product Short Code.   

  PROCNAME VARCHAR(40) := 'SEARCH_ORDERS';
  ConCatParamsVar 			VARCHAR(5000) := '';
  ConCatResultVar 			VARCHAR(5000) := '';
  EC Integer := 0 ; -- Error Code
  ED VarChar2(255) := ''; -- Error Description
  DAYRANGEFORBLANKDATE Integer := 14; -- Number of days back to go if the 'From Date' (EF) is null

  RecCount Integer := 0;
  FirstRecord Boolean := True;
  SecondRecord Boolean := False;
  vEF VarChar2(10) := EF;	   
  vET VarChar2(10) := ET;	   
  vSU Logons.LogonName%Type := SU;
  TempDate Date := sysdate; 
  LDateIsValid Boolean;
  TransmittedCount Integer := 0;
  Sttmp Varchar(100) := '';
BEGIN
   -- Returns the headers for Entered tickets based on the parameters supplied
   -- BSDL 9973 TV 13Sep13
  
   MachineIDValidate(MI, EC, ED);

   IF EC = 0 THEN
      UserLogonValidate(UL, EC, ED);
   end if;

   IF EC = 0 THEN
      SalesOfficeValidate(SO, UL, EC, ED);  -- check DeviceToSalOff?
   end if;

   --StockLocationValidate()
   --this could be tricky as there are multiple rules and more may be added.
   --if they are all catered for the procedure will be too inflexible.
   --so 'just' pass in a dynarray.
   --would have to be only locations for the sales office. (SofToStcloc)
   IF EC = 0 THEN
      StockLocationValidate(SL, EC, ED);  -- check DeviceToSalOff?
   end if;

   IF EC = 0 THEN --validate the dates. never null because they have a default.
      LDateIsValid := False;
      LValidateValue ('DATE', 'CCYYMMDD', False, EF, PROCNAME, 'EF', LDateIsValid, EC, ED); 
   end If;
   
   IF EC = 0 THEN --validate the dates. never null because they have a default.
      LDateIsValid := False;
      LValidateValue ('DATE', 'CCYYMMDD', False, ET, PROCNAME, 'ET', LDateIsValid, EC, ED); 
   end If;

   IF EC = 0 THEN
      --From date validate
      if NVL(EF, 'null') = 'null' then
         -- if the from date is blank then make it 14 days ago 
         vEF := TO_CHAR (sysdate - DAYRANGEFORBLANKDATE, 'YYYYMMDD');
      else
         BEGIN
            TempDate := TO_DATE (vEF, 'YYYYMMDD');
            EXCEPTION
                WHEN OTHERS THEN
                    EC :=  1901;
                    ED := 'Date From is not a date (YYYYMMDD) <'||vEF||'>';
         END;
      End IF;
   END IF;
   		 
   IF EC = 0 THEN
      --To date validate
      if NVL(ET, 'null') = 'null' then
         -- if the to date is blank then make it 14 days in the future (should not pick up any more 
	     -- tickets unless there are post dated tickets raised, which is done in the current
		 -- paper system. 
         vET := TO_CHAR (sysdate + DAYRANGEFORBLANKDATE, 'YYYYMMDD');
      else
         BEGIN
            TempDate := TO_DATE (vET, 'YYYYMMDD');
            EXCEPTION
               WHEN OTHERS THEN
                  EC :=  1902;
                  ED := 'Date To is not a date (YYYYMMDD) <'||vET||'>';
         END;
      End IF;
   END IF;
	  
   
   IF EC = 0 THEN
      --open cursor
      EC := -1;
      
      DECLARE
      CURSOR SEARCH_CURSOR IS
           Select Count (*) OVER () as RecCount, TNTNO, TNTTBKRECNO, ActCstCode, OrdDate, DelComment, DlvOrdNo, TotValue, LogonName, UserName, SITicketStatus  from 
          (
          Select TKTNT.TNTNO, TKTNT.TNTTBKRECNO, Orders.ActCstCode, Orders.OrdDate, 
          (Select DelComm from DelComms where Delhed.DlvOrdNo = DelCommTypRecNo and DelTyp = 3) as DelComment,
           DelHed.DlvOrdNo,
          (Select Nvl(sum(Nvl(Delprice.DelNettValue, 0)),0) from Delprice, deldet where DelHed.DlvOrdNo = DelDet.DelDlvOrdNo and DelDet.DelRecNo = DelPrice.DprDelRecNo) as TotValue,
          (	select Logons.LogonName  from Delaudit, DelDet, logons 
              where DelAudit.DELAUDDELRECNO = DelDet.DELRECNO 
            and Delaudit.LogonNo = Logons.LogonNo
            and DelHed.DlvOrdNo = DelDet.DelDlvOrdNo
            and Delaudit.DELAUDRECNO = (Select Min(Delaudit.Delaudrecno) from delaudit, deldet where DelHed.DlvOrdNo = DelDet.DelDlvOrdNo and DelAudit.DELAUDDELRECNO = DelDet.DELRECNO )
          ) as LogonName,
          (	select Logons.UserName  from Delaudit, DelDet, logons 
              where DelAudit.DELAUDDELRECNO = DelDet.DELRECNO 
            and Delaudit.LogonNo = Logons.LogonNo
            and DelHed.DlvOrdNo = DelDet.DelDlvOrdNo
            and Delaudit.DELAUDRECNO = (Select Min(Delaudit.Delaudrecno) from delaudit, deldet where DelHed.DlvOrdNo = DelDet.DelDlvOrdNo and DelAudit.DELAUDDELRECNO = DelDet.DELRECNO )
          ) as UserName,	  
          (Case When (TNTDLVORDNO = -1)                                         Then 1
                When (TNTDLVORDNO = 0)                                          Then 1
                When Nvl(DELHED.ISOPENFORMORE, 0) > 1                           Then 3
              When DELHED.DLVRELINV IS NULL AND DELHED.ISOPENFORMORE <  2     Then 4
                When DELHED.DLVRELINV IS NULL AND DELHED.ISOPENFORMORE >= 2     Then 5
              When DELHED.DLVRELINV in ('Dlv')                                Then 6
              When DELHED.DLVRELINV in ('Inv')                                Then 8
              When DELHED.DLVRELINV in ('Rel')                                Then 7
              else                                                                -1
           End ) SITicketStatus	
            FROM  tktnt, tktbk, Orders, delhed--, deldet   --SR added deldet 02/01/14 so can do sales office link
                  where tktnt.TNTTBKRECNO = tktbk.TBKRECNO --dont ever link in deldet or you will get duplicated lines.
                  AND tktnt.TNTDlvOrdNo = delhed.DLVORDNO
                  AND Orders.OrdRecNo = DelHed.DlvOrdRecNo 
                  AND DELHED.DLVSALOFFNO = SO
                  AND DELHED.DLVSTKLOC = SL 
                  --AND delhed.DlvOrdNo = deldet.DelDlvOrdNo
           AND  Orders.OrdDate >= to_date(EF, 'YYYYMMDD')	
           AND  Orders.OrdDate <= to_date(ET, 'YYYYMMDD')
           AND  (NVL(TB, 0)=0 OR TKTNT.TNTNO = nvl(TB,0))
           AND  (NVL(CL, 0)=0 OR Orders.ActCstCode = nvl(CL,0)) 
           --AND  (NVL(PS, 0)=0 OR deldet.DelPrcPrdNo in(select PRDRECTOSO.PRCPRDNO from PRDRECTOSO Where PRDRECTOSO.SalOffNo = SO AND RTrim(PRDRECTOSO.SOSHORTCODE) = RTrim(PS))  )
           
           
           --AND  (PS IS NULL OR deldet.DelPrcPrdNo in(select PRDRECTOSO.PRCPRDNO from PRDRECTOSO Where PRDRECTOSO.SalOffNo = SO AND RTrim(PRDRECTOSO.SOSHORTCODE) = RTrim(PS))  )
           
           
           --SS search status. 0 = All; 4 = Allocated; 9 = Not Allocated;
           
           --AND (case When NVL(SS, 0) > 4 then (delhed.dlvOrdNo = 1000)  else (delhed.dlvOrdNo = 1000) end )
           
           --and (case When SS = 4 then delhed.dlvOrdNo = 196160 else delhed.dlvOrdNo = 196161 end)
           --AND  (NVL(SS, 0)=0 OR Orders.ActCstCode = nvl(CL,0))
          /* AND  (NVL(SS, 0) in(0,4,9) 
                 AND ( NVL(SS, 0) = 0
                       OR (SS = 4 AND delhed.dlvOrdNo in (196160) )                  
                       OR (SS = 9 AND delhed.dlvOrdNo in (196161) )
                     )  
                )*/
                
             AND  (NVL(SS, 0) in(0,4,9) 
                 AND ( NVL(SS, 0) = 0
                       OR (SS = 4 AND delhed.dlvOrdNo in (select deldlvOrdNo from deldet, deltoall where deldet.delrecno = deltoall.daltyperecno AND dalRecordType = 1 AND deldet.deldlvOrdNo = delhed.dlvOrdNo) )                  
                       OR (SS = 9 AND delhed.dlvOrdNo NOT in (select deldlvOrdNo from deldet, deltoall where deldet.delrecno = deltoall.daltyperecno AND dalRecordType = 1 AND deldet.deldlvOrdNo = delhed.dlvOrdNo) )
                     )  
                )   
           
           /* and delhed.dlvOrdNo in(
                case When NVL(SS, 0) = 4
                     Then (196160) 
                     else (196161)
                     end         )                    
          */
          --need a better solution than    select delhed.dlvOrdNo from delhed
           
          /* and delhed.dlvOrdNo in(
                case When NVL(SS, 0) = 4
                     Then (select deldlvOrdNo from deldet, deltoall where deldet.delrecno = deltoall.daltyperecno AND dalRecordType = 1 AND deldet.deldlvOrdNo = delhed.dlvOrdNo) 
                     else (select delhed.dlvOrdNo from delhed)
                     end         )                    
           
           and delhed.dlvOrdNo NOT in(
                case When NVL(SS, 0) = 9
                     Then (select deldlvOrdNo from deldet, deltoall where deldet.delrecno = deltoall.daltyperecno AND dalRecordType = 1 AND deldet.deldlvOrdNo = delhed.dlvOrdNo) end)
           
          */ 
           
           and (PS IS NULL 
                OR DELHED.dlvordno in (select deldlvordno from deldet 
                                        Where delhed.DlvOrdNo = deldet.DelDlvOrdNo 
                                        AND delrecno in(select delRecNo from deldet, PRDRECTOSO 
                                                        where deldet.deldlvordno = delhed.DlvOrdNo 
                                                        and PRDRECTOSO.SalOffNo = SO
                                                        and PRDRECTOSO.PrcPrdNo = deldet.DelPrcPrdNo
                                                        and Rtrim(SOSHORTCODE) = PS))
               )  
               
            --PO is LOT number for TPUK.   
            and (PO IS NULL OR PO = 0 
                 OR DELHED.dlvOrdNo in(	Select Distinct DelDet.DelDlvOrdNo From DelDet 
						                            Where delDet.DelRecNo in(select DalTypeRecNo from deltoall
												                                         Where DalRecordType = 1
												                                         And DalAllocNo in(select Allocate.AllocNo from lothed, lotDet, LotIte, Allocate
																	                                                 Where lothed.LHeRecNo = PO
																	                                                 AND lothed.LHeRecNo = lotDet.DetLHeRecNo
																	                                                 AND LotIte.LitDetNo = lotDet.DetRecNo
																	                                                 AND Allocate.ALLOCLITITENO = LotIte.LitIteNo
																                                                  )
												                                        )				  
						                          )	
               )                                                
          ) RetTable
          Where 1=1 ; 
        
           V_SEARCH_RECORD SEARCH_CURSOR%ROWTYPE;

	 	 BEGIN
		   IF NOT SEARCH_CURSOR%ISOPEN
		   then
	       	  OPEN SEARCH_CURSOR;
		   END IF;
	 
		   LOOP

          FETCH SEARCH_CURSOR INTO V_SEARCH_RECORD;
  
          EXIT WHEN SEARCH_CURSOR%NOTFOUND;
	 					 
          --First Record, so check to see how many records are returned 
          
    		  IF FirstRecord then
		         FirstRecord := False;	 
		         If MR >0 then
		  	       If V_SEARCH_RECORD.RecCount > MR THEN
					        EC := -1;
					        ED := 'Too Many Records to return';	
					        RecCount := V_SEARCH_RECORD.RecCount;
					        EXIT;
               Else
                  EC := 0;
		  		     END IF; 
            ELSE
              EC := 0;
			      END IF;	
            
            If EC = 0 THEN 
              HandleOPStr('{"LINES":[', ConCatResultVar);
              SecondRecord := True;
            END IF;
         END IF;

         -- Only send records which are for this user if a username is specified
         -- TV 27Nov13 (SQL is too slow if you try to do this in the query)
         IF EC = 0 THEN
            IF ((SU IS NULL) OR (V_SEARCH_RECORD.LogonName = vSU)) THEN
               If SecondRecord then
                  SecondRecord := False;
               Else
                  HandleOPStr(',', ConCatResultVar);
	             END IF;	   
            
               TransmittedCount := TransmittedCount + 1;   
               HandleOPStr('{' , ConCatResultVar);
               HandleOPStr('"TB":' || V_SEARCH_RECORD.TNTNO || ',', ConCatResultVar );
               HandleOPStr('"BT":' || V_SEARCH_RECORD.TNTTBKRECNO || ',', ConCatResultVar );
               HandleOPStr('"CL":' || V_SEARCH_RECORD.ACTCSTCODE || ',', ConCatResultVar );
               HandleOPStr('"OD":"' || TO_CHAR(V_SEARCH_RECORD.ORDDATE,'YYYYMMDD') || '",', ConCatResultVar);
               HandleOPStr('"OC":"' || REPLACE(REPLACE(TRIM(V_SEARCH_RECORD.DELCOMMENT), '\', '\\'), '"', '\"')  || '",', ConCatResultVar);
               LConvertValue (PROCNAME, 'FLOAT', V_SEARCH_RECORD.TOTVALUE, NULL, Sttmp, EC, ED);  -- 0.5 becomes .5 (JSON error)
               HandleOPStr('"NT": '|| (Sttmp) || ',', ConCatResultVar);    
               HandleOPStr('"UL":"' || TRIM(V_SEARCH_RECORD.LOGONNAME) || '",', ConCatResultVar);
               HandleOPStr('"UN":"' || REPLACE(REPLACE(TRIM(V_SEARCH_RECORD.USERNAME), '\', '\\'), '"', '\"')   || '"', ConCatResultVar);
               HandleOPStr('}', ConCatResultVar);
            END IF;
        END IF;
      END LOOP;

      IF EC = 0 THEN
         HandleOPStr('],', ConCatResultVar);
         HandleOPStr('"RC":' || TransmittedCount || '}', ConCatResultVar);
      END IF;  
        
      IF SEARCH_CURSOR%ISOPEN
		  then    
         CLOSE SEARCH_CURSOR;
      End if;
      
      IF FirstRecord = true THEN
         EC := -1;
         ED := 'No Records found';
      END IF;
     END; 
   END IF;
 
   ConCatParamsVar := '?MI = '|| MI || '; UL = ' || UL || '; EH = ' || EH || '; SO = ' || SO ||
                      '; SL = '|| SL || '; TB = ' || TB || '; SU = ' || SU || '; EF = ' || EF ||
                      '; ET = '|| ET || '; CL = ' || CL || '; PO = ' || PO || '; PR = ' || PR ||
                      '; SS = '|| SS || '; MR = ' || MR ;                      
  
   IF EC > 0 THEN        -- ERROR MESSAGE RETURNED TO SCREEN/INTERFACE
      HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);
   ELSE	  
   	  If EC < 0 THEN
	     --Break with too many records 
         HandleOPStr('{"RC": '|| RecCount ||'}', ConCatResultVar);
	  END IF;
   END IF;	  
   
   HANDHELDLOG (MI, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, UL ) ;

END; -- End SEARCH_ORDERS

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

PROCEDURE SEARCH_PO    (MI IN Varchar2 default null,      --Machine ID
                        UL IN Varchar2 default null,      --User Logon
                        EH IN Varchar2 default null,      --Encryped Hash Password + Stock Location MD5
                        SO IN INTEGER default 0,          --Sales Office
                        SL IN INTEGER default 0,          --Stock Location
                        SU IN varchar2 default null,      --Search User Name (Optional)
                        EF IN varchar2 default TO_CHAR (sysdate - 14, 'YYYYMMDD'),      --Search Date From (Optional)(YYYYMMDD)
                        ET IN varchar2 default TO_CHAR (sysdate + 14, 'YYYYMMDD'),      --Search Date To (Optional)(YYYYMMDD)
                        SC IN Integer default 0,          --Supplier Number (Optional) 
                        PO IN Integer default 0,          --PO Number, PO (Optional)
                        LT IN Integer default 0,          --Lot Number (Optional)
                        PR IN Integer default 0,          --Product (Optional)
                        DE IN Integer default 0,          --Department (Optional)
                        SS IN Integer default 0,          --Search Status (Optional)
                        MR IN Integer default -1) IS      --Max Records (-1 = all)(Optional)

  PROCNAME VARCHAR(40) := 'SEARCH_PO';
  ConCatParamsVar 			VARCHAR(5000) := '';
  ConCatResultVar 			VARCHAR(5000) := '';
  EC Integer := 0 ; -- Error Code
  ED VarChar2(255) := ''; -- Error Description
  RecCount Integer := 0;
  V_DevRecNoCheck integer := 0;
  
  DAYRANGEFORBLANKDATE Integer := 14; -- Number of days back to go if the 'From Date' (EF) is null

  vEF VarChar2(10) := EF;	   
  vET VarChar2(10) := ET;	   
  
  TempDate Date := sysdate; 
  LDateIsValid Boolean;
  FirstRecord Boolean := True;

BEGIN  
   -- Returns the headers for Purchase Orders based on the parameters supplied
   -- BSDL 9973 TV 13Sep13
   -- Main Body Written 01/11/13 SR.
   --TODO  SU parameter.
  
   MachineIDValidate(MI, EC, ED, V_DevRecNoCheck);   

   IF EC = 0 THEN
      UserLogonValidate(UL, EC, ED);
   end if;

   IF EC = 0 THEN
      SalesOfficeValidate(SO, UL, EC, ED);  -- check DeviceToSalOff?
   end if;

   --StockLocationValidate()
   IF EC = 0 THEN
      StockLocationValidate(SL, EC, ED);  -- check DeviceToSalOff?
   end if;
   
   --determine the date range goalposts. optionally passed in but will be set here.   
   
   /*IF EC = 0 THEN 
      if SU is Not Null Then
         EC :=  1911;
         ED := 'SU [Search User Name] is not yet implemented.';
      end if;
   end If;*/
   
   IF EC = 0 THEN --FROM DATE--validate the dates. never null because they have a default.      
      LDateIsValid := False;
      LValidateValue ('DATE', 'CCYYMMDD', False, EF, PROCNAME, 'EF', LDateIsValid, EC, ED); 
      
      if EC = 0 Then
         vEF := EF;      
      end if;
   end If;
   
   IF EC = 0 THEN --TO DATE--validate the dates. never null because they have a default.
      --if ET is NULL Then
      --   vET := TO_CHAR (sysdate - DAYRANGEFORBLANKDATE, 'YYYYMMDD');
      --else
         LDateIsValid := False;
         LValidateValue ('DATE', 'CCYYMMDD', False, ET, PROCNAME, 'ET', LDateIsValid, EC, ED); 
      --end if;   
      if EC = 0 Then
         vET := ET;      
      end if;
   end If;
   
   IF EC = 0 THEN
      BEGIN
            TempDate := TO_DATE (vEF, 'YYYYMMDD');
            EXCEPTION
                WHEN OTHERS THEN
                    EC :=  1901;
                    ED := 'Date From is not a date (YYYYMMDD) <'||vEF||'>';
      END;
   end if; 
   
   IF EC = 0 THEN
      BEGIN
            TempDate := TO_DATE (vET, 'YYYYMMDD');
            EXCEPTION
                WHEN OTHERS THEN
                    EC :=  1901;
                    ED := 'Date To is not a date (YYYYMMDD) <'||vET||'>';
      END;
   end if;
   
   IF EC = 0 THEN
      EC := -1;
   
      DECLARE 
      CURSOR SEARCHPO_CURSOR IS
      --select porno reccount from purord;
      --select detrecno reccount from LOTDET;
      
      
            Select count (*) OVER () as RecCount, SearchPoDets.* From
               (select PorRecNo, PorNo, ShipDate, ExptdDate, RCVDInd, RCVDate, PorSalOff, PorClosed, 
                   LHeRecNo, LheSenCode, LheExpDate, LHeRcvInd, LHeRcvDate, LHePayTyp, LHeSupRef, 
                 Count(LitIteNo) NumLotIteLines, Min(LitBuyer) MinLitBuyer, Min(Smn.SmnName) MinSmnName, Sum(itesto.IstSldQty + itesto.IstTrnQty) SoldQty,
                 Min(Nvl(DepartmentsToSmn.DptRecNo, 0)) DptRecNo,
                 (Case When Nvl(PorClosed, 0) = 0 AND Sum(Nvl(LitQtyRcv, 0)) = 0 Then 1 -- expected (nothing rcvd) 
                       When Nvl(PorClosed, 0) = 0 AND Sum(Nvl(LitQtyRcv, 0)) > 0 
                                                  AND Sum(itesto.IstSldQty + itesto.IstTrnQty) = 0 Then 2 -- 2 at least 1 box rcvd. (and none all sold) 
                       When Nvl(PorClosed, 0) = 0 AND Sum(Nvl(LitQtyRcv, 0)) > 0                      --rcv 
                                                  AND Sum(itesto.IstSldQty + itesto.IstTrnQty) > 0    --some sold ... 
                                                  AND Sum(itesto.IstSldQty + itesto.IstTrnQty) < Sum(Nvl(LitQtyRcv, 0))  Then 3-- 3 rcvd and something sold but not fully sold.
                       When Nvl(PorClosed, 0) = 0 AND Sum(Nvl(LitQtyRcv, 0)) > 0                      --rcv 
                                                  AND Sum(itesto.IstSldQty + itesto.IstTrnQty) = Sum(Nvl(LitQtyRcv, 0)) Then 4    -- fully sold 							
                     When Nvl(PorClosed, 0) = 1 Then 5                                -- 4 complete - PO is closed.
                  end) As LotStatus,
                  
               Nvl((select Nvl(AuditDoneBy, 0) from auditrecord  
		                                where auditrecord.porno = PurOrd.PorNo 
		                                AND AuditRecordNo = (Select Nvl(Min(AuditRecordNo), 0) from auditrecord where auditrecord.porno = PurOrd.PorNo)), 0) CreationLogonNo,
										
  		         Nvl((select Nvl(Rtrim(logons.LogOnName), 0) from auditrecord 
									 	left outer join logons on (auditrecord.AuditDoneBy = Logons.LogOnNo) 
		                                where auditrecord.porno = PurOrd.PorNo 
		                                AND AuditRecordNo = (Select Nvl(Min(AuditRecordNo), 0) from auditrecord where auditrecord.porno = PurOrd.PorNo)), 0) CreationLogonName,
										
               (select Rtrim(logons.UserName) from auditrecord      --dont convert nulls to zeros    Rtrim(logons.UserName)
									 	left outer join logons on (auditrecord.AuditDoneBy = Logons.LogOnNo) 
		                                where auditrecord.porno = PurOrd.PorNo 
		                                AND AuditRecordNo = (Select Nvl(Min(AuditRecordNo), 0) from auditrecord where auditrecord.porno = PurOrd.PorNo)) CreationUserName
                  
            from purord, Lothed, LotDet, LotIte, Smn, itesto, DepartmentsToSmn
            Where purord.PorRecNo = Lothed.LhePorRecNo
            AND LotDet.DetLheRecNo = LotHed.LheRecNo
            AND LotDet.DetRecNo = LotIte.LitDetNo 
            AND Smn.SmnNo = LotIte.LitBuyer
            AND itesto.IstLitNo = LotIte.LitIteNo
            AND DepartmentsToSmn.SmnNo = Smn.SmnNo
            --AND purord.exptddate > TO_DATE('30/01/2013', 'dd/mm/yyyy')
            AND purord.exptddate >= TO_DATE (vEF, 'YYYYMMDD')
            AND purord.exptddate <= TO_DATE (vET, 'YYYYMMDD')
            AND  (NVL(SC, 0)=0 OR Lothed.LheSenCode = nvl(SC,0))
            AND  (NVL(PO, 0)=0 OR PurOrd.PorNo = nvl(PO,0))
            AND  (NVL(LT, 0)=0 OR LotHed.LHeRecNo = nvl(LT,0))
            AND  (NVL(PR, 0)=0 OR LotIte.LitPrdNo = nvl(PR,0))
            AND  (NVL(DE, 0)=0 OR DepartmentsToSmn.DptRecNo = nvl(DE,0))
            Group By PorRecNo, PorNo, ShipDate, ExptdDAte, RCVDInd, RCVDate, PorSalOff, PorClosed, 
                   LHeRecNo, LheSenCode, LheExpDate, LHeRcvInd, LHeRcvDate, LHePayTyp, LHeSupRef
            Order By PorNo, LHeRecNo
            ) SearchPoDets
            Where (NVL(SS, 0) = 0 OR LotStatus = NVL(SS, 0))
            --AND (NVL(SU, 0) = 0 OR CreationUserName = nvl(SU,0)) ;
            AND (  (NVL(SU, 'x') = 'x') OR (CreationUserName = Nvl(SU, null))   ) ;
            
   
            V_SEARCH_RECORD SEARCHPO_CURSOR%ROWTYPE;
 
         BEGIN
             IF NOT SEARCHPO_CURSOR%ISOPEN then
                  OPEN SEARCHPO_CURSOR;
             END IF;
         
             LOOP
      
                FETCH SEARCHPO_CURSOR INTO V_SEARCH_RECORD;
        
                EXIT WHEN SEARCHPO_CURSOR%NOTFOUND;
                   
                --First Record, so check to see how many records are returned 
                IF FirstRecord then
                   FirstRecord := False;	 
                   If MR > 0 then
                     If V_SEARCH_RECORD.RecCount > MR THEN
                        EC := -1;
                        ED := 'Too Many Records to return';	
                        RecCount := V_SEARCH_RECORD.RecCount;
                        EXIT;
                     Else
                        EC := 0;
                     END IF; 
                  ELSE
                    EC := 0;
                  END IF;	
                  
                  If EC = 0 THEN 
                    HandleOPStr('{"RC":' || V_SEARCH_RECORD.RecCount || ',', ConCatResultVar);
                    HandleOPStr('"LINES":[', ConCatResultVar);
                  END IF;
               ELSE
                  HandleOPStr(',', ConCatResultVar);
               END IF;
            
               HandleOPStr('{' , ConCatResultVar);
               HandleOPStr('"PO":' || V_SEARCH_RECORD.PORNO || ',', ConCatResultVar );
               HandleOPStr('"LT":' || V_SEARCH_RECORD.LHERECNO || ',', ConCatResultVar );
               HandleOPStr('"DD":"' || TO_CHAR(V_SEARCH_RECORD.ExptdDate,'YYYYMMDD') || '",', ConCatResultVar );     
               HandleOPStr('"SC":' || V_SEARCH_RECORD.LheSenCode || ',', ConCatResultVar );
               HandleOPStr('"OC":"' || V_SEARCH_RECORD.MinSmnName || '",', ConCatResultVar);
               HandleOPStr('"DE":' || V_SEARCH_RECORD.DptRecNo || ',', ConCatResultVar);
               HandleOPStr('"PL":' || TRIM(V_SEARCH_RECORD.NumLotIteLines) || ',', ConCatResultVar);
               HandleOPStr('"SS":' || V_SEARCH_RECORD.LotStatus , ConCatResultVar);
               HandleOPStr('}', ConCatResultVar);   
                   
            END LOOP;
    
          IF EC = 0 THEN
             HandleOPStr(']}', ConCatResultVar);
          END IF;  
            
          IF SEARCHPO_CURSOR%ISOPEN
          then    
             CLOSE SEARCHPO_CURSOR;
          End if;
          
          IF FirstRecord = true THEN
             EC := -1;
             ED := 'No Records found';
          END IF;
      END; 
   END IF;
   
   
   
   
   
   
   
   
   
   

   ConCatParamsVar := '?MI='|| MI || '=' || UL || '=' || EH || '=' || SO ||
                      '='|| SL || '=' || SU || '=' || EF ||
                      '='|| ET || '=' || SC || '=' || PO || '=' || LT ||
                      '='|| PR || '=' || DE || '=' || SS || '=' || MR  ;
                      
   --Debugging Only
  -- if EC = 0 then
  --   EC := -1; -- too many records
  -- END IF;
   
   IF EC > 0 THEN        -- ERROR MESSAGE RETURNED TO SCREEN/INTERFACE
      HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);
   ELSE	  
   	  If EC < 0 THEN
	     --Break with too many records 
         HandleOPStr('{"RC": '|| RecCount ||'}', ConCatResultVar);
	    END IF;
   END IF;	  
   
   HANDHELDLOG (MI, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, UL ) ;
           
END; -- End SEARCH_PO


--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

PROCEDURE LOT_USAGE   (MI IN Varchar2 default null,      --Machine ID
                       UL IN Varchar2 default null,      --User Logon
                       EH IN Varchar2 default null,      --Encryped Hash Password + Stock Location MD5
                       SO IN INTEGER default 0,          --Sales Office
                       SL IN INTEGER default 0,          --Stock Location
                       LT IN Integer default 0) IS       --Lot Number 

  PROCNAME VARCHAR(40) := 'LOT_USAGE';
  ConCatParamsVar 			VARCHAR(5000) := '';
  ConCatResultVar 			VARCHAR(5000) := '';
  EC Integer := 0 ; -- Error Code
  ED VarChar2(255) := ''; -- Error Description
BEGIN
   -- Returns details of sales against one entered lot
   -- BSDL 9973 TV 13Sep13
  
   MachineIDValidate(MI, EC, ED);

   IF EC = 0 THEN
      UserLogonValidate(UL, EC, ED);
   end if;

   IF EC = 0 THEN
      SalesOfficeValidate(SO, UL, EC, ED);  -- check DeviceToSalOff?
   end if;

   IF EC = 0 THEN
      StockLocationValidate(SL, EC, ED);  -- check DeviceToSalOff?
   end if;

   ConCatParamsVar := '?MI='|| MI || '=' || UL || '=' || EH || '=' || SO ||
                      '='|| SL || '=' || LT ;
   
   --DEBUG only
   if EC = 0 then
      EC := 2001;
      ED := 'Invalid Lot Number';
   End if;
   
   IF EC > 0 THEN        -- ERROR MESSAGE RETURNED TO SCREEN/INTERFACE
      HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);
   END IF;	  
   
   HANDHELDLOG (MI, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, UL ) ;

END; -- End LOT_USAGE

PROCEDURE UPLOAD_PURCHASE_ORDER (OJ IN VARCHAR2) IS
--Steve Rimen 23/07/2013  --Accepts PO information and writes to intermediary upload tables MKTHHELD_POHDR & MKTHHELD_PODET.

--Usage Rules.
--This method handes initial uploads (Request for PO creation) AND edits.
--The webservice returns a real time response and does not do the actual create or edit in the webservice.
--  (This is done in the FreshTrade HandHeld order upload mechanism)
--  The creator PO handheld passes -1 as the PO.
--  This device can make edits, and the webservice should check if the PO is created or not.  
--  Edits will be accepted in all circumstances other than 'Another user has amended the PO'.
--  Other HH users must have downloaded the PO before edits can be made.

-- If the POrno passed in...
-- -1 = New PO
-- 123 = Edit This PO (PO Number) [All Details passed back in]

  EC Integer := 0 ; -- Error Code
  ED VarChar2(255) := ''; -- Error Description
  PROCNAME VARCHAR(40) := 'UPLOAD_PURCHASE_ORDER';
  ConCatParamsVar 			VARCHAR(500);
  ConCatResultVar 			VARCHAR(2000)  := '';    
  
   vNewPOHeader BOOLEAN := False;
	 vNewPOLine   BOOLEAN := False;
    PO_Jsonobj             JSON;      --Order_Jsonobj
    PODetail_lines         JSON_LIST;
    PODetail_Jsonobj       JSON;
    
    V_POHDR_ROW    	MKTHHELD_POHDR%ROWTYPE;
    V_PODET_ROW	  	MKTHHELD_PODET%ROWTYPE;
    V_PURORD_ROW    PURORD%ROWTYPE;
    
    v_POToEditIsCreated BOOLEAN := False;
    v_HaveUploadData    BOOLEAN := False;
    v_IsTheDevThatCrtdThePOMe BOOLEAN := False;
    LPOEdit BOOLEAN;
    LNewPO BOOLEAN;
    StorePOHdr_FT_SeqNo integer;
    VStatusToSet integer;
    FTPONeedsUpldDets BOOLEAN;
    CheckingParam VARCHAR(2);
    V_CheckSmnNameIsBuyer VARCHAR(30);
    
-- HEADER VARIABLES  
    V_HDR_FT_SEQNO      MKTHHELD_POHDR.FT_SEQNO%TYPE;
    V_MachineID         DEVICENAME.DEVID%TYPE;
    V_DevRecNo          DEVICENAME.DEVRECNO%TYPE  ; -- DEVICE NAME FROM QUERY
    V_LogOnNo           MKTHHELD_POHDR.LOGONNO%TYPE;
    V_SalOffNo          MKTHHELD_POHDR.SALOFFNO%TYPE;
    V_StcRecNo          MKTHHELD_POHDR.STCRECNO%TYPE;
    V_HdrSmnNo          MKTHHELD_POHDR.SMNNO%TYPE;
    V_LHePayTyp         MKTHHELD_POHDR.LHEPAYTYP%TYPE;
    V_ClaRecNo          MKTHHELD_POHDR.CLARECNO%TYPE;
    V_POComm            MKTHHELD_POHDR.POCOMM%TYPE;    
    V_ExptdDate         MKTHHELD_POHDR.EXPTDDATE%TYPE;
    V_RcvDate           MKTHHELD_POHDR.RCVDATE%TYPE;
    V_Status            MKTHHELD_POHDR.STATUS%TYPE;
    V_LastAudit         MKTHHELD_POHDR.LASTAUDIT%TYPE;
    V_DateCreated       MKTHHELD_POHDR.DATECREATED%TYPE;
    V_PorNo             MKTHHELD_POHDR.PORNO%TYPE;    
    
    V_PorRecNo         MKTHHELD_POHDR.PORNO%TYPE;
    
    V_EncrHash          VARCHAR2(128);        
    V_LogOnName         LOGONS.LOGONNAME%TYPE; 
    V_DevRecNoCheck integer := 0;
   
    
-- DETAIL VARIABLES
    V_LineNo            MKTHHELD_PODET.LINENO%TYPE;
    V_PrcPrdNo          MKTHHELD_PODET.PRCPRDNO%TYPE;
    V_LineComm          MKTHHELD_PODET.LINECOMM%TYPE;
    V_ExpQty            MKTHHELD_PODET.EXPQTY%TYPE;
    V_RcvQty            MKTHHELD_PODET.RCVQTY%TYPE;
    V_Price             MKTHHELD_PODET.PURCHASEPRICE%TYPE;
    V_GuideSellPrice    MKTHHELD_PODET.GUIDESELLPRICE%TYPE;    
    V_LitSmnNo          MKTHHELD_PODET.SMNNO%TYPE;
    V_LitPayTyp         MKTHHELD_PODET.LITPAYTYP%TYPE;
    V_DptRecNo          MKTHHELD_PODET.DPTRECNO%TYPE;
    V_MGPrice           MKTHHELD_PODET.MGPRICE%TYPE;
    
    --V_IstRecNo          MKTHHELD_PODET.ISTRECNO%TYPE;
    
BEGIN

   --HANDHELDLOG (V_MachineID, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, Rtrim(V_LogOnName)) ;

   -- validate the JSON
    BEGIN
         PO_Jsonobj := json(OJ);
    EXCEPTION
        WHEN OTHERS THEN
           EC := 401;
           ED := 'INVALID JSON FILE OJ='||  UTL_URL.ESCAPE(OJ);
    END;
    
    -- validate the JSON lines
    IF EC = 0 THEN
        BEGIN
             PODetail_lines   := json_list(PO_Jsonobj.get('LINES'));
        EXCEPTION
            WHEN OTHERS THEN
               EC := 401;
               ED := 'INVALID JSON FILE (LINES) OJ='||  UTL_URL.ESCAPE(OJ);
        END;
   end if;
   
 -- ENSURE THE MAIN ELEMENTS EXIST
    IF EC = 0 THEN
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'MI', EC, ED); --i.	Machine ID 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'UL', EC, ED); --ii.	User Logon 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'EH', EC, ED); --iii.	Encrypted hash (User Password + Account )
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'SO', EC, ED); --iv.	Sales Office 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'SN', EC, ED); --v.	Salesman 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'SL', EC, ED); --vi.	Stock Location 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'CL', EC, ED); --vii.	Supplier Account Code (Clarecno)
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'PC', EC, ED); --viii.	Purchase Order Comment 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'DT', EC, ED); --ix.	Entry Date 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'ED', EC, ED); --x.	Expected Delivery Date 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'RD', EC, ED); --xi.	Received Date 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'PT', EC, ED); --xii.	Payment Type 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'PO', EC, ED); --xiii.	Purchase Order Number 
        DoesJSONElemExist (PROCNAME, PO_Jsonobj, 'LA', EC, ED); --xiv .Last Audit Record Number         
    END IF;

 -- VALIDATE THAT THESE ELEMENTS ARE INTEGERS, NUMBERS, DATES
    IF EC = 0 THEN
        --IsJSONElemAnInt IsJSONElemANumber IsJSONElemADate           
        --DoesJSONElemExist (PO_Jsonobj, 'EH', EC, ED); --iii.	Encrypted hash (User Password + Account )
        IsJSONElemAnInt (PO_Jsonobj, 'SO', EC, ED); --iv.	Sales Office 
        IsJSONElemAnInt (PO_Jsonobj, 'SN', EC, ED); --v.	Salesman 
        IsJSONElemAnInt (PO_Jsonobj, 'SL', EC, ED); --vi.	Stock Location 
        IsJSONElemAnInt (PO_Jsonobj, 'CL', EC, ED); --vii.	Supplier Account Code (Clarecno)
        IsJSONElemADate (PO_Jsonobj, 'DT', EC, ED); --ix.	Entry Date 
        IsJSONElemADate (PO_Jsonobj, 'ED', EC, ED); --x.	Expected Delivery Date 
        IsJSONElemADate (PO_Jsonobj, 'RD', EC, ED); --xi.	Received Date 
        IsJSONElemAnInt (PO_Jsonobj, 'PT', EC, ED); --xii.	Payment Type 
        IsJSONElemAnInt (PO_Jsonobj, 'PO', EC, ED); --xiii.	Purchase Order Number 
        IsJSONElemAnInt (PO_Jsonobj, 'LA', EC, ED); --xiv .Last Audit Record Number        
    END IF;

   -- PUT THE HEADER JSON VARIABLES INTO OUR VARIABLES
 -- THIS SHOULD TRAP ANY OTHER ISSUES WITH THE VARIABLES eg a number (5) having 6 digits
    IF EC = 0 THEN
        BEGIN        
            V_MachineID         := PO_Jsonobj.get('MI').get_string;
            V_LogOnName         := Trim(PO_Jsonobj.get('UL').get_string);
            V_EncrHash          := PO_Jsonobj.get('EH').get_string;
            V_SalOffNo          := PO_Jsonobj.get('SO').get_number;
            V_HdrSmnNo          := PO_Jsonobj.get('SN').get_number;
            V_StcRecNo          := PO_Jsonobj.get('SL').get_number;
            V_ClaRecNo          := PO_Jsonobj.get('CL').get_number;
            V_POComm            := PO_Jsonobj.get('PC').get_string;            
            --V_DateCreated       := json_ext.to_date2(PO_Jsonobj.get('DT')); --lunacy. (Idea is HH was out of radio range on Monday, 'created' Monday uploaded Tuesday)
            V_ExptdDate         := json_ext.to_date2(PO_Jsonobj.get('ED'));
            V_RcvDate           := json_ext.to_date2(PO_Jsonobj.get('RD'));            
            V_LHePayTyp         := PO_Jsonobj.get('PT').get_number;
            V_PorNo             := PO_Jsonobj.get('PO').get_number;
            V_LastAudit         := PO_Jsonobj.get('LA').get_number;                      
        EXCEPTION
            WHEN OTHERS THEN
                EC := 401;
                ED := 'Invalid JSON File : SqlErrM='||  SQLERRM;
        END;
    END IF;
    
    -- Validate Purchase Type (Header) is an allowed type.
    IF EC = 0 THEN
       if Not (V_LHePayTyp = 5 OR V_LHePayTyp = 6 OR V_LHePayTyp = 7 OR V_LHePayTyp = 8 OR V_LHePayTyp = 9) Then
          EC := 409;
          ED := 'Payment type PT (Header) ' || V_LitPayTyp || ' is not an allowed type';
       end if;
   END IF;
    
   
   IF EC = 0 THEN 
      if V_PorNo = -1 Then
         LNewPO  := True;         
      else
         LNewPO  := False;
      end If;
      LPOEdit := NOT LNewPO;
   end if;   

   IF EC = 0 THEN
      MachineIDValidate(V_MachineID, EC, ED, V_DevRecNoCheck);
   end if;
   
   IF EC = 0 THEN
      if V_HdrSmnNo = 0 Then
          EC :=    425;
          ED := 'New Purchase Order Must have a buyer (salesman) [SN] value';
      end If;
   end if;
   
   --this is a valid check, but dont want to prevent all processing until mod is done for 'BUY'ERS
   
   /*IF EC = 0 THEN
        BEGIN		   
           select SmnName INTO V_CheckSmnNameIsBuyer from smn where smnno = V_HdrSmnNo and smnType = 'Buy';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    121;
                --ED := 'Buyer ' || V_HdrSmnNo || ' ' ||  ' is not registered as a buyer.  (Continuing anyway...)';
                ED := 'Buyer ' || V_HdrSmnNo || ' ' ||  ' is not registered as a buyer. ';
           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Buyer information for smn '|| V_HdrSmnNo || '. SqlErrM='||  SQLERRM;
        END;
   END IF;*/
   
   IF EC = 0 THEN
      if V_ClaRecNo = 0 Then
          EC :=    426;
          ED := 'New Purchase Order Must have a Account [CL] value';
      end If;
   end if;

   --For a new PO get the real PO Number
   IF EC = 0 THEN
      if LNewPo Then
         begin   --visible? run grant script
            select sp_WizGetControl('CONTPONO', 1, 'MKTPROCEDURE_UPLOAD_PURCHASE_ORDER') into V_PorNo From Dual;
         EXCEPTION
            WHEN OTHERS THEN
                EC :=    410;
                ED := 'SQL Error attempting to get New PO Number.' || ' SqlErrM='||  SQLERRM;
         end;  
         
         IF EC = 0 THEN         
            begin                           
               select sp_WizGetControl('CONTPORRECNO', 1, 'MKTPROCEDURE_UPLOAD_PURCHASE_ORDER') into V_PorRecNo From Dual;
            EXCEPTION
                WHEN OTHERS THEN
                    EC :=    411;
                    ED := 'SQL Error attempting to get New PO Record Number.' || ' SqlErrM='||  SQLERRM;
            end;                                     
         end if;            
      end if;
   end if;   

   
   
    -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
    IF EC = 0 THEN
         IF V_MachineID IS NULL THEN
            EC := 100;
            ED := 'You must enter a machine name (MI)';
         END IF;
     END IF;

     IF EC = 0 THEN
        BEGIN		   
           SELECT  DEVRECNO  INTO V_DevRecNo FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = UPPER(V_MachineID);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := V_MachineID || ' is not a registered active device';
           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| V_MachineID || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

     -- CHECK THE DATABASE to see if USER EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        IF V_LogOnName IS NULL THEN
            EC := 401;
            ED := 'You must enter a user logon name (UL)';
        END IF;
     END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if LOGONS EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
            SELECT LOGONNO INTO V_LogOnNo
            FROM LOGONS
            WHERE TRIM(LOGONNAME) = TRIM(UPPER(V_LogOnName))
            AND AVAILTOMKTHANDHELD = 1
            AND ACTIVE = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    402;
                ED := V_LogOnName || ' is not a registered active logon';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain LOGONS information for '|| V_LogOnName || ' SqlErrM='||  SQLERRM;
        END;
     END IF;

-- *****************Check statuses are ok for Uploading and editing.*********************

--Pass in PO                          -1                >0
--vNewPOHeader                        True              False
--v_POToEditIsCreated                 False             (Check)
--v_HaveUploadData                    (will be none)    if MKT PO, True.
--v_IsTheDeviceThatCreatedThePOMe     N/A               (Check)
--V_LastAudit
--The PO must be at status 1 'complete' to be edited. (UNLESS it is edited by the same handheld and it has not yet been created; status 0)

   --REMEMBER a user can edit a PO that has never been used by the MKTHH. (and so will have no MKTHHELD_POHDR)
    If EC = 0 then
       if LNewPO Then
          v_POToEditIsCreated := False; --not relevant
          vNewPOHeader := True;
       else   
          v_POToEditIsCreated := True;  
          vNewPOHeader := False;
          if LPOEdit Then --user passed in a PO to edit.
             --The real test of has the PO been created is 'has the PO been created'.             
             Begin
                     Select *
                     INTO V_PURORD_ROW   
                     FROM PurOrd
                     WHERE PORNO = V_PorNo;
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
		               v_POToEditIsCreated := False;
		             WHEN OTHERS THEN
                   EC :=  109;
                   ED := 'Unable to Execute Sql to Obtain Header information for PO '|| V_PorNo || ' SqlErrM='||  SQLERRM;
            END; 
         end if;   
      end if;
   end if;

	 -- Check to see if the PO is already uploaded (NOT created, Uploaded 'pending')	
   -- Check to see any existing status of the PO.
     If EC = 0 then
        if LNewPO Then 
           v_HaveUploadData := False; 
        else   
           v_HaveUploadData := True;    
              Begin
                     Select *
                     INTO V_POHDR_ROW   
                     FROM MKTHHELD_POHDR
                     WHERE PORNO = V_PorNo;
                     --WHERE DEVRECNO =  V_DevRecNo --why did I do this?
                     --    AND PORNO = V_PorNo;
              EXCEPTION
              WHEN NO_DATA_FOUND THEN
		             v_HaveUploadData := False;
		          WHEN OTHERS THEN
                 EC :=  108;
                 ED := 'Unable to Execute Sql to Obtain Header information for PO '|| V_PorNo || ' SqlErrM='||  SQLERRM;
              end;   
        END If;
	 END IF;
   
  --if we dont have upload data, lets have upload data.
  --we will not have upload data if we have downloaded, and resending edits for a FT created PO.
  -- if v_POToEditIsCreated = true AND v_HaveUploadData = False  then this is a FT created PO. There is Not currently and data in the Upload Table.
  --Option 1 = write    MoveDataToUploadTables('PO', PO)   
  --Option 2 = expand below writes.
  If EC = 0 then
     FTPONeedsUpldDets := False;
     if v_POToEditIsCreated = true AND v_HaveUploadData = False  then 
        FTPONeedsUpldDets := True; --we are not creating the PO but we are writing the details to the upload tables for the first time.
     end if;   
  end if;
  
   
  If EC = 0 then
     if v_HaveUploadData = False Then
        v_IsTheDevThatCrtdThePOMe := False;
     else
        if V_POHDR_ROW.DevRecNo = V_DevRecNoCheck Then
           v_IsTheDevThatCrtdThePOMe := True;
        else
           v_IsTheDevThatCrtdThePOMe := False;
        end If;
     end If;
  end if;
  

  
  If EC = 0 then  --if the PO IS pending (NOT created) it can be edited by the device that created it.
     if LPOEdit Then --I want to edit a PO
        if v_HaveUploadData Then
           if v_IsTheDevThatCrtdThePOMe = True Then
              if V_POHDR_ROW.Status <> 0 AND V_POHDR_ROW.Status <> 1 AND V_POHDR_ROW.Status <> 2 Then
                 EC := 110; 
                 ED := 'Cannot edit a PO at this status.';
              else   
                 StorePOHdr_FT_SeqNo := V_POHDR_ROW.FT_SeqNo;
              end if;
           else
              if V_POHDR_ROW.Status = 0 Then
                 EC := 111; 
                 ED := 'Cannot edit another users PO.';
              end if;
           end if;     
        end If;  
     end if;
  end If;  
  
  
   
  If EC = 0 then --Check for interrim changes : user changed PO since download was done.
     --Note that PO date changes may have been Monday but we check lotites changed Wednesday - must be at detail level.
     if v_HaveUploadData Then
        if V_LastAudit > V_POHDR_ROW.LastAudit Then
           EC := 112; 
           ED := 'Cannot Amend! - PO has been edited since PO download was executed. Audit Number Passed: ' || V_LastAudit || ';  Last PO Audit: ' || V_POHDR_ROW.LastAudit || ';';
        end if;
     end If;
  end If; 
   
  /*If EC = 0 then
     if v_HaveUploadData Then --edit: we are going to rewrite the upload data with the new data passed in.     
        Begin
          DELETE from MKTHHELD_PODET Where HDR_FT_SeqNo = V_POHDR_ROW.FT_SeqNo;        
          --DELETE from MKTHHELD_POHDR Where FT_SeqNo = V_POHDR_ROW.FT_SeqNo;
       EXCEPTION
       WHEN OTHERS THEN         
           EC := 113; 
           ED := 'Cannot delete from holding tables MKTHHELD_POHDR and MKTHHELD_PODET.';
        end;   
     end if;
  end if;*/
  



	 -- Check to see if the PO is in a status that can be edited
	/* If EC = 0 then
	    Begin
	 	   If V_POHDR_ROW.Status = -2 then
		      Begin
			     --Order is being uploaded by Freshtrade at present (-2), so cannot upload a new version
                 EC :=  402;
                 ED := 'PO '|| V_PorNo || ' is being uploaded to Freshtrade.  Try again in a couple of seconds';
 			    End;
		   End if;
		End;
	 End If;*/

--**********************************************************

	 If EC = 0 then
	 Begin
	 	If (vNewPOHeader = true OR FTPONeedsUpldDets = True) then
		BEGIN
      	   -- New Header
            IF EC = 0 THEN
               BEGIN
                   V_HDR_FT_SEQNO       := MKTHANDHELD_POHDR_FT_SEQNO.NEXTVAL;
               EXCEPTION
                       WHEN OTHERS THEN
                          EC := 401;
                          ED := 'INVALID HEADER SEQ NO ';
               END;
           END IF;

          -- WRITE THE HEADER RECORD AT THIS STAGE WITH A STATUS OF -1 - WHICH MEANS THAT IT HAS NOT SUCCESSFULLY UPLOADED YET   -(What!?!?No ...ok set to zero at end)
           IF EC = 0 THEN
               V_Status := 0;
               BEGIN
                   INSERT INTO MKTHHELD_POHDR (FT_SEQNO, DEVRECNO, LOGONNO, SALOFFNO, STCRECNO, SMNNO, LHEPAYTYP,
                                               CLARECNO, POCOMM, EXPTDDATE, RCVDATE, STATUS, LASTAUDIT, DATECREATED, PORNO, DATETHISRECORDCREATED)                                                                                            
                   VALUES(
                       V_HDR_FT_SEQNO, V_DevRecNo, V_LogOnNo, V_SalOffNo, V_StcRecNo, V_HdrSmnNo, V_LHePayTyp,
                       V_ClaRecNo, V_POComm, V_ExptdDate, V_RcvDate, -5, V_LastAudit, SYSDATE, V_PorNo, SYSDATE    --V_DateCreated    V_Status - = webserv uploading
                       );
                   COMMIT;
               EXCEPTION
                    WHEN OTHERS THEN
                       EC :=  107;
                       ED := 'Unable to Execute Sql to INSERT INTO MKTHHELD_POHDR  SqlErrM='||  SQLERRM;
               END;
           END IF;
		END;
		ELSE
		   --Else here for update of existing record
       
       if V_POHDR_ROW.FT_SEQNO is not Null Then
          V_HDR_FT_SEQNO := V_POHDR_ROW.FT_SEQNO;
       else
          V_HDR_FT_SEQNO := StorePOHdr_FT_SeqNo;
       end if;
       
       if V_HDR_FT_SEQNO is Null then
           EC :=  108;
           ED := 'Error - cannot get PO Header sequence';
       end if;
       
       
		   --V_HDR_FT_SEQNO := V_POHDR_ROW.FT_SEQNO;
       --V_HDR_FT_SEQNO := StorePOHdr_FT_SeqNo;
       --V_Status := 2; --Amendments Pending
	 	   BEGIN
	          UPDATE MKTHHELD_POHDR SET
			       LOGONNO      = V_LogOnNo,        
             SALOFFNO     = V_SalOffNo,
             STCRECNO     = V_StcRecNo,
             SMNNO        = V_HdrSmnNo, --V_LitSmnNo, 
             LHEPAYTYP    = V_LhePayTyp,
             CLARECNO     = V_ClaRecNo,
             POCOMM       = V_POComm,
             EXPTDDATE    = V_ExptdDate,
             RCVDATE      = V_RcvDate,
             STATUS       = -5, -- 2 ='amendments pending' ---1, --V_Status,  ---1,   --note this gets set to 0 near the end of the method.
             LASTAUDIT    = V_LastAudit,
             DATECREATED  = V_DateCreated,   --(was - dont mess with the creation date....now have DATETHISRECORDCREATED.
             PORNO        = V_PorNo                      
			  WHERE FT_SEQNO = V_HDR_FT_SEQNO;
              COMMIT;
              EXCEPTION
                 WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to UPDATE INTO MKTHHELD_POHDR  SqlErrM='||  SQLERRM;

           END;
		END IF;

	END;
	END IF;

-- SCAN THROUGH THE DETAILS, VALIDATE THEM  AND UPLOAD THEM
-- NOTE THE HEADER FLAG IS NOT WRITTEN AT THIS STAGE

IF EC = 0 THEN
   FOR i in 1..PODetail_lines.count LOOP
            BEGIN
                PODetail_Jsonobj :=  json(PODetail_lines.get(i));
            EXCEPTION
                WHEN OTHERS THEN
                   EC := 401;
                   ED := 'INVALID DETAILS IN JSON FILE ';
            END;

            -- ENSURE THE DETAIL ELEMENTS EXIST
            IF EC = 0 THEN
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'LN', EC, ED);
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'PR', EC, ED);--Product PrcPrdNo
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'LE', EC, ED);--(Lot)Qty Exp
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'LR', EC, ED);--(Lot)Qty Rcv
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'PV', EC, ED);--Purch Price
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'PB', EC, ED);--Guide Price
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'PG', EC, ED);--Minimum Guaranteed Price
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'LC', EC, ED);--Line Comment
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'SD', EC, ED);--salesman Detail 
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'PD', EC, ED);--Payment Type Detail LitPayTyp
                DoesJSONElemExist (PROCNAME, PODetail_Jsonobj, 'DE', EC, ED);--Department                
            END IF;

             -- VALIDATE THAT THESE ELEMENTS ARE INTEGERS, NUMBERS, DATES
            IF EC = 0 THEN
                IsJSONElemAnInt(PODetail_Jsonobj, 'LN', EC, ED);
                IsJSONElemAnInt (PODetail_Jsonobj, 'PR', EC, ED);--Product PrcPrdNo
                IsJSONElemAnInt (PODetail_Jsonobj, 'LE', EC, ED);--(Lot)Qty Exp
                IsJSONElemAnInt (PODetail_Jsonobj, 'LR', EC, ED);--(Lot)Qty Rcv
                IsJSONElemANumber (PODetail_Jsonobj, 'PV', EC, ED);--Purch Price
                IsJSONElemANumber (PODetail_Jsonobj, 'PB', EC, ED);--Guide Price             
                IsJSONElemANumber (PODetail_Jsonobj, 'PG', EC, ED);-- Minimum Guaranteed Price             
                IsJSONElemAnInt (PODetail_Jsonobj, 'SD', EC, ED);--salesman Detail 
                IsJSONElemAnInt (PODetail_Jsonobj, 'PD', EC, ED);--Payment Type Detail LitPayTyp
                IsJSONElemAnInt (PODetail_Jsonobj, 'DE', EC, ED);--Department 
            END IF;

           -- PUT THE DETAIL JSON VARIABLES INTO OUR VARIABLES
           -- THIS SHOULD TRAP ANY OTHER ISSUES WITH THE VARIABLES eg a number (5) having 6 digits
            IF EC = 0 THEN
                CheckingParam := '';
                BEGIN   
                  CheckingParam := 'LN';
                  V_LineNo            := PODetail_Jsonobj.get('LN').get_number;
                  CheckingParam := 'PR';
                  V_PrcPrdNo          := PODetail_Jsonobj.get('PR').get_number;                  
                  CheckingParam := 'LC';
                  V_LineComm          := PODetail_Jsonobj.get('LC').get_string;
                  CheckingParam := 'LE';
                  V_ExpQty            := PODetail_Jsonobj.get('LE').get_number;                                    
                  CheckingParam := 'LR';
                  V_RcvQty            := PODetail_Jsonobj.get('LR').get_number;                 
                  CheckingParam := 'PV';
                  V_Price             := PODetail_Jsonobj.get('PV').get_number;
                  CheckingParam := 'PB';
                  V_GuideSellPrice    := PODetail_Jsonobj.get('PB').get_number;                   
                  CheckingParam := 'SD';
                  V_LitSmnNo          := PODetail_Jsonobj.get('SD').get_number;
                  CheckingParam := 'PD';
                  V_LitPayTyp         := PODetail_Jsonobj.get('PD').get_number;
                  CheckingParam := 'DE';
                  V_DptRecNo          := PODetail_Jsonobj.get('DE').get_number;
                  CheckingParam := 'PG';
                  V_MGPrice           := PODetail_Jsonobj.get('PG').get_number;
                  
                  
                  --V_LitIteNo          := Detail_Jsonobj.get('DE').get_number; 
                  CheckingParam := '??';
                EXCEPTION
                    WHEN OTHERS THEN
                        EC := 401;
                       -- ED := 'Invalid Details on JSON File : SqlErrM='||  SQLERRM;
                        ED := 'Invalid Details on JSON File.\nParameter :'  || CheckingParam || '. \nError = '||  SQLERRM;
                END;
            END IF;
            
      -- Validate Purchase Type (detail) is an allowed type.
            IF EC = 0 THEN
               if Not (V_LitPayTyp = 5 OR V_LitPayTyp = 6 OR V_LitPayTyp = 7 OR V_LitPayTyp = 8 OR V_LitPayTyp = 9) Then
                  EC := 401;
                  ED := 'Payment type PD ' || V_LitPayTyp || ' is not an allowed type';
               end if;
           END IF;  
           
           IF EC = 0 THEN
              if V_LitSmnNo = 0 Then
                 --EC := 408;
                 --ED := 'Parameter SD is zero. Buyer for Lot is mandatory requirement';
                 V_LitSmnNo := V_HdrSmnNo;
              end if;
           END IF;

			vNewPOLine := True;
      --IF (EC = 0) AND (vNewPOHeader) THEN
      IF (EC = 0) Then
         if (v_HaveUploadData = true) THEN      
			      BEGIN
			        -- Check to see if there are existing details
			        vNewPOLine := False;
		          Select *
		          INTO V_PODET_ROW
		          FROM MKTHHELD_PODET
		          WHERE HDR_FT_SEQNO = V_HDR_FT_SEQNO    -- V_POHDR_ROW.FT_SEQNO   
                    AND LINENO = V_LineNo;
                  --AND PRCPRDNO = 1662;
            EXCEPTION
                  WHEN NO_DATA_FOUND THEN
		                vNewPOLine := True;
		              WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to Obtain Line information for PO '|| V_PorNo || ' Line No='|| v_LineNo || ' SqlErrM='||  SQLERRM;
            END;
         end if;   
      END IF;
      
      if FTPONeedsUpldDets Then
         vNewPOLine := true;
      end If;

      IF EC = 0 THEN
         If vNewPOLine THEN
 			      BEGIN
                     INSERT INTO MKTHHELD_PODET (
                         FT_SEQNO, HDR_FT_SEQNO, LINENO, PRCPRDNO, LINECOMM, EXPQTY, RCVQTY, PURCHASEPRICE, GUIDESELLPRICE,
                         SMNNO, LITPAYTYP, DPTRECNO, MGPRICE)
                     VALUES (
                         MKTHANDHELD_PODET_FT_SEQNO.NEXTVAL, V_HDR_FT_SEQNO,
                         V_LineNo, V_PrcPrdNo, V_LineComm, V_ExpQty, V_RcvQty, V_Price, V_GuideSellPrice,
                         V_LitSmnNo, V_LitPayTyp, V_DptRecNo, V_MGPrice);
                     COMMIT;
                     
            EXCEPTION
                     WHEN OTHERS THEN
                        EC :=  107;
                        ED := 'Unable to INSERT INTO MKTHHELD_PODET ('||  SQLERRM || ')';
            END;
			   ELSE
			      BEGIN
                           UPDATE MKTHHELD_PODET
                            SET PRCPRDNO = V_PrcPrdNo,
                                LINECOMM = V_LineComm,
                                EXPQTY   = V_ExpQty,
                                RCVQTY   = V_RcvQty,
                                PURCHASEPRICE    = V_Price,
                                GUIDESELLPRICE      = V_GuideSellPrice,
                                SMNNO  = V_LitSmnNo,
                                LITPAYTYP = V_LitPayTyp,
                                DPTRECNO = V_DptRecNo,
                                MGPRICE  = V_MGPRICE
                                --ISTRECNO = V_IstRecNo
                         WHERE FT_SEQNO = V_PODET_ROW.FT_SEQNO;
                     COMMIT;
            EXCEPTION
                     WHEN OTHERS THEN
                        EC :=  107;
                        ED := 'Unable to Execute Sql to UPDATE MKTHHELD_PODET  SqlErrM='||  SQLERRM;

			      END;
			   END IF;
      END IF; --ec = 0

   END LOOP;
END IF;

    IF EC = 0 THEN
       if LNewPO Then
          VStatusToSet := 0; --Ready to upload
       else
          VStatusToSet := 2; --Amendments Pending (edit ready to upload)       
       end if;
    
        BEGIN           
            UPDATE MKTHHELD_POHDR SET  STATUS = VStatusToSet WHERE FT_SEQNO = V_HDR_FT_SEQNO;  --0 = ready to upload.
            COMMIT;
        EXCEPTION
             WHEN OTHERS THEN
                EC :=  107;
                ED := 'Unable to Execute update Sql MKTHHELD_PODET -STATUS = 0 - SqlErrM='||  SQLERRM;
        END;
    END IF;

-- Get Next PO Number()
 

    IF EC = 0 THEN        -- SUCCESS RETURNED
       HandleOPStr('{"PO": '|| V_PorNo || '}', ConCatResultVar); 
       --HandleOPStr('{"DU": '|| TO_CHAR(SYSDATE, 'YYYYMMDD') || ',', ConCatResultVar); 
       --HandleOPStr('{"DT": '|| TO_CHAR(SYSDATE, 'HHMMSS')   || ',}', ConCatResultVar); 
         /*HTP.P('{
            "DU": '|| TO_CHAR(SYSDATE, 'YYYYMMDD') || ',
            "DT": "'|| TO_CHAR(SYSDATE, 'HHMMSS') ||'"
               }');*/  
    END IF;
       
   --LOG THE TRANSACTION
   --formatted string
   --ConCatParamsVar := '?MI='|| V_MachineID || ', UL=' || V_LogOnName || ', EH=' || V_EncrHash || ', SO=' || V_SalOffNo || ', SN=' || V_HdrSmnNo || ', SL=' || V_StcRecNo || ', CL=' || V_ClaRecNo || ', PC=' || V_POComm || ', DT=' || V_DateCreated  || ', ED=' || V_ExptdDate || ', RD=' || V_RcvDate || ', PT=' || V_LHePayTyp;    
   
   --raw string...
   ConCatParamsVar := OJ;
   
	 --HANDHELDLOG (V_MachineID, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar ) ;
   HANDHELDLOG (V_MachineID, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, Rtrim(V_LogOnName)) ;
   
   IF EC != 0 THEN        -- ERROR MESSAGE RETURNED TO SCREEN/INTERFACE
      HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);
   END IF;
   
END; --PROCEDURE UPLOAD_PURCHASE_ORDER()

PROCEDURE MachineIDValidate (MI IN Varchar2 default null, EC IN OUT INTEGER, ED IN OUT Varchar2, DR IN OUT INTEGER) IS
  --Validate the Machine ID
  --Steve Rimen 16/07/2013
  --if Validation fails, the results are returned in EC and ED
  
  VMI DEVICENAME.DEVID%TYPE;
  VDEVNAME DEVICENAME.DEVNAME%TYPE := ''; -- DEVICE NAME FROM QUERY
  VDEVRECNO DEVICENAME.DEVRECNO%TYPE;
BEGIN
  --HTP.P('BBB');
  
   IF MI is null then
	 	EC := 100;
		ED := 'You must enter a machine name (MI)';
	 END IF;
   
    
   -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     IF EC = 0 THEN
        BEGIN
           VMI := UPPER(MI);

           SELECT  DEVNAME, DEVRECNO
           INTO VDEVNAME, VDEVRECNO
           FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;
     
     if EC = 0 Then
        DR := VDEVRECNO;
     end if;   
     
     /*IF EC != 0 THEN
        -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
     END IF;*/

END; --machine ID Validate()

PROCEDURE DOWNLOAD_PO (MI IN Varchar2 default null,    --Machine ID
                          UL IN Varchar2 default null,      --User Logon
                          EH IN Varchar2 default null,      --Encryped Has Password + PO MD5
                          SO IN INTEGER default 0,          --Sales Office
                          PO IN INTEGER default 0) IS         --Purchase Order
                          
--Download an existing PO to the handheld for viewing.
--this does not determine if the PO can be edited, it just returns the data.

  EC Integer := 0 ; -- Error Code
  ED VarChar2(255) := ''; -- Error Description
  PROCNAME VARCHAR(40) := 'DOWNLOAD_PO';
  ConCatParamsVar 			VARCHAR(500);
  ConCatResultVar 			VARCHAR(2000)  := ''; 
  
  StTmp VARCHAR(100);
  
  --V_MachineID         DEVICENAME.DEVID%TYPE;
  V_NUMPOS Integer   := 0; --will be zero if PO not yet created.
  V_NUMLotites Integer   := 0;
  V_PornoUpldStatus Integer := 0;
  V_StoreLastAuditRecNo Integer := 0;
  
  --V_DateCreated  PURORD.DATECREATED%TYPE; 
  --V_ExptdDate    PURORD.EXPTDDATE%TYPE; 
  --V_RcvDate      PURORD.RCVDATE%TYPE;  
  
  V_DateCreatedStr  VARCHAR(8)  := ''; 
  V_ExptdDateStr    VARCHAR(8)  := ''; 
  V_RcvDateStr      VARCHAR(8)  := ''; 
  
  V_LotIteLineNo Integer := 0 ;
  V_DevRecNo Integer := 0 ;

/*CURSOR PURORD_CURSOR  IS 
SELECT PorRecNo, PorNo, ShipDate, ExptdDate, RcvdInd, RcvDate, RcvInst, ShipFrom, 
CarType, CarName, BillLaid, PorAllRcv, 
PorPrt, PorClosed, FfsOrgCode, FfsVesNo, FfsPalnetSent, FfsLocCode, 
PorTransType, PorExpoCode, PorSalOff, ClrAgentStcLoc, 
DeclaredWgt, ETA, ATA, OpenForTPIInvoicing, IsTranshipPO, POSEASON, 
DespatchLoc, RcvingTyp, PoReqOrAct, 
   (Select StocLoc.StcLocDesc
    From StocLoc
    Where StocLoc.StcRecNo = ClrAgentStcLoc) AS ClrAgeDisp, POQCNarRecNo,
   (SELECT QCNarrative
   FROM PalQCNar
   WHERE POQCNarRecNo = QcNarRecNo) AS QCNarrative,
   (select Min(LitBuyer) from lotite Where LitPorRec in(select PorRecNo from Purord Where PorNo = PO) ) LitBuyer
FROM PURORD
Where PorNo = PO
And (Nvl(PorSalOff, -32000) = 2
Or Exists
  (Select OSOSalOffNo From OriginatingSO
   Where OSOPorNo = PO
   And OSOSalOffNo = 2));*/
  CURSOR PURORD_CURSOR  IS  
SELECT PorRecNo, PorNo, ShipDate, ExptdDate, RcvdInd, RcvDate, NVL(PorClosed, 0) PorClosed, PorSalOff, PURORD.DateCreated, 
   LinkLotIte.LitBuyer, LinkLotIte.LitStcLoc, LinkLotIte.LitSenCode,
 (select Min(DELCOMM) POCOMMENT from delcomms where deltyp = 10 and delcommtyprecno = PO) POCOMMENT,   --return only first comment. Note: error if subquery returns more than 1 row.
 (select Min(LHEPayTyp) LHEPayTyp from lothed where LHePorRecNo = PO) LHEPayTyp, 
 (select NVL(Max(AuditRecordNo),0) from auditrecord Where porno = PO) as LastAuditRecNo        
FROM PURORD, 
   (Select Min(LitPorRec) LitPorRec, Min(LitBuyer) LitBuyer, Min(LitStcLoc) LitStcLoc, Min(LitSenCode) LitSenCode  
    FROM Lotite Where LitPorRec = (select porrecno from purord where porno = PO) ) LinkLotIte		
Where PorNo = PO
AND LinkLotIte.LitPorRec = PURORD.PORRECNO
And Nvl(PorSalOff, -32000) = 2;   

--Qty sold can be got in 2 ways... 
--(note - will be invalid during day - only up to date when day end process done, stock dissected then 'update market sales' MktToDeliverNew)
--1) Sum of the itesto.IstSldQty & itesto.IstTrnQty
--2) Sum deltoists and prepalinoutsales.

CURSOR LOTITE_CURSOR IS  
    select lotite.LitIteNo, LitPrdNo, LitOrgExp, LitQtyRcv, Nvl(LitQtyRcv, 0),-- as LitQtyRcv,     
       --0 as QtySold, 
       (select NVL(Itesto.IstSldQty, 0) + NVL(Itesto.IstTrnQty, 0) From Itesto Where Itesto.IstLitNo = lotite.LitIteNo) as QtySold, 
       Nvl(LitUniCost, 0) LitUniCost , Nvl(LitGuidePrice, 0) LitGuidePrice, Nvl(MGPrice, 0) MGPrice, LitID2, LitBuyer, LitPayTyp, 
       (Select Nvl(Min(DptRecNo), 0) from DEPARTMENTSTOSMN Where SmnNo = lotite.LitBuyer) as Dept,
       (Select Max(Lotite.LitIteNo) From LotIte Where LitPorRec = (select porrecno from purord where porno = PO) ) MaxLitIteNo,
       (select Max(AuditRecordNo) from auditrecord Where auditrecord.LitIteNo = lotite.LitIteNo) as LastAuditRecNo
    from lotite
    Where LitPorRec = PO
    Order by lititeNo;

--CURSOR TMPPOHDR IS
--select FT_SEQNO, DEVRECNO, LOGONNO, SALOFFNO, STCRECNO, SMNNO, LHEPAYTYP, CLARECNO, POCOMM, EXPTDDATE, RCVDATE, STATUS, LASTAUDIT, DATECREATED, PORNO 
--from MKTHHELD_POHDR Where porno = PO;
--Not Required! to do a download the PO MUST be a created FT PO. ('same' User can upload a PO that is not created)

BEGIN                          
   IF EC = 0 THEN        
      --MachineIDValidate(MI, EC, ED);
      MachineIDValidate(MI, EC, ED, V_DevRecNo);
   end if; 
   
    IF EC = 0 THEN
      UserLogonValidate(UL, EC, ED);
   end if;
  
   IF EC = 0 THEN
      SalesOfficeValidate(SO, UL, EC, ED);  -- check DeviceToSalOff?
   end if;
   
   IF EC = 0 THEN
      IF NVL(PO, 0) <= 0 THEN
         EC := 919;
         ED := 'PO Number ' || PO ||  ' - Not found';
      END IF; 
   END IF;
   
   --validate user is on correct sales office for PO. (Done Below)
   

   
   --EH Encrypted Hash (handheld password + ticket number)
   
   /*IF EC = 0 THEN
      IF EH is null then
		     EC := 920;
		     ED := 'No Hash Total parameter specified';               
      end if;   
   end if;
   
   IF EC = 0 THEN
      GetHandHeldPassword(UL, vHANDHELDPASSWORD, EC, ED);  
     -- HTP.P(vHANDHELDPASSWORD);
   end if;*/
   
   IF EC = 0 THEN
     --ach! what is the NRecords equivalent for a cursor?
     FOR V_PURORD_RECORD IN PURORD_CURSOR  LOOP 
       begin
          V_NUMPOS := V_NUMPOS + 1;
       end;   
     end loop;
     
      FOR V_LOTITE_RECORD IN LOTITE_CURSOR  LOOP 
       begin
          V_NUMLotites := V_NUMLotites + 1;
       end;   
     end loop;
   end if;
   
  -- IF EC = 0 THEN
       --V_NUMPOS     := PURORD_CURSOR%ROWCOUNT; 
       --V_NUMLotites := LOTITE_CURSOR%ROWCOUNT; 
       
       /*begin
         select count(*) into V_NUMPOS from PURORD_CURSOR;
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EC :=    405;
                    ED :=  ' is not a valid Product';

                WHEN OTHERS THEN
                    EC :=  107;
                    ED := 'Unable to Execute Sql to valid Product information for '|| ' SqlErrM='||  SQLERRM;

            END;*/
   --end if;
   
   IF EC = 0 THEN
     --if no POs it may not be uploaded yet.
      IF V_NUMPOS = 0 THEN
         BEGIN
            SELECT Status INTO V_PornoUpldStatus  FROM MKTHHELD_POHDR where PorNo = PO;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    931;
                --ED := MI || ' PO is not a FreshTrade OR Market PO.';
                ED := ' PO is not a FreshTrade OR Market PO.';

           WHEN OTHERS THEN
              EC :=  932;
              ED := 'Unable to Execute Sql to Obtain PO information for '|| MI || ' SqlErrM='||  SQLERRM;
         END;     
            
         IF EC = 0 THEN 
            if V_PornoUpldStatus = 0 Then
               EC := 931;
               ED := ' Market PO not yet created in FreshTrade: ' || PO;
            end if;
         end if;         
         
       END if; --no purord PO             
   end if;
   
   IF EC = 0 THEN --we have an FT PO      
       if V_NUMLotites = 0 Then
          EC := 937;
          ED := ' PO has no lot items! ' || PO;
       end if;
   end if; --we have 2 populated tables.
   
   IF EC = 0 THEN  --Validate the details before we start to output the header data.
      FOR V_LOTITE_RECORD IN LOTITE_CURSOR  LOOP
      
         V_NUMLotites := V_NUMLotites + 1;     
         IF EC = 0 THEN      
            if V_LOTITE_RECORD.LitPrdNo = NULL Then
                EC := 935;
                ED := MI || ' Fatal Error - Lotite has no product';
            end if;
         end if;   
         
         --check for missing payment type?
         --check for missing or incorrect dept for buyer?
         
      END LOOP;
   END IF;
   
   IF EC = 0 THEN
      FOR V_PURORD_RECORD IN PURORD_CURSOR  LOOP            
      
         IF EC = 0 THEN 
            if SO <> V_PURORD_RECORD.PorSalOff Then
               EC := 920;
               ED := 'This PO is for Sales Office' || V_PURORD_RECORD.PorSalOff;
            end if;
         end if;     
      
         IF EC = 0 THEN         
           IF V_NUMPOS = 1 THEN  --Output PO Header
           
              V_DateCreatedStr := TO_CHAR(V_PURORD_RECORD.DateCreated, 'YYYYMMDD');
              V_ExptdDateStr   := TO_CHAR(V_PURORD_RECORD.ExptdDate, 'YYYYMMDD');
              V_RcvDateStr     := TO_CHAR(V_PURORD_RECORD.RcvDate, 'YYYYMMDD');
              V_StoreLastAuditRecNo := V_PURORD_RECORD.LastAuditRecNo;
           
              HandleOPStr('{"SO": '|| (V_PURORD_RECORD.PorSalOff) || ',', ConCatResultVar);                 --SO Sales Office
              HandleOPStr('"SN": '|| (V_PURORD_RECORD.LitBuyer) || ',', ConCatResultVar);                   --SN Salesman (POs have buyers)
              HandleOPStr('"SL": '|| (V_PURORD_RECORD.LitStcLoc) || ',', ConCatResultVar);                  --SL Stock Location
              HandleOPStr('"CL": '|| (V_PURORD_RECORD.LitSenCode) || ',', ConCatResultVar);                 --CL Clarecno
              HandleOPStr('"PC": "'|| (V_PURORD_RECORD.POComment) || '",', ConCatResultVar);                --PC Purchase Comment
              HandleOPStr('"DT": '|| (V_DateCreatedStr) || ',', ConCatResultVar);                           --DT Entry Date
             -- HandleOPStr('"DT": '|| (V_PURORD_RECORD.DateCreated) || ',', ConCatResultVar);              --DT Entry Date
              HandleOPStr('"ED": '|| (V_ExptdDateStr) || ',', ConCatResultVar);                             --ED Expected Delivery Date
              HandleOPStr('"RD": '|| (V_RcvDateStr)   || ',', ConCatResultVar);                             --RD Receive Date
              HandleOPStr('"PT": '|| (V_PURORD_RECORD.LHePayTyp) || ',', ConCatResultVar);                  --PT Payment Type
              HandleOPStr('"PO": '|| (V_PURORD_RECORD.PorNo) || ',', ConCatResultVar);                      --PO PO Number
              HandleOPStr('"LA": '|| (V_PURORD_RECORD.LastAuditRecNo) || ',', ConCatResultVar);             --LA Last Audit
              HandleOPStr('"PX": '|| (V_PURORD_RECORD.PorClosed) || ',', ConCatResultVar);                  --PX PO Closed
              HandleOPStr('"LINES":[', ConCatResultVar);
           
             /* TmpDateStr := TO_CHAR(V_DNLDORDER_RECORD.DlvDelDate, 'YYYYMMDD'); --TO_DATE(ATRPSTDATE, 'DD/MM/YYYY')
              HandleOPStr('{"SO": '|| (V_DNLDORDER_RECORD.PorSalOff) || ',', ConCatResultVar);                 --SN Salesman
              HandleOPStr('"ST": '|| (V_DNLDORDER_RECORD.DlvDltRecNo) || ',', ConCatResultVar);         --ST Sale Type
              HandleOPStr('"SO": '|| (V_DNLDORDER_RECORD.DlvSalOffNo) || ',', ConCatResultVar);               --SO Sales Office
              HandleOPStr('"SL": '|| (V_DNLDORDER_RECORD.DlvStkLoc) || ',', ConCatResultVar);                 --SL Stock Location 
              HandleOPStr('"CL": '|| (V_DNLDORDER_RECORD.ActCstCode) || ',', ConCatResultVar);                --CL Clarecno
              HandleOPStr('"TN": '|| (V_DNLDORDER_RECORD.TntNo) || ',', ConCatResultVar);                     --TN Ticket Number           
              HandleOPStr('"TB": '|| (V_DNLDORDER_RECORD.TNTTBKRECNO) || ',', ConCatResultVar);               --TB Ticket Book            
              HandleOPStr('"OD": "'|| TmpDateStr || '",', ConCatResultVar);                                     --OD Order Date
              HandleOPStr('"OC": "'|| (V_DNLDORDER_RECORD.DelComm) || '",', ConCatResultVar);                   --OC Order Comment
              HandleOPStr('"NT": "'|| (V_DNLDORDER_RECORD.DlvNettValue) || '",', ConCatResultVar);              --NT Nett Total
              HandleOPStr('"V1": "'|| (V_DNLDORDER_RECORD.DlvVatExtended) || '",', ConCatResultVar);            --V1 Vat 1 Total
              HandleOPStr('"V2": "'|| (V_DNLDORDER_RECORD.DlvVat2Extended) || '",', ConCatResultVar);           --V2 Vat 2 Total
              HandleOPStr('"GT": "'|| (V_DNLDORDER_RECORD.DlvGrossValue) || '",', ConCatResultVar);             --GT Gross Total
              HandleOPStr('"LA": "'|| (V_DNLDORDER_RECORD.Max_DelAudRecNo) || '",', ConCatResultVar);           --LA Last Audit Number
              HandleOPStr('"LINES":[', ConCatResultVar);*/
           END IF;  
        END IF;    
         
      END LOOP;
   END IF;   
   
      
   IF EC = 0 THEN
      V_LotIteLineNo := 0;
      FOR V_LOTITE_RECORD IN LOTITE_CURSOR  LOOP            
      
         IF EC = 0 THEN  
       
           /* select lotite.LitIteNo, LitPrdNo, LitOrgExp, LitQtyRcv, Nvl(LitQtyRcv, 0),-- as LitQtyRcv,   
    0 as QtySold, LitUniCost, LitGuidePrice, LitID2, LitBuyer, LitPayTyp, 
    (Select Nvl(Min(DptRecNo), 0) from DEPARTMENTSTOSMN Where SmnNo = lotite.LitBuyer) as Dept*/
              V_LotIteLineNo := V_LotIteLineNo + 1;
              HandleOPStr('{"LN": '|| (V_LotIteLineNo) || ',', ConCatResultVar);                  --LN Line number
              HandleOPStr('"PR": '|| (V_LOTITE_RECORD.LitPrdNo) || ',', ConCatResultVar);         --PR Product PrcPrdNo
              HandleOPStr('"LE": '|| (V_LOTITE_RECORD.LitOrgExp) || ',', ConCatResultVar);        --LE Quantity Expected
              HandleOPStr('"LR": '|| (V_LOTITE_RECORD.LitQtyRcv) || ',', ConCatResultVar);        --LR Qty Received
              HandleOPStr('"LS": '|| (V_LOTITE_RECORD.QtySold) || ',', ConCatResultVar);          --LS Qty Sold   
              
              LConvertValue (PROCNAME, 'FLOAT', V_LOTITE_RECORD.LitUniCost, NULL, Sttmp, EC, ED);  -- 0.5 becomes .5 (JSON error)
              HandleOPStr('"PV": '|| (Sttmp) || ',', ConCatResultVar);     --PV Purchase Price
              LConvertValue (PROCNAME, 'FLOAT', V_LOTITE_RECORD.LitGuidePrice, NULL, Sttmp, EC, ED);  -- 0.5 becomes .5 (JSON error)
              HandleOPStr('"PB": '|| (Sttmp) || ',', ConCatResultVar);     --PB Guide Price
              LConvertValue (PROCNAME, 'FLOAT', V_LOTITE_RECORD.MGPrice, NULL, Sttmp, EC, ED);  -- 0.5 becomes .5 (JSON error)
              HandleOPStr('"PG": '|| (Sttmp) || ',', ConCatResultVar);      --PG Minimum Guaranteed Price

              HandleOPStr('"LC": "'|| (V_LOTITE_RECORD.LitID2) || '",', ConCatResultVar);         --LC Line Comment
              HandleOPStr('"SD": '|| (V_LOTITE_RECORD.LitBuyer) || ',', ConCatResultVar);         --SD Salesman
              HandleOPStr('"PD": '|| (V_LOTITE_RECORD.LitPayTyp) || ',', ConCatResultVar);        --PD Payment type
              HandleOPStr('"DE": '|| (V_LOTITE_RECORD.Dept) || '}', ConCatResultVar);             --DE Department
              --Removed TV 28Oct13 as not in spec
			  --HandleOPStr('"LA": '|| (V_LOTITE_RECORD.LastAuditRecNo) || '}', ConCatResultVar);   --LA LAST AUDIT NO (not done yet)
         
              IF V_LOTITE_RECORD.LitIteNo < V_LOTITE_RECORD.MaxLitIteNo THEN  --at eot()?
                 HandleOPStr(',' , ConCatResultVar);  --end of current detail seperator.   
              ELSE 
                 HandleOPStr(']}' , ConCatResultVar); 
              END IF;                 
         
         END IF;                   
         
      END LOOP;
   END IF; 
     
   --keep the temp table up to date with the last audit done at the time of download.
   IF EC = 0 THEN
      -- V_PURORD_RECORD.LastAuditRecNo
      BEGIN
            --SELECT Status INTO V_PornoUpldStatus  FROM MKTHHELD_POHDR where PorNo = PO;
            update MKTHHELD_POHDR Set LastAudit = V_StoreLastAuditRecNo Where PorNo = PO; 
      EXCEPTION            
           WHEN OTHERS THEN
              EC :=  933;
              ED := 'Unable to update last audit for PO  '|| PO || ' SqlErrM='||  SQLERRM;
      END;
   end if;   
      
      
   
   
  
   --LOG THE TRANSACTION
   ConCatParamsVar := '?MI='|| MI || 'UL=' || UL || 'EH=' || EH  || 'SO='|| SO  || 'PO='|| PO;   --EH SO PO
	 HANDHELDLOG (MI, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar ) ;
   IF EC != 0 THEN        -- ERROR MESSAGE RETURNED TO SCREEN/INTERFACE
      HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);
   END IF;
   
   

END; --DOWNLOAD_PURCHASE_ORDER


  PROCEDURE PAYMENT (MI IN Varchar2 default null,    --Machine ID
                     UL IN Varchar2 default null,      --User Logon
                     SO IN INTEGER default 0,          --Sales Office
                     SL IN INTEGER default 0,          --Stock Location
                     CL IN Integer default 0,          --Supplier Number (Optional .. 0 means default cash customer) 
                     TB IN INTEGER default 0,          --Ticket Book
                     TN IN INTEGER default 0,          --Ticket number 
					           TT IN INTEGER default 0,          --Transaction Type (ie 1= Cash etc) 
					           PR IN Varchar2 default null,      --Payment Reference
					           NT IN FLOAT default 0.0) IS  	   -- Payment Amount
 
  PROCNAME VARCHAR(40) := 'PAYMENT';
  ConCatParamsVar 			VARCHAR(5000) := '';
  ConCatResultVar 			VARCHAR(5000) := '';
  EC Integer := 0 ; -- Error Code
  ED VarChar2(255) := 'Success'; -- Error Description
  
  V_PAY_FT_SEQNO      MKTHHELD_PAYMENTS.FT_SEQNO%TYPE;
  --V_HDR_FT_SEQNO    MKTHHELD_ORDHDR.FT_SEQNO%TYPE;
  
  V_DevRecNo Integer := 0 ;
  vConv_PayValue Varchar(15) := '';
  V_LogOnNo integer := 0;
BEGIN
   -- Uploads payment details when a ticket is paid for 
   -- puts the data in an intermediate table for FT to upload
   -- properly
   -- BSDL TV 5Nov13

   ---------------------------
   --  This is only a Stub! --
   ---------------------------
   
   MachineIDValidate(MI, EC, ED, V_DevRecNo);

   IF EC = 0 THEN
      UserLogonValidate(UL, EC, ED);
   end if;

   IF EC = 0 THEN
      SalesOfficeValidate(SO, UL, EC, ED);  -- check DeviceToSalOff?
   end if;

   IF EC = 0 THEN
      StockLocationValidate(SL, EC, ED);  -- check DeviceToSalOff?
   end if;
   
   IF EC = 0 THEN --Validate inputs
      if NVL(CL,0) < 1  OR NVL(TB,0) < 1 OR NVL(TN,0)  < 1 OR (NVL(TT,0) < 1 OR NVL(TT,0) > 4) OR PR is null OR NT < 0.000001 Then
            if NVL(CL,0) < 1 Then
               EC :=  150;
               ED := 'Bad CL value passed;' || 'PAYMENTS webservice validation failed - no customer identifier.';
            end if;
            if TB < 0 Then
               EC :=  151;
               ED := 'Bad TB value passed';
            end if;
            if TN < 0 Then
               EC :=  152;
               ED := 'Bad TN value passed';
            end if;
            if TT < 0 OR TT > 4 Then
               EC :=  153;
               ED := 'Bad TT value passed';
            end if;
            if PR is null Then
               EC :=  154;
               ED := 'No PR value passed';
            end if;
            if NT < 0 Then
               EC :=  155;
               ED := 'Bad NT value passed';
            end if;
       end if;     
   end if;   
   
    IF EC = 0 THEN
        BEGIN
            SELECT LOGONNO INTO V_LogOnNo
            FROM LOGONS
            WHERE TRIM(LOGONNAME) = TRIM(UPPER(UL))
            AND AVAILTOMKTHANDHELD = 1
            AND ACTIVE = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    402;
                ED := UL || ' is not a registered active logon for the app';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain LOGONS information for '|| UL || ' SqlErrM='||  SQLERRM;
        END;
     END IF;
   
   --IF EC = 0 THEN
      --LConvertValue (PASSPROCNAME IN VarChar, TYP IN Varchar, PassValInt IN Number, PassValStr IN VarChar, RetVal IN OUT Varchar, EC IN OUT INTEGER, ED IN OUT Varchar2)
      --vConv_PayValue := '';
      --LConvertValue (PROCNAME, 'FLOAT', NT, NULL, vConv_PayValue, EC, ED);
      
      --Bug!
      --10 returned as ####
      --vConv_PayValue := Cast(NT as Varchar(10) );
      vConv_PayValue := Cast(NT as Varchar );
  -- end if;  
  
  IF EC = 0 THEN
     if NT > 100000 then
         EC :=    403;
         ED := NT || ' Monetary value is too large.  Cannot accept a payment of this magnitude.';
     end if;
  end if;
   

                 -- New Header
   IF EC = 0 THEN
                     BEGIN
                         V_PAY_FT_SEQNO       := MKTHHELD_PAYMENTS_FT_SEQNO.NEXTVAL;
                     EXCEPTION
                             WHEN OTHERS THEN
                                EC := 401;
                                ED := 'INVALID PAYMENT HEADER SEQ NO ';
                     END;
   END IF;

  IF EC = 0 THEN
                  -- WRITE THE HEADER RECORD AT THIS STAGE WITH A STATUS OF -1 - WHICH MEANS THAT IT HAS NOT SUCCESSFULLY UPLOADED YET (No need - not editing)
                 
                     BEGIN
                        --INSERT INTO MKTHHELD_PAYMENTS (FT_SEQNO)                        VALUES ( V_PAY_FT_SEQNO);
                                          
                        INSERT INTO MKTHHELD_PAYMENTS (FT_SEQNO, DEVRECNO, LOGONNO, SALOFFNO, STCRECNO, CLARECNO, TNTTBKRECNO, TNTNO, TRANSTYPE, PAYMENTREF, PAYMENTAMT, STATUS, 
                                                       DATE_UPLD, DATE_CRTD) 
                        VALUES ( V_PAY_FT_SEQNO, V_DevRecNo, V_LogOnNo, SO, SL, CL, TB, TN, TT, PR, NT, 0, SYSDATE() , Null);                                          
                     COMMIT;
                     EXCEPTION
                          WHEN OTHERS THEN
                             EC :=  107;
                             ED := 'Unable to Execute Sql to INSERT INTO MKTHHELD_PAYMENTS  SqlErrM= '||  SQLERRM;
                     END;       
   END if;
   


   ConCatParamsVar := '?MI='|| MI || ' UL=' || UL || ' SO=' || SO || ' SL=' || SL ||
                      ' CL='|| CL || ' TB=' || TB || ' TN=' || TN || ' TT=' || TT ||
                      ' PR='|| PR || ' NT=' || NT ;


   HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);

   HANDHELDLOG (MI, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, UL ) ;

END; -- End PAYMENT


PROCEDURE SIGNATURE (MI IN Varchar2 default null,    --Machine ID
                       UL IN Varchar2 default null,    --User Logon
                       TB IN INTEGER default 0,        --Ticket Book
                       TN IN INTEGER default 0,        --Ticket number 
					             FN IN Varchar2 default null) IS -- Filename
  PROCNAME VARCHAR(40) := 'SIGNATURE';
  ConCatParamsVar 			VARCHAR(5000) := '';
  ConCatResultVar 			VARCHAR(5000) := '';
  EC Integer := 0 ; -- Error Code
  ED VarChar2(255) := 'Success'; -- Error Description
  vTB INTEGER := 0;
  vTN INTEGER := 0;
  vTNTRECNO INTEGER := 0;
  V_SIG_SEQNO INTEGER := -1;
  V_DevRecNo DeviceName.DEVRECNO%TYPE := 0;
  V_LOGONNO Logons.LogonNo%Type;
  V_MI DeviceName.DevID%TYPE ;
  V_UL Logons.LOGONNAME%TYPE ;
  
BEGIN
   -- Records the filename of the signature JPG  
   -- that is collected on the device
   -- the actual file is transferred by ftp 
   -- BSDL TV 5Nov13
   
   MachineIDValidate(MI, EC, ED);

   IF EC = 0 THEN
      UserLogonValidate(UL, EC, ED);
   end if;

   IF EC = 0 THEN
      IF FN IS NULL THEN
         EC := 2501;
         ED := 'No Filename passed';
      END IF;
   END IF;
   
   IF EC = 0 THEN
      IF LENGTH(NVL(FN, ' ')) > 100 THEN 
         EC := 2502;
         ED := 'Filename too long (max 100 char)';
      END IF;
   end if;
   
      
   IF EC = 0 THEN
      V_MI := UPPER(MI);
      BEGIN		 
         SELECT DevRecNo INTO V_DevRecNo FROM DeviceName 
         WHERE DEVActive = 1 AND Upper(DevID) = Upper(V_MI);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC := 2503;
                ED := V_MI || ' is not a registered active device';
           WHEN OTHERS THEN
              EC :=  2504;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| V_MI || ' SqlErrM='||  SQLERRM;
      END;
   END IF;

   IF EC = 0 THEN
      V_UL := UL;
      BEGIN
         SELECT LOGONNO INTO V_LOGONNO
         FROM LOGONS
            WHERE LOGONNAME = V_UL
            AND AVAILTOMKTHANDHELD = 1
            AND ACTIVE = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            EC := 2505;
            ED := V_UL || ' is not a registered active logon';

         WHEN OTHERS THEN
            EC :=  2506;
            ED := 'Unable to Execute Sql to Obtain LOGONS information for '|| V_UL || ' SqlErrM='||  SQLERRM;
      END;
   END IF;
   
	 If EC = 0 then
       Begin
		   vTB := NVL(TB, 0);
       vTN := NVL(TN, 0);
       
       Select TNTRECNO
		   INTO vTNTRECNO
		   FROM TKTNT
           Where TNTNO = vTN
           AND TNTTBKRECNO = vTB;

       EXCEPTION
           WHEN NO_DATA_FOUND THEN
                EC :=	2507;
		            ED := vTN || ' is not a valid ticket number from book ' || vTB;

		   WHEN OTHERS THEN
              EC :=  2508;
              ED := 'Unable to Execute Sql to Obtain ticket information for ticket '|| vTN || ' SqlErrM='||  SQLERRM;
       END;
	 END IF;
   
   IF EC = 0 THEN
      BEGIN
         V_SIG_SEQNO       := MKTHHELD_SIGNATURE_SIG_SEQNO.NEXTVAL;
      EXCEPTION
         WHEN OTHERS THEN
            EC := 2509;
            ED := 'Cannot get next Signature record number';
      END;
   END IF;

   IF EC = 0 THEN
     BEGIN
        INSERT INTO MKTHHELD_SIGNATURE 
           ( SIG_SEQNO, DEVRECNO, LOGONNO, TNTTBKRECNO, 
             TNTNO, FILENAME, DATEUPLOADED ) 
        VALUES 
           (  V_SIG_SEQNO,
              V_DevRecNo, --Device Record No
              V_LOGONNO, --Logon No
              vTB, --Ticket Book
              vTN, --Ticket Number
              FN, --FileName
              sysdate
           );
           
        COMMIT;
     EXCEPTION
        WHEN OTHERS THEN
           EC :=  2510;
           ED := 'Unable to Execute Sql to INSERT INTO MKTHHELD_SIGNATURE  SqlErrM= '||  SQLERRM;
     END;       
   END IF;

   ConCatParamsVar := '?MI='|| MI || ' UL=' || UL || ' TB=' || TB || ' TN=' || TN ||
                      ' FN='|| FN ;

   HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);

   HANDHELDLOG (MI, PROCNAME, ConCatParamsVar, EC , ED, ConCatResultVar, UL ) ;

END; -- End PAYMENT



PROCEDURE UPLOAD_SETTINGS (OJ IN VARCHAR2) IS
--Upload user settings for storage on the server in DEVICEUSERSETTINGS
--TV 30Dec13 taken from UPLOAD_ORDERS
     EC INTEGER := 0 ;          -- ERROR CODE
     ED VARCHAR2(255) := '';    -- ERROR DESCRIPTION
	 PROCNAME VARCHAR(40) := 'UPLOAD_SETTINGS';
	 
   ConCatResultVar 			VARCHAR(5000)  := '';

    Settings_Jsonobj          JSON;
    Detail_lines              JSON_LIST;
    Detail_Jsonobj            JSON;

-- HEADER VARIABLES
    V_MachineID         DEVICENAME.DEVID%TYPE;
    V_DevRecNo          DEVICENAME.DEVRECNO%TYPE  ; -- DEVICE NAME FROM QUERY
    V_LogOnNo           DEVICEUSERSETTINGS.LOGONNO%TYPE;
    V_LogOnName         LOGONS.LOGONNAME%TYPE;
    
	  
-- DETAIL VARIABLES
    V_SettingKey        DEVICEUSERSETTINGS.SETTINGKEY%TYPE;
    V_SettingValue      DEVICEUSERSETTINGS.SETTINGVALUE%TYPE;
    
    V_SettingDelete     Boolean;
    
  	V_DEVICEUSERSETTINGS_ROW		DEVICEUSERSETTINGS%ROWTYPE;
    V_DevRecNoCheck integer := 0;
   	vNewLine   BOOLEAN := False;

BEGIN

 -- validate the JSON
    BEGIN
         Settings_Jsonobj := json(OJ);
    EXCEPTION
        WHEN OTHERS THEN
           EC := 401;
           ED := 'INVALID JSON FILE OJ='||  UTL_URL.ESCAPE(OJ);
    END;


	  -- validate the JSON lines
    BEGIN
         Detail_lines   := json_list(Settings_Jsonobj.get('SETTINGS'));
    EXCEPTION
        WHEN OTHERS THEN
           EC := 401;
           ED := 'INVALID JSON FILE (LINES) OJ='||  UTL_URL.ESCAPE(OJ);
    END;

  --ach! Note: if issue = eg. UL not supplied, then the Machine ID is not verified and so log record is for blank devide id/name.
  --Could verify, validate and assign one at a time, but ultimately the WS does return the correct result UL is blank.

 -- ENSURE THE MAIN ELEMENTS EXIST
    IF EC = 0 THEN
        DoesJSONElemExist (PROCNAME, Settings_Jsonobj, 'MI', EC, ED);
        DoesJSONElemExist (PROCNAME, Settings_Jsonobj, 'UL', EC, ED);
    END IF;

 -- PUT THE HEADER JSON VARIABLES INTO OUR VARIABLES
 -- THIS SHOULD TRAP ANY OTHER ISSUES WITH THE VARIABLES eg a number (5) having 6 digits
    IF EC = 0 THEN
        BEGIN
            V_MachineID         := Settings_Jsonobj.get('MI').get_string;
            V_LogOnName         := Settings_Jsonobj.get('UL').get_string;
        EXCEPTION
            WHEN OTHERS THEN
                 EC := 401;
                 ED := 'Invalid JSON File : SqlErrM='||  SQLERRM;
        END;
    END IF;

     -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
    IF EC = 0 THEN
         MachineIDValidate(V_MachineID, EC, ED, V_DevRecNoCheck);
    END IF;

    IF EC = 0 THEN
        BEGIN
           SELECT  DEVRECNO  INTO V_DevRecNo FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = UPPER(V_MachineID);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := V_MachineID || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| V_MachineID || ' SqlErrM='||  SQLERRM;
        END;
    END IF;


     -- CHECK THE DATABASE to see if USER EXISTS AND IS ACTIVE
    IF EC = 0 THEN
        IF V_LogOnName IS NULL THEN
            EC := 401;
            ED := 'You must enter a user logon name (UL)';
        END IF;
    END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if LOGONS EXISTS AND IS ACTIVE
    IF EC = 0 THEN
       BEGIN
           SELECT LOGONNO INTO V_LogOnNo
           FROM LOGONS
           WHERE TRIM(LOGONNAME) = TRIM(UPPER(V_LogOnName))
           AND AVAILTOMKTHANDHELD = 1
           AND ACTIVE = 1;
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
               EC :=    402;
               ED := V_LogOnName || ' is not a registered active logon';

          WHEN OTHERS THEN
             EC :=  107;
             ED := 'Unable to Execute Sql to Obtain LOGONS information for '|| V_LogOnName || ' SqlErrM='||  SQLERRM;
       END;
    END IF;

    
   -----------------!!!VALIDATION DONE!!! ---------Start the upload.

-- SCAN THROUGH THE DETAILS, VALIDATE THEM  AND UPLOAD THEM
-- NOTE THE HEADER FLAG IS NOT WRITTEN AT THIS STAGE

    IF EC = 0 THEN
        FOR i in 1..Detail_lines.count LOOP
            BEGIN
                Detail_Jsonobj :=  json(Detail_lines.get(i));
            EXCEPTION
                WHEN OTHERS THEN
                   EC := 401;
                   ED := 'INVALID DETAILS IN JSON FILE ';
            END;
             -- ENSURE THE DETAIL ELEMENTS EXIST
            IF EC = 0 THEN
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'SK', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'SV', EC, ED);
                DoesJSONElemExist (PROCNAME, Detail_Jsonobj, 'SD', EC, ED);
            END IF;

            -- VALIDATE THAT THESE ELEMENTS ARE INTEGERS, NUMBERS, DATES
            IF EC = 0 THEN
                 IsJSONElemABool(Detail_Jsonobj, 'SD', EC, ED);
            END IF;

           -- PUT THE DETAIL JSON VARIABLES INTO OUR VARIABLES
           -- THIS SHOULD TRAP ANY OTHER ISSUES WITH THE VARIABLES eg a number (5) having 6 digits
            IF EC = 0 THEN
                BEGIN
                    V_SettingKey        := Detail_Jsonobj.get('SK').get_string;
                    V_SettingValue      := Detail_Jsonobj.get('SV').get_string;
                    V_SettingDelete     := Detail_Jsonobj.get('SD').get_bool;
                    
                    
                EXCEPTION
                    WHEN OTHERS THEN
                        EC := 401;
                        ED := 'Invalid Details on JSON File : SqlErrM='||  SQLERRM;
                END;
            END IF;

            IF ((EC = 0) AND (V_SettingKey IS NOT NULL)) Then
               BEGIN
                  -- Check to see if there are existing details
                  vNewLine := False;
                  Select *
                  INTO V_DEVICEUSERSETTINGS_ROW
                  FROM DEVICEUSERSETTINGS
                    WHERE LOGONNO = V_LogOnNo
                        AND SETTINGKEY = V_SettingKey;
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                        vNewLine := True;
                  WHEN OTHERS THEN
                        EC :=  107;
                        ED := 'Unable to Execute Sql to Obtain Line information for user '|| V_LogOnName || ' Setting='|| V_SettingKey || ' SqlErrM='||  SQLERRM;
               END;
            END IF;

            IF EC = 0 THEN
                If ((vNewLine) AND (NOT V_SettingDelete))  THEN
                   BEGIN
                           INSERT INTO DEVICEUSERSETTINGS (
                               LOGONNO, SETTINGKEY, SETTINGVALUE)
                           VALUES (
                               V_LogOnNo, V_SettingKey, V_SettingValue
                                  );
                           COMMIT;
                   EXCEPTION
                           WHEN OTHERS THEN
                              EC :=  107;
                              ED := 'Unable to INSERT INTO DEVICEUSERSETTINGS ('||  SQLERRM || ')';

                   END;
               ELSE --Not newline.
                  If V_SettingDelete THEN
                     BEGIN
                         DELETE FROM DEVICEUSERSETTINGS
                         WHERE LOGONNO = V_LOGONNO
                         AND SETTINGKEY = V_SettingKey;
                         COMMIT;
                     EXCEPTION
                              WHEN OTHERS THEN
                                 EC :=  107;
                                 ED := 'Unable to Execute Sql to DELETE DEVICEUSERSETTINGS  SqlErrM='||  SQLERRM;
                     END;                 
                  ELSE
                     BEGIN
                         UPDATE DEVICEUSERSETTINGS
                         SET SETTINGVALUE = V_SettingValue
                         WHERE LOGONNO = V_LOGONNO
                         AND SETTINGKEY = V_SettingKey;
                         COMMIT;
                     EXCEPTION
                              WHEN OTHERS THEN
                                 EC :=  107;
                                 ED := 'Unable to Execute Sql to UPDATE DEVICEUSERSETTINGS  SqlErrM='||  SQLERRM;
                     END;
                  END IF;
               END IF;
            END IF; --ec = 0
      END LOOP;
   END IF;
 
    
    IF EC = 0 THEN        -- SUCCESS RETURNED
		     HandleOPStr('{
            "EC": 0,
            "ED": "Success"
               }', ConCatResultVar);

    ELSE   -- ERROR MESSAGE RETURNED
         HandleOPStr('{
            "EC": '|| EC || ',
            "ED": "'|| ED ||'"
               }', ConCatResultVar);
    END IF;

  --if UL supplied is null, see if we at least have the offending user. (so log shown is better)
   if V_MachineID IS NULL Then
         BEGIN
            V_MachineID         := Settings_Jsonobj.get('MI').get_string;
         EXCEPTION
             WHEN OTHERS THEN
                EC :=  109;
                --ED := 'Unable to Execute update Sql MKTHHELD_ORDHDR -STATUS = 0 - SqlErrM='||  SQLERRM;
         END;
   end if;

    --Log the transaction
    HANDHELDLOG (V_MachineID , PROCNAME, '?OJ='|| OJ, EC , ED, ConCatResultVar, V_LogOnName) ;

  END; --UPLOAD_SETTINGS END;


--------------------------------------------------------------------------------
--  TV 13th Jan 14  DOWNLOAD_SETTINGS
-------------------------------------------------------------------------------
PROCEDURE DOWNLOAD_SETTINGS (MI IN VARCHAR2 DEFAULT NULL, UL IN VARCHAR2 DEFAULT NULL) IS

     --V1.0 TV 13Jan14
     --  Downloads any setttings for the user

     EC INTEGER := 0 ; -- ERROR CODE
     ED VARCHAR2(255) := ''; -- ERROR DESCRIPTION
	   PROCNAME VARCHAR(40) := 'DOWNLOAD_SETTINGS';

    V_SettingKey     DEVICEUSERSETTINGS.SETTINGKEY%TYPE;
    V_SettingValue   DEVICEUSERSETTINGS.SETTINGVALUE%TYPE;
        
  	V_DEVICEUSERSETTINGS_ROW		DEVICEUSERSETTINGS%ROWTYPE;
    
    V_LogOnNo           DEVICEUSERSETTINGS.LOGONNO%TYPE;
    V_LogOnName         LOGONS.LOGONNAME%TYPE;
    
    VMI DEVICENAME.DEVID%TYPE;
    VUL NUMBER(10);
    V_DEVRECNO DEVICENAME.DEVRECNO%TYPE := ''; -- DEVICE NAME FROM QUERY

    V_CNT         NUMBER(5) := 0;
    -- V_DEVRECNO_STR      NUMBER(5) := 0;

     --TYPE V_LIST_OF_DEV IS TABLE OF DEVICENAME.DEVRECNO%TYPE
     --   INDEX BY PLS_INTEGER;
     --DEVICELIST  V_LIST_OF_DEV;
    -- l_DEVICEROW PLS_INTEGER;
     
     ConCatResultVar 			VARCHAR(2000)  := '';

   
     CURSOR V_SETTINGS_CURSOR(IN_LOGONNO NUMBER) IS
        (SELECT * 
        FROM DEVICEUSERSETTINGS
        WHERE LOGONNO = IN_LOGONNO
        AND SETTINGKEY IS NOT NULL
        ) ;   


  BEGIN

     -- MI = MACHINE ID - UNIQUE IDENTIFIER FOR MACHINE.  PROBABLY THE MAC ADDRESS.

     IF MI IS NULL THEN
        EC := 100;
        ED := 'You must enter a machine name (MI)';
     END IF;

     -- GO THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if DEVICE EXISTS AND IS ACTIVE
     -- & GET THE DEVICE NUMBER
     IF EC = 0 THEN
        VMI := UPPER(MI);
        BEGIN
           SELECT  DEVRECNO
           INTO V_DEVRECNO
           FROM DEVICENAME
           WHERE DEVACTIVE = 1
           AND UPPER(DEVID) = VMI;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EC :=    106;
                ED := MI || ' is not a registered active device';

           WHEN OTHERS THEN
              EC :=  107;
              ED := 'Unable to Execute Sql to Obtain Device information for '|| MI || ' SqlErrM='||  SQLERRM;
        END;
     END IF;
     
    IF EC = 0 THEN
        IF UL IS NULL THEN
            EC := 401;
            ED := 'You must enter a user logon name (UL)';
        END IF;
    END IF;

     -- GOT THROUGH THE INITAL VALIDATION, SO NOW CHECK THE DATABASE to see if LOGONS EXISTS AND IS ACTIVE
    IF EC = 0 THEN
       BEGIN
           SELECT LOGONNO INTO V_LogOnNo
           FROM LOGONS
           WHERE TRIM(LOGONNAME) = TRIM(UPPER(UL))
           AND AVAILTOMKTHANDHELD = 1
           AND ACTIVE = 1;
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
               EC :=    402;
               ED := UL || ' is not a registered active logon';

          WHEN OTHERS THEN
             EC :=  107;
             ED := 'Unable to Execute Sql to Obtain LOGONS information for '|| UL || ' SqlErrM='||  SQLERRM;
       END;
    END IF;

     -- GET A LIST OF Device User Settings for this logon
     IF EC = 0 THEN
        --VUL := UL;
        FOR V_DEVICEUSERSETTINGS_ROW IN V_SETTINGS_CURSOR(V_LogOnNo)  LOOP
            V_CNT := V_CNT + 1;

            IF V_CNT = 1 THEN
               HandleOPStr('{"SETTINGS": [', ConCatResultVar);
            ELSE
               HandleOPStr(',', ConCatResultVar);
            END IF;

            HandleOPStr('{', ConCatResultVar);
            HandleOPStr('"SK": "'|| (V_DEVICEUSERSETTINGS_ROW.SETTINGKEY) || '",', ConCatResultVar);
            HandleOPStr('"SV": "'|| (V_DEVICEUSERSETTINGS_ROW.SETTINGVALUE) || '"}', ConCatResultVar);
        END LOOP;
     END IF;

     IF V_CNT > 0 THEN
        HandleOPStr(']}', ConCatResultVar); 
     END IF;

	   IF V_CNT = 0 THEN
        EC := 1;
        ED := 'Nothing to download for this user';
     END IF;

     IF EC != 0 THEN
        HandleOPStr('{"EC": '|| EC || ', "ED": "'|| ED ||'"}', ConCatResultVar);        
     END IF;
        
     --Log the transaction	.
     HANDHELDLOG (MI, PROCNAME, '?MI='|| MI || ' UL=' || UL , EC , ED, ConCatResultVar, UL ) ;


  END; --DOWNLOAD_SETTINGS




END; --END PACKAGE BODY