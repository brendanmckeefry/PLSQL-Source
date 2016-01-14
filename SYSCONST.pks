--
-- SYSCONST  (Package) 
--
CREATE OR REPLACE PACKAGE SYSCONST AS

  -- BSDL_EMAIL constants (moved out of BSDL_EMAIL so that they can be parameterised here for each customer)
  -- NB This package should be installed as SYS, not as the individual user.  This is to allow it to be 
  -- accessed anywhere on the server (for example from non Freshtrade databases, Booking tool etc.)
  -- Also this file will not be backed up with a database data-pump backup of the live, so restoring
  -- a live database to test on another server, will not copy across the Email setttings.  
  
  -- This package should be distributed to customers with care, because it will contain customer configuration
  -- at each customer site
  
  -- need to grant to everyone with
  -- grant all on "SYS"."SYSCONST" to "PUBLIC" ;
  

  cVersionControlNo   VARCHAR2(12) := '1.0.1'; -- Current Version Number


  -- Email server.  This machine must be set to accept smtp traffic from the Oracle server
  C_SMTP_SERVER       CONSTANT VARCHAR2(20) := '10.1.1.139';                 /* Email server	*/ 
  C_SMTP_SERVER_PORT  CONSTANT NUMBER       := 25;                           /* Port on Email server	*/


  -- Oracle Directory where attachments are put.  This directory must be visible from both the client and Oracle
  -- machines.  Configure it by making sure that users can read/write to the directory and then give Oracle 
  -- permissions as follows
  --  CREATE OR REPLACE DIRECTORY BSDLATTACHMENTDIRECTORY AS '\\svbsdl01\TEMP';
  --  GRANT READ,WRITE ON DIRECTORY BSDLATTACHMENTDIRECTORY TO TEST111;
  C_DIRECTORY_NAME    CONSTANT VARCHAR2(200):= 'BSDLATTACHMENTDIRECTORY';    /* This is an ORACLE directory */

  -- If this is not null then every email will be sent from this email address regardless of the 
  -- value passed in in the SENTFROM parameter.  This is because Microsoft Online only allows 
  -- emails to be sent from a certain number of email addresses.  Lotus Notes never cared! */
  C_FIXED_FROM_NAME   CONSTANT VARCHAR2(50) := 'noreply@totalproduce.com';   


  -- If the parameters are set correctly, then running the sql below should work:
  -- CALL BSDL_EMAIL( 'Test@BeresfordSoftware.com','TVivian@BeresfordSoftware.com', '', '', 'Email Test', 'Test from BSDL_EMAIL',  '');
 

END SYSCONST;
/
