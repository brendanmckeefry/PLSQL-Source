********************************************************************************* 
****  
****   Name :  BSDL_EMAIL		Type : PROCEDURE
****   Procedure used by Freshtrade to send emails from the Oracle server. 
****   
****        
****   NB This procedure should be installed in the sys user, not as a user
****   permission is then given to all other users with:
****   CREATE OR REPLACE PUBLIC SYNONYM "BSDL_EMAIL" FOR "SYS"."BSDL_EMAIL";
****   grant all on "SYS"."BSDL_EMAIL" to "PUBLIC" ;
****
****   Requires sys.sysconst to be installed
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
****  	Taken from the web and modified by Tim Vivian
****  	Date: 2009                        
****  	Original Log Number: Prehistoric (early BSDL)                
****  
*********************************************************************************
	Body Version 11.0.2                      

	Modified by: Tim Vivian
	Modified on: 14/04/2015      	
	Modified Log: 
	Changes Made:      
	1) Changed parameters that are set by customer out of the procedure and
           put into a constants package sysconst.  This allows the procedure to be
           amended without changes at every customer. 

*********************************************************************************

