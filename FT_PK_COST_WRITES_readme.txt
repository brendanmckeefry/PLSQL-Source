********************************************************************************* 
****  
****   Name : FT_PK_COST_WRITES		Type : PACKAGE
****   Package to write to ITECHG/ EXPCHA and associated tables.
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

	Version 1.0.1
  	

	Modified by: Steve Rimen
	Modified on: 24/03/2015      	
	Modified Log: 7510 (13676)	
	Changes Made:      
	1) INSERT_ITECHG() IteChg.ICHCHNGDBYUSER was hardcoded to false; now written as per value passed in.
        2) UPDATE_EXPCHA() Only updated field EXCCHAPERRATE; now also writes EXCRAWAMM, EXCEUROAMM, EXCCONAMM
	

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