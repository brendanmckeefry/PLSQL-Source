********************************************************************************* 
****  
****   Name : FT_PK_DELETETMPTABLES		Type : PACKAGE
****   Package that is run every night to clear up temporary table, sequences & 
****   temporary preinv data
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
****  	Written by Brendan McKeefry
****  	Date: April 2016                        
****  	Original Log Number: 
****  
*********************************************************************************


*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.1

	Modified by: Brendan McKeefry
	Modified on: 11/04/2016
	Modified Log: 	15825
	Changes Made:      
	1) now deletes the temporary preinv data as part of the RUNNIGHTLY routine
	added  DELETEPREINVTEMPDATA

*********************************************************************************	                                        

	Spec Version 1.0.0
  	Body Version 1.0.0                             

	Modified by: Brendan McKeefry
	Modified on: 11/04/2016
	Modified Log: 
	Changes Made:      
	1) Changed to package and renamed to FT_PK_...
	2) Added version control info
	3) use FT_PK_ERRORS.LOG_AND_STOP
	

*********************************************************************************