********************************************************************************* 
****  
****   Name : FT_PK_GOODS_COSTS		Type : PACKAGE
****   Package used calculate goods agreed after product cost
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
	Body Version 1.0.3

	Modified by: Arshad Din
	Modified on: 06/11/2015      	
	Modified Log: 15007
	Changes Made:      
	1) Added additional condition on the Main Goodscost query to include re-opened PO's.

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.2

	Modified by: Paul Michael Thomas
	Modified on: 11/05/2015      	
	Modified Log: 13648
	Changes Made:      
	1) Anchored sold quantity and rcv quantity to avoid integer rounding.

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
	1) New methods to calculate the product cost for GAA
	2) Renamed package FT_PK_...
	3) Added version control info

*********************************************************************************