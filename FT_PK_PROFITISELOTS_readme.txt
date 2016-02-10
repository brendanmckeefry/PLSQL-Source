********************************************************************************* 
****  
****   Name : FT_PK_PROFITISELOTS		Type : PACKAGE
****   Package used to maintain profitise status on LOTPROFITSALOFF
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

	Spec Version 1.0.1
	Body Version 1.0.5

	Modified by: Arshad Din
	Modified on: 10/02/2016
	Modified Log: 
	Changes Made:      
	1) 15791 - See COMMENT 
		   - PREVPROFIT IS SET TO EQUAL PROFIT SO THAT THE REOPENED FLAG IS NOT SET TO TRUE,
		   THIS IS SO THAT CLEARED DOWN OVERSOLD PO's REMAIN PROFITISED
*********************************************************************************

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.4

	Modified by: Brendan McKeefry
	Modified on: 29/10/2015
	Modified Log: 
	Changes Made:      
	1) removed the used of CONST. to enable me to run queries in testing
*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.3

	Modified by: Brendan McKeefry
	Modified on: 17/09/2015
	Modified Log: 14993
	Changes Made:      
	1) use ICHAUTHTOGLAMTBASE rather than go to ACCITE & PORECOVITE to get AUTH TO GL figures

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