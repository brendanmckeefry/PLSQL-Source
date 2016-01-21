********************************************************************************* 
****  
****   Name :  MKTHANDHELD_1	Type : PACKAGE
****   Package used by handheld webservices  
****   (Blueberry Consultants Android version 2014
****        
****   NB This procedure should be installed in a separate WEBSERV user with the 
****   appropriate tables given grants and synonyms for the user.  This removes
****   the ability of an APEX user accessing all the data tables via the webservices
****   CREATE OR REPLACE SYNONYM "PALNOLOC" FOR "TPUKLIVE"."PALNOLOC";
****   GRANT ALL ON "TPUKLIVE"."PALNOLOC" TO "WEBSERV" ;
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
****  	Author: Tim Vivian/ Steve Rimen and all BSDL programmers in parts
****  	Date: 15 Apr 15                        
****  	Original Log Number: 10422
****    Version: '1.0.1'              
****  
*********************************************************************************
