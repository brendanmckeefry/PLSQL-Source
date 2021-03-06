create or replace PACKAGE BODY FT_PK_TRANS_COSTS AS

  cVersionControlNo   VARCHAR2(12) := '1.0.5'; -- Current Version Number
	CURSOR TRANSFER_OWNER_SUBCHG_CUR(TRORECNO_IN TRANSFEROWNER.TRORECNO%TYPE)
	IS
	SELECT TRORECNO, TROFROMISTRECNO, TROTOISTRECNO, TROTRANDELRECNO, DELQTY SUBDELQTY, ISTRANSHIPONLY, TRODPRRECNO
	  FROM TRANSFEROWNER
	 WHERE TRANSFEROWNER.TRORECNO = TRORECNO_IN
	   AND NOT EXISTS(SELECT *
	   	   	   			FROM DELPRICE
					   WHERE TRANSFEROWNER.TRODPRRECNO = DELPRICE.DprRecNo
					   	 AND NVL(DELPRICE.DPRISPRICEADJONLY,0)  = 1);

  CURSOR TRANSFER_OWNER_BF_CHG(TRORECNOLI TRANSFEROWNER.TRORECNO%TYPE)
  IS
    SELECT TRANSICHRECNO, TRANSADDRECNO, TRANSADDCTYNO,TRANSCHGSALOFFNO,
    CASE WHEN NVL(DELQTY,0) > 0 THEN  NVL(SUBDELQTY,0) * NVL(TRANSBASEAPPAMT,0) / NVL(DELQTY,0) ELSE 0 END APPAMT
    ,CASE WHEN NVL(DELQTY,0) > 0 THEN  NVL(SUBDELQTY,0) * NVL(TRANSRAWAPPAMT,0) / NVL(DELQTY,0) ELSE 0 END RAWAPPAMT
    FROM (
    SELECT TRORECNO, DELQTY, TRANSICHRECNO, TRANSADDRECNO,TRANSBASEAPPAMT, TRANSRAWAPPAMT,TRANSADDCTYNO,TRANSCHGSALOFFNO,
    (SELECT DELQTY
    FROM TRANSFEROWNER T2
    WHERE T2.TRORECNO = TRORECNOLI) SUBDELQTY
    FROM TRANSFEROWNER, TRANSFERADDCHGS
    WHERE TROTOISTRECNO IN (SELECT TROFROMISTRECNO
                           FROM TRANSFEROWNER T2
                    WHERE T2.TRORECNO = TRORECNOLI)
    AND TRANSFEROWNER.TRORECNO = TRANSFERADDCHGS.TRANSADDTRORECNO);

	CURSOR TRANSFER_OWNER_TO_CUR(TRORECNO_TO_IN TRANSFEROWNER.TRORECNO%TYPE)
	IS
	SELECT TroRecNo, DelQty
	  FROM Transferowner
	 WHERE TROFROMISTRECNO IN (SELECT TroToIstRecNo
	 	   				   	  	 FROM transferowner t2
								WHERE t2.troRecNo = TRORECNO_TO_IN);

	CURSOR TRANSFER_OWNER_FROM_CUR(TRORECNO_FROM_IN TRANSFEROWNER.TRORECNO%TYPE)
	IS
	SELECT TroRecNo, DelQty
	  FROM Transferowner
	 WHERE TROFROMISTRECNO IN (SELECT TroToIstRecNo
	 	   				   	  	 FROM transferowner t2
								WHERE t2.troRecNo = TRORECNO_FROM_IN);


  CURSOR TRANSFEROWNER_FROM_BF(TRORECNOLI TRANSFEROWNER.TRORECNO%TYPE)
	IS
	SELECT TroRecNo
	  FROM Transferowner
	 WHERE TroToIstRecNo IN (SELECT TROFROMISTRECNO
                          FROM transferowner t2
                          WHERE t2.troRecNo = TRORECNOLI);

	CURSOR TRANSFEROWNER_TO_BF(TRORECNOLI TRANSFEROWNER.TRORECNO%TYPE)
	IS
	SELECT TroRecNo
	  FROM Transferowner
	 WHERE TroToIstRecNo IN (SELECT TROFROMISTRECNO
	 	   				   	  	 FROM transferowner t2
								WHERE t2.troRecNo = TRORECNOLI);

	CURSOR COST_SCHEMA_CUR(EXPCHA_Collection RECORD_NUMBERS)
	IS
	SELECT ICHRECNO, EXCRECNO, ITECHG.DPRRECNO, ITECHG.DELRECNO, CTYNO, ICHAPPAMT, ICHAUTHAMM,
		   ICHRAWAPPAMT, ICHRAWAUTHAMM, EXCCURRNO, EXCRAWAMM, EXCEUROAMM,
		   EXCCONAMM, EXCTOEUROEXCRATE, EXCTOBASERATE, EXCSALOFF, IstranshipOnly,
		   TransferOwner.TRORECNO, TransferOwner.DelQty ToDelQty, TransferOwner.TROTOISTRECNO,
		   Delprice.DelPrcQty AS SDelQty, IchAppAmt TotalValue,TransferOwner.TroTranDelRecNo,
		   1 TotCount,
		   IchAppAmt TOTApp
	  FROM TransferOwner, Delprice ,ExpCha, IteChg, ITESTO
	 WHERE TransferOwner.TRODPRRECNO = Delprice.DprRecNo
   AND Delprice.DprRecNo = Itechg.DprRecNo
   AND TRANSFEROWNER.TROTOISTRECNO = ITESTO.IstRecNo
   And TRANSFEROWNER.TROFROMISTRECNO = Itechg.ICHISTRECNO
   AND ExpCha.EXCCHAREC = IteChg.EXCRECNO
   AND ExpCha.EXCCHAREC IN (SELECT column_value FROM TABLE(EXPCHA_Collection))

	UNION ALL

	SELECT ICHRECNO, EXCRECNO, 0 AS DPRRECNO, ITECHG.DELRECNO, CTYNO, ICHAPPAMT, ICHAUTHAMM,
		   ICHRAWAPPAMT, ICHRAWAUTHAMM, EXCCURRNO, EXCRAWAMM, EXCEUROAMM,
		   EXCCONAMM, EXCTOEUROEXCRATE, EXCTOBASERATE, EXCSALOFF, IstranshipOnly,
		   TransferOwner.TRORECNO, TransferOwner.DelQty ToDelQty, TransferOwner.TROTOISTRECNO,
		   Deldet.DelQty, IchAppAmt TotalValue,TransferOwner.TroTranDelRecNo,
		   (SELECT COUNT(*)
		      FROM TransferOwner to1
			 WHERE to1.TroTranDelRecNo = TransferOwner.TroTranDelRecNo) TotCount,
		   ROUND((CASE WHEN NVL(TransferOwner.DelQty,0) > 0
		   			   THEN NVL(TransferOwner.DelQty,0) * 1.00 *  NVL(ICHAPPAMT,0) / NVL(Deldet.DelQty,0) * 1.00
					   ELSE 0.00
				  END),2) TOTApp
	  FROM TransferOwner, Deldet,ExpCha, IteChg , ITESTO
	 WHERE TransferOwner.TroTranDelRecNo = Deldet.DelRecNo
	   AND TRANSFEROWNER.TROTOISTRECNO = ITESTO.IstRecNo
	   AND Deldet.DelRecNo = Itechg.DelRecNo
	   AND ExpCha.EXCCHAREC = IteChg.EXCRECNO
	   AND ExpCha.EXCCHAREC IN (SELECT column_value FROM TABLE(EXPCHA_Collection))

	ORDER BY EXCRECNO, Ichrecno ,DelRecNo, DPRRECNO;

-- 	TYPE COST_SCHEMA_RECS IS TABLE OF COST_SCHEMA_CUR%ROWTYPE INDEX BY PLS_INTEGER;

  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE  
      RETURN cVersionControlNo;
    END IF;                
  END CURRENTVERSION;

	------------------------
	-- PRIVATE PROCEDURES --
	-- PRIVATE PROCEDURES --
	------------------------
  	PROCEDURE TRANSFERADDCHGSAPP_PRIV(EXPCHA_Collection_IN RECORD_NUMBERS)
	IS
      PARAMETER_LIST         FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;

	  V_TRANSADDRECNO		 INTEGER;
	  V_TRANSADDTRORECNO	 INTEGER;
	  V_TRANSICHRECNO		 INTEGER;
	  V_TRANSADDCTYNO		 SMALLINT;
	  V_TRANSBASEAPPAMT		 NUMBER;
	  V_TRANSRAWAPPAMT		 NUMBER;
	  V_TRANSADDBFFLAG		 SMALLINT;
    V_TRANSCHGSALOFFNO  SMALLINT;

	  LInsert				 BOOLEAN;
	  TranAddRecNoLi		 INTEGER;

	--ValueToDo		  		 NUMBER;
	  TotAppAmtNu	  		 NUMBER;
	  TotRawAppAmtNu  		 NUMBER;

	  AppSubBaseValNu		 NUMBER;
	  AppSubRawValNu		 NUMBER:= 0.0;

	  Counter	  	  		 INTEGER:= 0;
	  SalOffNoSi	  		 SMALLINT;

    SalOffNoBFSi      SMALLINT;
    CtyNoBFSi         SMALLINT;

	  CritStr				 VARCHAR(40);

    TRORECNO_Collection RECORD_NUMBERS := RECORD_NUMBERS();

    TRORECNO_CollectionBF RECORD_NUMBERS := RECORD_NUMBERS();

  	  TYPE NUM_Array IS TABLE OF NUMBER		-- Associative array type
      	   INDEX BY VARCHAR2(64);      		--  indexed by INTEGER

  	  ValueToDo_N_Array  NUM_Array;        	-- Associative array variable
  	BEGIN
		 FOR ITRREC IN COST_SCHEMA_CUR(EXPCHA_Collection_IN) LOOP

			LInsert:= TRUE;
			Counter:= Counter + 1;

			SalOffNoSi:= NULL;

			TotAppAmtNu:= ITRREC.TOTApp;

			CritStr:= ITRREC.ICHRECNO || '~' || ITRREC.DPRRECNO || '~' || ITRREC.DELRECNO;
			IF not ValueToDo_N_Array.EXISTS(CritStr) THEN
			   ValueToDo_N_Array(CritStr):= ITRREC.ICHAPPAMT;
			END IF;
			ValueToDo_N_Array(CritStr):= ValueToDo_N_Array(CritStr) - TotAppAmtNu;

			IF Counter = ITRREC.TotCount THEN
				Counter:= 0;
				IF ABS(ValueToDo_N_Array(CritStr)) > 0.009 THEN
					TotAppAmtNu:= TotAppAmtNu + ValueToDo_N_Array(CritStr);
				END IF;
			END IF;

			IF ABS(ITRREC.EXCTOBASERATE) > 0.00009 THEN
				TotRawAppAmtNu:= TotAppAmtNu * ITRREC.EXCTOBASERATE;
				TotRawAppAmtNu:= ROUND(TotRawAppAmtNu, 2);
			END IF;

			IF ITRREC.IstranshipOnly = 0 THEN
				SalOffNoSi:=  ITRREC.EXCSALOFF;
			END IF;

			BEGIN
				 SELECT TRANSADDRECNO, TRANSADDTRORECNO, TRANSICHRECNO, TRANSADDCTYNO, TRANSBASEAPPAMT, TRANSRAWAPPAMT, TRANSADDBFFLAG
				   INTO V_TRANSADDRECNO, V_TRANSADDTRORECNO, V_TRANSICHRECNO, V_TRANSADDCTYNO, V_TRANSBASEAPPAMT, V_TRANSRAWAPPAMT, V_TRANSADDBFFLAG
				   FROM TRANSFERADDCHGS
				  WHERE TRANSFERADDCHGS.TRANSADDTRORECNO = ITRREC.TRORECNO
				  	AND TRANSFERADDCHGS.TRANSICHRECNO = ITRREC.ICHRECNO;

				TranAddRecNoLi:= V_TRANSADDRECNO;
				LInsert:= FALSE;

			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					SELECT sp_WizGetControl('NXTTRANSADDRECNO', 1, '') AS NXTTRANSADDRECNO INTO TranAddRecNoLi
					  FROM DUAL;

				    IF TranAddRecNoLi < 1 THEN
				       PARAMETER_LIST('#PARAMNAME') := 'sp_WizGetControl.NXTTRANSADDRECNO';
				       PARAMETER_LIST('#PARAMVALUE') := TranAddRecNoLi;
				       FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
				    END IF;

			    WHEN OTHERS THEN
			    	 FT_PK_ERRORS.LOG_AND_STOP;
			END;

			BEGIN
				IF LInsert THEN
				   INSERT INTO TRANSFERADDCHGS(TRANSADDRECNO, TRANSADDTRORECNO, TRANSICHRECNO, TRANSADDCTYNO, TRANSBASEAPPAMT, TRANSRAWAPPAMT, TRANSCHGSALOFFNO)
				   VALUES(TranAddRecNoLi, ITRREC.TRORECNO, ITRREC.ICHRECNO, ITRREC.CTYNO, TotAppAmtNu, TotRawAppAmtNu, SalOffNoSi);
				ELSE
					UPDATE TRANSFERADDCHGS
					   SET TRANSBASEAPPAMT = TotAppAmtNu,
					   	   TRANSRAWAPPAMT = TotRawAppAmtNu,
						   TRANSCHGSALOFFNO = SalOffNoSi
					 WHERE TRANSADDRECNO = TranAddRecNoLi;
				END IF;

				COMMIT;

			EXCEPTION
		      WHEN OTHERS THEN
			  	 ROLLBACK;
		      	 FT_PK_ERRORS.LOG_AND_STOP;
			END;

      TRORECNO_Collection.DELETE;
			FOR TRANSFER_TO_ITRREC IN TRANSFER_OWNER_TO_CUR(ITRREC.TRORECNO) LOOP
        IF NOT TRORECNO_Collection.EXISTS(TRANSFER_TO_ITRREC.TRORECNO) THEN
          TRORECNO_Collection.EXTEND(1);
          TRORECNO_Collection(TRORECNO_Collection.COUNT) := TRANSFER_TO_ITRREC.TRORECNO;
        END IF;

        FOR TRANSFER_FROM_ITRREC IN TRANSFER_OWNER_FROM_CUR(TRANSFER_TO_ITRREC.TRORECNO) LOOP

          IF NOT TRORECNO_Collection.EXISTS(TRANSFER_FROM_ITRREC.TRORECNO) THEN
            TRORECNO_Collection.EXTEND(1);
            TRORECNO_Collection(TRORECNO_Collection.COUNT) := TRANSFER_FROM_ITRREC.TRORECNO;
          END IF;
       END LOOP;
      END LOOP;

			IF TRORECNO_Collection.COUNT > 0 THEN
	    		FOR TRORECNO_ITRREC IN TRORECNO_Collection.FIRST..TRORECNO_Collection.LAST LOOP

					FOR TRANSFER_OWNER_SUBCHG_ITEREC IN TRANSFER_OWNER_SUBCHG_CUR(TRORECNO_Collection(TRORECNO_ITRREC)) LOOP

						AppSubBaseValNu:= 0.00;
						AppSubRawValNu:= 0.00;
						LInsert:= TRUE;

						IF ITRREC.ToDelQty > 0 THEN
						   AppSubBaseValNu:= TRANSFER_OWNER_SUBCHG_ITEREC.SUBDELQTY * TotAppAmtNu;
						   AppSubBaseValNu:= AppSubBaseValNu / ITRREC.ToDelQty;

						   AppSubRawValNu:=  TRANSFER_OWNER_SUBCHG_ITEREC.SUBDELQTY * TotRawAppAmtNu;
						   AppSubRawValNu:=  AppSubRawValNu / ITRREC.ToDelQty;
						END IF;

						BEGIN
							SELECT TRANSADDRECNO, TRANSADDTRORECNO, TRANSICHRECNO, TRANSADDCTYNO, TRANSBASEAPPAMT, TRANSRAWAPPAMT, TRANSADDBFFLAG, TRANSCHGSALOFFNO
							  INTO V_TRANSADDRECNO, V_TRANSADDTRORECNO, V_TRANSICHRECNO, V_TRANSADDCTYNO, V_TRANSBASEAPPAMT, V_TRANSRAWAPPAMT, V_TRANSADDBFFLAG, V_TRANSCHGSALOFFNO
							  FROM TRANSFERADDCHGS
							 WHERE TRANSADDTRORECNO = TRANSFER_OWNER_SUBCHG_ITEREC.TRORECNO
							   AND TRANSICHRECNO = ITRREC.ICHRECNO
							   AND TRANSADDBFFLAG = 1;

						    TranAddRecNoLi:= V_TRANSADDRECNO;
							LInsert:= FALSE;

						EXCEPTION
							WHEN NO_DATA_FOUND THEN
								SELECT sp_WizGetControl('NXTTRANSADDRECNO', 1, '') AS NXTTRANSADDRECNO INTO TranAddRecNoLi
								  FROM DUAL;

							    IF TranAddRecNoLi < 1 THEN
							       PARAMETER_LIST('#PARAMNAME') := 'sp_WizGetControl.NXTTRANSADDRECNO';
							       PARAMETER_LIST('#PARAMVALUE') := TranAddRecNoLi;
							       FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
							    END IF;

						    WHEN OTHERS THEN
						    	 FT_PK_ERRORS.LOG_AND_STOP;
						END;

						IF LInsert THEN
						   INSERT INTO TRANSFERADDCHGS(TRANSADDRECNO, TRANSADDTRORECNO, TRANSICHRECNO, TRANSADDCTYNO, TRANSBASEAPPAMT, TRANSRAWAPPAMT, TRANSADDBFFLAG, TRANSCHGSALOFFNO)
						   VALUES(TranAddRecNoLi, TRANSFER_OWNER_SUBCHG_ITEREC.TRORECNO, ITRREC.ICHRECNO, ITRREC.CTYNO, AppSubBaseValNu, AppSubRawValNu, 1, SalOffNoSi);
						ELSE
							UPDATE TRANSFERADDCHGS
							   SET TRANSBASEAPPAMT = AppSubBaseValNu,
							   	   TRANSRAWAPPAMT = AppSubRawValNu,
								   TRANSCHGSALOFFNO = SalOffNoSi
							 WHERE TRANSADDRECNO = TranAddRecNoLi;
						END IF;

						COMMIT;
					END LOOP;
				END LOOP;
			END IF;

      TRORECNO_CollectionBF.DELETE;
      TRORECNO_CollectionBF.EXTEND(1);
      TRORECNO_CollectionBF(1) := ITRREC.TRORECNO;

      FOR TRANSFER_TO_ITRREC IN TRANSFEROWNER_FROM_BF(ITRREC.TRORECNO) LOOP
        IF NOT TRORECNO_CollectionBF.EXISTS(TRANSFER_TO_ITRREC.TRORECNO) THEN
            TRORECNO_CollectionBF.EXTEND(1);
            TRORECNO_CollectionBF(TRORECNO_CollectionBF.COUNT) := TRANSFER_TO_ITRREC.TRORECNO;
        END IF;

        FOR TRANSFER_FROM_ITRREC IN TRANSFEROWNER_TO_BF(TRANSFER_TO_ITRREC.TRORECNO) LOOP
          IF NOT TRORECNO_CollectionBF.EXISTS(TRANSFER_FROM_ITRREC.TRORECNO) THEN
              TRORECNO_CollectionBF.EXTEND(1);
              TRORECNO_CollectionBF(TRORECNO_CollectionBF.COUNT) := TRANSFER_FROM_ITRREC.TRORECNO;
          END IF;
        END LOOP;
      END LOOP;

      IF TRORECNO_CollectionBF.COUNT > 0 THEN
	    		FOR TRORECNO_ITRREC IN TRORECNO_CollectionBF.FIRST..TRORECNO_CollectionBF.LAST LOOP

            FOR TRANSFER_OWNER_BF_CHG_ITEREC IN TRANSFER_OWNER_BF_CHG(TRORECNO_CollectionBF(TRORECNO_ITRREC)) LOOP

            AppSubBaseValNu:= TRANSFER_OWNER_BF_CHG_ITEREC.APPAMT;
						AppSubRawValNu := TRANSFER_OWNER_BF_CHG_ITEREC.RAWAPPAMT;
            SalOffNoBFSi:= TRANSFER_OWNER_BF_CHG_ITEREC.TRANSCHGSALOFFNO;
            CtyNoBFSi := TRANSFER_OWNER_BF_CHG_ITEREC.TRANSADDCTYNO;
						LInsert:= TRUE;

            BEGIN
							SELECT TRANSADDRECNO, TRANSADDTRORECNO, TRANSICHRECNO, TRANSADDCTYNO, TRANSBASEAPPAMT, TRANSRAWAPPAMT, TRANSADDBFFLAG, TRANSCHGSALOFFNO
              INTO V_TRANSADDRECNO, V_TRANSADDTRORECNO, V_TRANSICHRECNO, V_TRANSADDCTYNO, V_TRANSBASEAPPAMT, V_TRANSRAWAPPAMT, V_TRANSADDBFFLAG, V_TRANSCHGSALOFFNO
              FROM TRANSFERADDCHGS
              WHERE TRANSADDTRORECNO = ITRREC.TRORECNO
              AND TRANSICHRECNO = TRANSFER_OWNER_BF_CHG_ITEREC.TRANSICHRECNO
							AND TRANSADDBFFLAG = 1;

              TranAddRecNoLi:= V_TRANSADDRECNO;
							LInsert:= FALSE;

              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  SELECT sp_WizGetControl('NXTTRANSADDRECNO', 1, '') AS NXTTRANSADDRECNO INTO TranAddRecNoLi
                    FROM DUAL;

                    IF TranAddRecNoLi < 1 THEN
                       PARAMETER_LIST('#PARAMNAME') := 'sp_WizGetControl.NXTTRANSADDRECNO';
                       PARAMETER_LIST('#PARAMVALUE') := TranAddRecNoLi;
                       FT_PK_ERRORS.RAISE_ERROR(FT_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
                    END IF;

                  WHEN OTHERS THEN
                     FT_PK_ERRORS.LOG_AND_STOP;
              END;

              IF LInsert THEN
                INSERT INTO TRANSFERADDCHGS(TRANSADDRECNO, TRANSADDTRORECNO, TRANSICHRECNO, TRANSADDCTYNO, TRANSBASEAPPAMT, TRANSRAWAPPAMT, TRANSADDBFFLAG, TRANSCHGSALOFFNO)
                VALUES(TranAddRecNoLi, ITRREC.TRORECNO, TRANSFER_OWNER_BF_CHG_ITEREC.TRANSICHRECNO, CtyNoBFSi, AppSubBaseValNu, AppSubRawValNu, 1, SalOffNoBFSi);
              ELSE
                UPDATE TRANSFERADDCHGS
                   SET TRANSBASEAPPAMT = AppSubBaseValNu,
                       TRANSRAWAPPAMT = AppSubRawValNu,
                       TRANSCHGSALOFFNO = SalOffNoBFSi
                 WHERE TRANSADDRECNO = TranAddRecNoLi;
              END IF;
            END LOOP;
          END LOOP;
      END IF;
		 END LOOP;

	EXCEPTION
      WHEN OTHERS THEN
      	   FT_PK_ERRORS.LOG_AND_STOP;
	END TRANSFERADDCHGSAPP_PRIV;



	------------------------
	-- PUBLIC PROCEDURES --
	-- PUBLIC PROCEDURES --
	------------------------

  	PROCEDURE TRANSFERADDCHGSAPP_BYRTHNO(RTHNO_IN RECORD_NUMBERS)
	IS
    EXPCHA_Collection  RECORD_NUMBERS := RECORD_NUMBERS();
	BEGIN
		FOR RTHNO_ITR IN RTHNO_IN.FIRST..RTHNO_IN.LAST LOOP

			 SELECT EXCCHAREC
	      	 		BULK COLLECT INTO EXPCHA_Collection
		   	   FROM EXPCHA
			  WHERE EXCRTHNO IN (SELECT RTEHEAD.RTHNO
							 	   FROM RTEDETAI, RTEHEAD
							   	  WHERE RTEDETAI.RTDRTHRECNO = RTEHEAD.RTHNO
									AND RTEDETAI.RTDRTHRECNO = RTHNO_IN(RTHNO_ITR));
		END LOOP;

		TRANSFERADDCHGSAPP_PRIV(EXPCHA_Collection);

   	EXCEPTION
      WHEN OTHERS THEN
      	   FT_PK_ERRORS.LOG_AND_STOP;
	END TRANSFERADDCHGSAPP_BYRTHNO;

  	PROCEDURE TRANSFERADDCHGSAPP_BYEXPCHA(EXCCHAREC_IN RECORD_NUMBERS)
	IS
    EXPCHA_Collection   RECORD_NUMBERS := RECORD_NUMBERS();
	BEGIN
		 FOR EXCCHAREC_ITR IN EXCCHAREC_IN.FIRST..EXCCHAREC_IN.LAST LOOP

			 SELECT EXPCHA.EXCCHAREC
	      	 		BULK COLLECT INTO EXPCHA_Collection
		   	   FROM EXPCHA
			  WHERE EXPCHA.EXCCHAREC = EXCCHAREC_IN(EXCCHAREC_ITR);
		END LOOP;

		TRANSFERADDCHGSAPP_PRIV(EXPCHA_Collection);

	EXCEPTION
      WHEN OTHERS THEN
      	   FT_PK_ERRORS.LOG_AND_STOP;
	END TRANSFERADDCHGSAPP_BYEXPCHA;

  	PROCEDURE TRANSFERADDCHGSAPP_BYDLVORDNO(DLVORDNO_IN RECORD_NUMBERS)
	IS
    EXPCHA_Collection   RECORD_NUMBERS := RECORD_NUMBERS();
	BEGIN
		 FOR DLVORDNO_ITR IN DLVORDNO_IN.FIRST..DLVORDNO_IN.LAST LOOP

			 SELECT EXPCHA.EXCCHAREC
	      	 		BULK COLLECT INTO EXPCHA_Collection
			   FROM EXPCHA
			  WHERE EXPCHA.EXCRTHNO IN (SELECT RTEHEAD.RTHNO
			  						   	  FROM RTEDETAI, RTEHEAD
										 WHERE RTEDETAI.RTDRTHRECNO = RTEHEAD.RTHNO
										   AND RTEDETAI.RTDDLVORDNO = DLVORDNO_IN(DLVORDNO_ITR) );
		END LOOP;

		TRANSFERADDCHGSAPP_PRIV(EXPCHA_Collection);

	EXCEPTION
      WHEN OTHERS THEN
      	   FT_PK_ERRORS.LOG_AND_STOP;
	END TRANSFERADDCHGSAPP_BYDLVORDNO;

	PROCEDURE TRANSFERADDCHGSAPP_BYDLV_DPR(DLVORDNO_IN RECORD_NUMBERS)
	IS
    EXPCHA_Collection   RECORD_NUMBERS := RECORD_NUMBERS();
	BEGIN
		 FOR DLVORDNO_ITR IN DLVORDNO_IN.FIRST..DLVORDNO_IN.LAST LOOP

			 SELECT EXPCHA.EXCCHAREC
		          BULK COLLECT INTO EXPCHA_Collection
		     FROM EXPCHA
		     WHERE EXPCHA.EXCDLVORDNO = DLVORDNO_IN(DLVORDNO_ITR);
	     END LOOP;

		 TRANSFERADDCHGSAPP_PRIV(EXPCHA_Collection);

	EXCEPTION
      WHEN OTHERS THEN
      	   FT_PK_ERRORS.LOG_AND_STOP;
	END TRANSFERADDCHGSAPP_BYDLV_DPR;

  PROCEDURE TRANSFERADDCHGSAPP
	IS
    EXPCHA_Collection   RECORD_NUMBERS := RECORD_NUMBERS();
	BEGIN
		 FOR AUTOCOSTSREC IN (SELECT DISTINCT SALES_VIEW.DLVORDNO FROM FT_V_DLV SALES_VIEW, AUTOCOSTS_PROCESS WHERE SALES_VIEW.DPRRECNO = AUTOCOSTS_PROCESS.DPRRECNO AND AUTOCOSTS_PROCESS.TRANSFERADDCHGSAPP = CONST.C_TRUE) LOOP

			  SELECT EXPCHA.EXCCHAREC
        BULK COLLECT INTO EXPCHA_Collection
        FROM EXPCHA
			  WHERE EXPCHA.EXCRTHNO IN (SELECT RTEHEAD.RTHNO
			  						   	  FROM RTEDETAI, RTEHEAD
										 WHERE RTEDETAI.RTDRTHRECNO = RTEHEAD.RTHNO
										   AND RTEDETAI.RTDDLVORDNO = AUTOCOSTSREC.DLVORDNO);
        
        TRANSFERADDCHGSAPP_PRIV(EXPCHA_Collection);
        
        SELECT EXPCHA.EXCCHAREC
        BULK COLLECT INTO EXPCHA_Collection
        FROM EXPCHA
        WHERE EXPCHA.EXCDLVORDNO = AUTOCOSTSREC.DLVORDNO;
         
        TRANSFERADDCHGSAPP_PRIV(EXPCHA_Collection);
         
		END LOOP;

		

	EXCEPTION
      WHEN OTHERS THEN
      	   FT_PK_ERRORS.LOG_AND_STOP;
	END TRANSFERADDCHGSAPP;  

END FT_PK_TRANS_COSTS;
/
