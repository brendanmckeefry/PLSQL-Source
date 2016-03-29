********************************************************************************* 
****  
****   Name : FT_PK_SALES_COSTS             Type : PACKAGE
****   Package used by the AdHoc Charges and the auto costing to re-apportion manual charges
****   
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
****  	Written by Stephen Rimen
****  	Date: March 2015                        
****  	Original Log Number: 7510 (13676)               
****  
*********************************************************************************

*********************************************************************************


	Spec Version 1.0.1
	Body Version 1.0.5

	Modified by: Brendan McKeefry
	Modified on: 13/01/2016      	
	Modified Log: 15710
	Changes Made:      
	1) When the DOCOST_ACCRUALS library creates Adhoc charges for a allocated line that has multiple DELTOALLS it uses the Max(PALLOCISTRECNO) to write the ITECHG
	This Package uses the min(Istrecno) and this caused an issue 
	Changed it to use Max

*********************************************************************************


	Spec Version 1.0.1
	Body Version 1.0.4

	Modified by: Arshad Din
	Modified on: 09/10/2015      	
	Modified Log: 14860
	Changes Made:      
	1) Records not apportioned if fixed and Ichistrecno is null
  2) New rules added - i) Do not want to apportion debit notes, credit notes (stk and non stk)
  3) Want to apportion to unallocated lines, allocated lines and dlvd lines.
  4) should fix and unfix trigger a re-apportionment.

*********************************************************************************

*********************************************************************************


	Spec Version 1.0.1
	Body Version 1.0.4

	Modified by: Paul Michael Thomas
	Modified on: 26/06/2015      	
	Modified Log: 14754
	Changes Made:      
	1) Added ROWNUM = 1 to prevent error on duplicate ITECHG.

*********************************************************************************

*********************************************************************************

	Spec Version 1.0.1
	Body Version 1.0.3

	Modified by: Stephen Richard Rimen
	Modified on: 26/06/2015      	
	Modified Log: 14516
	Changes Made:      
	1) LOTITEAPPORTION_DELPRICE changed DTISel so that DLV status deliveries use delToIst figures without duplicating them.

*********************************************************************************	

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.2

	Modified by: Stephen Richard Rimen
	Modified on: 28/04/2015      	
	Modified Log: 14172
	Changes Made:      
	1) Call made to enqueue_dpr after delaudits written.

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.1

	Modified by: Paul Michael Thomas
	Modified on: 08/04/2015      	
	Modified Log: 13648
	Changes Made:      
	1) Changed CurrentVersion to return spec and body version numbers
	2) Changed AUTOCOSTING table name
	3) cut n paste issue '\n' removed from built up sqlstr; SR.
        4) delprices > 0 becomes delprices <> 0 so credits are added. SR.

*********************************************************************************	                                        

	Spec Version 1.0.0 
	Body Version 1.0.0
  	
	Modified by: Stephen Rimen
	Modified on: 19/03/2015      	
	Modified Log: 13676	
	Changes Made:      
	1) New procedure written, copied from code in the costing library. (should be identical functionality).

*********************************************************************************