 ****************************************************************************************************** 
 ****   Sales Details View  - 	Used mainly for Entering Delivery lines in the sales screens
 ****				Only one Delprice Detail is shown 
 ****				If there is more than 1 Delivery DELPRICE then the DELPRICE & DPRRECNO & FOC are null		
 ****************************************************************************************************** 
 ****                                           
 ****   Property of ;                           
 ****   Beresford Software Development Ltd      
 ****  	Horticultural Market                    
 ****  	Wholesale Markets Precinct              
 ****  	Pershore Street                         
 ****  	Birmingham B5 6UN                       
 ****  	England                                 
 ****  	Phone +44 121 666 4820                  
 ****  	Fax +44 121 666 4821                    
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Writen by Brendan McKeefry              
 ****  	Date: Dec 2014                          
 ****  	Original Log Number: 	Was originally done for TeleSales Galway                
 ****************************************************************************************************** 

 ****  	Version 11.0.2                            
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     09/06/2016      		
 ****  	Last Modified Log:    16498	
 ****  	Change Made:          
	(1)	Added in Client Product Description

 ****************************************************************************************************** 

 ****  	Version 11.0.1                            
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     18/12/2014      		
 ****  	Last Modified Log:    13472 	
 ****  	Change Made:          
	(1)	Create Version Details 
	(2)	Made the DPRRECNO, DELPRICE_PRICE, DELNETTVALUE, DELVATVALUE & DELFREEOFCHG  all only populated if there is only 1 DELPRICE at status 1 
		- this is so that they can be picked up in a standard sales entry screen - if there is multiple DELPRICEs @ DELINVSTATUS = 1 then use split price program
	(3) 	Added in ALL_DELPRICE_CNT,   ALL_DELNETTVALUE,   ALL_DELVATVALUE - which includes all Dlv, Dbts And Cdt lines
 ****  	                                        

