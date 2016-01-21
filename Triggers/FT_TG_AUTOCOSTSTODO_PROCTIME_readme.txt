********************************************************************************* 
****  
****   Name : FT_TG_AUTOCOSTSTODO_PROCTIME			Type : TRIGGER
****   Records the Start Process time of the Autocosttodo
****   This should be the time when a session has started processind the record
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
****  	Date: Jan 2016                        
****  	Original Log Number: 15697
****  
*********************************************************************************

*********************************************************************************	                                       


	Spec Version 1.0.1                            

	Modified by: Brendan McKeefry
	Modified on: 12/01/2016      	
	Modified Log: 15697
	Changes Made:      
	1) New field added called PROCESSSTARTTIME
	This Records the Start Process time of the Autocosttodo
	This should be the time when a session has started processind the record
	so when either the PROCESSSTAT or the SESSIONNO changes this is updated
	it is used to see how long a particular process is taking and there is a WIZCHKSTMT to pick up on this 

*********************************************************************************	                                        

