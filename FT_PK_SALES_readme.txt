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
****  	Date: Jan 2015                        
****  	Original Log Number: 7510                
****  
*********************************************************************************


*********************************************************************************	                                        

	Spec Version 1.0.3
	Body Version 1.0.4

	Modified by: Brendan McKeefry
	Modified on: 27/01/2016      	
	Modified Log: 	
	Changes Made:      
	1) Put an error trap around the DOFT_PK_DISCOUNTS.DO_DISCOUNTS


*********************************************************************************	                                        

	Spec Version 1.0.3
	Body Version 1.0.3

	Modified by: Brendan McKeefry
	Modified on: 10/12/2015      	
	Modified Log: 14298 	
	Changes Made:      
	1) Split DELPRICE_NETTVALUE into sub method DELPRICE_CALCNETTVALUE so that it just returns the Nett Value


*********************************************************************************	                                        

	Spec Version 1.0.2
	Body Version 1.0.2

	Modified by: Brendan McKeefry
	Modified on: 04/09/2015      	
	Modified Log: 14965	
	Changes Made:      

		Work was done to replace the writing of AUTOCOSTTODOS & DISCOUNTS in the UTILITY library
		Procedure where added to this package that can be called as a timed job to do the same work

	added methods  PROCEDURE PROCESS_DELAUDIT_FORAUTOCOST;
        	       PROCEDURE GET_DELAUDIT_FORAUTOCOST

*********************************************************************************	                                        

*********************************************************************************	                                        

	Spec Version 1.0.1
	Body Version 1.0.1

	Modified by: Brendan McKeefry
	Modified on: 18/03/2015      	
	Modified Log: 	
	Changes Made:      
	1) use FT_PK_VAT.CALCDELPRICEVAT instead of BSDL_PK_VAT.CALCDELPRICEVAT
	2) added  cSpecVersionControlNo    & cVersionControlNo  & New CURRENTVERSION function 

*********************************************************************************	                                        

	Spec Version 1.0.0
  	Body Version 1.0.0                             

	Modified by: Brendan McKeefry
	Modified on: 01/01/2015      	
	Modified Log: 7510	
	Changes Made:      
	1) Renamed package FT_PK_...
	2) Added version control info

*********************************************************************************