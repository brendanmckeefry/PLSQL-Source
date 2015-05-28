 ****************************************************************************************************** 
 ****   VIEW SHOWING THE TIME TAKEN TO RUN THE 3 DIFFERENT PROCESSES IN MARKETTODELIVERNEW
	-- RECNO        -  unique FreshTrade Number 
	-- SALESOFFICE  - sales office description
	-- TYPEDESC,    - SPLIT   EXTRACT, UPDATE
	-- USERNAME     - who ran the process
	-- RECS_UPDATED - for splits this is the number of allocated lines (DELTOALL) 
	--              - for EXTRACT this is the number of Deliveries (DELHED)
	--              - for UPDATE this is the number of Deliveries (DELHED)
	-- MIN_DIFF -   minutes taken to run the process 
	-- SEC_DIFF -   seconds taken to run the process
	-- STARTTIME, STARTTIME_STR   - start date of the extraction - _str is there to show the min and secs in SQL developer
	-- ENDTIME,   ENDTIME_STR       - finish date of the extraction - _str is there to show the min and secs in SQL developer
	-- NOOFERRS - if an extract or update then number of errors occured  - not populated for splits
	-- EXTRAINFO = not used
	-- SALOFFNO - SALES OFFICE SALOFFNO
	-- TYPE    1 = SPLIT , 2 = EXTRACT, 3 = UPDATE 
	-- LOGONNO   - LOGONS.LOGONNO

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
 ****  	Date: 18 Mar 2014                          
 ****  	Original Log Number: 11015	                
 ****************************************************************************************************** 
 ****  	Version 11.0.1                           
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     03/04/2014		
 ****  	Last Modified Log:    	
 ****  	Change Made:          
	(1)	Rename to FT rather than BSDL
	(2) 	Create Version Details
 ****  	                                        

