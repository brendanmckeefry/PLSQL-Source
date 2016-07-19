 ****************************************************************************************************** 
 ****   ALLOCATE CHECK - this package will be developed to primarily check and fix allocate issues and possibly write to allocate in the future
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
 ****  	Date: AUG 2014                          
 ****  	Original Log Number: 	                
 ****************************************************************************************************** 
 ****************************************************************************************************** 

 ****************************************************************************************************** 
 ****  	   Spec Version 1.0.1
 ****  	   Body Version 1.0.1                             
 *********************************************************************************	                                        
	Modified by: Brendan McKeefry
	Modified on: 13/07/2016      	
	Modified Log: 
	Changes Made:      
	1) Added then following methods 

    REPAIR_ALLTOARE;            -- THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE ALLTOARE TABLE  - CAN BE XPANDED 
    REMOVE_INVALIDALLOCATES;    -- THIS METHOD REMOVES ANY ALLOCATE RECORDS THAT ARE IN NO OTHER TABLES
    REPAIR_ALLOCATES           -- THIS METHOD REPAIRS any ALLOCATE records with negative qties

 ****************************************************************************************************** 
 ****  	Spec Version 1.0.0
 ****  	Body Version 1.0.0
 ****************************************************************************************************** 
 ****  	                    
	Added then following methods 

    REPAIR_MAIN;  - 	THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE ALLOCATE AND RELATED TABLES - should be called if you want to do full table
    PROCEDURE REPAIR_ALLOCALLOC;   -- THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE ALLOCATE.ALLOCALLOC  
  
  -- THESE METHODS FIXES ANY ISSUES THAT MAY BE IN THE DELTOALL
    PROCEDURE REPAIR_DELTOALL_FULL; -- THIS IS A MORE COMPREHENSIVE REPAIR AND CALLS REPAIR_DELTOALL AS PART OF THE PROCEDURE
    PROCEDURE REPAIR_DELTOALL_MIN;  -- THIS DOES THE MINIMUM REPAIRS TO DELTOALL                     


I SPLIT THE DELTOALL REPAIR INTO 2 AS I AM CALLING THE _MIN PART FROM STOCK DISSECTION AND I DID NOT WANT TO GIVE IT TO MUCH WORK TO DO

 	