********************************************************************************* 
****  
****   Name :  SYSCONST		Type : PACKAGE
****   Package used by BSDL_EMAIL procedure to hold setup site specific 
****   constants for emailing (server IP address, fixed 'from' user etc)
****        
****   NB This procedure should be installed in the sys user, not as a user
****   permission is then given to all other users with:
****   CREATE OR REPLACE PUBLIC SYNONYM "SYSCONST" FOR "SYS"."SYSCONST";
****   GRANT ALL ON "SYS"."SYSCONST" TO "PUBLIC" ;
****
****   Be very careful about sending out this package.  It should normally not
****   be distributed as it contains site specific setups.
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
****  	Author: Tim Vivian
****  	Date: 14 Apr 15                        
****  	Original Log Number: 14037  
****    Version: '1.0.1'              
****  
*********************************************************************************
