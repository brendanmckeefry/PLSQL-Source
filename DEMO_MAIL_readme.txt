********************************************************************************* 
****  
****   Name :  DEMO_MAIL		Type : PACKAGE
****   Deprecated package for sending emails from Oracle
****
****
****   DO NOT USE THIS PACKAGE FOR ANY NEW DEVELOPMENTS.  USE BSDL_EMAIL INSTEAD
****   THIS PACKAGE WILL BE REMOVED AS SOON AS ALL CALLS TO IT HAVE BEEN UPGRADED  
****
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
****  	Written by Oracle and modified by Tim Vivian
****  	Date: 2009                        
****  	Original Log Number: pre-historic (TCS days)                
****  
*********************************************************************************


	Spec Version 1.0.1   
        Body Version 1.0.1                      

	Modified by: Tim Vivian
	Modified on: 09/04/2015      	
	Modified Log: 
	Changes Made:      
	1) Inserted CurrentVersion to return spec and body version numbers
        2) Changed all calls with a sender parameter to ignore the sender if the 
           constant from_address is not null.  This is to allow systems using 
           Microsoft email to always send using the same address (Lotus Notes 
           used to allow any email address to send). 

*********************************************************************************

