CREATE OR REPLACE PACKAGE BODY BSDL_PK_VAT AS

PROCEDURE GETBESTVAT( ClaRecNo_in IN ACCCLASS.CLARECNO%TYPE,
                      PrcPrdNo_in IN PRDREC.PRCPRDNO%TYPE,
                      StcLoc_in IN STOCLOC.STCRECNO%TYPE,
                      SalOffNo_in IN SALOFFNO.SALOFFNO%TYPE,
                      VatRecNo_out OUT VATRATES.VATRECNO%TYPE,
                      VeaRecNo_out OUT VATEXEMPT.VEARECNO%TYPE,
					  VatLnkRecNo_out OUT VATLINKS.VATLNKRECNO%TYPE,
					  DlvType_in IN DLVTYPE.DLTRECNO%TYPE DEFAULT -32000,
					  CtyNo_in IN CHGTYP.CTYNO%TYPE DEFAULT 1) AS

canproc			  			   BOOLEAN DEFAULT true;
vAll						   CONSTANT INTEGER DEFAULT -32000;
vClaAccCstSup				   ACCCLASS.CLAACCCSTSUP%TYPE;
vCstVatType					   ACCOUNTS.CSTVATTYPE%TYPE;
vDlvCountryNo				   COUNTRY.COUCOURECNO%TYPE;
vFromCountryNo				   COUNTRY.COUCOURECNO%TYPE;
vPrcRef1					   PRDALLDESCS.ALLPREFNO%TYPE DEFAULT vAll;
vPrcRef2					   PRDALLDESCS.ALLPREFNO%TYPE DEFAULT vAll;
vPrcRef3					   PRDALLDESCS.ALLPREFNO%TYPE DEFAULT vAll;
vPrcRef4					   PRDALLDESCS.ALLPREFNO%TYPE DEFAULT vAll;
vPrcRef5					   PRDALLDESCS.ALLPREFNO%TYPE DEFAULT vAll;
vPrcRef6					   PRDALLDESCS.ALLPREFNO%TYPE;
vChgVatGrpNo				   CHGVATGROUPS.CHGVATGRPNO%TYPE;
vDlvType					   DLVTYPE.DLTRECNO%TYPE;
vSalOffNo					   SALOFFNO.SALOFFNO%TYPE;

BEGIN
    -- Validate Input Parameters
	 IF canproc
	 THEN
		BEGIN
			SELECT accclass.ClaAccCstSup, NVL(accounts.CstVatType, vAll), NVL(accounts.AccCountryNo, vAll)
			INTO vClaAccCstSup, vCstVatType, vDlvCountryNo
			FROM ACCCLASS accclass
			INNER JOIN ACCOUNTS accounts
			ON accounts.AccRecNo = accclass.ClaAccNo
			WHERE accclass.ClaRecNo = ClaRecNo_in;
		EXCEPTION
				 WHEN OTHERS THEN canproc := false ;
		END;
	 END IF;

	 IF canproc
	 THEN
	 	 IF PrcPrdNo_in <> vAll
		 THEN
		 	 BEGIN
			 	  SELECT NVL(prdrec.PrcRef1, vAll), NVL(prdrec.PrcRef2, vAll), NVL(prdrec.PrcRef3, vAll), NVL(prdrec.PrcRef4, vAll), NVL(prdrec.PrcRef5, vAll), NVL(prdrec.PrcRef6, vAll)
				  INTO vPrcRef1, vPrcRef2, vPrcRef3, vPrcRef4, vPrcRef5, vPrcRef6
				  FROM PRDREC prdrec
				  WHERE prdrec.PrcPrdNo = PrcPrdNo_in;
			 EXCEPTION
			 		  WHEN OTHERS THEN canproc := false ;
			 END;
		 END IF;
	 END IF;

	 IF canproc
	 THEN
		BEGIN
			SELECT NVL(stocloc.InCountry, vAll)
			INTO vFromCountryNo
			FROM STOCLOC stocloc
			WHERE stocloc.StcRecNo = StcLoc_in;
		EXCEPTION
				 WHEN OTHERS THEN canproc := false ;
		END;
	 END IF;

	 IF canproc
	 THEN
		BEGIN
			SELECT ChgVatGrpNo
			INTO vChgVatGrpNo
			FROM CHGVATGRPDETS chgvatgrpdets
			WHERE chgvatgrpdets.CtyNo = CtyNo_in;
		EXCEPTION
				 WHEN NO_DATA_FOUND THEN vChgVatGrpNo := vAll ;
				 WHEN OTHERS THEN canproc := false ;
		END;
	 END IF;

	 IF canproc
	 THEN
	 	 vDlvType := NVL(DlvType_in,vAll);
		 vSalOffNo := NVL(SalOffNo_in,vAll);
	 END IF;

	 IF canproc
	 THEN
	 	DECLARE
			CURSOR vat_match_cur IS
			 	SELECT vatlinks.VatLnkRecNo,
			  		   vatlinks.VatRecNo,
			  		   vatlinks.VatVeaRecNo,
					   (CASE WHEN NVL(vatlinks.VatPrcRef1,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatPrcRef2,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatPrcRef3,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatPrcRef4,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatPrcRef5,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatPrcRef6,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatFromCountryNo,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatDlvCountryNo,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.ChgVatGrpNo,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.CstVatType,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatSalesOffice,vAll) <> vAll THEN 1 ELSE 0 END +
						 CASE WHEN NVL(vatlinks.VatDlvType,vAll) <> vAll THEN 1 ELSE 0 END) AS NoMatches
				  FROM VATLINKS vatlinks
				  WHERE vatlinks.VatAccCstSup = vClaAccCstSup
				  		AND vatlinks.PanItRef1 = -1
						AND (NVL(vatlinks.VatPrcRef1,vAll) IN(vAll, vPrcRef1))
						AND (NVL(vatlinks.VatPrcRef2,vAll) IN(vAll, vPrcRef2))
						AND (NVL(vatlinks.VatPrcRef3,vAll) IN(vAll, vPrcRef3))
						AND (NVL(vatlinks.VatPrcRef4,vAll) IN(vAll, vPrcRef4))
						AND (NVL(vatlinks.VatPrcRef5,vAll) IN(vAll, vPrcRef5))
						AND (NVL(vatlinks.VatPrcRef6,vAll) IN(vAll, vPrcRef6))
						AND (NVL(vatlinks.VatFromCountryNo,vAll) IN(vAll, vFromCountryNo))
						AND (NVL(vatlinks.VatDlvCountryNo,vAll) IN(vAll, vDlvCountryNo))
						AND (NVL(vatlinks.ChgVatGrpNo,vAll) IN(vAll, vChgVatGrpNo))
						AND (NVL(vatlinks.CstVatType,vAll) IN(vAll, vCstVatType))
						AND (NVL(vatlinks.VatDlvType,vAll) IN(vAll, vDlvType))
						AND (NVL(vatlinks.VatSalesOffice,vAll) IN(vAll, vSalOffNo))
				  ORDER BY 4 DESC, 2;

			vat_match_rec 		vat_match_cur%ROWTYPE;
		BEGIN
			OPEN vat_match_cur;
			FETCH vat_match_cur INTO vat_match_rec;

			IF vat_match_cur%NOTFOUND
			THEN
				CLOSE vat_match_cur;
				RAISE NO_VAT_FOUND;
			ELSIF vat_match_rec.VatRecNo < 0
			THEN
				CLOSE vat_match_cur;
				RAISE NO_VAT_FOUND;
			ELSE
				VatRecNo_out := vat_match_rec.VatRecNo;
			    VeaRecNo_out := vat_match_rec.VatVeaRecNo;
				VatLnkRecNo_out := vat_match_rec.VatLnkRecNo;
				CLOSE vat_match_cur;
			END IF;
		END;
	 END IF;

	 IF NOT canproc
	 THEN
	 	 RAISE VAT_ERROR ;
	 END IF;

END GETBESTVAT;

PROCEDURE CALCSALESVAT(	ClaRecNo_in IN ACCCLASS.CLARECNO%TYPE,
                      	PrcPrdNo_in IN PRDREC.PRCPRDNO%TYPE,
                      	StcLoc_in IN STOCLOC.STCRECNO%TYPE,
                      	SalOffNo_in IN SALOFFNO.SALOFFNO%TYPE,
                      	DlvType_in IN DLVTYPE.DLTRECNO%TYPE,
						ExtPrice_in IN FLOAT ,
						VatRecNo_out OUT VATRATES.VATRECNO%TYPE,
                      	VeaRecNo_out OUT VATEXEMPT.VEARECNO%TYPE,
						VatAmount1_out OUT FLOAT,
						VatAmount2_out OUT FLOAT) AS

canproc					BOOLEAN DEFAULT true;
VatLnkRecNo_out			VATLINKS.VATLNKRECNO%TYPE;
vApply2Vat				ACCOUNTS.ACCAPPLY2VATSSALES%TYPE;
vCompoundVat			ACCOUNTS.ACCAPPLYCOMPVATSALE%TYPE;
rec_VatRates			VATRATES%ROWTYPE;

BEGIN
	VatRecNo_out := NULL;
    VeaRecNo_out := NULL;
	VatAmount1_out := NULL;
	VatAmount2_out := NULL;

	IF canproc
	THEN
		IF ClaRecNo_in IS NULL
		   OR PrcPrdNo_in IS NULL
		   OR StcLoc_in IS NULL
		   OR SalOffNo_in IS NULL
		   OR ExtPrice_in IS NULL
		THEN
			canproc := false;
		END IF;
	END IF;

	IF canproc
	THEN
		BEGIN
			 SELECT accounts.AccApply2VATSSales, accounts.AccApplyCompVATSale
			 INTO vApply2Vat, vCompoundVat
			 FROM ACCOUNTS accounts
			 INNER JOIN ACCCLASS accclass
			 ON accclass.ClaAccNo = accounts.AccRecNo
			 WHERE accclass.ClaRecNo = ClaRecNo_in;
		EXCEPTION
				 WHEN OTHERS THEN canproc := false;
 		END;
	END IF;

	IF canproc
	THEN
		BEGIN
			 GETBESTVAT(ClaRecNo_in,
                       	PrcPrdNo_in,
                      	StcLoc_in,
                      	SalOffNo_in,
                      	VatRecNo_out,
                      	VeaRecNo_out,
					  	VatLnkRecNo_out,
						DlvType_in,
						1);
		EXCEPTION
				 WHEN OTHERS THEN canproc := false;
		END;
	END IF;

	IF canproc
	THEN
		BEGIN
			SELECT vatrates.*
			INTO rec_VatRates
			FROM VATRATES vatrates
			WHERE vatrates.VatRecNo = VatRecNo_out;
		EXCEPTION
				 WHEN OTHERS THEN canproc := false;
		END;
	END IF;

	IF canproc
	THEN
		VatAmount1_out := ExtPrice_in * (rec_VatRates.VatRate/100.0);
		VatAmount1_out := ROUND(VatAmount1_out, 2);

		IF vApply2Vat = 1
		THEN
			IF vCompoundVat = 1
			THEN
				VatAmount2_out := (ExtPrice_in + VatAmount1_out) * (rec_VatRates.VatRate2/100.0);
			ELSE
				VatAmount2_out := ExtPrice_in * (rec_VatRates.VatRate2/100.0);
			END IF;

			VatAmount2_out := ROUND(VatAmount2_out, 2);
		END IF;
	END IF;

	IF NOT canproc
	THEN
		RAISE VAT_ERROR ;
	END IF;

END CALCSALESVAT;


PROCEDURE CALCDELPRICEVAT(  CLARECNO_IN     IN  ACCCLASS.CLARECNO%TYPE,
                                PRCPRDNO_IN     IN  PRDREC.PRCPRDNO%TYPE,
                                STCLOC_IN       IN  STOCLOC.STCRECNO%TYPE,
                                SALOFFNO_IN     IN  SALOFFNO.SALOFFNO%TYPE,
                                DLVTYPE_IN      IN  DLVTYPE.DLTRECNO%TYPE,
                                VALUE_IN        IN  FLOAT ,
                                VATRECNO_OUT    OUT VATRATES.VATRECNO%TYPE,
                                VATRATE1_OUT    OUT VATRATES.VATRATE%TYPE,
                                VATRATE2_OUT    OUT VATRATES.VATRATE2%TYPE,
                                VATAMOUNT_OUT   OUT FLOAT) AS

    V_CANPROC                   BOOLEAN DEFAULT TRUE;
    V_VATLNKRECNO               VATLINKS.VATLNKRECNO%TYPE;
    V_VEARECNO                  VATEXEMPT.VEARECNO%TYPE;                  
    V_APPLY2VAT                 ACCOUNTS.ACCAPPLY2VATSSALES%TYPE;
    V_COMPOUNDVAT               ACCOUNTS.ACCAPPLYCOMPVATSALE%TYPE;
    REC_VATRATES                VATRATES%ROWTYPE;
    V_VATAMOUNT2                FLOAT;

    BEGIN
        VATRECNO_OUT    := NULL;    
        VATRATE1_OUT    := NULL;
        VATRATE2_OUT    := NULL;
        VATAMOUNT_OUT  := NULL;
        
        
        IF V_CANPROC THEN
            IF CLARECNO_IN IS NULL
               OR PRCPRDNO_IN IS NULL
               OR STCLOC_IN IS NULL
               OR SALOFFNO_IN IS NULL
               OR VALUE_IN IS NULL THEN
                V_CANPROC := FALSE;
            END IF;
        END IF;

        IF V_CANPROC THEN
            BEGIN
                 SELECT NVL(ACCOUNTS.ACCAPPLY2VATSSALES,0), NVL(ACCOUNTS.ACCAPPLYCOMPVATSALE,0)
                 INTO V_APPLY2VAT, V_COMPOUNDVAT
                 FROM ACCOUNTS ACCOUNTS
                 INNER JOIN ACCCLASS ACCCLASS
                 ON ACCCLASS.CLAACCNO = ACCOUNTS.ACCRECNO
                 WHERE ACCCLASS.CLARECNO = CLARECNO_IN;
            EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                -- THIS ACCOUNT MAY HAVE NO INVOICES WHICH IS FINE            
                    NULL;
                    V_CANPROC := FALSE;  
                WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(-20002, 'BSDL_PK_VAT.CALCDELPRICEVAT - GET ACCOUNTS -'||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);
                    NULL;   
                    V_CANPROC := FALSE;
            END;
        END IF;

        IF V_CANPROC THEN
            BEGIN
                 GETBESTVAT(CLARECNO_IN,
                            PRCPRDNO_IN,
                            STCLOC_IN,
                            SALOFFNO_IN,
                            VATRECNO_OUT,
                            V_VEARECNO,
                            V_VATLNKRECNO,
                            DLVTYPE_IN,
                            1);
            EXCEPTION
                WHEN OTHERS THEN 
                    V_CANPROC := FALSE;
            END;
        END IF;
        
        IF V_CANPROC  THEN
            IF NVL(VATRECNO_OUT,0) = 0 THEN
                V_CANPROC := FALSE;
            END IF;
        END IF; 
             

        IF V_CANPROC     THEN
            BEGIN
                SELECT VATRATES.*
                INTO REC_VATRATES
                FROM VATRATES VATRATES
                WHERE VATRATES.VATRECNO = VATRECNO_OUT;
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(-20002, 'BSDL_PK_VAT.CALCDELPRICEVAT - GET VATRATES -'||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);                
                    NULL;   
                    V_CANPROC := FALSE;
            END;
        END IF;
        
        IF V_CANPROC     THEN                
            VATRATE1_OUT    := REC_VATRATES.VATRATE;
            IF V_APPLY2VAT = 1 THEN
            BEGIN                            
                VATRATE2_OUT    := REC_VATRATES.VATRATE2;
            END;
            END IF;            
                        
        END IF;
        
        IF V_CANPROC  THEN
            IF ABS(NVL(VALUE_IN,0)) < 0.0001  THEN
            -- NO NEED TO CALCULATE VAT FIGURES IF THIS IS ZERO
                V_CANPROC := FALSE;
            END IF;
        END IF;     

        IF V_CANPROC  THEN
            
            IF ABS(NVL(REC_VATRATES.VATRATE,0)) > 0.00001  THEN
            BEGIN        
                VATAMOUNT_OUT := VALUE_IN * (REC_VATRATES.VATRATE/100.0);
                -- THIS WILL NEED EXTRA WORK FOR CURRENCY DECIMAL PLACES    
                VATAMOUNT_OUT := ROUND(VATAMOUNT_OUT, 2);              
            END;
            END IF;
        END IF;

        IF V_CANPROC  THEN
            IF V_APPLY2VAT = 1 THEN
            BEGIN                
                IF ABS(NVL(REC_VATRATES.VATRATE2,0)) > 0.00001  THEN                                  
                BEGIN                                
                    
                    IF V_COMPOUNDVAT = 1 THEN            
                        V_VATAMOUNT2 := ((VALUE_IN + VATAMOUNT_OUT) * (REC_VATRATES.VATRATE2/100.0));                        
                    ELSE
                        V_VATAMOUNT2 := (VALUE_IN * (REC_VATRATES.VATRATE2/100.0));
                    END IF;
                    -- THIS WILL NEED EXTRA WORK FOR CURRENCY DECIMAL PLACES
                    V_VATAMOUNT2 := ROUND(V_VATAMOUNT2, 2);
                    VATAMOUNT_OUT := VATAMOUNT_OUT + V_VATAMOUNT2;
                    
                END;
                END IF;
            END;
            END IF;
        END IF;

    END CALCDELPRICEVAT;

END BSDL_PK_VAT;
/

