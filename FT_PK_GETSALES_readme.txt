********************************************************************************* 
****  
****   Name : FT_PK_GETSALES		Type : PACKAGE
****   Package used to maintain sales detail table DPRSTOLOTS/DPRSTOLOTSCHGS
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
****  	Original Log Number: 7510                
****  
*********************************************************************************
*********************************************************************************	                                        

	Spec Version 1.0.3
	Body Version 1.0.7

	Modified by: Arshad Din
	Modified on: 11/01/2015      	
	Modified Log: 13902
	Changes Made:      
	1) Exception block added to trap the data not found error for the select into statement.
	   See lines 690 - 701


*********************************************************************************
*********************************************************************************	                                        

	Spec Version 1.0.3
	Body Version 1.0.7

	Modified by: Brendan McKeefry
	Modified on: 14/09/2015      	
	Modified Log: 14993
	Changes Made:      
	1) 
Added new fields to 
BALTOLOTSCHGS - BASEAUTHTOGLAMT & RAWAUTHTOGLAMT 
DPRSTOLOTSCHGS - DTLBASEAUTHTOGLAMT & DTLRAWAUTHTOGLAMT

And changed the Body to write to these

*********************************************************************************	                                        

	Spec Version 1.0.3
	Body Version 1.0.3

	Modified by: Arshad Din
	Modified on: 26/06/2015      	
	Modified Log: 13465 - 13513
	Changes Made:      
	1) Purchase costs and routes costs added.
	2) Lot balances added.

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

	Modified by: Arshad Din
	Modified on: 01/01/2015      	
	Modified Log: 7510	
	Changes Made:      
	1) New methods to record sales data apportioned back to lot
	2) Renamed package FT_PK_...
	3) Added version control info

*********************************************************************************