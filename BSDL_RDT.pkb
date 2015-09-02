create or replace
PACKAGE BODY BSDL_RDT
AS

cVersionControlNo   VARCHAR2(12) := '11.1.1'; -- Current Version Number

FUNCTION  CHECKPICKRELAX(  In_UserName        IN VARCHAR2,
                           In_DelDetRecNo     IN INTEGER,
                           In_PalLocRecNo     IN INTEGER       )
          RETURN INTEGER  IS Ret_PickStatus INTEGER  := -999 ;


	/** BSDL 8730 31Dec12 TV
	    This function checks to see if a passed PalLocRecNo is suitable to use for picking against the
		passed DelDetRecNo.

		Currently doesn't do anything with the passed userlogon name, but it might be useful in the future if we need to log
		usage.

		The pallet is compared using the user settings in the RelaxPal table which are the settings used by the RDT program
		NOT the screen based forms (which use RelaxPrd).

		The checks are done by DelDet, not by Allocate because this function is used for non-allocated picking.  Therefore
		the checks for QCcolour etc are ignored.

		NB this function does not check for Pallet and Delivery sales office compatibility, or if the quantities are suitable.

		Returned values are:
		   0 = Pallet and Delivery match perfectly
		   1 .. 6 = Pallet and delivery do not match but are acceptable in Relaxation rules (the number indicates the
		            first level of product that does not match).
		   -1 .. -6 = Pallet and delivery do not match and are NOT acceptable in Relaxation rules (the number indicates the
		            first level of product that does not match).

		   -10 .. -19 = Errors with DelRecNo
		   -20 .. -29 = Errors with Pallocrecno
		   -30 .. -39 = errors in RelaxPrd

	**/


    --Variables
	  GoOn   Boolean	:= True;
	  V_PalLocRecNo PALNOLOC.PALLOCRECNO%TYPE;
	  V_DelDetRecNo DELDET.DelRecNo%TYPE;
	  V_PALNOLOC_PRDREC PRDREC%ROWTYPE;
	  V_DELDET_PRDREC   PRDREC%ROWTYPE;
	  V_RELAXPRD        RELAXPRD%ROWTYPE;

    BEGIN


		IF GoOn THEN
           IF NVL(In_DelDetRecNo, 0) <= 0 THEN
           	  -- No Del Det passed. so error
              Ret_PickStatus := -10;
			  GoOn := False;
           END IF;
		END IF;


		IF GoOn THEN
           IF nvl(In_PalLocRecNo,0) <= 0 THEN
              -- No PalLocRecNo passed. so error
              Ret_PickStatus := -20;
			  GoOn := False;
		   END IF;
        END IF;


		IF GoOn THEN
		   -- Get the Palnoloc Product parameters
		   BEGIN
    		   V_PalLocRecNo := In_PalLocRecNo;

    	       select PRDREC.*
			      INTO V_PALNOLOC_PRDREC
			      from Palnoloc, ITESTO, PRDREC
                  where PalLocRecNo = V_PalLocRecNo
                  AND PalLocStatus = 1
                  AND PalLocRcvFlag = 'Y'
                  AND NVL (PalLocAllNo, -1) > 0
                  AND PALNOLOC.PALLOCISTRECNO = ITESTO.ISTRECNO
                  AND PRDREC.PRCPRDNO = ITESTO.ISTPRDNO	;
    	    EXCEPTION
               WHEN NO_DATA_FOUND THEN
			      IF DEBUG THEN
					 RAISE;
				  END IF;
    	          Ret_PickStatus := -21;
			   	  GoOn := False;

   		       WHEN OTHERS THEN
			      IF DEBUG THEN
				     RAISE;
				  END IF;
  	   	          Ret_PickStatus := -22;
			   	  GoOn := False;
           END;
		END IF; -- GoOn



		IF GoOn THEN
		   -- Get the Deldet Prdrec parameters
		   BEGIN
    		   V_DelDetRecNo := In_DelDetRecNo;

			   Select PRDREC.*
			      Into V_DELDET_PRDREC
			      from deldet, Prdrec
                  Where delrecno = V_DelDetRecNo
				  AND DELDET.DELPRCPRDNO = PRDREC.PRCPRDNO;


    	    EXCEPTION
               WHEN NO_DATA_FOUND THEN
			      IF DEBUG THEN
					 RAISE;
				  END IF;
    	          Ret_PickStatus := -11;
			   	  GoOn := False;

   		       WHEN OTHERS THEN
			      IF DEBUG THEN
					 RAISE;
			  	  END IF;
  	   	          Ret_PickStatus := -12;
			   	  GoOn := False;
           END;
		END IF; -- GoOn


		-- add a check to see if the two products are the same .. if so, son't bother with the stuff below!
		If GoOn THEN
		   IF V_PALNOLOC_PRDREC.PRCPRDNO = V_DELDET_PRDREC.PRCPRDNO THEN
		      Ret_PickStatus := 0;
		 	  GoOn := False; -- not an error, but saves doing the complex stuff below
		   END IF;
		END IF;


		IF GoOn THEN
		   -- Get the best RelaxPrd record which are appropriate
		   -- ie the line with the max number of 'hits' (matches in prdrec)
		   BEGIN
		   	  SELECT *
			  INTO V_RELAXPRD
			     FROM (
    		     SELECT relaxprd.*
    			  from relaxprd
                  WHERE   (((V_DELDET_PRDREC.PRCREF1 = V_PALNOLOC_PRDREC.PRCREF1) AND V_DELDET_PRDREC.PRCREF1 = RELAXPRD.PRCREF1) OR RELAXPRD.PRCREF1 = -1)
                      AND (((V_DELDET_PRDREC.PRCREF2 = V_PALNOLOC_PRDREC.PRCREF2) AND V_DELDET_PRDREC.PRCREF2 = RELAXPRD.PRCREF2) OR RELAXPRD.PRCREF2 = -1)
                      AND (((V_DELDET_PRDREC.PRCREF3 = V_PALNOLOC_PRDREC.PRCREF3) AND V_DELDET_PRDREC.PRCREF3 = RELAXPRD.PRCREF3) OR RELAXPRD.PRCREF3 = -1)
                      AND (((V_DELDET_PRDREC.PRCREF4 = V_PALNOLOC_PRDREC.PRCREF4) AND V_DELDET_PRDREC.PRCREF4 = RELAXPRD.PRCREF4) OR RELAXPRD.PRCREF4 = -1)
                      AND (((V_DELDET_PRDREC.PRCREF5 = V_PALNOLOC_PRDREC.PRCREF5) AND V_DELDET_PRDREC.PRCREF5 = RELAXPRD.PRCREF5) OR RELAXPRD.PRCREF5 = -1)
                      AND (((V_DELDET_PRDREC.PRCREF6 = V_PALNOLOC_PRDREC.PRCREF6) AND V_DELDET_PRDREC.PRCREF6 = RELAXPRD.PRCREF6) OR RELAXPRD.PRCREF6 = -1)
    			  ORDER BY (  (case PRCREF1 when -1 THEN 0 ELSE 1 END) + (case PRCREF2 when -1 THEN 0 ELSE 1 END)
                             +(case PRCREF3 when -1 THEN 0 ELSE 1 END) + (case PRCREF4 when -1 THEN 0 ELSE 1 END)
    		                 +(case PRCREF5 when -1 THEN 0 ELSE 1 END) + (case PRCREF6 when -1 THEN 0 ELSE 1 END)) DESC
			  ) TMPQUERY
			  WHERE RowNum = 1;

			EXCEPTION

    	       WHEN NO_DATA_FOUND THEN
			      IF DEBUG THEN
					 RAISE;
				  END IF;
    	          Ret_PickStatus := -31;
			   	  GoOn := False;

   		       WHEN OTHERS THEN
			      IF DEBUG THEN
					 RAISE;
				  END IF;
  	   	          Ret_PickStatus := -32;
			   	  GoOn := False;
           END;
		END IF; -- GoOn = 1


        IF GoOn THEN
		   --Now check to see if the selected line allows the differences

		    IF V_DELDET_PRDREC.PRCREF6 <> V_PALNOLOC_PRDREC.PRCREF6 THEN
		      IF V_RELAXPRD.RELAXPRCREF6 = 1 THEN
			     -- Relaxed but allowed to be
				 Ret_PickStatus := 6;
			  ELSE
			     -- Relaxation not allowed
				 Ret_PickStatus := -6;
		      END IF;
		    END IF;


		   IF V_DELDET_PRDREC.PRCREF5 <> V_PALNOLOC_PRDREC.PRCREF5 THEN
		      IF V_RELAXPRD.RELAXPRCREF5 = 1 THEN
			     -- Relaxed but allowed to be
				 Ret_PickStatus := 5;
			  ELSE
			     -- Relaxation not allowed
				 Ret_PickStatus := -5;
		      END IF;
		    END IF;

		    IF V_DELDET_PRDREC.PRCREF4 <> V_PALNOLOC_PRDREC.PRCREF4 THEN
		      IF V_RELAXPRD.RELAXPRCREF4 = 1 THEN
			     -- Relaxed but allowed to be
				 Ret_PickStatus := 4;
			  ELSE
			     -- Relaxation not allowed
				 Ret_PickStatus := -4;
		      END IF;
		    END IF;

		    IF V_DELDET_PRDREC.PRCREF3 <> V_PALNOLOC_PRDREC.PRCREF3 THEN
		      IF V_RELAXPRD.RELAXPRCREF3 = 1 THEN
			     -- Relaxed but allowed to be
				 Ret_PickStatus := 3;
			  ELSE
			     -- Relaxation not allowed
				 Ret_PickStatus := -3;
		      END IF;
		    END IF;

			IF V_DELDET_PRDREC.PRCREF2 <> V_PALNOLOC_PRDREC.PRCREF2 THEN
		      IF V_RELAXPRD.RELAXPRCREF2 = 1 THEN
			     -- Relaxed but allowed to be
				 Ret_PickStatus := 2;
			  ELSE
			     -- Relaxation not allowed
				 Ret_PickStatus := -2;
		      END IF;
		    END IF;


			IF V_DELDET_PRDREC.PRCREF1 <> V_PALNOLOC_PRDREC.PRCREF1 THEN
		      IF V_RELAXPRD.RELAXPRCREF1 = 1 THEN
			     -- Relaxed but allowed to be
				 Ret_PickStatus := 1;
			  ELSE
			     -- Relaxation not allowed
				 Ret_PickStatus := -1;
		      END IF;
		    END IF;

	    END IF; -- GoOn

    RETURN Ret_PickStatus;

END CHECKPICKRELAX;




FUNCTION  PICKPALLET(      In_UserName        IN VARCHAR2,
                           In_DelDetRecNo     IN INTEGER,
                           In_PalLocRecNo     IN INTEGER,
						   In_BoxQty          IN INTEGER       )
          RETURN INTEGER IS Ret_PickStatus INTEGER  := -999 ;
		  PRAGMA AUTONOMOUS_TRANSACTION;

 	/** BSDL 8730 31Dec12 TV
	    This function takes a passed PalLocRecNo and picks the passed number of boxes against the passed DelDetRecNo.

		Currently don't do anything with the passed userlogon name, but it might be useful in the future if we need to log
		usage.

		Ths function does not check to make sure that the pallet is 'allowed' to be picked for the deldet, there are other
		functions for that.

		The pallet is set as though it has been picked by palconf_scan ie the delivery does not have to be allocated to stock
		or allocated to areas

		It is intended for use with the RDT program but there is no reason why it should not be used elsewhere as long as any other
		program carries out the validation before picking.

		Returned values (not all values are currently used... room for expansion of errors!) are:
		   0 = Pallet successfully picked
		   -10 .. -19 = Errors with DelRecNo
		   -20 .. -29 = Errors with Pallocrecno
		   -30 .. -39 = errors in Quantity
		   -40 .. -49 = DelToLoc errors
		   -50 .. -59 = DelToAll errors
           -60 .. -69 = Allocate Errors
           -70 .. -79 = Alltoare Errors
		   -80 .. -89 = PalInTran Errors
		   -90 .. -99 = Palindet errors

		   -999 = failure for an unspecified reason (debug)

	**/


    --Variables
	  GoOn   Boolean	:= True;
	  V_PalLocRecNo PALNOLOC.PALLOCRECNO%TYPE;
	  V_DelDetRecNo DELDET.DelRecNo%TYPE;
      V_DEFBAYNO 	WHINTLOC.STCBAYRECNO%TYPE;
	  V_LOCRECNO    DELTOLOC.LOCRECNO%TYPE;

	  V_PALNOLOC    PALNOLOC%ROWTYPE;
	  V_DELDET      DELDET%ROWTYPE;

	  V_RTEHEAD	    RTEHEAD%ROWTYPE;  --this needs addressing 'cos you should not need to put the schema name in here!

	  DELTOLOCBOXES           INTEGER;
	  TOTBOXESTOALLOCATE      INTEGER;
	  BoxesToAllocateThisLine INTEGER;
	  UnPicked   			  INTEGER;

      ALREADYALLOCATED        INTEGER;
	  V_DelToAllRecNo         INTEGER;
	  V_DalQty		          INTEGER;
	  V_NEW_DALQTY			  INTEGER;
      V_NEW_DELTOLOC_QTY	  INTEGER;
      AmountToUpdate	  	  INTEGER;

	  FoundPalInTran          BOOLEAN;
	  FoundPalInDet           BOOLEAN;
	  LoadingBay              INTEGER;
	  RteHeadRecNo            INTEGER;


	  -- DELTOLOC
      CURSOR V_DELTOLOC_CURSOR (V_DELRECNO INTEGER, V_ALLOCNO INTEGER) IS
        (SELECT * FROM DELTOLOC WHERE LOCDELRECNO = V_DELRECNO
		AND LOCALLOCNO = V_ALLOCNO );

	  -- DELTOALL
      CURSOR V_DELTOALL_CURSOR (V_DELRECNO INTEGER, V_ALLOCNO INTEGER, V_PALLOCRECNO INTEGER) IS
        (SELECT * FROM DELTOALL WHERE DALTYPERECNO = V_DELRECNO
		AND DALALLOCNO = V_ALLOCNO AND DALPALLOCRECNO = V_PALLOCRECNO AND DALRECORDTYPE = 1 );

	  -- ALLOCATE
      CURSOR V_ALLOCATE_CURSOR (V_ALLOCNO INTEGER) IS
        (SELECT * FROM ALLOCATE WHERE ALLOCNO = V_ALLOCNO);

      -- ALLTOARE
      CURSOR V_ALLTOARE_CURSOR (V_ALLOCNO INTEGER, V_BAYRECNO INTEGER) IS
        (SELECT * FROM ALLTOARE WHERE AAREALLOCNO = V_ALLOCNO
		 AND AAREBAYRECNO = V_BAYRECNO);

	  -- PALINTRAN
	  CURSOR V_PALINTRAN_CURSOR (V_PALLOCRECNO INTEGER) IS
		(SELECT * FROM PALINTRAN WHERE PALLOCRECNO = V_PALLOCRECNO);

	  -- PALINTRAN
	  CURSOR V_PALINDET_CURSOR (V_PALLOCRECNO INTEGER, V_DELRECNO INTEGER, V_DELLOCRECNO INTEGER ) IS
		(SELECT * FROM PALINDET WHERE PALLOCRECNO = V_PALLOCRECNO
		 AND ORIGINALPALLOCRECNO = V_PALLOCRECNO AND DELRECNO = V_DELRECNO AND DELLOCRECNO = V_DELLOCRECNO);

   BEGIN


		IF GoOn THEN
           IF NVL(In_DelDetRecNo, 0) <= 0 THEN
           	  -- No Del Det passed. so error
              Ret_PickStatus := -10;
			  GoOn := False;
           END IF;
		END IF;


		IF GoOn THEN
           IF nvl(In_PalLocRecNo,0) <= 0 THEN
              -- No PalLocRecNo passed. so error
              Ret_PickStatus := -20;
			  GoOn := False;
		   END IF;
        END IF;

		IF GoOn THEN
           IF nvl(In_BoxQty,0) <= 0 THEN
              -- No box quantity passed. so error
              Ret_PickStatus := -30;
			  GoOn := False;
		   END IF;
        END IF;


		IF GoOn THEN
		   -- Get the Palnoloc details
		   BEGIN
    		   V_PalLocRecNo := In_PalLocRecNo;

    	       select PALNOLOC.*
			      INTO V_PALNOLOC
			      from Palnoloc
                  where PalLocRecNo = V_PalLocRecNo
                  AND PalLocStatus = 1
                  AND PalLocRcvFlag = 'Y'
                  AND NVL (PalLocAllNo, -1) > 0;
    	    EXCEPTION
               WHEN NO_DATA_FOUND THEN
			      IF DEBUG THEN
					 RAISE;
				  END IF;
    	          Ret_PickStatus := -21;
			   	  GoOn := False;

   		       WHEN OTHERS THEN
			      IF DEBUG THEN
					 RAISE;
				  END IF;
  	   	          Ret_PickStatus := -22;
			   	  GoOn := False;
           END;
		END IF; -- GoOn


        IF GoOn THEN
		   -- Get the Deldet details
		   BEGIN
    		   V_DelDetRecNo := In_DelDetRecNo;

			   Select DELDET.*
			      Into V_DELDET
			      from deldet
                  Where delrecno = V_DelDetRecNo
				  AND nvl(DELDET.DelStatus, 'Pik') = 'Pik';

    	    EXCEPTION
               WHEN NO_DATA_FOUND THEN
			      IF DEBUG THEN
					 RAISE;
				  END IF;
    	          Ret_PickStatus := -11;
			   	  GoOn := False;

   		       WHEN OTHERS THEN
			      IF DEBUG THEN
				     RAISE;
				  END IF;
  	   	          Ret_PickStatus := -12;
			   	  GoOn := False;
           END;
		END IF; -- GoOn


		/*************
		*   DELTOLOC
		**************/

		-- now check to see if there are any deltoloc records for this deldet
		IF GoOn THEN
    		TOTBOXESTOALLOCATE := In_BoxQty;
    		FOR V_DELTOLOC_RECORD IN V_DELTOLOC_CURSOR (V_DELDET.DELRECNO, V_PALNOLOC.PALLOCALLNO)
    		LOOP
    		   Unpicked := nvl(V_DELTOLOC_RECORD.LOCALLQTY,0) - nvl(V_DELTOLOC_RECORD.LOCQTYINIT,0);

    		   IF Unpicked > TotBoxesToAllocate THEN
    		   	  BoxesToAllocateThisLine := TotBoxesToAllocate;
    		   ELSE
    		   	  BoxesToAllocateThisLine := Unpicked;
    		   END IF;

    		   --Set the deltoloc to picked
    		   IF BoxesToAllocateThisLine > 0 THEN
    		 	  BEGIN
    			  	  UPDATE DELTOLOC
    			      SET LOCQTYINIT = V_DELTOLOC_RECORD.LOCQTYINIT + BoxesToAllocateThisLine,
    				   	  LOCQTYPICKED = V_DELTOLOC_RECORD.LOCQTYPICKED + BoxesToAllocateThisLine
    			      WHERE LOCRECNO = V_DELTOLOC_RECORD.LOCRECNO;

        	      EXCEPTION
       		         WHEN OTHERS THEN
					 	IF DEBUG THEN
						   RAISE;
						END IF;
      	   	            Ret_PickStatus := -40;
    			   	    GoOn := False;
                  END;

    		      TOTBOXESTOALLOCATE := TOTBOXESTOALLOCATE - BoxesToAllocateThisLine;
				  V_LOCRECNO := V_DELTOLOC_RECORD.LOCRECNO;
    		   END IF;

    		END LOOP;
    	END IF; --GoOn

		--If any deltoloc records were set to completely picked, they need to have their status changed to 500
		IF GoOn THEN
		   BEGIN
 		  	  UPDATE DELTOLOC
   		      SET LOCSTATUS = 500
		      WHERE LOCDELRECNO = V_DELDET.DELRECNO
			  AND LOCALLQTY <= LOCQTYPICKED;

        	  EXCEPTION
       		     WHEN OTHERS THEN
				    IF DEBUG THEN
					   RAISE;
					END IF;
      	   	        Ret_PickStatus := -42;
    			   	GoOn := False;
           END;
		END IF;


		--If the entire quantity has not been allocated to existing deltolocs then write a new line for the pallet specifically
		IF GoOn THEN
    		IF TOTBOXESTOALLOCATE > 0 THEN
    		   BEGIN
			      V_LOCRECNO := sp_WizGetControl('LSTDELLOC', 1, 'RDT-' || In_UserName);

    			  INSERT INTO DELTOLOC
				     ( LOCSTATUS, LOCRECNO, LOCDELRECNO, LOCALLOCNO, LOCSTCBAYREC,
					   LOCALLQTY, LOCQTYPICKED, LOCQTYINIT, LOCRDTUSERNO, SELBYDATE,
					   GROWER, PALLOCRECNO,	STCBAYRECTO, PALTOMOVE, PALMODONE,
					   PALMOINIT, LOCPHRRECNO, LOCMOVRECNO, STCLOC )
					 VALUES ( 500, V_LOCRECNO, V_DELDET.DELRECNO, V_PALNOLOC.PALLOCALLNO, V_PALNOLOC.PALLOCBAYRECNO,
					          TOTBOXESTOALLOCATE, TOTBOXESTOALLOCATE, TOTBOXESTOALLOCATE, NULL, NULL,
							  NULL, V_PALNOLOC.PALLOCRECNO, NULL, NULL, NULL,
                              NULL, NULL, NULL, (select whintloc.stcloc from palnoloc, whintloc
							                     WHERE palnoloc.PALLOCBAYRECNO= whintloc.stcbayrecno
							                     AND palnoloc.pallocrecno = V_PALNOLOC.PALLOCRECNO));

               EXCEPTION
       		      WHEN OTHERS THEN
				     IF DEBUG THEN
						RAISE;
					 END IF;
      	   	         Ret_PickStatus := -41;
    		  	     GoOn := False;
               END;
			 END IF; --TotBoxesToAllocate
		END IF; -- GoOn


		/*************
		*   DELTOALL
		**************/

		-- now check to see if there are any deltoall records for this deldet
		IF GoOn THEN
    		TOTBOXESTOALLOCATE := In_BoxQty;
    	    ALREADYALLOCATED   := 0;
			V_DelToAllRecNo    := 0;
			V_DalQty		   := 0;

			--loop through all deltoall which are allocated to this specific pallet
		    FOR V_DELTOALL_RECORD IN V_DELTOALL_CURSOR (V_DELDET.DELRECNO, V_PALNOLOC.PALLOCALLNO, V_PALNOLOC.PALLOCRECNO)
    		LOOP
    		   AlreadyAllocated := AlreadyAllocated + nvl(V_DELTOALL_RECORD.DALQTY,0);
			   V_DelToAllRecNo  := V_DELTOALL_RECORD.DalWizUniqueID;
			   V_DalQty         := V_DELTOALL_RECORD.DalQty;
   		    END LOOP;

			IF V_DelToAllRecNo <> 0 THEN
			   --If a record was found then increase the allocated amount to the sum of
			   --already picked pallet boxes plus the current pick if the allocated amount is
			   --less than the amount already picked plus this pallet's boxes.
			   IF AlreadyAllocated < TOTBOXESTOALLOCATE THEN
    			   BEGIN
				      --Changed BSDL8484 TV 26Jun13 Query did not work on Oracle 9
    				  UPDATE DELTOALL
       		          SET DALQTY = 	CAST(nvl((select sum(QtyBoxes) from palindet
    				                 where Palindet.DELRECNO = DALTYPERECNO
    				                 AND ORIGINALPALLOCRECNO = DALPALLOCRECNO
    				                 AND DALRECORDTYPE = 1),0) AS INTEGER) + TOTBOXESTOALLOCATE
    		          WHERE DALWIZUNIQUEID = V_DELTOALLRECNO;
            	   EXCEPTION
           		      WHEN OTHERS THEN
    				     IF DEBUG THEN
    						RAISE;
    					 END IF;
          	   	         Ret_PickStatus := -50;
        			     GoOn := False;
                   END;
				END IF; -- Allocated amount less than picked amount
			ELSE
			   -- no record was found so insert a new record
			   BEGIN
			      INSERT INTO DELTOALL ( DALWIZUNIQUEID, DALRECORDTYPE, DALTYPERECNO, DALPALLOCRECNO, DALALLOCNO,
                                         DALQTY, DALTYP, DALDATEALL, SALOFFNO, ALLFLAG,
										 OFFALLRECNO, QCCHECKED, QCFLAGGED, QTYPER,	ACTSPLITQTY )
							    VALUES ( sp_WizGetControl('NXTDALWIZUNIQUEID', 1, 'RDT-' || In_UserName), 1, V_DELDET.DELRECNO, V_PALNOLOC.PALLOCRECNO, V_PALNOLOC.PALLOCALLNO,
                                        TOTBOXESTOALLOCATE, NULL, NULL, NULL, NULL,
									    NULL, NULL, NULL , NULL, NULL);
        	   EXCEPTION
       		      WHEN OTHERS THEN
				     IF DEBUG THEN
						RAISE;
					 END IF;
      	   	         Ret_PickStatus := -51;
    			     GoOn := False;
			   END;
			END IF;
		END IF; --GoOn



		/*************
		*   ALLOCATE
		**************/

		-- now edit the allocate record
		-- In the DeltoAll section above the amount to adjust the allocate as
		-- (Current DelToAll - Original DeltoAll) if > 0
		-- so all we have to do here is update the allocate AllocAlloc by this amount if there is enough on the allocate.

		If GoOn THEN
    		BEGIN
               SELECT NVL(SUM(DALQTY), 0)
    		   INTO V_NEW_DALQTY
    		   FROM DELTOALL
    		   WHERE DALTYPERECNO = V_DELDET.DELRECNO
    		   AND DALALLOCNO = V_PALNOLOC.PALLOCALLNO
    		   AND DALPALLOCRECNO = V_PALNOLOC.PALLOCRECNO
    		   AND DALRECORDTYPE = 1 ;
       	    EXCEPTION
           	   WHEN OTHERS THEN
    		      IF DEBUG THEN
    			 	 RAISE;
    			  END IF;
          	   	  Ret_PickStatus := -52;
        		  GoOn := False;
    		END;
    	END IF;


		IF GoOn THEN
			--loop through all allocates (actually can only be only one!)
		    FOR V_ALLOCATE_RECORD IN V_ALLOCATE_CURSOR (V_PALNOLOC.PALLOCALLNO)
    		LOOP
			   If V_DalQty < V_NEW_DALQTY THEN
    			   AmountToUpdate := V_ALLOCATE_RECORD.AllocAlloc + V_NEW_DALQTY - V_DalQty;

    			   -- don't allocate more than the total amount possible to allocate on the record
    			   IF AmountToUpdate > V_ALLOCATE_RECORD.AllocQty THEN
    			      AmountToUpdate := V_ALLOCATE_RECORD.AllocQty;
    			   END IF;

    	   	       BEGIN
    			      UPDATE ALLOCATE
       		          SET ALLOCALLOC = 	AmountToUpdate
    		          WHERE ALLOCNO = V_PALNOLOC.PALLOCALLNO;
            	   EXCEPTION
           		      WHEN OTHERS THEN
    				     IF DEBUG THEN
    						RAISE;
    					 END IF;
          	   	         Ret_PickStatus := -60;
        			     GoOn := False;
                   END;
			   END IF;
			END LOOP;
		END IF; --GoOn




		/*************
		*   ALLTOARE
		**************/

		-- now edit the alltoare record
  	    -- In the DeltoAll section above the amount to adjust the allotoare by was found out as
		-- (Current DelToAll - Original DeltoAll) if > 0
		-- so all we have to do here is update the alltoare AllocAlloc by this amount if there is enough on the allocate.


		IF GoOn THEN
		   -- Get the sum of DelToLocs because they should equal the amount allocated to areas (NB this may include other deliveries)
		   BEGIN
		      SELECT nvl(sum(locAllQty), 0)
			     INTO V_NEW_DELTOLOC_QTY
			     FROM deltoloc
                 WHERE LocAllocNo = V_PALNOLOC.PALLOCALLNO
                 AND  LocStcBayRec = V_PALNOLOC.PALLOCBAYRECNO;
	       EXCEPTION
              WHEN OTHERS THEN
    		     IF DEBUG THEN
    				RAISE;
    			 END IF;
          	   	    Ret_PickStatus := -71;
        			GoOn := False;
           END;
		END IF;

		IF GoOn THEN
			--loop through all allocates (actually can only be only one!)
		    FOR V_ALLTOARE_RECORD IN V_ALLTOARE_CURSOR (V_PALNOLOC.PALLOCALLNO, V_PALNOLOC.PALLOCBAYRECNO)
    		LOOP
			   If V_ALLTOARE_RECORD.AAREAllocQty <> V_NEW_DELTOLOC_QTY THEN
    			   AmountToUpdate := V_NEW_DELTOLOC_QTY;
    			   -- don't allocate more than the total amount possible to allocate on the record
    			   IF AmountToUpdate > V_ALLTOARE_RECORD.AAREPhysQty THEN
    			      AmountToUpdate := V_ALLTOARE_RECORD.AAREPhysQty;
    			   END IF;

    	   	       BEGIN
    			      UPDATE ALLTOARE
       		          SET AAREALLOCQTY = 	AmountToUpdate
    		          WHERE AAREALLOCNO = V_PALNOLOC.PALLOCALLNO
    				  AND AAREBAYRECNO	=  V_PALNOLOC.PALLOCBAYRECNO;
            	   EXCEPTION
           		      WHEN OTHERS THEN
    				     IF DEBUG THEN
    						RAISE;
    					 END IF;
          	   	         Ret_PickStatus := -70;
        			     GoOn := False;
                   END;
				END IF;
			END LOOP;
		END IF; --GoOn




		/*************
		*  PALINTRAN
		**************/

		-- Check to see if there is a palintran for this pallet (ie picked already. or in transit)


		-- first get the route loading bay
		LoadingBay := 0;
		RteHeadRecNo  := NULL;

		IF GoOn THEN
		   BEGIN
		   	  Select *
			  INTO V_RTEHEAD FROM (
			  SELECT RTEHEAD.*
			  FROM rtedetai, Rtehead
              WHERE RteHead.RthNo = RteDetai.RTDRthRecNo
              AND rtedetai.RTDDelDetRecNo = V_DELDET.DELRECNO) tempStr
			    WHERE RowNum = 1;
 	       EXCEPTION
               WHEN NO_DATA_FOUND THEN
    	          --Delivery is not set up on a route, so get the default loading bay
				  LoadingBay := -1;
   		       WHEN OTHERS THEN
			      IF DEBUG THEN
					 RAISE;
				  END IF;
  	   	          Ret_PickStatus := -80;
			   	  GoOn := False;
           END;

		   IF GoOn THEN
			  IF (LoadingBay = 0) THEN
                 LoadingBay   :=  NVL(V_RTEHEAD.RTHBAYNO, 0);
				 RteHeadRecNo := V_RTEHEAD.RTHNO;
			  END IF;
	       END IF;


		   IF (    (GoOn)
		       AND (LoadingBay <= 0)
			  ) THEN
			  -- Either no route, or no bay set up on the route, so get the default loading bay
			  BEGIN
			     SELECT stocloc.DEFLOADBAYRECNO
				 INTO V_DEFBAYNO
				 FROM whintloc, stocloc
                 WHERE WHINTLOC.STCBAYRECNO = V_PALNOLOC.PALLOCBAYRECNO
                 AND WHINTLOC.STCLOC = STOCLOC.STCRECNO;
			  EXCEPTION
                 WHEN NO_DATA_FOUND THEN
    	          --NO default loading bay
				  IF DEBUG THEN
					 RAISE;
				  END IF;
				  Ret_PickStatus := -81;
			   	  GoOn := False;
   		       WHEN OTHERS THEN
			      IF DEBUG THEN
				     RAISE;
				  END IF;
  	   	          Ret_PickStatus := -82;
			   	  GoOn := False;
			   END;

			   IF GoOn THEN
			      --Get the default loading bay
			   	  LoadingBay := NVL(V_DEFBAYNO, 0);
			   END IF;
		   END IF;
		END IF; -- GoOn


		FoundPalInTran := False;
		IF GoOn THEN
    		FOR V_PALINTRAN_RECORD IN V_PALINTRAN_CURSOR (V_PALNOLOC.PALLOCRECNO)
    		LOOP
			   --Must have been already picked, or more likely in transit.  Update to picked pallet
			   FoundPalinTran := True;


			   --Update the Palintran
    	  	   BEGIN
			      UPDATE PALINTRAN
        		  SET PALLOCDESTINATION = NULL,
        			   PALBAYRECNO = LoadingBay,
    				   PALINRTHNO  = RteHeadRecNo,
    				   PALINFROMBAYRECNO = V_PALNOLOC.PALLOCBAYRECNO,
    				   AWAITINGMOVEMENT  = NULL,
    				   NEWDELMOVE = 1,
    				   DESTINATIONWHIAREA = NULL,
    				   PREPLANKEY = NULL,
    				   PUTAWAYMOVE = NULL
    			  WHERE PALLOCRECNO = V_PALNOLOC.PALLOCRECNO;

        	      EXCEPTION
       		         WHEN OTHERS THEN
					    IF DEBUG THEN
						   RAISE;
						END IF;
      	   	            Ret_PickStatus := -83;
    			   	    GoOn := False;
               END;
    		END LOOP;
    	END IF; --GoOn


		--Palintran does not exist so write a new record.
		IF GoOn THEN
		    IF NOT FoundPalInTran THEN
			   BEGIN
    			  INSERT INTO PALINTRAN ( PALLOCRECNO, PALLETNO, PALLOCDESTINATION, PALBAYRECNO, PALINRTHNO,
                                          PALINFROMBAYRECNO, AWAITINGMOVEMENT, NEWDELMOVE, DESTINATIONWHIAREA, PREPLANKEY,
                                          PUTAWAYMOVE )
							     VALUES (V_PALNOLOC.PALLOCRECNO, V_PALNOLOC.PALLETNO, NULL, LoadingBay, RteHeadRecNo,
								         V_PALNOLOC.PALLOCBAYRECNO, NULL, 1, NULL, NULL, NULL);
               EXCEPTION
       		      WHEN OTHERS THEN
				     IF DEBUG THEN
						RAISE;
					 END IF;
      	   	         Ret_PickStatus := -84;
    		  	     GoOn := False;
               END;
			 END IF; --foundPalInTran
		END IF; -- GoOn



		/*************
		*  PALINDET
		**************/

		-- Check to see if there is a palindet for this pallet (ie picked already)

		FoundPalInDet := False;
		IF GoOn THEN

    		FOR V_PALINDET_RECORD IN V_PALINDET_CURSOR (V_PALNOLOC.PALLOCRECNO, V_DELDET.DELRECNO, V_LOCRECNO )
    		LOOP
			   --Must have been already picked, Update the quantity
			   FoundPalinDet := True;

			   --Update the PalinDet
    	  	   BEGIN
			      UPDATE PALINDET
				  SET QTYBOXES = V_PALINDET_RECORD.QTYBOXES + TOTBOXESTOALLOCATE,
        			  QTYMOVEDOFFPAL = V_PALINDET_RECORD.QTYMOVEDOFFPAL + TOTBOXESTOALLOCATE,
        			  WEIGHTSHIP = NULL
    			  WHERE PALLOCRECNO = V_PALNOLOC.PALLOCRECNO
				  AND ORIGINALPALLOCRECNO = V_PALNOLOC.PALLOCRECNO
				  AND DELRECNO = V_DELDET.DELRECNO
				  AND DELLOCRECNO = V_LOCRECNO;

        	      EXCEPTION
       		         WHEN OTHERS THEN
					    IF DEBUG THEN
						   RAISE;
						END IF;
      	   	            Ret_PickStatus := -90;
    			   	    GoOn := False;
               END;
    		END LOOP;
    	END IF; --GoOn


		--PalinDet does not exist so write a new record.
		IF GoOn THEN
		    IF NOT FoundPalInDet THEN
			   BEGIN

   				  INSERT INTO PALINDET ( PALLOCRECNO, ORIGINALPALLOCRECNO, DELRECNO, QTYBOXES, QTYMOVEDOFFPAL,
                                         WEIGHTSHIP, DELLOCRECNO )
								VALUES ( V_PALNOLOC.PALLOCRECNO, V_PALNOLOC.PALLOCRECNO, V_DELDET.DELRECNO, TOTBOXESTOALLOCATE, TOTBOXESTOALLOCATE,
                                         NULL, V_LOCRECNO);

               EXCEPTION
       		      WHEN OTHERS THEN
				     IF DEBUG THEN
						RAISE;
					 END IF;
      	   	         Ret_PickStatus := -84;
    		  	     GoOn := False;
               END;
			 END IF; --NOT foundPalInDet
		END IF; -- GoOn


		--Write a palaudit
		IF GoOn THEN
		   --RDT UnallocPick = RDT PalAudit 42
		   --RDT FormNumber = 999
	   	   Ret_PickStatus := PALLETAUDIT(In_UserName,In_PalLocRecNo, 42, TO_CHAR(V_DELDET.DELDLVORDNO) , TO_CHAR(TOTBOXESTOALLOCATE));
		   COMMIT;
		ELSE
		   ROLLBACK;
		END IF;


    RETURN Ret_PickStatus;

END PICKPALLET;


FUNCTION  PALLETAUDIT(     In_UserName        IN VARCHAR2,
                           In_PalLocRecNo     IN INTEGER,
						   In_AuditType       IN INTEGER,
						   In_FromValue		  IN VARCHAR2,
						   In_ToValue		  IN VARCHAR2,
						   In_FormNumber      IN INTEGER := 999 )
          RETURN INTEGER IS Ret_Status INTEGER := 0;
          PRAGMA AUTONOMOUS_TRANSACTION;

 	/*  BSDL 8730 7Jan13 TV
	    This function writes a new record to the PalAudit table

		In_UserName ia trimmed to 40 Char
		In_FromValue and In_ToValue trimmed to 28 Char

		If the In_FormNo is null then the form No is defaulted to the RDT form no (999)
	*/

	BEGIN
	   BEGIN
	      INSERT INTO PALAUDIT ( PALAUDRECNO, PALAUDPALLOCRECNO, PALAUDBY,
	                          PALAUDDATE, PALAUDTIME, PALAUDTYP,
							  PALAUDFROM, PALAUDTO,
							  PALAUDTRANIND, FORMNO )
				     VALUES (sp_WizGetControl('NXTPALAUDRECNO', 1, 'RDT-' || In_UserName), In_PalLocRecNo, SUBSTR(In_UserName, 1, 40),
  							 TO_CHAR( sysdate), To_Char(SysDate, 'HH:MI:SS'), In_AuditType,
							 SUBSTR(In_FromValue,1,28), SUBSTR(In_ToValue,1,28),
    						 1, In_FormNumber);


       EXCEPTION
       WHEN OTHERS THEN
	      IF DEBUG THEN
			 RAISE;
		  END IF;
          Ret_Status := -1;
    END;

	COMMIT;

	RETURN Ret_Status;
END PALLETAUDIT;


  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER default CONST.C_SPEC) RETURN VARCHAR2
  IS
   -- Returns the current version number so that calling programs can detect if a version is out of date
   -- As with the rest of Freshtrade the version number is in the format nn.nn.nn so it has to be returned as
   -- a string
   -- TV 9Apr15
   -- This is not now the BSDL standard, because it accepts a default parameter
   -- but the RDT historically calls it in this manner
   BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE  
      RETURN cVersionControlNo;
    END IF;                
  END CURRENTVERSION;
--**********************************************************************
  
END BSDL_RDT;
/
