 ****************************************************************************************************** 
 ****   VIEW SHOWING DETAILS OF STOCK DISSECTION EXTRACTIONS AND THE ASSOCIATED TIMES
	--  RECNO       -  unique FreshTrade Number 
	--  DEPARTMENT  - department description 
	--  USERNAME    - who ran the stock dissection
	-- SALESOFFICE  - sales office description
	-- STATUS       -    EXTRACTED or UPDATED
	-- EXTRACTSTARTDATE, EXTRACTSTARTDATE_STR   - start date of the extraction - _str is there to show the min and secs in SQL developer
	-- EXTRACTENDDATE, EXTRACTENDDATE_STR       - finish date of the extraction - _str is there to show the min and secs in SQL developer
	-- EXTRACT_MINTAKEN -   minutes taken to run the extract 
	-- EXTRACT_SECTAKEN -   seconds taken to run the extract

	-- UPDATESTARTDATE, UPDATESTARTDATE_STR   - start date of the UPDATE - _str is there to show the min and secs in SQL developer  - NOTE HAS ONLY JUST BEEN ADDED TO STCKDISS SO MAY NOT YET BE WRITTEN TO (18/03/2014)
	-- UPDATEENDDATE, UPDATEENDDATE_STR       - finish date of the UPDATE - _str is there to show the min and secs in SQL developer
	-- UPDATE_MINTAKEN -   minutes taken to run the UPDATE 
	-- UPDATE_SECTAKEN -   seconds taken to run the UPDATE

	-- DATECOMPLETE, - date when the update was finished
	-- NOTE THERE IS NO START DATE/TIME FOR THE UPDATE 
	-- NOOFLOTS     - no of lots in extract
	-- NOOFOLDDLVS  - no of existing delivery lines in extract
	-- NOOFDLVSTOUPDATE - no of  delivery lines that will be updated in extract
	-- NOOFRETURNRECS - no of return lines assoc with the LOTS in the extract

	-- DPTRECNO  - DEPARTMENT.DPTRECNO
	-- LOGONNO   - LOGONS.LOGONNO
	-- ISCOMPLETE - 0 = EXTRACTED 1 = UPDATED  2 = EXTRACTIONS THAT WERE NEVER UPDATED
	-- SALOFFNO - SALES OFFICE SALOFFNO
	-- UNDISS  - 1 - SOME LINES ON THIS DISSECTION WHERE UNDISSECTED AFTER UPDATE

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

