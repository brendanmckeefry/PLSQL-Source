 ****************************************************************************************************** 
 ****   STOCK DISSECTION 
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
 ****  	Original Log Number: 	

DISSECTDELIVERY  

 ****************************************************************************************************** 
 ****  	Spec Version 1.0.4
 ****  	Body Version 1.0.12
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     05/10/2016
 ****  	Last Modified Log:    16827
 ****  	Change Made:          
	(1)	Realised that i needed a method to call that would dissect deliveries without checking the sales office preference -TELESALES_AUTODISSECT
		so added DISSECTDLV_WITHNOSOPREFCHK

	Turning on that preference means that printing in TELESALES disects the dlv - this is not what we want in all sales offices.


 ****************************************************************************************************** 
 ****  	Spec Version 1.0.3
 ****  	Body Version 1.0.10
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     11/03/2016
 ****  	Last Modified Log:    
 ****  	Change Made:          
	(1)	Allow interdepartment sales to be dissected
	commented out the followign 
		--OR INTERDEPTFLAG IS NOT NULL



 ****************************************************************************************************** 
 ****  	Spec Version 1.0.3
 ****  	Body Version 1.0.11
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     28/04/2016
 ****  	Last Modified Log:  	16256 
 ****  	Change Made:          
	(1)	was getting a devide by zero error in EXTRACTONALLOC_DETS line 1076 & 1098 due to 0 in 
		PRCWEIGHT, PRCBOXQTY, InnerQty

 ****************************************************************************************************** 
 ****  	Spec Version 1.0.3
 ****  	Body Version 1.0.9
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     20/11/2015      		
 ****  	Last Modified Log:    15404	
 ****  	Change Made:          
	(1)	Was allowing none market sales to be dissected in DISSECTDELIVERY  proc
		NVL(DLVISMKTSALE, 0)  =0

	      

 ****************************************************************************************************** 
 ****  	Spec Version 1.0.3
 ****  	Body Version 1.0.8
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     21/10/2015      		
 ****  	Last Modified Log:    	
 ****  	Change Made:          
	(1)	Noticed that this does not use the ALLOCATESPLITS table so changed it so that it will 


 ****************************************************************************************************** 
 ****  	Spec Version 1.0.3
 ****  	Body Version 1.0.7
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     06/10/2015      		
 ****  	Last Modified Log:    14893	
 ****  	Change Made:          
	(1)	Bug fix to the method DISSECTDELIVERY   on this this line 
              (SELECT DALWIZUNIQUEID, FT_PK_STOCKDISSECTION.ISALLOCATE_OVERALLOC(NULL, DELTOALL.DALWIZUNIQUEID, SYSDATE)  ISALLOCATE_OVERALLOC

became	
              (SELECT DALWIZUNIQUEID, FT_PK_STOCKDISSECTION.ISALLOCATE_OVERALLOC(NULL, DELTOALL.DALWIZUNIQUEID, DELHED.DLVSHPDATE)  ISALLOCATE_OVERALLOC


When using the sysdate 
If you had a dlv for Monday 
And expected stock on Sunday 
It would allow that to be dissected on Friday as it did not cause an oversell on the SYSDATE.
THis should not go throught as MARKETTODELIVER will try to pick it up and process it and this results in a screen error

                
            
 ****************************************************************************************************** 
 ****  	Spec Version 1.0.3
 ****  	Body Version 1.0.6
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     01/10/2015      		
 ****  	Last Modified Log:    14893	
 ****  	Change Made:          
	(1)	Bug fix to the above 
this line 
	AND NVL(DELTOALL.DALQTY,0) > 0 ),0) DALQTY
became	
	AND NVL(DELTOALL.DALQTY,0) + NVL(DELTOALL.ACTSPLITQTY,0) > 0 ),0) DALQTY
to include splits
    
 ****************************************************************************************************** 
 ****  	Spec Version 1.0.3
 ****  	Body Version 1.0.5
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     24/08/2015      		
 ****  	Last Modified Log:    14893	
 ****  	Change Made:          
	(1)	REQUEST MADE TO UPDATE THE DELIVERY AS DISSECTED WHEN DELIVERY NOTE PRINTED IN TELESALES
	2 PROCEDURES WHERE ADDED TO DO THIS 
		PROCEDURE DISSECTDELIVERY (V_DLVORDNO IN NUMBER);
		PROCEDURE FLAGDELIVERY (V_DLVORDNO IN NUMBER, V_UNDISSECT IN NUMBER); 


                
 ****************************************************************************************************** 
 ****  	Spec Version 1.0.2
 ****  	Body Version 1.0.4
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     13/08/2015      		
 ****  	Last Modified Log:    13531 	
 ****  	Change Made:          
	(1)	SOMETHING WAS CREATING DELTOALLS WITH -VE QTYIES AND SO THIS ADDED IN A CALL TO FT_PK_ALLOCATE_CHECK.REPAIR_DELTOALL_MIN TO CLEARS THEM DOWN BEFORE STOCK DISSECTION IS RUN
		A FRIG BUT A NECESSARY ONE (BMK)
		i PUT THIS INTO WRITEMISSINGALLOCDETS   WHICH IS ALREADY A BIT OF A FRIG 

                
 ****************************************************************************************************** 
 ****  	Spec Version 1.0.2
 ****  	Body Version 1.0.3
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     11/08/2015      		
 ****  	Last Modified Log:    13531 	
 ****  	Change Made:          
	(1)	A query in EXTRACTONALLOC_DETS  to FLAG THE OVERSOLD LINES was quite slow as it did not have the following limiter
	WHERE STKDISSHDR_RECNO = V_HDRRECNO 

	

 ****************************************************************************************************** 
 ****  	Spec Version 1.0.2
 ****  	Body Version 1.0.2
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     16/04/2014      		
 ****  	Last Modified Log:    13987	
 ****  	Change Made:          
	(1)	Changes made as per instruction of Steve to deal with an oddity when the AllocExp is negative (which it should not be)                              
	08/04/2015 --SR. Search 13987.  AllocExp can go negative when RTS is done. 
		In OrdManNew ticking over allocate does not return correct lines as this proc returned 0.

	(2) Added in New CURRENTVERSION stuff 

 ****************************************************************************************************** 
 ****  	Version 1.0.1                            
 ****************************************************************************************************** 
 ****  	                                        
 ****  	Last Modified by:     Brendan McKeefry         		
 ****  	Last Modified on:     12/12/2014      		
 ****  	Last Modified Log:    13500    	
 ****  	Change Made:          
	(1)	Rename to FT rather than BSDL
	(2) 	Create Version Details
	(3) 	Stop RTS deliveries being picked up     
		added 
		AND NVL(ORDSALTYP, 'N')  <> 'R'   -- 08/05/2014 WE NEED TO IGNORE RTS LINES
		to line 568 & 1046
                                                        
 ****  	Line    				
 ****  	                                        

 ****************************************************************************************************** 
 ****  	Version 1.0.0                            
 ****************************************************************************************************** 
 ****  	                                        
 ****This was the original work
 ****
    -- 03/09/2014 added V_USEDLVDATE  to ISALLOCATE_OVERALLOC - so that it would ignore deliveries that were allocated after the passed in date
    -- 06/06/2014 EXTRACT_STK_FOR_DETAILS AND MAINRUN_ALLLOTS_FIRSTSTAGE added V_SUPGRPNO (SR 12150)
    -- 14/05/2014  12055 ignore non-allocated delivery lines by date    
    -- 08/05/2014 NEEDED TO IGNORE RTS DELIVERY LINES IN THE ALREADY SOLD DETAILS - EXTRACTALREDYSLD_DETS
    -- 01/05/2014 was igoring non allocated deliveries at Pik status   --- (DELHED.DLVRELINV IS NULL or DELHED.DLVRELINV = 'Pik')
    -- 01/05/2014 Log 11955
    -- 01/05/2014      line 1640 changed this GLBOVERSOLD_INNERQTY := VAR_BOXREQFORSPLIT_INNER  to this GLBOVERSOLD_INNERQTY := VAR_REQ_SPLITQTY_INNER;
    -- 01/05/2014      as it was calculating the number of inner split wrong                          
                            
    -- 30/04/2014  BMK removed the code to delete LOTS with no sales if it is a using a up to date    
    -- 18Apr2014 UPD_OPENINGQTY  - took out the LITRCVIND = 'Y' 
    -- 10/04/2014 ADDED IN ISALLOCATE_OVERALLOC_INCEXP AND CHKISALLOCATE_OVERALLOC
    -- 02/04/2013   in ISALLOCATE_OVERALLOC where it calc the GLBOVERSOLD_INNERQTY it was using the VAR_PROD_EACHQTY instead of the VAR_INNERQTY.    
    -- 31/03/2014  ADDED A NEW LINE TO ALLOCATE EXTRACT IN EXTRACTONALLOC_DETS COS AN EXPECTED PO IS NOT WRITTEN TO STKDISS_DETS BUT THIS WASW PICKING UP SALES AGAINST THEM AND ALLOWING THEM TO BE UPDATED
    -- 31/03/2014 ADDED V_UPTODATE AND V_USEDLVDATE TO MAINRUN_SNDSTAGE AND EXTRACTONALLOC_DETS
    -- 18/03/2014 added ALREDYSLDDT_PRIOR
    -- 11/12/2013 Loads of changes to include Open lots for report 
    -- 06/12/2013 REMOVEFULLEXTRACT
    -- 28/11/2013 REMOVEUNCOMMITTED - ADDED IN SALES OFFFICE LIMITATION 
    -- 27/11/2013 MOVED THIS QUERY HERE FROM ABOVE IN THE LOOP  - SEEMS TO HAVE SPEEDED UP THE EXTRACT SIGNIFICANTL
    -- 26/11/2013 lINE 305 LIMITED EXTRACTED LOTS TO ONLY RELEVANT DEPARTMENT FOR TRANSFERS            
    -- 25/11/2013 STKDISS_DETS_ONALLOC POPULATION WAS NOT LIMITING BY SALES OFFICE (LINE 836)
    -- 06/09/2013 INTER DEPARTMENT TRANFERS CAN CONFIRM THE DELIVERY WHICH MEANS THE LOTITE IS COMPLETED - THESE LOTS WHERE NOT GETTIN PICKED UP   
    -- 03/09/2013 line 883 AND DELHED.DLVRECNO = ORDERS.ORDRECNO changed to AND DELHED.DLVORDRECNO = ORDERS.ORDRECNO
    -- 27/08/2013  the charges should all have the itesto number in itechg so there is no need to apportion them across the DELTOISTS                                      
    -- 04/06/2013 ADDED IN THE GET_OVERALLOC_DETAILS METHOD 
    -- 02/05/2013 ADDED REMOVEUNCOMMITTED PROCEDURE
    -- 25/04/2013  9512 OVERSOLD LINES NOW FLAGGED 
    -- 05/04/2013 9468  UNALLOCATED SALES NEEDED A SALES OFFICE RESTRICTION
    -- 16/08/2012 8025 in method EXTRACTONALLOC_DETS if a deldet had a deltoall and no allocate the query to pick up the allocated lines does not pick it up and
    --             the query to pick up unallocated lines does not pick it up eithder as that just checks DELTOALL-so i've added the allocate to this query so that it will now show as an overallocation
    --        Also if you have a DELDET line with a null in the qty field But has a DELTOALL record then it did not pick this line up
    -- 01/08/2012 ISALLOCATE_OVERALLOC - Paul h added a futher check on DELTOALL.DALQTY - i (BMK) think this is not required but it does no harm so i've left it in 
    -- 04/07/2012 ISALLOCATE_OVERALLOC - added a check on DELTOALL ACTSPLITQTY rather than just ALLOCATE.ALLOCQTY_SPLIT in case this figure was not populated correct
    -- 19/01/2011 ISALLOCATE_OVERALLOC - ADDEC A FEW NVL INTO THE QUERIES
    -- 11/01/12 PP_SLDDETS_RECORD.DPRQTYTHIS,   -- PP_SLDDETS_RECORD.DELPRCQTY, changed 11/01/2012
    --          changed this so it can use the part that is for this lotite - not all the DELPRICE
    -- 10/01/12 REB_ONALLOC WHERE NOT CALC PROPERLY - USING THE DISC FIELD
    -- 18/11/11 ADDED ISALLOCATE_OVERALLOC
    -- 03/11/11 changed this from BULKQTYEQUIV to DPRQTYTHIS as this should use the used split qty to work out the apportionment
    -- 11/01/12 PP_SLDDETS_RECORD.DPRQTYTHIS,   -- PP_SLDDETS_RECORD.DELPRCQTY, changed 11/01/2012
    -- change this so it can use the part that is for this lotite - not all the DELPRICE
    -- 10/01/12 REB_ONALLOC WHERE NOT CALC PROPERLY - USING THE DISC FIELD
    -- 18/11/11 ADDED ISALLOCATE_OVERALLOC
    -- 03/11/11 changed this from BULKQTYEQUIV to DPRQTYTHIS as this should use the used split qty to work out the apportionment
    /
