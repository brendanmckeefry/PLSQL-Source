create or replace
package MKTHANDHELD_1 as

  PROCEDURE test;
  PROCEDURE SysInfo; --Human readable
  PROCEDURE ServerInfo; --Device parameters returned
  PROCEDURE ValidateJSONString (OJ IN VARCHAR2);
  
  PROCEDURE testparm (UN IN Varchar2);
  
  PROCEDURE PublishTktDets (TN IN Varchar2);

  PROCEDURE heartbeat (MI IN Varchar2 default null, MM IN Varchar2 DEFAULT Null, OS in VarChar2 default null,
                       MS in Varchar2 default null, UN in Varchar2 default null, AP in Varchar2 default null,
					   CV in Number default 0.0);

  PROCEDURE USERS (MI IN VARCHAR2 DEFAULT NULL);

  PROCEDURE MarketHandHeldPrefs (MI IN Varchar2 default null);

  --PROCEDURE ACCOUNTS (SO INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL, LA IN INTEGER DEFAULT NULL);
  PROCEDURE ACCOUNTS (SO INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL);
  --PROCEDURE PRODUCTS (SO INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL, LA IN INTEGER DEFAULT NULL);
  PROCEDURE PRODUCTS (SO INTEGER DEFAULT NULL, MI IN VARCHAR2 DEFAULT NULL);
  PROCEDURE SHORTCODES (SO IN INTEGER DEFAULT 0, MI IN VARCHAR2 DEFAULT NULL);

  PROCEDURE DOWNLOADVAT(MI IN VARCHAR2,
		  			  SO IN INTEGER,
					  SL IN INTEGER,
					  CL IN INTEGER,
					  PR IN INTEGER,
					  EP IN OUT FLOAT);


  PROCEDURE TICKET_DLVRELINV_GETSTATUS (TB INTEGER, TN INTEGER, MI IN VARCHAR2 DEFAULT NULL);


  PROCEDURE AccountBalances(MI IN Varchar2,
		  				SO IN Integer,
						  CL IN Integer,
						  UL IN VarChar2,
						  HT IN VarChar2,
              TB IN Varchar2 DEFAULT NULL,
              TN IN VarChar2 DEFAULT NULL);


  PROCEDURE STOCK_LEVELS (MI IN VARCHAR2 DEFAULT NULL,        -- Machine ID
                        UL IN VARCHAR2 DEFAULT NULL,        -- User Logon
                        SO IN INTEGER  DEFAULT 0,           -- Sales Office
                        SL IN INTEGER  DEFAULT 0,           -- Stock Location
                        PR IN INTEGER  DEFAULT 0,           -- Product Internal Code
                        DE IN INTEGER  DEFAULT 0,           -- Department Code
                        HT IN VARCHAR2 DEFAULT NULL);        -- Hash Total


  PROCEDURE TICKETBOOK (MI IN VARCHAR2 DEFAULT NULL, TB IN INTEGER);

  PROCEDURE RESET_TICKETBOOK ;	  
  
  PROCEDURE RESET_MY_TICKETBOOK (MI IN VARCHAR2 DEFAULT NULL);

  PROCEDURE GetLookUps(MI IN VARCHAR2 DEFAULT NULL);

  PROCEDURE UPLOAD_ORDER (OJ IN VARCHAR2 DEFAULT NULL);

  PROCEDURE DoesJSONElemExist (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2);
  PROCEDURE DoesJSONElemExist (ProcName IN VARCHAR2, IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2);

  PROCEDURE IsJSONElemAnInt (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2);
  PROCEDURE IsJSONElemANumber (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2);
  PROCEDURE IsJSONElemADate (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2);
  PROCEDURE IsJSONElemABool (IN_JSON JSON, ELEM IN VARCHAR2, IN_ERRCODE IN OUT INTEGER,      IN_ERRDESC IN OUT VARCHAR2);


  PROCEDURE HandleOpStr (PASSOPSTR IN VARCHAR2 DEFAULT NULL, CONCATRESULTVAR IN OUT VARCHAR2);
  --PROCEDURE HANDHELDLOG (DEVICEID IN VARCHAR2 DEFAULT NULL, PROCNAME IN VARCHAR2 DEFAULT NULL, PARAMETERS IN VARCHAR2 DEFAULT NULL, ERRORINT IN INTEGER DEFAULT 0, ERRORSTR IN VARCHAR2 DEFAULT NULL, PASSRESULTSTR  IN VARCHAR2 DEFAULT NULL);
  PROCEDURE HANDHELDLOG (DEVICEID IN VARCHAR2 DEFAULT NULL, PROCNAME IN VARCHAR2 DEFAULT NULL, PARAMETERS IN VARCHAR2 DEFAULT NULL, ERRORINT IN INTEGER DEFAULT 0, ERRORSTR IN VARCHAR2 DEFAULT NULL, PASSRESULTSTR  IN VARCHAR2 DEFAULT NULL, PASSLOGONNAME IN VARCHAR2 DEFAULT NULL);
  
  PROCEDURE UserLogonValidate (UL IN Varchar2 default null, EC IN OUT INTEGER, ED IN OUT Varchar2);
  --PROCEDURE MachineIDValidate (MI IN Varchar2 default null, EC IN OUT INTEGER, ED IN OUT Varchar2);
  PROCEDURE MachineIDValidate (MI IN Varchar2 default null, EC IN OUT INTEGER, ED IN OUT Varchar2, DR IN OUT INTEGER);
  PROCEDURE SalesOfficeValidate (SO IN Integer default null, UL IN Varchar2 default null, EC IN OUT INTEGER, ED IN OUT Varchar2);
  PROCEDURE StockLocationValidate (SL IN Integer default null, EC IN OUT INTEGER, ED IN OUT Varchar2);
  PROCEDURE GetLogonNo (UL IN Varchar2 default null, LN IN OUT Integer, EC IN OUT INTEGER, ED IN OUT Varchar2);
  PROCEDURE GetHandHeldPassword(UL IN Varchar2, PW IN OUT Varchar2, EC IN OUT INTEGER, ED IN OUT Varchar2);
  
  PROCEDURE LConvertValue (PASSPROCNAME IN VarChar, TYP IN Varchar, PassValInt IN Number, PassValStr IN VarChar, RetVal IN OUT Varchar, EC IN OUT INTEGER, ED IN OUT Varchar2);
  PROCEDURE LValidateValue (PASSVALIDATETYPE IN VarChar, PASSVALIDATEFORMAT IN Varchar, LAllowNull IN Boolean, PASSVALIDATEVALUE IN VarChar, CallingProcName IN Varchar, CallingParamName IN Varchar, LIsValid IN OUT Boolean, EC IN OUT INTEGER, ED IN OUT Varchar2); 
  
 PROCEDURE DOWNLOAD_ORDER (MI IN Varchar2 default null,    --Machine ID
                          UL IN Varchar2 default null,      --User Logon
                          EH IN Varchar2 default null,      --Encryped Has Password + ticket MD5
                          SO IN INTEGER default 0,          --Sales Office
                          SL IN INTEGER default 0,          --Stock Location
                          TB IN INTEGER default 0,          --Ticket Number
                          BT IN INTEGER default 0);         --Ticket Book (Optional)
  
 PROCEDURE SEARCH_ORDERS (MI IN Varchar2 default null,    --Machine ID
                          UL IN Varchar2 default null,      --User Logon
                          EH IN Varchar2 default null,      --Encryped Hash Password + ticket MD5
                          SO IN INTEGER default 0,          --Sales Office
                          SL IN INTEGER default 0,          --Stock Location
                          TB IN INTEGER default 0,          --Ticket Number (Optional)
                          SU IN varchar2 default null,      --Search User Name (Optional)
                          EF IN varchar2 default TO_CHAR (sysdate - 14, 'YYYYMMDD'),      --Search Date From (Optional)(CCYYMMDD)
                          ET IN varchar2 default TO_CHAR (sysdate + 14, 'YYYYMMDD'),      --Search Date To (Optional)(CCYYMMDD)
                          CL IN Integer default 0,          --Customer Number (Optional) 
                          PO IN Integer default 0,          --Lot Number, PO (Optional)
                          PR IN Integer default 0,          --Product (Optional)
                          SS IN Integer default 0,          --Search Status (Optional)
                          MR IN Integer default -1,
                          PS IN Varchar2 default null);        --Max Records (-1 = all)(Optional)
   

  PROCEDURE SEARCH_PO    (MI IN Varchar2 default null,      --Machine ID
                          UL IN Varchar2 default null,      --User Logon
                          EH IN Varchar2 default null,      --Encryped Hash Password + Stock Location MD5
                          SO IN INTEGER default 0,          --Sales Office
                          SL IN INTEGER default 0,          --Stock Location
                          SU IN varchar2 default null,      --Search User Name (Optional)
                          EF IN varchar2 default TO_CHAR (sysdate - 14, 'YYYYMMDD'),      --Search Date From (Optional)(CCYYMMDD)
                          ET IN varchar2 default TO_CHAR (sysdate + 14, 'YYYYMMDD'),      --Search Date To (Optional)(CCYYMMDD)
                          SC IN Integer default 0,          --Supplier Number (Optional) 
                          PO IN Integer default 0,          --PO Number, PO (Optional)
                          LT IN Integer default 0,          --Lot Number (Optional)
                          PR IN Integer default 0,          --Product (Optional)
                          DE IN Integer default 0,          --Department (Optional)
                          SS IN Integer default 0,          --Search Status (Optional)
                          MR IN Integer default -1);        --Max Records (-1 = all)(Optional)

                          
   PROCEDURE LOT_USAGE   (MI IN Varchar2 default null,      --Machine ID
                          UL IN Varchar2 default null,      --User Logon
                          EH IN Varchar2 default null,      --Encryped Hash Password + Stock Location MD5
                          SO IN INTEGER default 0,          --Sales Office
                          SL IN INTEGER default 0,          --Stock Location
                          LT IN Integer default 0);         --Lot Number 
                          
  PROCEDURE UPLOAD_PURCHASE_ORDER (OJ IN VARCHAR2 DEFAULT NULL);                        
                         
  PROCEDURE DOWNLOAD_PO (MI IN Varchar2 default null,    --Machine ID
                          UL IN Varchar2 default null,      --User Logon
                          EH IN Varchar2 default null,      --Encryped Has Password + PO MD5
                          SO IN INTEGER default 0,          --Sales Office
                          PO IN INTEGER default 0);         --Purchase Order
                          
						  
  PROCEDURE PAYMENT (MI IN Varchar2 default null,    --Machine ID
                     UL IN Varchar2 default null,      --User Logon
                     SO IN INTEGER default 0,          --Sales Office
                     SL IN INTEGER default 0,          --Stock Location
                     CL IN Integer default 0,          --Supplier Number (Optional .. 0 means default cash customer) 
                     TB IN INTEGER default 0,          --Ticket Book
                     TN IN INTEGER default 0,          --Ticket number 
					           TT IN INTEGER default 0,          --Transaction Type (ie 1= Cash etc) 
					           PR IN Varchar2 default null,      --Payment Reference
					           NT IN FLOAT default 0.0);		   -- Payment Amount
                                       
								  
  PROCEDURE SIGNATURE (MI IN Varchar2 default null,    --Machine ID
                       UL IN Varchar2 default null,    --User Logon
                       TB IN INTEGER default 0,        --Ticket Book
                       TN IN INTEGER default 0,        --Ticket number 
					             FN IN Varchar2 default null);	 -- Filename
                       
  PROCEDURE UPLOAD_SETTINGS (OJ IN VARCHAR2 DEFAULT NULL);
  
  PROCEDURE DOWNLOAD_SETTINGS (MI IN VARCHAR2 DEFAULT NULL, UL IN VARCHAR2 DEFAULT NULL);

                        

  
end;