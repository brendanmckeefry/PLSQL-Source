********************************************************************************* 
****  
****   Name : FT_PK_FGLGETPALLOCRECNOS			Type : PACKAGE
****   Package used only in FGL to deal with nxtPALLOCRECNO issue
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
****  	Date: May 2015                        
****  	Original Log Number: 3777
****  
*********************************************************************************

*********************************************************************************	                                        

	Spec Version 1.0.0
	Body Version 1.0.0

	Modified by: 	Brendan McKeefry
	Modified on: 	20/05/2015      	
	Modified Log: 	 3777
	Changes Made:   
   
	IN FGL there was once an issue with the next PALNOLOC.PALLOCRECNO where it jumped in steps of 20000 and so the number was used up very quickly
	PH devised a table to hold the non-used PALLOCRECNOS 
	This holds up to 2 million available numbers

	This mod just put that into a package and created a job to run it 
	The job runs the first of every month and if the number available is less than 200000 it populates the table with 2 million 
	This 200000 should be more than enought to cover a month - then currently use about 100000 a month

	The job also deletes the used PALLOCRECNOs to keep the table tidy and increase its efficiency.


	

