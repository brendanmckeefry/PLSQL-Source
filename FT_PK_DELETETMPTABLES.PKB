create or replace PACKAGE BODY FT_PK_DELETETMPTABLES AS

  CVERSIONCONTROLNO   VARCHAR2(12) := '1.0.1'; -- Current Version Number
  
  -- CURRENTVERSION public method returns the Version number of the header or body
  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
         RETURN cSpecVersionControlNo;
    ELSE  
        RETURN cVersionControlNo;
    END IF;        
  END CURRENTVERSION;

  PROCEDURE RUNNIGHTLY AS
    BEGIN
      DELETEPDOX_TEMPTABLES;
      DELETEPDOX_TEMPSEQUENCES;
      DELETEUSERSESSION_RECORDS;      
      DELETEPREINVTEMPDATA;
    END RUNNIGHTLY;
    
  PROCEDURE DELETEPDOX_TEMPTABLES AS
    BEGIN
      DECLARE
      	  LCONT			 		NUMBER(1);
          LDELTMPTAB			NUMBER(1);
      	  V_TMPTABNAME			CHAR(100);
          V_UNDERSCOREPOS		NUMBER(5);
          V_SQLSTR				VARCHAR(32675);
          V_JAVIERTMPTAB		VARCHAR(2);
          
          CURSOR TMPTABLELIST_CURSOR IS
            SELECT DISTINCT TABLE_NAME AS EXISTINGTABLE
          FROM USER_TABLES
          WHERE  TABLE_NAME LIKE 'TMP%';
          TMPTABLE_RECORD TMPTABLELIST_CURSOR%ROWTYPE;

    BEGIN
   LCONT := 1;

-- DELETE THE UNREQUIRED TABLES
   IF  LCONT = 1 THEN
   BEGIN
   		OPEN TMPTABLELIST_CURSOR ;
      LOOP
			FETCH TMPTABLELIST_CURSOR INTO TMPTABLE_RECORD;
			EXIT WHEN TMPTABLELIST_CURSOR%NOTFOUND;

			V_TMPTABNAME  := TMPTABLE_RECORD.EXISTINGTABLE;

      IF LENGTH(V_TMPTABNAME) > 5 THEN
      BEGIN
          -- REMOVE THE TMP PART
          V_TMPTABNAME    := SUBSTR(V_TMPTABNAME, 4, LENGTH(V_TMPTABNAME)-3);
          V_UNDERSCOREPOS := INSTR(V_TMPTABNAME, '_');

          IF V_UNDERSCOREPOS > 0 THEN
          BEGIN
              LDELTMPTAB := 0;
              IF LENGTH(V_TMPTABNAME) > 2 THEN
              BEGIN
                -- javiers temp tables are in the format tmp__abc - CHECK TO SEE IF THIS IS ONE OF THEM
                V_JAVIERTMPTAB := SUBSTR(V_TMPTABNAME, 1, 2);
                IF  V_JAVIERTMPTAB = '__' THEN
                BEGIN
                  LDELTMPTAB := 1;
                END;
                END IF;
              END;
              END IF;
              IF LDELTMPTAB = 0 THEN
              BEGIN
                V_TMPTABNAME := SUBSTR(V_TMPTABNAME, 1, V_UNDERSCOREPOS-1);
                
                -- CHECK TO SEE IF THE SESSION NO IS STILL VALID                 
                LDELTMPTAB := ISSESSIONNOLONGERVALID(V_TMPTABNAME);
              END;
              END IF;
					
            /*INSERT INTO AA_LISTDELTMPTABS (TABNAME, UNIQNO, DEL)
              VALUES(TMPTABLE_RECORD.EXISTINGTABLE, V_TMPTABNAME, LDELTMPTAB);
            COMMIT;*/
  
            IF LDELTMPTAB = 1 THEN
            BEGIN
              V_SQLSTR := 'DROP TABLE ' ||TO_CHAR(TMPTABLE_RECORD.EXISTINGTABLE) || '  CASCADE CONSTRAINTS';
              EXECUTE IMMEDIATE V_SQLSTR;
            EXCEPTION
              WHEN OTHERS THEN
                LCONT := 0;
                FT_PK_ERRORS.LOG_AND_STOP;
            END;
            END IF ;
          END;
					END IF;
      END ;
			END IF ;
     	END LOOP;
		COMMIT;
		CLOSE TMPTABLELIST_CURSOR;

   END;
 END IF ;
END;
END DELETEPDOX_TEMPTABLES;
    
    
-- DO THE SEQUENCES
-- THERE MAY BE AN ARGUEMENT TO KEEP THESE TO SEE WHAT SESSIONS HAVE CRASHED OUT BUT THAT IS AVAILABLE IN USERSESSNOLOG IF YOU WANT IT
  PROCEDURE DELETEPDOX_TEMPSEQUENCES AS
  BEGIN
    DECLARE
      	  V_SQLSTR				VARCHAR(32675);
          LDELTMPTAB			NUMBER(1);
          V_TMPTABNAME			CHAR(100);
          V_UNDERSCOREPOS		NUMBER(5);
          
          CURSOR SEQUENCE_CURSOR IS
            SELECT DISTINCT SEQUENCE_NAME
          FROM USER_SEQUENCES
          WHERE  SEQUENCE_NAME LIKE 'TMP%';
          SEQUENCE_RECORD SEQUENCE_CURSOR%ROWTYPE;
          
    BEGIN
    	OPEN SEQUENCE_CURSOR ;
      LOOP
			FETCH SEQUENCE_CURSOR INTO SEQUENCE_RECORD;
			EXIT WHEN SEQUENCE_CURSOR%NOTFOUND;

			V_TMPTABNAME  := SEQUENCE_RECORD.SEQUENCE_NAME;

      IF LENGTH(V_TMPTABNAME) > 5 THEN
      BEGIN
        -- REMOVE THE TMP PART
				V_TMPTABNAME    := SUBSTR(V_TMPTABNAME, 4, LENGTH(V_TMPTABNAME)-3);
				V_UNDERSCOREPOS := INSTR(V_TMPTABNAME, '_');

				IF V_UNDERSCOREPOS > 0 THEN
				BEGIN
	 				 V_TMPTABNAME := SUBSTR(V_TMPTABNAME, 1, V_UNDERSCOREPOS-1);
	 				 -- CHECK TO SEE IF THE SESSION NO IS STILL VALID                 
           LDELTMPTAB := ISSESSIONNOLONGERVALID(V_TMPTABNAME);
	 				 
	 				/*INSERT INTO AA_LISTDELTMPTABS (TABNAME, UNIQNO, DEL)
	  				VALUES(SEQUENCE_RECORD.SEQUENCE_NAME, V_TMPTABNAME, LDELTMPTAB);
	 				COMMIT;*/

					IF LDELTMPTAB = 1 THEN
					BEGIN
            V_SQLSTR := 'DROP SEQUENCE ' ||TO_CHAR(SEQUENCE_RECORD.SEQUENCE_NAME) ;
			   		EXECUTE IMMEDIATE V_SQLSTR;
          EXCEPTION
	    			WHEN OTHERS THEN
							 FT_PK_ERRORS.LOG_AND_STOP;
					END;
					END IF ;
        END ;
				END IF ;
      END ;
			END IF ;
     	END LOOP;
		COMMIT;
		CLOSE SEQUENCE_CURSOR;      
      
   END;  
END DELETEPDOX_TEMPSEQUENCES;    

-- DO THE FRESHTRADE USER SESSIONS    
-- THERE MAY BE AN ARGUEMENT TO KEEP THESE TO SEE WHAT SESSIONS HAVE CRASHED OUT BUT THAT IS AVAILABLE IN USERSESSNOLOG IF YOU WANT IT
  PROCEDURE DELETEUSERSESSION_RECORDS AS
  BEGIN
    DECLARE
      	  V_SQLSTR				VARCHAR(32675);

          CURSOR DEL_SESSNO_CURSOR  IS
            SELECT USERSESSRECNO    FROM USERSESSNO
            WHERE NOT EXISTS ( SELECT 1 FROM
                  (SELECT DISTINCT TO_CHAR(AUDSID) UNIQNO FROM V$SESSION WHERE AUDSID > 0) TMP,
                  USERSESSNOLOG
                  WHERE USERSESSNO.USLRECNO =  USERSESSNOLOG.USLRECNO
                  AND TMP.UNIQNO = USERSESSNOLOG.ORACLESESSRECNO);
            DEL_SESSNO_RECORD DEL_SESSNO_CURSOR%ROWTYPE;
    BEGIN
      OPEN DEL_SESSNO_CURSOR ;
      LOOP
			FETCH DEL_SESSNO_CURSOR INTO DEL_SESSNO_RECORD;
			EXIT WHEN DEL_SESSNO_CURSOR%NOTFOUND;
        BEGIN
          V_SQLSTR := 'DELETE FROM USERSESSNO where USERSESSRECNO = '|| DEL_SESSNO_RECORD.USERSESSRECNO;
          EXECUTE IMMEDIATE V_SQLSTR;
          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            FT_PK_ERRORS.LOG_AND_STOP;
          END;
     	END LOOP;
      COMMIT;
      CLOSE DEL_SESSNO_CURSOR;
   END;  
END DELETEUSERSESSION_RECORDS;    


-- delete the temporary data created by PREINV 
PROCEDURE DELETEPREINVTEMPDATA AS
  BEGIN    
    BEGIN   
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_PREINVDISCTYP D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_PREINVPRT D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_PREINVPRT2 D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_PREINVTOT D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_INVPRT2 D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_INVPRT D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_INVTOT D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_INVERR D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_INVEDI D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM
          (
            SELECT D.EXTRACTSESSIONID
            FROM PREINVTEMP_INVDISCTYP D
              INNER JOIN PREINVTEMP_INVEXTRACTHED E ON E.EXTRACTSESSIONID = D.EXTRACTSESSIONID
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
        
          DELETE FROM 
          (
            SELECT E.SALESOFFICENO
            FROM PREINVTEMP_INVEXTRACTHED E
              LEFT JOIN SALOFFNO S ON S.SALOFFNO = E.SALESOFFICENO AND S.INUSE = 1
            WHERE S.SALOFFNO IS NULL
          );
          COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
    END;
     	
END DELETEPREINVTEMPDATA;   
    
  FUNCTION ISSESSIONNOLONGERVALID(IN_SESSIONNO IN VARCHAR) RETURN NUMBER 
  IS
    CNTRECS			 		NUMBER(5) := 0;
  BEGIN
            
    IF IN_SESSIONNO IS NULL THEN
      RETURN 0 ; 
    END IF;
    
    BEGIN      
          SELECT COUNT(*) INTO CNTRECS  FROM USERSESSNO
          WHERE  USERSESSRECNO = TO_NUMBER(IN_SESSIONNO)
          AND EXISTS ( SELECT 1 FROM
                (SELECT DISTINCT TO_CHAR(AUDSID) UNIQNO FROM V$SESSION WHERE AUDSID > 0) TMP,
                USERSESSNOLOG
                WHERE USERSESSNO.USLRECNO =  USERSESSNOLOG.USLRECNO
                AND TMP.UNIQNO = USERSESSNOLOG.ORACLESESSRECNO);
    EXCEPTION
          WHEN OTHERS THEN
            FT_PK_ERRORS.LOG_AND_STOP;
		END;  
      
    IF  CNTRECS > 0 THEN 
          RETURN 0 ; 
    END IF;
      
    RETURN 1 ;           
      
  END ISSESSIONNOLONGERVALID;
  
  
  END FT_PK_DELETETMPTABLES;