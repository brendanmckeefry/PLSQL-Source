create or replace PACKAGE BODY FT_PK_SALES_COSTS AS

  cVersionControlNo   VARCHAR2(12) := '1.0.1'; -- Current Version Number
  
  CURSOR TC_IchOldAppAmt(IN_EXCRECNO INTEGER) IS
      Select IchRecNo, IchAppAmt FROM IteChg, chgtyp 
      Where itechg.CtyNo = chgtyp.CtyNo 
      AND IteChg.ExcRecNo =  IN_EXCRECNO
      AND IteChg.ICHSPETO IS NULL;
 
  CURSOR TC_DlvToExp(IN_DLVORDNO INTEGER, IN_EXCRECNO INTEGER) IS     
      Select DelRecNo, DelPrice.DprRecNo, DelQtyPer, PrcWeight, PrcBoxQty, InnerQty,
	   (Case When DelPricePer = 2 then DelNettweight * DelPrcQty else PrcWeight * DelPrcQty end) Weight_ALLOC,
	   (Case When DelPricePer = 2 then DelNettweight * DisQty else PrcWeight * DisQty end) Weight_DLVD,
	   Case When PRCPACPAL = 0 then DelPrcQty else Round(delQty / PRCPACPAL, 2) end RndPals,
	   Case When PRCPACPAL = 0 then DelPrcQty else Ceil(Round(delQty / PRCPACPAL, 2)) end ActPals,
	   (Select Count(PallocRecNo) from Paltodel Where PallocDelrecno  = DelDet.DELRECNO) PaltoDelCount,
	   DelQty, DelPrice.DelPrcQty, DelPrice.delNettValue, ExcChaRec, ExcRawAmm, ExcConAmm, EXCTOEUROEXCRATE,EXCTOBASERATE,EXCAPPTYPE, ExcCtyNo, EXCCHGCALC,
	   NVL(ExcConAmm,0) - NVL((Select SUM(NVL(IchAppAmt,0))
					   			From IteChg
									Where IteChg.ICHSPETO IS NOT NULL
									And Expcha.ExcCharec = IteChg.ExcRecNo),0) TotToApp,
	      chgtyp.Ctydesc, Nvl(chgtyp.ChgIgnoreCrDr, 0) ChgIgnoreCrDr, DelDet.RndApportPals,
		NVL(deltoist.DisStkQty, delprice.DelPrcQty) AS DisStkQty,
	 Nvl(deltoist.DisIstRecNo, (Select Min(PalLocIstRecNo) from PalNoLoc, DelToAll Where DelToAll.DalAllocNo = PalNoLoc.pallocallno AND DalRecordType = 1 AND DalTypeRecNo = Deldet.DelRecNo)) DisIstRecNo
	From DelDet, DelPrice, PrdRec, Expcha, chgtyp, DELTOIST
	Where Deldet.delprcprdno = PrdRec.prcprdno
	AND DelPrice.DprDelrecNo = DelDet.DelrecNo
	And Deldet.DelDlvOrdNo =  IN_DLVORDNO
	And Expcha.ExcDlvOrdNo = Deldet.DelDlvOrdNo
	And Expcha.ExcChaRec =  IN_EXCRECNO
	And DelPrice.DelPrcQty <> 0
	And DelPrice.DprRecNo = deltoist.DisDprRecNo(+)
	AND Expcha.ExcCtyNo = chgtyp.CtyNo
	And Not Exists (Select *
					 	 From IteChg
						 Where IteChg.ExcRecNo = ExpCha.ExcChaRec
						 And IteChg.ICHSPETO IS NOT NULL
						 And IteChg.DPRRECNO = Delprice.DprRecNo)
	 Order by delrecno, dprrecno;

CURSOR TC_DelAudResultSet(IN_DLVORDNO INTEGER, IN_EXCRECNO INTEGER) IS
  select IteChg.IchRecNo, ExcRecNo, IteChg.DprRecNo, CtyNo, IchAppAmt, DelPrice.DprDelRecNo DelRecNo  
  from IteChg, ExpCha, DelPrice 
  Where ExpCha.excDlvOrdNo = IN_DLVORDNO
  And Expcha.ExcChaRec =  IN_EXCRECNO
  AND IteChg.ExcRecNo = ExpCha.ExcChaRec
  AND IteChg.DprRecNo = DelPrice.DprRecNo
  And IteChg.ICHSPETO IS NULL;

--**********************************************************************
  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE  
      RETURN cVersionControlNo;
    END IF;                
  END CURRENTVERSION;
--**********************************************************************

--SRimen 04/03/2015 13676
PROCEDURE LOTITEAPPORTION_DELPRICE(IN_DLVORDNO IN NUMBER, IN_EXCRECNO IN NUMBER) AS

  --Called by AdHocDlv_Chgs (which is called from AdHocDlvMain.fsl)

  V_CONT              NUMBER(1) := 1;
  V_excChaRecCheck    NUMBER;
  DlvIsDlvd           NUMBER;
  SQLStr      				VARCHAR(32675);
  
  DTISel VARCHAR(200);
  DTITab VARCHAR(200);
  DTILnk VARCHAR(200);
  
  RefCursorVar SYS_REFCURSOR;
  
  ExcCtyNo          NUMBER;
  FWeightTot_ALLOC  Float;
  FWeightTot_DLVD   Float;
  IRndPalsTot       NUMBER;
  IDelQtyTot        NUMBER;
  IEXCAPPTYPE       NUMBER;
  IMAX_DELINVSTATUS NUMBER;
  FDelNettValueTot  Float;                                                                                           
  FTotRndApportPals Float;
  
  TotToAppFacNu     Float;
  FloatDelQty       Float;
  
  IIchRecNo        Itechg.IchRecNo%Type;
  FIchAppAmt       Float;
  
  TYPE TYPE_DYN_ORIGITECHG IS TABLE OF FLOAT INDEX BY PLS_INTEGER;
  ORIGITECHG      TYPE_DYN_ORIGITECHG;
  
  NumDlvToExp_RECs NUMBER;
  DlvToExpLoopCnt  NUMBER;
  ExcConAmmNuLeft  Number;
  NuTotalValueToApportion  Number;
  InsertIt        Boolean;
  PerLnToAppFacNu Float;
  NuDivisor       Float;
  NuFloatBoxQty   Float;
  LIgnoreCrDr     Boolean;
  FoundIte        Boolean;
  
  V_IchRecNo      NUMBER; 
  V_IchSpeTo      CHAR(1);
  V_IchAppAmt     Float;
  LAlterLive      Boolean;
  TotToAppPerIte  Float;
  NxtIteNo        NUMBER; 
  ITECHG_TO_WRITE ITECHG%ROWTYPE;
  DELAUDIT_TO_WRITE DELAUDIT%ROWTYPE;
  
  DelAudCnt         NUMBER;
  NumDelAudsToWrite NUMBER;
  DelAudGroupNo     NUMBER;
  NextDelAudRecNo   NUMBER;
  OldIchAppAmt      FLOAT;
  LiLogonNo         NUMBER;
  
  StrFrom           VarChar(16);
  StrTo             VarChar(16);
BEGIN
  
  IF V_CONT =1 THEN
    BEGIN      
      select excChaRec
      INTO V_excChaRecCheck
      from ExpCha Where excdlvordno = IN_DLVORDNO and excChaRec = IN_EXCRECNO;      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FT_PK_ERRORS.LOG_AND_STOP;
        V_CONT := 0;        
      WHEN OTHERS THEN
        V_CONT := 0;         
        FT_PK_ERRORS.LOG_AND_STOP;        
    END;      
  END IF; 
            
  IF V_CONT = 1 THEN
    BEGIN      
     --Dpt is palindet - will be deltoist when confirmrcv
     Select (Case When Nvl(DlvRelInv, 'Ent') in('Ent', 'Pik', 'Dpt') Then 0 else 1 end) --as DlvIsDlvd 
     INTO DlvIsDlvd
     From delhed Where DlvOrdNo = IN_DLVORDNO;
   EXCEPTION
     WHEN OTHERS THEN
       FT_PK_ERRORS.LOG_AND_STOP;       
    END;
  END IF;
  
  -- TODO  LCheckIteChgIgnoreCrDr(Sttmp) << Actually not currently used (in this proc at least)  
    
  IF V_CONT = 1 THEN   
    IF DlvIsDlvd = 1 THEN
      --link in deltoist as actual weight may be different
      DTISel := '  SUM(Case When DelPricePer = 2 then DelNettweight * DisQty else PrcWeight * DisQty end) WeightTot_DLVD,';
      DTITab := ', DelToIst';
      DTILnk := ' And DelPrice.DprRecNo = deltoist.DisDprRecNo(+)';
    ELSE
      DTISel := ' NULL as WeightTot_DLVD, ';
      DTITab := '';
      DTILnk := '';
    END IF; 
  END IF;
          
--***** (1) Determine the Apportionment ******************************        
        
  IF V_CONT = 1 THEN    
    BEGIN
	    SQLStr := 'Select ExcCtyNo, SUM((Case When DelPricePer = 2 then DelNettweight * DelQty else PrcWeight * DelQty end)) WeightTot_ALLOC, ' || DTISel ||
        '   Sum(Case When PRCPACPAL = 0 then delQty else Round(delQty / PRCPACPAL, 2) end) RndPalsTot,' ||
        --'   Sum(Case When PRCPACPAL = 0 then DelQty else Ceil(Round(delQty / PRCPACPAL, 2)) end) ActPalsTot,' ||
        --'   SUM((Select Count(PallocRecNo) from Paltodel Where PallocDelrecno  = DelDet.DELRECNO)) PaltoDelCount,' ||
        --'   SUM(DelPrcQty) DelQtyTot, ExcChaRec, ExcRawAmm, ExcConAmm, EXCTOEUROEXCRATE,EXCTOBASERATE,EXCAPPTYPE, EXCCHAPERRATE, Max(DelPrice.DELINVSTATUS) as MAX_DELINVSTATUS, ' ||
        ' SUM(DelPrcQty) DelQtyTot,' ||
        ' EXCAPPTYPE, Max(DelPrice.DELINVSTATUS) as MAX_DELINVSTATUS,' ||
        '   NVL(Sum(DelNettValue), 0) DelNettValueTot,  ' ||
        '   Sum(RndApportPals) TotRndApportPals' ||
        ' From DelDet, DelPrice, PrdRec, Expcha' || DTITab ||
        ' Where Deldet.delprcprdno = PrdRec.prcprdno' ||
        ' AND DelPrice.DprDelrecNo = DelDet.DelrecNo' ||
        ' And Deldet.DelDlvOrdNo = ' || IN_DLVORDNO ||
        ' And Expcha.ExcDlvORdNo = ' || IN_DLVORDNO ||
        ' And Expcha.ExcChaRec = ' || IN_EXCRECNO ||
        ' And Not Exists (Select *' ||
        '				 	 From IteChg' ||
        '					 Where IteChg.ExcRecNo = ExpCha.ExcChaRec' ||
        '					 And IteChg.ICHSPETO IS NOT NULL' ||
        '					 And IteChg.DPRRECNO = Delprice.DprRecNo) ' ||
        DTILnk ||
        ' And Deldet.DelQty > 0 ' ||
        ' group by ExcCtyNo, ExcChaRec, ExcRawAmm, ExcConAmm, EXCTOEUROEXCRATE,EXCTOBASERATE,EXCAPPTYPE, EXCCHAPERRATE';
    
  /*	if Not (tc["DlvToExpTot"].DelQtyTot > 0) Then
			;CanCont = False
			;Need to remove this validation because... [log 8442]
			;if a delivery is fully returned, the total sums to zero.
			;if this flag is set, we bomb out here and this does not allow for the zeroing of the charges.
			;(the expcha is zeroed but the itechgs still retain their charge)
			;usually (always) if a delivery IS fully returned and sums to zero, the user will be in here to zero the charges in accordance with the delivery value.
			;the flip side of this is that, if we set this to zero and continue, ALL of the value will be applied to the last itechg.
			;This looks wrong, but Ash agrees it is right 'they can fix it and change it if they need to'.
		endIf*/
  
      BEGIN       
        --For a potentially 'better' way of handling dynamic SQL see FT_PK_COST_WRITES.INSERT_ITECHG BIND_VAR      
        OPEN RefCursorVar for SQLSTR;
        LOOP
          FETCH RefCursorVar into ExcCtyNo,
                                  FWeightTot_ALLOC,
                                  FWeightTot_DLVD,
                                  IRndPalsTot,
                                  IDelQtyTot,
                                  IEXCAPPTYPE,
                                  IMAX_DELINVSTATUS,
                                  FDelNettValueTot,                                                                                            
                                  FTotRndApportPals;
                    
            EXIT WHEN RefCursorVar%NOTFOUND;
             
             CASE IEXCAPPTYPE
               WHEN CONST.C_APP_BOX THEN TotToAppFacNu := IDelQtyTot;          --Box               
               WHEN CONST.C_APP_WGT THEN IF DlvIsDlvd = 0 THEN                 --Wgt 
                              TotToAppFacNu := FWeightTot_ALLOC;
                           ELSE   
                              TotToAppFacNu := FWeightTot_DLVD;
                           END IF;   
               WHEN 3 THEN TotToAppFacNu := IRndPalsTot;          --Multiplier         
               WHEN 4 THEN TotToAppFacNu := IRndPalsTot;          --Pallet
               WHEN 5 THEN TotToAppFacNu := 1;                    --Flat  - NOT VALID for AD HOC
               WHEN 6 THEN TotToAppFacNu := FDelNettValueTot;     --% of Sale
               WHEN 10 THEN TotToAppFacNu := FTotRndApportPals;   --Rounded Plts
             END CASE;                        
        END LOOP;
        CLOSE RefCursorVar;
        
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
             --RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES_COSTS - LOTITEAPPORTION_DELPRICE() - RefCursorVar No Data' ||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);    
             FT_PK_ERRORS.LOG_AND_STOP;
             V_CONT := 0;
        WHEN OTHERS THEN
             FT_PK_ERRORS.LOG_AND_STOP;
             --RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES_COSTS - LOTITEAPPORTION_DELPRICE() - RefCursorVar' ||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);    
             V_CONT := 0;
      END;       
       
      if IEXCAPPTYPE = CONST.C_APP_BOX THEN   
        Select                             
         Sum(Case when DelQtyPer = 1 Then delQty 
                  when DelQtyPer = 2 Then DelQty / Nvl(PrcWeight, 1)
                  when DelQtyPer = 3 Then DelQty / Nvl(PrcBoxQty, 1)
                  when DelQtyPer = 4 Then DelQty / Nvl(InnerQty, 1)	
       	     end) 
        INTO FloatDelQty                  
        from deldet, PrdRec
        Where deldet.deldlvordno = IN_DLVORDNO
        AND deldet.DelPrcPrdNo = PrdRec.PrcPrdNo
        AND deldet.DelRecNo in (Select DprDelRecNo from DelPrice Where DprRecNo in (select DprRecNo From Expcha, IteChg 
                                                                                   Where Expcha.ExcChaRec = IN_EXCRECNO
                                                                                   AND Expcha.ExcChaRec = IteChg.ExcRecNo))  --only charges where dpr exist
        Order by delRecNo;
      END IF;                                                                                                        
    
     EXCEPTION
       WHEN OTHERS THEN
         --RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES_COSTS - LOTITEAPPORTION_DELPRICE() - DlvToExpTot' ||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);                         
         FT_PK_ERRORS.LOG_AND_STOP;
    END;  
  END IF;
         
--***** (2) Find existing IteChgs and update or insert******************************         
         
  IF V_CONT = 1 THEN
    BEGIN
    
      -- S = Sales, I = Purchases (of course) ;= recalc the sales Itechgs.   tc["IchOldAppAmt"]
	    --Get ALL unfixed itechgs to apportion.                                          
    FOR IchOldAppAmt_REC IN TC_IchOldAppAmt(IN_EXCRECNO) LOOP                   
       ORIGITECHG(IchOldAppAmt_REC.IchRecNo) := IchOldAppAmt_REC.IchAppAmt;
       
       --For example of dynarray equivalent, see...
       --FT_PK_COSTING.AUTO_PO_COSTS() =>   TYPE CONTAINER_AMTS IS TABLE OF FLOAT INDEX BY PLS_INTEGER;
       
       --ZEROING: Cannot do this here as it zeroes it every other go
       --FT_PK_COST_WRITES.UPDATE_ICHAPPAMT(IchOldAppAmt_REC.IchRecNo, 0.00);       
    END LOOP;
    
    --;Reset the IteChgs that are NOT fixed.  
    -- could use FT_PK_COST_WRITES.UPDATE_ICHAPPAMT(ICHRECNO_IN ITECHG.ICHRECNO%TYPE, ICHAPPAMT_IN ITECHG.ICHAPPAMT%TYPE) 
   IF V_CONT = 1 THEN 
     UPDATE IteChg 	SET ICHAPPAMT = 0.00  --now done above
     Where IteChg.ExcRecNo = IN_EXCRECNO
     AND IteChg.ICHSPETO IS NULL;
   END IF;  
      
   NumDlvToExp_RECs := 0; 
   FOR DlvToExp_REC IN TC_DlvToExp(IN_DLVORDNO, IN_EXCRECNO) LOOP
     --want to do this...   --TCDlvToExpCount := TC_DlvToExp.Count;  
     --This is not counting the number of Itechgs, but the number needed.
       NumDlvToExp_RECs := NumDlvToExp_RECs + 1;
       
       ExcConAmmNuLeft         := DlvToExp_REC.TotToApp; --extracted at detail level because
       NuTotalValueToApportion := DlvToExp_REC.TotToApp; --some may be authorised.
    END LOOP; 
            
    IF V_CONT = 1 THEN
       IF NumDlvToExp_RECs = 0 Then
          BEGIN
             V_CONT := 0;
             --FT_PK_ERRORS.LOG_AND_STOP; --execption block only
          END;   
       END IF;
    END IF;
    
    --*** Itechg Loop ***
    IF V_CONT = 1 THEN
      DlvToExpLoopCnt := 0;
      FOR DlvToExp_REC IN TC_DlvToExp(IN_DLVORDNO, IN_EXCRECNO) LOOP
        DlvToExpLoopCnt := DlvToExpLoopCnt + 1;
           
        --For each loop through the delprices we either....
        --1) have an itechg that needs re-calculating.
        --2) have an itechg that is fixed (no recalc)
        --3) dont have an itechg for.
           
        InsertIt := True;
        
        LIgnoreCrDr := (DlvToExp_REC.ChgIgnoreCrDr = 1); 
        
        if Not LIgnoreCrDr Then
				   if DlvToExp_REC.DisStkQty < 1 AND DlvToExp_REC.EXCAPPTYPE = 1 Then  --;if box 
					    LIgnoreCrDr := True; --;Same as costing module
				   end If;
			  end If;

			  LIgnoreCrDr := False; --;FRIG SR 25/11/13 10752   The ignore cred it debit needs a rethink 
           
        CASE DlvToExp_REC.EXCAPPTYPE
          WHEN CONST.C_APP_BOX THEN 
            PerLnToAppFacNu := DlvToExp_REC.DisStkQty;          --Box               
                  
            if DlvToExp_REC.DelQtyPer > 1 Then
              CASE DlvToExp_REC.DelQtyPer
                WHEN 2 THEN NuDivisor := DlvToExp_REC.PrcWeight;
                WHEN 3 THEN NuDivisor := DlvToExp_REC.PrcBoxQty;
                WHEN 4 THEN NuDivisor := DlvToExp_REC.InnerQty;
              END CASE;                                                                                  
              if NuDivisor > 0 Then
                NuFloatBoxQty := DlvToExp_REC.DisStkQty / NuDivisor;
              else
                NuFloatBoxQty := DlvToExp_REC.DisStkQty;
              end If;
              PerLnToAppFacNu := NuFloatBoxQty;
            end If;
             
          WHEN CONST.C_APP_WGT THEN
              If DlvIsDlvd = 0 Then
						    PerLnToAppFacNu := DlvToExp_REC.Weight_ALLOC;
						  else
                PerLnToAppFacNu := DlvToExp_REC.Weight_DLVD;              
						  end If;
              
          --WHEN 3 THEN PerLnToAppFacNu := DlvToExp_REC.DisStkQty;    --'unused'
          WHEN CONST.C_APP_PAL THEN PerLnToAppFacNu := DlvToExp_REC.RndPals; 
          WHEN 5 THEN PerLnToAppFacNu := 1;                         --;Flat (not used)
          WHEN CONST.C_APP_PERCSALE THEN PerLnToAppFacNu := DlvToExp_REC.delNettValue; --% of Sale
          --WHEN 7 THEN  --Unhandled
          --WHEN 8 THEN  --at
          --WHEN 9 THEN  --Present
          WHEN CONST.C_APP_RNDPAL THEN PerLnToAppFacNu := DlvToExp_REC.RndApportPals;                             
        END CASE;  
        
        --Get the Itechg
        FoundIte := False;
        V_IchRecNo := NULL;
        If DlvToExp_REC.DisIstRecNo > 0 Then  
          BEGIN
            Select IchRecNo, IchSpeTo, IchAppAmt 
            INTO  V_IchRecNo, V_IchSpeTo, V_IchAppAmt 
            FROM ITECHG
            WHERE ExcRecNo  = IN_EXCRECNO
            AND DPRRECNO    = DlvToExp_REC.DprRecNo
            AND ICHISTRECNO = DlvToExp_REC.DisIstRecNo;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_IchRecNo  := NULL;
              V_IchSpeTo  := NULL;
              V_IchAppAmt := NULL;        
            WHEN OTHERS THEN
              FT_PK_ERRORS.LOG_AND_STOP;
          END;

          if V_IchRecNo > 0 Then
             FoundIte := True;
          end if;   
        end if;   
         
        If Not FoundIte THEN
          BEGIN
            SELECT IchRecNo, IchSpeTo, IchAppAmt 
            INTO  V_IchRecNo, V_IchSpeTo, V_IchAppAmt
            FROM ITECHG
            WHERE ExcRecNo = IN_EXCRECNO
            AND DPRRECNO = DlvToExp_REC.DprRecNo
            AND ICHISTRECNO IS NULL;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              V_IchRecNo  := NULL;
              V_IchSpeTo  := NULL;
              V_IchAppAmt := NULL;        
            WHEN OTHERS THEN
              FT_PK_ERRORS.LOG_AND_STOP;
          END;
          
          if V_IchRecNo > 0 Then
            FoundIte := True;
          end if;             
        end if;
    				        
        LAlterLive := False;
        if V_CONT = 1 Then
          if NOT LIgnoreCrDr Then
             if FoundIte = False Then
               LAlterLive := True; --add a new one
             else
               --if V_IchSpeTo = NULL Then  --<< does not work - it is null
               if V_IchSpeTo IS NULL Then
                  LAlterLive := True;
               else
                  LAlterLive := False; --never update fixed
               end If;
             end if;
          end if;
        end if;  
             
        if V_CONT = 1 AND NOT LIgnoreCrDr Then
        
          InsertIt := Not FoundIte;
        
          if FoundIte = True Then
           
            if V_IchSpeTo IS NULL Then
						  if TotToAppFacNu > 0.009 then
							  TotToAppPerIte := PerLnToAppFacNu * DlvToExp_REC.TotToApp;  -- TotToAppFacNu  TotToApp
							  TotToAppPerIte := TotToAppPerIte / TotToAppFacNu;
							  --TotToAppPerIte := TotToAppPerIte.round(2);
                TotToAppPerIte := round(TotToAppPerIte, 2);
						  end if;
						  ExcConAmmNuLeft := ExcConAmmNuLeft - TotToAppPerIte;
            end if;
             
            NxtIteNo := V_IchRecNo;
          end if;
           
           --else...
          if FoundIte = False Then                          
             --NxtIteNo = UtilsLib.GetWizNxtRecNo(FormName, "ContIchNo", 1)
             --NxtIteNo := SP_WIZGETCONTROL('ContIchNo', 1, 'INSERT_ITECHG');
             --Dont do this as rec acquired in FT_PK_COST_WRITES.INSERT_ITECHG;
             
             if TotToAppFacNu > 0.009 then --??will this handle/do we need to handle negatives?
							 TotToAppPerIte :=  PerLnToAppFacNu * DlvToExp_REC.TotToApp;
							 TotToAppPerIte := TotToAppPerIte / TotToAppFacNu;							 
               TotToAppPerIte := round(TotToAppPerIte, 2);
						 else
							 TotToAppPerIte := 0.00;
						 end if;
						 ExcConAmmNuLeft := ExcConAmmNuLeft - TotToAppPerIte;	
          end if;
          
          if V_CONT = 1 Then --;if were on the last record, whack it all on.				
					  if DlvToExpLoopCnt = NumDlvToExp_RECs Then
						  if Abs(ExcConAmmNuLeft) > 0.009 then
							   TotToAppPerIte := TotToAppPerIte + ExcConAmmNuLeft;
						  end if;
					  end if;
				  end if;          
          
          ITECHG_TO_WRITE.EXCRECNO       := IN_EXCRECNO;                    
          ITECHG_TO_WRITE.IchAppAmt      := TotToAppPerIte;
          ITECHG_TO_WRITE.ICHAPPFAC      := DlvToExp_REC.EXCAPPTYPE;
          ITECHG_TO_WRITE.ICHCHACALC     := DlvToExp_REC.EXCCHGCALC;          
          ITECHG_TO_WRITE.ICHCHNGDBYUSER := 1;
          ITECHG_TO_WRITE.IchIstRecNo    := DlvToExp_REC.disIstRecNo;
          
          if InsertIt then
            ITECHG_TO_WRITE.DprRecNo     := DlvToExp_REC.DprRecNo;
            ITECHG_TO_WRITE.CTYNO        := ExcCtyNo;
          else
            ITECHG_TO_WRITE.IchRecNo     := V_IchRecNo;
          end if;
          
          if InsertIt then                    
            FT_PK_COST_WRITES.INSERT_ITECHG(ITECHG_TO_WRITE);
          else   
            FT_PK_COST_WRITES.UPDATE_ITECHG(ITECHG_TO_WRITE);            
					end if;
                            
        end if;
                              
      END LOOP;
    END IF;      
    
    --Temporary frig until INSERT_ITECHG changed to not hardcode false to ICHCHNGDBYUSER
       /*   Begin
             Update IteChg
             Set ICHCHNGDBYUSER = 1
             Where excRecNo = IN_EXCRECNO; --in(select ExcChaRec from ExpCha Where excDlvOrdNo = 279650 AND CtyNo = )
          EXCEPTION            
            WHEN OTHERS THEN
              FT_PK_ERRORS.LOG_AND_STOP;
          end;*/                                                                      
  END;       
                  
END IF;      
   
BEGIN    --DO THE DELAUDITS...
  IF V_CONT = 1 THEN
    DelAudCnt := 0;
    FOR DelAudToWrite_REC IN TC_DelAudResultSet(IN_DLVORDNO, IN_EXCRECNO) LOOP
      DelAudCnt := DelAudCnt + 1;
    END LOOP; 
    
    IF DelAudCnt = 0 THEN
       V_CONT := 0;
    else   
       NumDelAudsToWrite := DelAudCnt;
    END IF;   
    
    IF V_CONT = 1 THEN      
      DelAudGroupNo   := SP_WIZGETCONTROL('DaudLstGrpNo', 1, 'PROC_LOTAPPORT_DPR');      
      NextDelAudRecNo := SP_WIZGETCONTROL('DaudLstRefNo', NumDelAudsToWrite, 'PROC_LOTAPPORT_DPR');      
      LiLogonNo       := FT_PK_SESSION_UTILS.GET_FT_LOGONNO; --Will only work called from Paradox with latest utility library.
    END IF;   
    
    FOR DelAudToWrite_REC IN TC_DelAudResultSet(IN_DLVORDNO, IN_EXCRECNO) LOOP
      DelAudCnt := DelAudCnt + 1;
            
      StrFrom := '';
      if ORIGITECHG.EXISTS(DelAudToWrite_REC.IchRecNo) THEN
         OldIchAppAmt := ORIGITECHG(DelAudToWrite_REC.IchRecNo);
         StrFrom := '(' || DelAudToWrite_REC.CtyNo || ') ' || OldIchAppAmt;
      END IF;
      
      StrTo   := DelAudToWrite_REC.IchAppAmt;
      
      /*1*/  DELAUDIT_TO_WRITE.DELAUDRECNO    := NextDelAudRecNo;  
      /*2*/  DELAUDIT_TO_WRITE.DELAUDDELRECNO := DelAudToWrite_REC.DelRecNo;
      /*3*/  DELAUDIT_TO_WRITE.DELAUDTYP      := 106; --Sales Charge Changed Type
      /*4*/  DELAUDIT_TO_WRITE.DELAUDGRPNO    := DelAudGroupNo;
      /*5*/  DELAUDIT_TO_WRITE.DELAUDDATE     := sysdate;
      /*6*/  DELAUDIT_TO_WRITE.DELAUDTIME     := to_char(sysdate, 'hh24:mi:ss');
      /*7*/  DELAUDIT_TO_WRITE.DELAUDFROM     := StrFrom;
      /*8*/  DELAUDIT_TO_WRITE.DELAUDTO       := StrTo;
      /*9*/  DELAUDIT_TO_WRITE.LOGONNO        := LiLogonNo;
      /*10*/ DELAUDIT_TO_WRITE.DPRRECNO       := DelAudToWrite_REC.DPRRECNO;
      /*11*/ DELAUDIT_TO_WRITE.FORMNO         := 1709;
      /*12*/ DELAUDIT_TO_WRITE.DPRTOACTION    := 1;
      /*13*/ DELAUDIT_TO_WRITE.FORMNAME       := 'SP_LOTAPPORT_DPR';
      
      NextDelAudRecNo := NextDelAudRecNo + 1;
      
      INSERT INTO DELAUDIT VALUES DELAUDIT_TO_WRITE;
  
    END LOOP;
  END IF;            
EXCEPTION
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
END;  
         
EXCEPTION            
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;     
       
END LOTITEAPPORTION_DELPRICE;

--*******************************************

PROCEDURE DoAutCostAdHocChgs_Int(IN_DLVORDNO IN NUMBER, IN_EXCRECNO IN NUMBER) AS
--internal proc called by DoAutCostAdHocChgs() and DoAutCostAdHocChgs [for single delivery, and all AC deliveries]
Begin
  --NULL;
  LOTITEAPPORTION_DELPRICE(IN_DLVORDNO, IN_EXCRECNO);
END DoAutCostAdHocChgs_Int;


PROCEDURE GetTotalDeliveryUnits(VExcAppType EXPCHA.ExcAppType%Type, IN_DLVORDNO DELHED.DLVORDNO%Type, TotDelQtyOrWgt IN OUT Float) as
   TypeReqd Varchar(7);
BEGIN  

  Case VExcAppType
  When 10 Then TypeReqd := 'RNDPALS';
  When  2 Then TypeReqd := 'WEIGHT';
  else         TypeReqd := 'BOX';              
  End Case;
  
  if TypeReqd = 'BOX' Then   
    Select Sum(DelQty) Into TotDelQtyOrWgt From Deldet WHERE DelDlvOrdNo = IN_DLVORDNO;
  end if;  
  
  if TypeReqd = 'RNDPALS' Then         
    --Select Ceil(HedSysCalcPals) NumPals, UserInpPals, (Case when Nvl(UserInpPals, 0) = 0 Then Ceil(HedSysCalcPals) else UserInpPals end) PalsForDlv "
    Select (Case when Nvl(UserInpPals, 0) = 0 Then Ceil(HedSysCalcPals) else UserInpPals end) 
    Into TotDelQtyOrWgt --PalsForDlv 
    From DelHed WHERE DlvOrdNo = IN_DLVORDNO;		
  end if;

  if TypeReqd = 'WEIGHT' Then   
    Select Sum(DelNettWeight) Into TotDelQtyOrWgt from Deldet WHERE DelDlvOrdNo = IN_DLVORDNO; --TotDelWgt
  end if;  
      
end GetTotalDeliveryUnits;

PROCEDURE DoAutCostAdHocChgs(IN_DLVORDNO INTEGER, IN_EXCRECNO IN NUMBER) AS
--Replaces CostingLib.DoAutCostAdhocChgs()
  PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
  LAnyAdHocToDo Boolean;
  
  VExcCtyNo             EXPCHA.ExcCtyNo%Type; 
  VExcCurrNo            EXPCHA.ExcCurrNo%Type;
  VExcChaPerRate        EXPCHA.ExcChaPerRate%Type;
  VEXCTOEUROEXCRATE     EXPCHA.EXCTOEUROEXCRATE%Type;
  VEXCTOBASERATE        EXPCHA.EXCTOBASERATE%Type;
  VEXCRAWAMM            EXPCHA.EXCRAWAMM%Type;
  VExcAppType           EXPCHA.ExcAppType%Type;
  VExcSalOff            EXPCHA.ExcSalOff%Type;
  VCtyDesc              ChgTyp.CtyDesc%Type;
  VNumIchChngdByUser   NUMBER;
  
  TotDelQtyOrWgt       Float;
  NewRawAmmNu          Float;
  UpdExpChaRec         EXPCHA%ROWTYPE;
  NuTmp Float; 
Begin
  NULL;  
  IF IN_DLVORDNO IS NULL THEN
    PARAMETER_LIST('#PARAMNAME') := 'IN_DLVORDNO';
    PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(IN_DLVORDNO);
    FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
  END IF;
  
  --SELECT EXCCHAREC, ExcCtyNo, ExcCurrNo, ExcChaPerRate, EXCTOEUROEXCRATE,EXCTOBASERATE ,EXCRAWAMM, ExcAppType, ExcSalOff, ChgTyp.CtyDesc
  SELECT ExcCtyNo, ExcCurrNo, ExcChaPerRate, EXCTOEUROEXCRATE,EXCTOBASERATE, EXCRAWAMM, ExcAppType, ExcSalOff, ChgTyp.CtyDesc,
         (select Count(itechg.IchChngdByUser) From Itechg Where ExpCha.ExcChaRec = IteChg.ExcRecNo AND IchChngdByUser = 1) NumIchChngdByUser
  Into VExcCtyNo, VExcCurrNo, VExcChaPerRate, VEXCTOEUROEXCRATE, VEXCTOBASERATE, VEXCRAWAMM, VExcAppType, VExcSalOff, VCtyDesc, VNumIchChngdByUser
  FROM EXPCHA, ChgTyp
  WHERE EXCDLVORDNO = IN_DLVORDNO
  AND EXCCHAREC     = IN_EXCRECNO
  AND EXPCHA.ExcCtyNo = ChgTyp.CtyNo
  Order By ExcCtyNo;
  
  LAnyAdHocToDo := (VNumIchChngdByUser > 0);
  
  if LAnyAdHocToDo Then
    FOR DLVEXPREC IN 
    (
      Select Distinct ExcChaRec, ExcDlvOrdNo
      from ExpCha 
      Where ExpCha.ExcDlvOrdNo = IN_DLVORDNO
      AND ExpCha.excChaRec     = IN_EXCRECNO
      AND (select Count(itechg.IchChngdByUser)   --AdHoc charges are user changed.
           From Itechg 
           Where ExpCha.ExcChaRec = IteChg.ExcRecNo
           AND IchChngdByUser = 1
          ) > 0
    )
    LOOP    
    
       --if Box rate specified, recalculate the ExpCha (cannot apportion across itechgs until the total charge is correct for the updated number of boxes.)
       begin
         if VExcChaPerRate > 0.009 Then
           TotDelQtyOrWgt := 0;
           GetTotalDeliveryUnits(VExcAppType, IN_DLVORDNO, TotDelQtyOrWgt);                    
           NewRawAmmNu := round( (TotDelQtyOrWgt * VExcChaPerRate), 2);                    
           
           if Abs(NewRawAmmNu - VEXCRAWAMM ) > 0.009 Then
             UpdExpChaRec.ExcChaRec             := IN_EXCRECNO;
             UpdExpChaRec.ExcCtyNo              := vExcCtyNo;     --?
             UpdExpChaRec.ExcCurrNo             := vExcCurrNo;    --?
             UpdExpChaRec.ExcChaPerRate         := VExcChaPerRate; --?
             UpdExpChaRec.EXCRAWAMM             := NewRawAmmNu;  
             NuTmp := NewRawAmmNu * VEXCTOEUROEXCRATE;
             UpdExpChaRec.EXCEUROAMM            := NuTmp;
             NuTmp := NewRawAmmNu * VEXCTOBASERATE; 
             UpdExpChaRec.EXCCONAMM             := NuTmp;          
             
             FT_PK_COST_WRITES.UPDATE_EXPCHA(UpdExpChaRec);
           end if;                                          
         end if;
      
         LOTITEAPPORTION_DELPRICE(IN_DLVORDNO, IN_EXCRECNO);
         --DoAutCostAdHocChgs_Int(DLVEXPREC.ExcChaRec, DLVEXPREC.ExcDlvOrdNo);
       Exception 
         WHEN OTHERS THEN
           FT_PK_ERRORS.LOG_AND_STOP;
       end;
    END LOOP;
  END IF;  
  
END DoAutCostAdHocChgs;

PROCEDURE DoAutCostAdHocChgs AS
--will be called from AutoCostLib.processCostChanges() until AC is fully housed in procs.
--if called from AutoCostLib.processCostChanges() then AUTOCOSTS_PROCESS will be populated
-- Note: calling Exec DoAutCostAdHocChgs will not work as AUTOCOSTS_PROCESS will not be populated.
-- (to run for a specific dlv and charge use DoAutCostAdHocChgs() )
Begin

  --loop all pending ad hoc autocosts
  FOR AUTOCOSTSREC IN 
  (
    Select Distinct ExcChaRec, ExcDlvOrdNo
    from FT_V_DLV, AUTOCOSTS_PROCESS, EXPCHA 
    Where FT_V_DLV.DprRecNo = AUTOCOSTS_PROCESS.DprRecNo
    AND AUTOCOSTS_PROCESS.DoAutCostAdHocChgs = CONST.C_TRUE
    AND ExpCha.ExcDlvOrdNo = FT_V_DLV.DlvOrdNo 
    --AND ExpCha.ExcDlvOrdNo = IN_DLVORDNO  --<< do for all adhoc chgs as determined by AutoCostLib.processCostChanges() / AUTOCOSTS_PROCESS
    AND (select Count(itechg.IchChngdByUser)   --AdHoc charges are user changed. Do not change automatic charges.
         From Itechg 
         Where ExpCha.ExcChaRec = IteChg.ExcRecNo
         AND IchChngdByUser = CONST.C_TRUE
        ) > 0
  )
  LOOP  
    DoAutCostAdHocChgs(AUTOCOSTSREC.ExcChaRec, AUTOCOSTSREC.ExcDlvOrdNo);     
  END LOOP;
  
EXCEPTION
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;  
  
END DoAutCostAdHocChgs;

END FT_PK_SALES_COSTS;
/
