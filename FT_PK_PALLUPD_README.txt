********************************************************************************* 
****  
****   Name : FT_PK_SALES		Type : PACKAGE
****   Package used to return specific sales information
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
****  	Date: MAY 2015                        
****  	Original Log Number: 14191                
****  
*********************************************************************************

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.2

	Modified by: Brendan McKeefry
	Modified on: 03/05/2016      
	Modified Log: 	17585
	Changes Made:      
	The Code using the STOCLOC.DEFSPLITAREAIN was incorrect  - 
	If you were allocating to splits (i.e. IN_QTYPER > 1)  it only picked up stock in the STOCLOC.DEFSPLITAREAIN 
	which meant that if this was not set up (ie null) no stock was ever picked up.

	Change to - if you do not have a 'Split Stock Area In' set up it should allow any stock to be allocated to splits  	

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.2

	Modified by: Brendan McKeefry
	Modified on: 22/02/2017      
	Modified Log: 	15917
	Changes Made:      
	Now takes into account the STOCLOC.DEFSPLITAREAIN
	If the allocation is for Boxes then any stock in this location are ignored 
	If the allocation is for splits then ONLY stock in this location is picked up 

*********************************************************************************	                                        

	Spec Version 1.0.0
	Body Version 1.0.0

	Modified by: Brendan McKeefry
	Modified on: 28/05/2015      	
	Modified Log: 	14191
	Changes Made:      
	tHIS PACKAGE WAS TO TAKE OUT 25 SQL STATEMENTS IN LOADTEMPALLOCNEW AND PUT THEM IN ONE ROUTINE

*********************************************************************************	                                        
