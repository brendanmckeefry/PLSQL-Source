********************************************************************************* 
****  
****   Name : FT_TG_AUTOCOSTSTODO_AUDIT			Type : TRIGGER
****   Audit record of inserts and deletes on AUTOCOSTSTODO 
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
****  	Date: Sept 2015                        
****  	Original Log Number: 14965
****  
*********************************************************************************

*********************************************************************************	                                        

	Spec Version 1.0.2                            

	Modified by: Brendan McKeefry
	Modified on: 10/09/2015      	
	Modified Log: 14965
	Changes Made:      
	1) Previous Trigger was an After Update query which when installed ran before the existing
	trigger to populate the key value. This meant that the AUTOCOSTREC was not yet populated
	and so in the audit this was null
	This in turn meant that the DELETE trigger did not write a DELETETIME to the correct reocrd
	So i made this trigger an 'AFTER INSERT'
	

*********************************************************************************	                                        

	Spec Version 1.0.1                            

	Modified by: Brendan McKeefry
	Modified on: 08/09/2015      	
	Modified Log: 14965
	Changes Made:      
	1) renamed trigger from AUTOCOSTSTODO_AUDIT" to FT_TG_AUTOCOSTSTODO_AUDIT
	2) Added in FORMNO field to enable us to tell which process is writing the records
	This will not be populated by all routines at this stage
	However hte new delaudit routine FT_PK_SALES.PROCESS_DELAUDIT_FORAUTOCOST() writes a -9 to there 	

*********************************************************************************	                                        

