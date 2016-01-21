********************************************************************************* 
****  
****   Name : FT_PK_AUTOCOSTING		Type : PACKAGE
****   Package to post and maintain the AUTOCOSTING procedures.
****  
*********************************************************************************                           
****  
****    Property of;                           
****    Beresford Software Development Ltd      
****  	Horticultural Market                    
****  	Wholesale Markets Precinct              
****  	Pershore Street                         
****  	Birmingham B5 6UN                       
****  	England                                 
****  	Phone +44 121 666 4820                  
****  	Fax +44 121 666 4821                     
****  
*********************************************************************************  
****  	                                        
****  	Written by Paul Michael Thomas
****  	Date: Jan 2015                        
****  	Original Log Number: 7510                
****  
*********************************************************************************

*********************************************************************************	                                        

	Spec Version 1.0.3
	Body Version 1.0.5

	Modified by: Brendan McKeefry
	Modified on: 19/01/2015      	
	Modified Log: 15697
	Changes Made:      
	1) Added New methods ENQUEUE_LIT & ENQUEUE_DPR to record FORMNO


*********************************************************************************	                                        

	Spec Version 1.0.2
	Body Version 1.0.4

	Modified by: Brendan McKeefry
	Modified on: 11/01/2015      	
	Modified Log: 15697
	Changes Made:      
	1) SET_IN_PROGRESS did not check to see if there was alrady any records in the AUTOCOSTSTODO table for my session - G_SID
	  this meant that if a session had an error it just added another batch to teh existing lot and chances where they would get an error too.

*********************************************************************************	                                        

	Spec Version 1.0.2
	Body Version 1.0.3

	Modified by: Brendan McKeefry
	Modified on: 09/09/2015      	
	Modified Log: 14965
	Changes Made:      
	1) Added 2 new methods to take the formno and write it to the AUTOCOSTSTODO record
	PROCEDURE ENQUEUE_LITRECS(LITRECS_IN RECORD_NUMBERS, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE, FORMNO_IN AUTOCOSTSTODO.FORMNO%TYPE);  
	PROCEDURE ENQUEUE_DPRRECS(DPRRECS_IN RECORD_NUMBERS, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE, FORMNO_IN AUTOCOSTSTODO.FORMNO%TYPE); 


	existing ENQUEUE_LITRECS & ENQUEUE_DPRRECS changed to call above methods with a 0 FORMNO

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.2

	Modified by: Paul Michael Thomas
	Modified on: 08/04/2015      	
	Modified Log: 14755
	Changes Made:      
	1) Changed to be single record inserts in all cases.
	2) Added DGP call to eliminate duplicates.

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.1

	Modified by: Paul Michael Thomas
	Modified on: 08/04/2015      	
	Modified Log: 13648
	Changes Made:      
	1) Changed CurrentVersion to return spec and body version numbers
	2) Changed AUTOCOSTING table name

*********************************************************************************	                                        

	Spec Version 1.0.0
  	Body Version 1.0.0                             

	Modified by: Paul Michael Thomas
	Modified on: 01/01/2015      	
	Modified Log: 7510	
	Changes Made:      
	1) Renamed package FT_PK_...
	2) Added version control info

*********************************************************************************