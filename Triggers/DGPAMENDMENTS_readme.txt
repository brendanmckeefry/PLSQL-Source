********************************************************************************* 
****  
****   Name : DGPAMENDMENTS		Type : TRIGGER
****   Posts records to the DGPDPRSTODO table
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
****  	Written by Arshad Din
****  	Date: Jan 2015                        
****  	Original Log Number: 13902                
****  
*********************************************************************************

*********************************************************************************	                                        

	Spec Version 1.0.1                            

	Modified by: Paul Michael Thomas
	Modified on: 11/06/2015      	
	Modified Log: 14337
	Changes Made:      
	1) Trigger was missing DPRRECNOs moved to auto cost procssing table

*********************************************************************************	                                        

	Spec Version 1.0.0                            

	Modified by: Paul Michael Thomas
	Modified on: 01/01/2015      	
	Modified Log: 13902	
	Changes Made:      
	1) Changed trigger to use new package FT_PK_DGP
	2) Made trigger AUTONOMOUS_TRANSACTION

*********************************************************************************