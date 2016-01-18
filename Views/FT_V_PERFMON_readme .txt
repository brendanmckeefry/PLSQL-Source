 ****************************************************************************************************** 
 ****   PERFMON VIEW 
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
 ****  	Writen by ???
 ****  	Date: Jan 2016                          
 ****  	Original Log Number: Moved it into Repository  	                

 ****************************************************************************************************** 
 ****  	Version 11.0.1                            
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     18/01/2016      		
 ****  	Last Modified Log:    15730
 ****  	Change Made:          
	(1)	The link to the usersessno table was wrong 
	Previously used the 

	INNER JOIN USERSESSNOLOG  ON (FT_PERFMON.PERFMONUSER = USERSESSNOLOG.USERSESSRECNO)  
		Should really use the  
	INNER JOIN USERSESSNOLOG  ON (FT_PERFMON.PERFMONUSER = USERSESSNOLOG.USLRECNO)


Also i hadn't a clue what this was for so i took it out

AND EXISTS
    (SELECT SESSNO.USERSESSRECNO
    FROM USERSESSNOLOG SESSNO
    WHERE SESSNO.ISLOGIN = 1
    GROUP BY SESSNO.USERSESSRECNO
    HAVING MAX(SESSNO.USLRECNO) = USERSESSNOLOG.USLRECNO
    )

****  	                                        

