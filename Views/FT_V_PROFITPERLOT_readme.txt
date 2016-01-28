********************************************************************************* 
****  
****   Name : FT_V_PROFITPERLOT		Type : VIEW
****   View to return sales and profitability by lot
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

	Spec Version 1.0.2

	Modified by: Arshad Din
	Modified on: 07/07/2015      	
	Modified Log: 14573
	Changes Made:      
	1) Added condition to include ONLY sales related charges (see code change below)
 
		AND DPRSTOLOTSCHGS.DTLCHGSTYPNO in (1,3)

		i)  If DPRSTOLOTSCHGS.DTLCHGSTYPNO = 1 then this is a sales cost linking on the dprrecno
		ii) If DPRSTOLOTSCHGS.DTLCHGSTYPNO = 2 then this is a Purchase cost linking on the LitIteNo
		iii)If DPRSTOLOTSCHGS.DTLCHGSTYPNO = 3 then this is a sales cost linking on the DelrecNo
			 

*********************************************************************************

*********************************************************************************	                                        

	Spec Version 1.0.0
  	Body Version 1.0.0                             

	Modified by: Arshad Din
	Modified on: 01/01/2015      	
	Modified Log: 7510	
	Changes Made:      
	1) Added version control info

*********************************************************************************