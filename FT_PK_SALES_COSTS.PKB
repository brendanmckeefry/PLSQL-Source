create or replace PACKAGE BODY FT_PK_SALES_COSTS AS

  cVersionControlNo   VARCHAR2(12) := '1.0.5'; -- Current Version Number

  CURSOR TC_IchOldAppAmt(IN_EXCRECNO INTEGER) IS
      Select Ichrecno, Ichappamt From Itechg, Chgtyp
      Where Itechg.Ctyno = Chgtyp.Ctyno
      And Itechg.Excrecno =  IN_EXCRECNO
      And (Itechg.Ichspeto Is Null Or Ichistrecno Is Null);

  CURSOR TC_DlvToExp(IN_DLVORDNO INTEGER, IN_EXCRECNO INTEGER) IS
		Select * from (Select Delrecno, Delprice.Dprrecno, Delqtyper, Prcweight, Prcboxqty, Innerqty,
       (Case When Delpriceper = 2 Then Delnettweight * Delprcqty Else Prcweight * Delprcqty End) Weight_Alloc,   
       (Case When Delpriceper = 2 Then Delnettweight * Disqty Else Prcweight * Disqty End) Weight_Dlvd,   
       Case When PRCPACPAL = 0 then DisQty else Round(nvl(DisQty, Delprice.Delprcqty) / PRCPACPAL, 2) end Rndpals,   
       Case When Prcpacpal = 0 Then nvl(DisQty, Delprice.Delprcqty) Else Ceil(Round( nvl(DisQty, Delprice.Delprcqty) / Prcpacpal, 2)) End Actpals,   
       (Select Count(Pallocrecno) From Paltodel Where Pallocdelrecno  = Deldet.Delrecno) Paltodelcount,   
	   Nvl(Case when Deltoist.DisQty is null 
	   			then Deldet.Rndapportpals 
				else (Case When Nvl(Deltoist.DisQty,0) = 0 
					 	   then 0 
						   else Nvl(RndApportPals,0) / (DisQty * (1.00)) 
						   end) 
		 end  
	   ,Case When Prcpacpal = 0 Then nvl(DisQty, Delprice.Delprcqty) Else Round(nvl(DisQty, Delprice.Delprcqty) / Prcpacpal, 2) End) Rndapportpals,  
        NVL(DELTOIST.DISQTY, DELPRICE.DELPRCQTY) AS DISSTKQTY,	   
       Delqty, Delprice.Delprcqty, nvl(Deltoist.DisNettValue,Delprice.Delnettvalue) Delnettvalue, Exccharec, Excrawamm, Excconamm, Exctoeuroexcrate,exctobaserate,excapptype, Excctyno, Excchgcalc, Exccurrno,
	   Case When NVL(Exccurrno,1) = 1
	   		then
		       Nvl(Excconamm,0) - Nvl((Select Sum(Nvl(Ichappamt,0))
					                    from Itechg
					                    where (Itechg.Ichspeto Is Not Null Or Ichistrecno Is Null)
					                    and Expcha.Exccharec = Itechg.Excrecno),0)
			else
			   Nvl(Excrawamm,0) - Nvl((Select Sum(Nvl(Ichrawappamt,0))
					                    from Itechg
					                    where (Itechg.Ichspeto Is Not Null Or Ichistrecno Is Null)
					                    AND EXPCHA.EXCCHAREC = ITECHG.EXCRECNO),0)
			END TOTTOAPP,
          CHGTYP.CTYDESC, NVL(CHGTYP.CHGIGNORECRDR, 0) CHGIGNORECRDR,

     Nvl(Deltoist.Disistrecno, (Select MAX(Pallocistrecno) From Palnoloc, Deltoall Where Deltoall.Dalallocno = Palnoloc.Pallocallno And Dalrecordtype = 1 And Daltyperecno = Deldet.Delrecno)) SubDisistrecno
    from Deldet, Delprice, Prdrec, Expcha, Chgtyp, Deltoist
    where Deldet.Delprcprdno = Prdrec.Prcprdno
    and Delprice.Dprdelrecno = Deldet.Delrecno
    and Deldet.Deldlvordno =  IN_DLVORDNO
    and Expcha.Excdlvordno = Deldet.Deldlvordno
    and Expcha.Exccharec =  IN_EXCRECNO
	And DelPrice.DelPrcQty <> 0
    and Delprice.Dprrecno = Deltoist.Disdprrecno(+)
    and Expcha.Excctyno = Chgtyp.Ctyno) Temp
    Where Not Exists (Select *
               From Itechg
               Where Itechg.Excrecno = Temp.Exccharec
               And Itechg.Ichspeto Is Not Null
               And Itechg.Ichistrecno  = Temp.SubDisistrecno
               And Itechg.Dprrecno = Temp.Dprrecno)
     Order By Delrecno, Dprrecno;

CURSOR TC_DELAUDRESULTSET(IN_DLVORDNO INTEGER, IN_EXCRECNO INTEGER) IS
  Select Itechg.Ichrecno, Excrecno, Itechg.Dprrecno, Ctyno, Ichappamt, Delprice.Dprdelrecno Delrecno
  From Itechg, Expcha, Delprice
  Where Expcha.Excdlvordno = IN_DLVORDNO
  And Expcha.Exccharec =  IN_EXCRECNO
  And Itechg.Excrecno = Expcha.Exccharec
  And Itechg.Dprrecno = Delprice.Dprrecno
  And (Itechg.Ichspeto Is Null Or Itechg.Ichistrecno Is Null);

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

  DTISel VARCHAR(4000);
  DTITab VARCHAR(200);
  DTILNK VARCHAR(200);
  DTISubLink VARCHAR(200);

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
      DTISEL := '  SUM(Case When DelPricePer = 2 then DelNettweight * DisQty else PrcWeight * DisQty end) WeightTot_DLVD, SUM(DisQty) DelQtyTot, '||
                '   Sum(Case When PRCPACPAL = 0 then DisQty else Round(DisQty / PRCPACPAL, 2) end) RndPalsTot,' ||
                '   NVL(Sum(Disnettvalue), 0) DelNettValueTot,  ' ||
                ' NVL(Sum(Case When Nvl(DisQty,0) = 0 then 0 else Nvl(RndApportPals,0) / (DisQty * (1.00))  end), Sum(Case When PRCPACPAL = 0 then DisQty else Round(DisQty / PRCPACPAL, 2) end)) TotRndApportPals, ';
                
      DTITab := ', DelToIst';
      DTILNK := ' And DelPrice.DprRecNo = deltoist.DisDprRecNo(+)';
      DTISubLink := ' And Itechg.Ichistrecno = DelToIst.DisIstRecNo';
    ELSE
      DTISEL := ' NULL as WeightTot_DLVD, SUM(DelPrcQty) DelQtyTot, ' ||
                ' Sum(Case When PRCPACPAL = 0 then Delprcqty else Round(Delprcqty / PRCPACPAL, 2) end) RndPalsTot,' ||
                ' NVL(Sum(DelNettValue), 0) DelNettValueTot,  ' ||
                ' NVL(Sum(RndApportPals), Sum(Case When PRCPACPAL = 0 then Delprcqty else Round(Delprcqty / PRCPACPAL, 2) end)) TotRndApportPals, ' ;
      DTITab := '';
      DTILNK := '';
      DTISubLink := '';
    END IF;
  END IF;

--***** (1) Determine the Apportionment ******************************

  IF V_CONT = 1 THEN
    BEGIN
	    SQLSTR := 'Select ExcCtyNo, SUM((Case When DelPricePer = 2 then DelNettweight * DelQty else PrcWeight * DelQty end)) WeightTot_ALLOC, ' || DTISEL ||
        ' EXCAPPTYPE, Max(DelPrice.DELINVSTATUS) as MAX_DELINVSTATUS' ||
        ' From DelDet, DelPrice, PrdRec, Expcha' || DTITab ||
        ' Where Deldet.delprcprdno = PrdRec.prcprdno' ||
        ' AND DelPrice.DprDelrecNo = DelDet.DelrecNo' ||
        ' And Deldet.DelDlvOrdNo = ' || IN_DLVORDNO ||
        ' And Expcha.ExcDlvORdNo = ' || IN_DLVORDNO ||
        ' And Expcha.ExcChaRec = ' || IN_EXCRECNO ||
        ' And Not Exists (Select *' ||
        '				 	        From IteChg' ||
        '					        Where IteChg.ExcRecNo = ExpCha.ExcChaRec' ||
        '					        And IteChg.ICHSPETO IS NOT NULL' ||
        '                 And Itechg.Ichistrecno Is Not Null' ||
        DTISubLink ||
        '					        And IteChg.DPRRECNO = Delprice.DprRecNo) ' ||
        DTILnk ||
        ' And Deldet.DelQty > 0 ' ||
        ' group by ExcCtyNo, ExcChaRec, ExcRawAmm, ExcConAmm, EXCTOEUROEXCRATE,EXCTOBASERATE,EXCAPPTYPE, EXCCHAPERRATE';

      BEGIN
        --For a potentially 'better' way of handling dynamic SQL see FT_PK_COST_WRITES.INSERT_ITECHG BIND_VAR
        OPEN RefCursorVar for SQLSTR;
        LOOP
          FETCH RefCursorVar into ExcCtyNo,
                                  FWeightTot_ALLOC,
                                  FWeightTot_DLVD,
                                  IDelQtyTot,
                                  IRndPalsTot,
                                  FDELNETTVALUETOT,
                                  FTOTRNDAPPORTPALS,
                                  IEXCAPPTYPE,
                                  IMAX_DELINVSTATUS;

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
      
      IF V_CONT = 1 THEN
        IF EXCCTYNO IS NULL THEN  -- NO EXPCHA FOUND
          V_CONT := 0;
        END IF;
      END IF;

      if V_CONT = 1 Then
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
          AND DELDET.DELPRCPRDNO = PRDREC.PRCPRDNO
          AND DELDET.DELRECNO IN (SELECT DELPRICE.DPRDELRECNO
                                  from DelPrice, Expcha,IteChg
                                  Where Expcha.ExcChaRec = IN_EXCRECNO
                                  AND EXPCHA.EXCCHAREC = ITECHG.EXCRECNO
                                  And Itechg.Dprrecno = Delprice.Dprrecno)  --only charges where dpr exist
          Order by delRecNo;
        END IF;
      End If;

    EXCEPTION
       WHEN OTHERS THEN
         --RAISE_APPLICATION_ERROR(-20002, 'ORACLE PACKAGE -FT_PK_SALES_COSTS - LOTITEAPPORTION_DELPRICE() - DlvToExpTot' ||CHR(13) || CHR(10) || SQLCODE || CHR(13) || CHR(10) || SQLERRM);
         FT_PK_ERRORS.LOG_AND_STOP;
         V_CONT := 0;
    END;
  END IF;

--***** (2) Find existing IteChgs and update or insert******************************

  IF V_CONT = 1 THEN
    BEGIN
      -- S = Sales, I = Purchases (of course) ;= recalc the sales Itechgs.   tc["IchOldAppAmt"]
	    --Get ALL unfixed itechgs to apportion.
    FOR IchOldAppAmt_REC IN TC_IchOldAppAmt(IN_EXCRECNO) LOOP
       ORIGITECHG(ICHOLDAPPAMT_REC.ICHRECNO) := ICHOLDAPPAMT_REC.ICHAPPAMT;
    END LOOP;

    --;Reset the IteChgs that are NOT fixed.
   IF V_CONT = 1 THEN
     UPDATE IteChg 	SET ICHAPPAMT = 0.00 , ICHRAWAPPAMT = 0.00 --now done above
     WHERE ITECHG.EXCRECNO = IN_EXCRECNO
     And (Itechg.Ichspeto Is Null Or Ichistrecno Is Null);
   END IF;

   NUMDLVTOEXP_RECS := 0;
   IF V_CONT = 1 THEN
     FOR DlvToExp_REC IN TC_DlvToExp(IN_DLVORDNO, IN_EXCRECNO) LOOP
       --want to do this...   --TCDlvToExpCount := TC_DlvToExp.Count;
       --This is not counting the number of Itechgs, but the number needed.
         NumDlvToExp_RECs := NumDlvToExp_RECs + 1;

         ExcConAmmNuLeft         := DlvToExp_REC.TotToApp; --extracted at detail level because
         NuTotalValueToApportion := DlvToExp_REC.TotToApp; --some may be authorised.
      END LOOP;
    End if;

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
        If DlvToExp_REC.SubDisistrecno > 0 Then
          BEGIN
            Select IchRecNo, IchSpeTo, IchAppAmt
            INTO  V_IchRecNo, V_IchSpeTo, V_IchAppAmt
            FROM ITECHG
            WHERE ExcRecNo  = IN_EXCRECNO
            AND DPRRECNO    = DlvToExp_REC.DprRecNo
            AND ICHISTRECNO = DlvToExp_REC.SubDisistrecno
            AND ROWNUM = 1;
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
            SELECT IchRecNo, NULL IchSpeTo, IchAppAmt
            INTO  V_IchRecNo, V_IchSpeTo, V_IchAppAmt
            FROM ITECHG
            WHERE ExcRecNo = IN_EXCRECNO
            AND DPRRECNO = DlvToExp_REC.DprRecNo
            AND ICHISTRECNO IS NULL
            AND ROWNUM = 1;
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

        IF V_CONT = 1 AND NOT LIGNORECRDR THEN
          ITECHG_TO_WRITE := NULL;

          InsertIt := Not FoundIte;

          if FoundIte = True Then

            IF V_ICHSPETO IS NULL THEN
			  if Abs(TotToAppFacNu) > 0.009 then
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

             if Abs(TotToAppFacNu) > 0.009 then --??will this handle/do we need to handle negatives?
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

		  if V_CONT = 1 Then
          ITECHG_TO_WRITE.EXCRECNO       := IN_EXCRECNO;
          ITECHG_TO_WRITE.Ichrawappamt   := TotToAppPerIte;

          if DlvToExp_REC.ExcCurrNo <> 1
          then
             ITECHG_TO_WRITE.IchAppAmt  := Round(TotToAppPerIte * Nvl(DlvToExp_REC.EXCTOBASERATE, 1.00), 2);
          else
             ITECHG_TO_WRITE.ICHAPPAMT   := TOTTOAPPPERITE;
          end if;

              ITECHG_TO_WRITE.ICHAPPFAC      := DlvToExp_REC.EXCAPPTYPE;
              ITECHG_TO_WRITE.ICHCHACALC     := DlvToExp_REC.EXCCHGCALC;
              ITECHG_TO_WRITE.ICHCHNGDBYUSER := 1;
              ITECHG_TO_WRITE.IchIstRecNo    := DlvToExp_REC.SubDisistrecno;

              if InsertIt then
                ITECHG_TO_WRITE.DprRecNo     := DlvToExp_REC.DprRecNo;
                ITECHG_TO_WRITE.CTYNO        := ExcCtyNo;
              else
                ITECHG_TO_WRITE.IchRecNo     := V_IchRecNo;
              end if;

              if InsertIt then
                FT_PK_COST_WRITES.INSERT_ITECHG(ITECHG_TO_WRITE);
                COMMIT;
              else
                FT_PK_COST_WRITES.UPDATE_ITECHG(ITECHG_TO_WRITE);
                COMMIT;
              end if;

          END IF;
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

      FT_PK_AutoCosting.ENQUEUE_DPR(DelAudToWrite_REC.DPRRECNO, 6);

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
       BEGIN
         UpdExpChaRec := NULL;
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
    DoAutCostAdHocChgs(AUTOCOSTSREC.ExcDlvOrdNo, AUTOCOSTSREC.ExcChaRec);
  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;

END DoAutCostAdHocChgs;

END FT_PK_SALES_COSTS;