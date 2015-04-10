create or replace
PROCEDURE     BSDL_EMAIL(SENTFROM			   IN VARCHAR2,
									   SENDTO              IN VARCHAR2,
									   CCTO                IN VARCHAR2,
									   BCCTO               IN VARCHAR2,
 									   SUBJECT             IN VARCHAR2,
                                       MESSAGE             IN CLOB,
                                       ATTACHMENTFILENAME  IN VARCHAR2 DEFAULT NULL
									   ) IS
   /* TV 3Nov09 .. procedure to send an email with attachments	Version 1.0a
      PMT/TV 13Aug14 Changed message to CLOB and added default L_FIXED_FROM_NAME 
 
 
   Stolen from code found on the Web, but extensively mucked around with!

   SENDFROM - One email address, need not be a genuine email address (ie can be 'dummy@test.com' etc) but some email
              servers will reject incorrectly formed from addresses.
   SENDTO   - Can have multiple recipients, separate the list with commas ie 'tvivian@beresfordsoftware.com,home@timvivian.com'
   CCTO     - As SENDTO above but CC recipients
   BCCTO    - As SENDTO above but BCC recipients
   SUBJECT  - Text string that contains the 'Subject' of the email
   MESSAGE  - Text string with the body of the email
   ATTACHMENTFILENAME - Can have multiple attachments, separate the list with commas ie 'file1.pdf, file3.gif''
                        Leave blank or null if there are no attachments

   All errors are returned as Oracle Exceptions	 					'

   Usage

     Before you can use this you need to set up the parameters below and also set an Oracle
	 directory using:

       CREATE OR REPLACE DIRECTORY BSDLATTACHMENTDIRECTORY AS '\\svbsdl01\TEMP';
	   GRANT READ,WRITE ON DIRECTORY BSDLATTACHMENTDIRECTORY TO TEST111;

     Then the sample below should work!
     CALL BSDL_EMAIL( 'Test@BeresfordSoftware.com','TVivian@BeresfordSoftware.com', '', '', 'Email Test', 'Test from BSDL_EMAIL',  '');
   */


   /** Setup Parameters ... set these up for each server **/
   L_SMTP_SERVER       CONSTANT VARCHAR2(20) := '10.1.1.139';                 /* Email server	*/ 
   L_SMTP_SERVER_PORT  CONSTANT NUMBER       := 25;                           /* Port on Email server	*/
   MAX_SIZE            CONSTANT NUMBER := 9999999999;                         /* Maximum message size in bytes */
   L_DIRECTORY_NAME    CONSTANT VARCHAR2(200):= 'BSDLATTACHMENTDIRECTORY';    /* This is an ORACLE directory */

   /* If this is not null then every email will be sent from this email address regardless of the 
      value passed in in the SENTFROM parameter.  This is because Microsoft Online only allows 
      emails to be sent from a certain number of email addresses.  Lotus Notes never cared! */
   L_FIXED_FROM_NAME   CONSTANT VARCHAR2(50) := 'noreply@totalproduce.com';   

   VSTART NUMBER := 1;
   VLENGTH NUMBER := 3999; -- What ever size to split the CLOB into

   /* Program parameters ... these don't need changing */
   MAX_BASE64_LINE_WIDTH         CONSTANT PLS_INTEGER    := 76 / 4 * 3 ;
   MIME_BOUNDARY                 CONSTANT VARCHAR(200) := 'TDV.MimeBoundary.01216664820';
   DELIM                         CONSTANT VARCHAR2(2)  := ',';  /* This is the delimeter between email addresses and filenames */

   L_LINE                        VARCHAR2(1000);                  /** TO STORE THE CONTENTS OF THE LINE READ FROM THE FILE **/
   CRLF                          VARCHAR2(2):= CHR(13) || CHR(10);
   L_MESG                        CLOB;                 /** TO STORE THE MESSAGE **/
   L_RAWDATA                     RAW(32767);                      /** STORE THE RAW DATA AS COPIED FROM THE ATTACMENT FILE TV 29JUL09 **/
   CONN                          UTL_SMTP.CONNECTION;             /** SMTP CONNECTION VARIABLE **/
   L_FILE_HANDLE                 UTL_FILE.FILE_TYPE;             /** FILE POINTER **/
   L_MESG_LEN                    NUMBER;                         /** TO STORE THE LENGHT OF THE MESSAGE **/

   ABORT_PROGRAM                 EXCEPTION;                      /** USER DEFINED EXCEPTION **/

   MESG_LENGTH_EXCEEDED          BOOLEAN := FALSE;               /** BOOLEAN VARIABLE TO TRAP IF THE MESSAGE LENGTH IS EXCEEDING **/

   RETURN_DESC1                  VARCHAR2(2000);                 /** VARIABLE TO STORE THE ERROR MESSAGE. TO BE RETURNED TO THE CALLING PROGRAM **/

   TEMPSTR                       VARCHAR2(32000);	    	   	 /* Used in parsing sendto and filename strings */
   DELIM_POS                     INTEGER;
   ONESENDTO                     VARCHAR2(1000);
   ONEATTACHMENTFILENAME         VARCHAR2(1000);
   vSENTFROM                     VARCHAR2(100);

/**** MAIN PROGRAM STARTS HERE ****/

BEGIN
   /* TV 19Dec13 */
   IF L_FIXED_FROM_NAME IS NULL 
   THEN
      vSENTFROM := SENTFROM;
   ELSE
      vSENTFROM := L_FIXED_FROM_NAME;
   END IF;


   IF vSENTFROM IS NULL
   THEN
      RETURN_DESC1  := '10 - E: NO SENDER EMAIL ADDRESS. ';
      RAISE ABORT_PROGRAM;	  
   END IF;

   IF ((SendTo IS NULL) AND (CCTO IS NULL) AND (BCCTO IS NULL))
   THEN
      RETURN_DESC1  := '20 - E: NO EMAIL ADDRESS TO SEND TO OR CC OR BCC. ';
      RAISE ABORT_PROGRAM;	  
   END IF;


   RETURN_DESC1  := '30 - E: THERE WAS AN ERROR IN OPENING CONNECTION. ';
   CONN:= UTL_SMTP.OPEN_CONNECTION( L_SMTP_SERVER, L_SMTP_SERVER_PORT ); /** OPEN CONNECTION ON THE SERVER **/

   UTL_SMTP.HELO( CONN, L_SMTP_SERVER );                                 /** DO THE INITIAL HAND SHAKE **/

   RETURN_DESC1  := '40 - E: THERE WAS AN ERROR IN THE SENDER ADDRESS <'||vSENTFROM||'>';   
   UTL_SMTP.MAIL( CONN, vSENTFROM );


   RETURN_DESC1  := '50 - E: THERE WAS AN ERROR IN PARSING/CREATING RECIPIENT(S) <'||SendTo||'>';
   TempStr := TRIM(SendTo);
   LOOP
      IF TEMPSTR IS NOT NULL
      THEN
	     /*  Split the SendTo string to give all the recipients  */
 	     DELIM_POS := INSTR (TEMPSTR, DELIM);
	     IF DELIM_POS > 0
	     THEN
		    /* Found a delimeter */
		    ONESENDTO := SUBSTR (TEMPSTR, 1, Delim_Pos-1);
    	    TEMPSTR   := SUBSTR (TEMPSTR, Delim_Pos+1);
   	     ELSE
			/* get the last one in the SendTo string */
			ONESENDTO := TempStr;
	 	    TempStr   := NULL;
         END IF;
		 ONESENDTO := Trim(ONESENDTO);

		 IF ONESENDTO IS NOT NULL
		 THEN
            UTL_SMTP.RCPT( CONN, ONESENDTO);
		 END IF;

      ELSE
	     EXIT;
      END IF;
   END LOOP;


   RETURN_DESC1  := '60 - E: THERE WAS AN ERROR IN PARSING/CREATING CC RECIPIENT(S) <'||CCTo||'>';
   TempStr := TRIM(CCTo);
   LOOP
      IF TEMPSTR IS NOT NULL
      THEN
	     /*  Split the SendTo string to give all the recipients  */
 	     DELIM_POS := INSTR (TEMPSTR, DELIM);
	     IF DELIM_POS > 0
	     THEN
		    /* Found a delimeter */
		    ONESENDTO := SUBSTR (TEMPSTR, 1, Delim_Pos-1);
    	    TEMPSTR   := SUBSTR (TEMPSTR, Delim_Pos+1);
   	     ELSE
			/* get the last one in the SendTo string */
			ONESENDTO := TempStr;
	 	    TempStr   := NULL;
         END IF;
		 ONESENDTO := Trim(ONESENDTO);

		 IF ONESENDTO IS NOT NULL
		 THEN
            UTL_SMTP.RCPT( CONN, ONESENDTO);
		 END IF;

      ELSE
	     EXIT;
      END IF;
   END LOOP;



   RETURN_DESC1  := '70 - E: THERE WAS AN ERROR IN PARSING/CREATING BCC RECIPIENT(S) <'||BCCTo||'>';
   TempStr := TRIM(BCCTo);
   LOOP
      IF TEMPSTR IS NOT NULL
      THEN
	     /*  Split the SendTo string to give all the recipients  */
 	     DELIM_POS := INSTR (TEMPSTR, DELIM);
	     IF DELIM_POS > 0
	     THEN
		    /* Found a delimeter */
		    ONESENDTO := SUBSTR (TEMPSTR, 1, Delim_Pos-1);
    	    TEMPSTR   := SUBSTR (TEMPSTR, Delim_Pos+1);
   	     ELSE
			/* get the last one in the SendTo string */
			ONESENDTO := TempStr;
	 	    TempStr   := NULL;
         END IF;
		 ONESENDTO := Trim(ONESENDTO);

		 IF ONESENDTO IS NOT NULL
		 THEN
            UTL_SMTP.RCPT( CONN, ONESENDTO);
		 END IF;

      ELSE
	     EXIT;
      END IF;
   END LOOP;


   UTL_SMTP.OPEN_DATA ( CONN );

   /*** GENERATE THE MIME HEADER ***/

   RETURN_DESC1  := '80 - E: THERE WAS AN ERROR IN GENERATING MIME HEADER. ';

   L_MESG:= 'Date: ' || TO_CHAR( SYSDATE, 'dd Mon yy hh24:mi:ss' ) || CRLF ||
            'From: ' || vSENTFROM || CRLF ||
            'Subject: ' || SUBJECT || CRLF ||
            'To: ' || SENDTO || CRLF ||
			'CC: ' || CCTO || CRLF ||
            'Mime-Version: 1.0' || CRLF ||
            'Content-Type: multipart/mixed; boundary="'|| MIME_BOUNDARY || '"' || CRLF ||
            '' || CRLF ||
            'This is a Mime message, which your current mail reader may not' || CRLF ||
            'understand. Parts of the message will appear as text. If the remainder' || CRLF ||
            'appears as random characters in the message body, instead of as' || CRLF ||
            'attachments, then you''ll have to extract these parts and decode them' || CRLF ||
            'manually.' || CRLF ||
            '' || CRLF ||
            '--' || MIME_BOUNDARY || CRLF ||
            'Content-Type: text/plain; name="message.txt"; charset=US-ASCII' || CRLF ||
            'Content-Disposition: inline; filename="message.txt"' || CRLF ||
            'Content-Transfer-Encoding: 7bit' || CRLF ||
            '' || CRLF ||
            MESSAGE || CRLF || CRLF || CRLF ;

   L_MESG_LEN := LENGTH(L_MESG);

   RETURN_DESC1  := '90 - E: THERE WAS AN ERROR IN WRITING MESSAGE TO CONNECTION. ';
   
    -- If the Body of the message is too large break up inserting into segments
    IF LENGTH(L_MESG) > VLENGTH THEN
      -- Build message in segments
      LOOP
        IF VSTART + VLENGTH <= LENGTH(L_MESG) + 1 THEN
          UTL_SMTP.WRITE_DATA(CONN , SUBSTR(L_MESG, VSTART, VLENGTH));
        END IF;
        VSTART := VSTART + VLENGTH;
        EXIT WHEN VSTART + VLENGTH > LENGTH(L_MESG);
      END LOOP;
      UTL_SMTP.WRITE_DATA(CONN, SUBSTR(L_MESG, VSTART, LENGTH(L_MESG) - VSTART + 1));
    ELSE 
      UTL_SMTP.WRITE_DATA(CONN, L_MESG);
    END IF;
   
   --UTL_SMTP.WRITE_DATA ( CONN, L_MESG);

   /*** START ATTACHING THE FILES ***/
   TempStr := ATTACHMENTFILENAME;

   LOOP

      IF TEMPSTR IS NULL
      THEN
  	     /* No More Files to attach*/
         EXIT;
      ELSE
         /*  Split the ATTACHMENTFILENAME string to give all the recipients  */
 	     DELIM_POS := INSTR (TEMPSTR, DELIM);
	     IF DELIM_POS > 0
	     THEN
		    /* Found a delimeter */
		    ONEATTACHMENTFILENAME := SUBSTR (TEMPSTR, 1, Delim_Pos-1);
    	    TEMPSTR := SUBSTR (TEMPSTR, Delim_Pos+1);
   	     ELSE
			/* get the last one in the attachmentfilename string */
		    ONEATTACHMENTFILENAME := TempStr;
	 	    TempStr := NULL;
         END IF;
		 ONEATTACHMENTFILENAME := TRIM(ONEATTACHMENTFILENAME);

      	 /* Attach One File */
	     BEGIN
            RETURN_DESC1     := '100 - E: THERE WAS AN ERROR IN OPENING FILE <'||ONEATTACHMENTFILENAME||'>';
            L_FILE_HANDLE    := UTL_FILE.FOPEN(L_DIRECTORY_NAME, ONEATTACHMENTFILENAME, 'RB' );

            L_MESG           := CRLF || '--' || MIME_BOUNDARY || CRLF ||
                                    'Content-Type: application/octet-stream; name="' || ONEATTACHMENTFILENAME || '"' || CRLF ||
                                    'Content-Disposition: attachment; filename="' || ONEATTACHMENTFILENAME || '"' || CRLF ||
                                    'Content-Transfer-Encoding: base64' || CRLF || CRLF ;

            L_MESG_LEN       := L_MESG_LEN + LENGTH(L_MESG);

            UTL_SMTP.WRITE_DATA ( CONN, L_MESG);

            LOOP
               RETURN_DESC1  := '110 - E: THERE WAS AN ERROR IN READING FILE <'||ONEATTACHMENTFILENAME||'>';

               UTL_FILE.GET_RAW(L_FILE_HANDLE, L_RAWDATA, MAX_BASE64_LINE_WIDTH);

		       IF L_MESG_LEN + LENGTH(L_RAWDATA) > MAX_SIZE THEN
                  L_MESG := '*** truncated ***' || CRLF;
                  UTL_SMTP.WRITE_DATA ( CONN, L_MESG );
                  MESG_LENGTH_EXCEEDED := TRUE;
                  RETURN_DESC1  := '120 - E: ATTACHED FILES <'||ATTACHMENTFILENAME||'> MAKE MESSAGE TOO BIG, MAXIMUM IS SET TO <'||MAX_SIZE||'>';
  				  RAISE ABORT_PROGRAM;
                  EXIT;
               END IF;

    	       utl_smtp.write_raw_data ( conn , utl_encode.base64_encode (L_RAWDATA));
               L_MESG_LEN := L_MESG_LEN + LENGTH(L_RAWDATA);

            END LOOP;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               NULL;
            WHEN UTL_FILE.INVALID_PATH THEN
               RAISE ABORT_PROGRAM;
            WHEN OTHERS THEN
               RAISE ABORT_PROGRAM;
         END;

         UTL_FILE.FCLOSE(L_FILE_HANDLE);

      END IF; -- else AttachmentFilename is null
   END LOOP;

   RETURN_DESC1  := '130 - E: THERE WAS AN ERROR IN CLOSING MIME BOUNDARY. ';
   L_MESG := CRLF || '--' || MIME_BOUNDARY || CRLF;

   UTL_SMTP.WRITE_DATA ( CONN, L_MESG );

   UTL_SMTP.CLOSE_DATA( CONN );

   UTL_SMTP.QUIT( CONN );

EXCEPTION
   WHEN ABORT_PROGRAM THEN
  	 BEGIN
	     /* try to close any open file.  If this fails then the file is already closed so don't care */
         UTL_FILE.FCLOSE(L_FILE_HANDLE);
  	 EXCEPTION
	 	WHEN ABORT_PROGRAM THEN
		   NULL;
	    WHEN OTHERS THEN
		   NULL;
	 END;
  	 BEGIN
	    /* Try to quit the connection. If this fails the connection has already aborted, so 'don't care */
  		UTL_SMTP.QUIT( CONN );
	 EXCEPTION
	    /*WHEN UTL_SMTP.TRANSIENT_ERROR OR UTL_SMTP.PERMANENT_ERROR THEN
		   NULL;	*/
		WHEN ABORT_PROGRAM THEN
		   NULL;
		WHEN OTHERS THEN
		   NULL;
  	 END;
     RAISE_APPLICATION_ERROR(-20001, RETURN_DESC1);

  WHEN OTHERS THEN
  	 BEGIN
	     /* try to close any open file.  If this fails then the file is already closed so don't care */
         UTL_FILE.FCLOSE(L_FILE_HANDLE);
  	 EXCEPTION
	    WHEN OTHERS THEN
		   NULL;
	 END;
  	 BEGIN
	    /* Try to quit the connection. If this fails the connection has already aborted, so 'don't care */
  		UTL_SMTP.QUIT( CONN );
	 EXCEPTION
	    WHEN UTL_SMTP.TRANSIENT_ERROR OR UTL_SMTP.PERMANENT_ERROR THEN
		   NULL;
		WHEN OTHERS THEN
		   NULL;
  	 END;
     RAISE_APPLICATION_ERROR(-20002, RETURN_DESC1);
END;