CREATE OR REPLACE PACKAGE BODY FT_PK_GETSALES AS

  cVersionControlNo   VARCHAR2(12) := '1.0.1'; -- Current Version Number

  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE  
      RETURN cVersionControlNo;
    END IF;                
  END CURRENTVERSION;

  PROCEDURE GETSALES_INT(DPRRECNOS_IN RECORD_NUMBERS) IS
  BEGIN
    FOR DPRREC IN DPRRECNOS_IN.FIRST..DPRRECNOS_IN.LAST LOOP
      DELETE FROM DPRSTOLOTSCHGS 
      WHERE EXISTS (SELECT 1 
                    FROM DPRSTOLOTS 
                    Where DPRSTOLOTSCHGS.DTLCHGSDTLRECNO  = DPRSTOLOTS.DTLRECNO
                    AND DPRSTOLOTS.DTLDPRRECNO = DPRRECNOS_IN(DPRREC));
    
    
      DELETE FROM DPRSTOLOTS WHERE DTLDPRRECNO = DPRRECNOS_IN(DPRREC);
      
      INSERT INTO DPRSTOLOTS( DTLDPRRECNO, 
                              DTLLITITENO, 
                              DTLDELRECNO,
                              DTLBULKSALESQTY, 
                              DTLSOLDSALESQTY,  
                              DTLSALESVALUE,
                              DTLOPENPRCQTY)
                              Select delprice.dprrecno
                              ,Itesto.istlitno
                              ,delprice.dprdelrecno
                              ,SUM(Case When (Abs(NVL(delprice.delprice, 0)) > 0.009
                                   OR Abs(NVL (delnettvalue, 0)) > 0.009
                                   OR NVL(delprice.delfreeofchg, 0) = 1) --exclude openprice
                   then
                     NVL(deltoist.DISSTKQTY,0)
                   else
                     0
                   end) bulkqty
                   
                              ,SUM(Case When (Abs(NVL(delprice.delprice, 0)) > 0.009
                                   OR Abs(NVL (delnettvalue, 0)) > 0.009
                                   OR NVL(delprice.delfreeofchg, 0) = 1) --exclude openprice
                   then
                     NVL(deltoist.DISSTKQTY,0)
                   else
                    0 
                   end) Soldqty 
                              ,SUM(NVL(deltoist.DISNETTVALUE,0))
                ,SUM(Case When (Abs(NVL(delprice.delprice, 0)) > 0.009
                                   OR Abs(NVL (delnettvalue, 0)) > 0.009
                                   OR NVL(delprice.delfreeofchg, 0) = 1) --exclude openprice
                   then
                    0 
                   else
                    NVL(deltoist.DISSTKQTY,0)
                   end) OpenPrcQty 						
                              From Deltoist,deldet, delprice, delhed, itesto, Purord
                              Where delprice.dprrecno = Deltoist.disdprrecno
                              and deltoist.DISISTRECNO = Itesto.ISTRECNO
                              And delprice.dprdelrecno = deldet.delrecno
                              and deldet.deldlvordno = delhed.dlvordno
                              And Itesto.IstPoNo = PurOrd.PorNo
                              AND (delhed.dlvrelinv <> 'Pik') -- Exclude updated pik status
                              AND (delhed.dlvtransship IS NULL OR NVL (delhed.transferflg, 0) > 0)
                              AND NVL (delhed.dlvsaltyp, 'S') <> 'R'
                              AND delprice.DPRRECNO  = DPRRECNOS_IN(DPRREC)
                              AND NOT exists ( Select 1 
                                               from DPRSTOLOTS checkIt 
                                               Where checkit.DTLDPRRECNO = Delprice.DprRecNo 
                                               and checkit.DTLLITITENO = Itesto.istlitno)
                              group by  delprice.dprrecno, Itesto.istlitno, delprice.delprice, delnettvalue, delfreeofchg, dprdelrecno;
                              
                              
                
            UPDATE DPRSTOLOTS
              SET (DTLBULKSALESQTY, 
              DTLSOLDSALESQTY, 
              DTLSALESVALUE,
              DTLOPENPRCQTY) = 
                      (SELECT NVL(DTLBULKSALESQTY,0) + SUM (CASE  WHEN (Abs(NVL(delprice.delprice, 0)) > 0.009
                                                                             OR Abs(NVL (delnettvalue, 0)) > 0.009
                                                                             OR NVL(delprice.delfreeofchg, 0) = 1
                                                                            ) --exclude openprice	
                                                                  THEN			
                                                                      CASE
                                                                      WHEN NVL (prepalinout.iniswgtcnt, 0) = 0 
                                                                      THEN  Case 
                                                                            When NVL(PrePalInOut.PPPALOUTQTY,0) = 0 
                                                                            then 0 
                                                                            else (NVL(to_number(NVL(PrePalInOut.PPalinQtyDec,PrePalInOut.PPPALINQTY)) ,0) * NVL(PrePalInOutSales.DprQtyThis,0)) 
                                                                                 / to_number(PrePalInOut.PPPALOUTQTY) 
                                                                            end
                                                                      ELSE  Case When NVL(PrePalInOut.PPPALOUTQTY,0) = 0 
                                                                            then 0 
                                                                            else (NVL(to_number(NVL(PrePalInOut.PPalinQtyDec,PrePalInOut.PPPALINQTY)) ,0) * NVL(PrePalInOutSales.DprQtyThis,0)) 
                                                                                 / to_number(PrePalInOut.PPPALOUTQTY) 
                                                                            end / Nvl(NULLIF(PrePalInOut.BoxWgtIn, 0.0), 1)
                                                                      END
                                                                  ELSE
                                                                    0															
                                                                  END) 
                      ,NVL(DTLSOLDSALESQTY,0) + SUM (CASE WHEN (Abs(NVL(delprice.delprice, 0)) > 0.009
                                                                 OR Abs(NVL (delnettvalue, 0)) > 0.009
                                                                 OR NVL(delprice.delfreeofchg, 0) = 1
                                                                ) --exclude openprice	
                                                          THEN
                                                            NVL(DPRQTYTHIS,0)
                                                          ELSE
                                                            0
                                                          END) 																 
                      ,NVL(DTLSALESVALUE,0) +  SUM(NVL(DPRBASEVALTHIS,0))
                      ,NVL(DTLOPENPRCQTY,0) + SUM (CASE WHEN (Abs(NVL(delprice.delprice, 0)) > 0.009
                                                               OR Abs(NVL (delnettvalue, 0)) > 0.009
                                                               OR NVL(delprice.delfreeofchg, 0) = 1
                                                              ) --exclude openprice	
                                                        THEN			
                                                          0
                                                        ELSE
                                                          CASE
                                                          WHEN NVL (prepalinout.iniswgtcnt, 0) = 0 
                                                          THEN  Case When NVL(PrePalInOut.PPPALOUTQTY,0) = 0 
                                                                then 0 
                                                                else (NVL(to_number(NVL(PrePalInOut.PPalinQtyDec,PrePalInOut.PPPALINQTY)) ,0) * NVL(PrePalInOutSales.DprQtyThis,0)) 
                                                                     / to_number(PrePalInOut.PPPALOUTQTY) 
                                                                end
                                                          ELSE  Case When NVL(PrePalInOut.PPPALOUTQTY,0) = 0 
                                                                then 0 
                                                                else (NVL(to_number(NVL(PrePalInOut.PPalinQtyDec,PrePalInOut.PPPALINQTY)) ,0) * NVL(PrePalInOutSales.DprQtyThis,0)) 
                                                                     / to_number(PrePalInOut.PPPALOUTQTY) 
                                                                end / Nvl(NULLIF(PrePalInOut.BoxWgtIn, 0.0), 1)
                                                          END														
                                                        END)
                      FROM prepalinout, prepalinoutsales, delprice, deldet, delhed, itesto
                      WHERE itesto.istrecno = prepalinout.palinbulkistrec
                      AND prepalinout.prepalrecno = prepalinoutsales.prepalinoutrecno
                      AND prepalinoutsales.delprcrecno = delprice.dprrecno
                      AND delprice.dprdelrecno = deldet.delrecno
                      AND deldet.deldlvordno = delhed.dlvordno
                      AND (delhed.dlvrelinv <> 'Pik') -- Exclude updated pik status
                      AND (delhed.dlvtransship IS NULL OR NVL (delhed.transferflg, 0) > 0)
                      AND NVL (delhed.dlvsaltyp, 'S') <> 'R'
                      AND DPRSTOLOTS.DTLDPRRECNO = Delprice.DprRecNo 
                      AND DPRSTOLOTS.DTLLITITENO = Itesto.istlitno
                      GROUP BY delprice.dprrecno, istlitno)
                      WHERE EXISTS (SELECT 1
                              FROM prepalinout, prepalinoutsales, delprice, deldet, delhed, itesto
                              WHERE itesto.istrecno = prepalinout.palinbulkistrec
                              AND prepalinout.prepalrecno = prepalinoutsales.prepalinoutrecno
                              AND prepalinoutsales.delprcrecno = delprice.dprrecno
                              AND delprice.dprdelrecno = deldet.delrecno
                              AND deldet.deldlvordno = delhed.dlvordno
                              AND (delhed.dlvrelinv <> 'Pik') -- Exclude updated pik status
                              AND (delhed.dlvtransship IS NULL OR NVL (delhed.transferflg, 0) > 0)
                              AND NVL (delhed.dlvsaltyp, 'S') <> 'R'
                              AND DPRSTOLOTS.DTLDPRRECNO = Delprice.DprRecNo 
                              AND DPRSTOLOTS.DTLLITITENO = Itesto.istlitno)
                      AND DPRSTOLOTS.DTLDPRRECNO = DPRRECNOS_IN(DPRREC);                  
                      
          INSERT INTO DPRSTOLOTS(DTLDPRRECNO, 
                            DTLLITITENO, 
                            DTLDELRECNO,
                            DTLBULKSALESQTY, 
                            DTLSOLDSALESQTY,  
                            DTLSALESVALUE,
                            DTLOPENPRCQTY)
                                        SELECT
                                              delprice.dprrecno
                                             ,itesto.istlitno
                                             ,delprice.dprdelrecno
                                             ,SUM( CASE WHEN (Abs(NVL(delprice.delprice, 0)) > 0.009
                                                       OR Abs(NVL (delnettvalue, 0)) > 0.009
                                                       OR NVL(delprice.delfreeofchg, 0) = 1
                                                      ) --exclude openprice
                                                        THEN						   
                                                            CASE
                                                            WHEN NVL (prepalinout.iniswgtcnt, 0) = 0 
                                                            THEN  Case 
                                                                  When NVL(PrePalInOut.PPPALOUTQTY,0) = 0 
                                                                  then 0 
                                                                  else (NVL(to_number(NVL(PrePalInOut.PPalinQtyDec,PrePalInOut.PPPALINQTY)) ,0) * NVL(PrePalInOutSales.DprQtyThis,0)) 
                                                                       / to_number(PrePalInOut.PPPALOUTQTY) 
                                                                  end
                                                            ELSE  Case When NVL(PrePalInOut.PPPALOUTQTY,0) = 0 
                                                                  then 0 
                                                                  else (NVL(to_number(NVL(PrePalInOut.PPalinQtyDec,PrePalInOut.PPPALINQTY)) ,0) * NVL(PrePalInOutSales.DprQtyThis,0)) 
                                                                       / to_number(PrePalInOut.PPPALOUTQTY) 
                                                                  end / Nvl(NULLIF(PrePalInOut.BoxWgtIn, 0.0), 1)
                                                            END
                                                        ELSE
                                                            0
                                                        END)
                                             ,SUM (CASE WHEN (Abs(NVL(delprice.delprice, 0)) > 0.009
                                                       OR Abs(NVL (delnettvalue, 0)) > 0.009
                                                       OR NVL(delprice.delfreeofchg, 0) = 1
                                                      ) --exclude openprice
                                                        THEN
                                                            NVL(DPRQTYTHIS,0)
                                                        ELSE
                                                            0
                                                        END) 
                                             ,SUM(NVL(DPRBASEVALTHIS,0)) 
                                             ,SUM (CASE WHEN (Abs(NVL(delprice.delprice, 0)) > 0.009
                                                       OR Abs(NVL (delnettvalue, 0)) > 0.009
                                                       OR NVL(delprice.delfreeofchg, 0) = 1
                                                      ) --exclude openprice
                                                        THEN
                                                            0
                                                        ELSE
                                                            CASE
                                                            WHEN NVL (prepalinout.iniswgtcnt, 0) = 0 
                                                            THEN  Case 
                                                                  When NVL(PrePalInOut.PPPALOUTQTY,0) = 0 
                                                                  then 0 
                                                                  else (NVL(to_number(NVL(PrePalInOut.PPalinQtyDec,PrePalInOut.PPPALINQTY)) ,0) * NVL(PrePalInOutSales.DprQtyThis,0)) 
                                                                       / to_number(PrePalInOut.PPPALOUTQTY) 
                                                                  end
                                                            ELSE  Case When NVL(PrePalInOut.PPPALOUTQTY,0) = 0 
                                                                  then 0 
                                                                  else (NVL(to_number(NVL(PrePalInOut.PPalinQtyDec,PrePalInOut.PPPALINQTY)) ,0) * NVL(PrePalInOutSales.DprQtyThis,0)) 
                                                                       / to_number(PrePalInOut.PPPALOUTQTY) 
                                                                  end / Nvl(NULLIF(PrePalInOut.BoxWgtIn, 0.0), 1)
                                                            END
                                                        END) 
                                        FROM prepalinout, prepalinoutsales, delprice, deldet, delhed, itesto
                                        WHERE itesto.istrecno = prepalinout.palinbulkistrec
                                        AND prepalinout.prepalrecno = prepalinoutsales.prepalinoutrecno
                                        AND prepalinoutsales.delprcrecno = delprice.dprrecno
                                        AND delprice.dprdelrecno = deldet.delrecno
                                        AND deldet.deldlvordno = delhed.dlvordno
                                        AND (delhed.dlvrelinv <> 'Pik') -- Exclude updated pik status
                                        AND (delhed.dlvtransship IS NULL OR NVL (delhed.transferflg, 0) > 0)
                                        AND NVL (delhed.dlvsaltyp, 'S') <> 'R'
                                        AND Delprice.DprRecNo = DPRRECNOS_IN(DPRREC)
                                        AND NOT EXISTS (Select 1 
                                                 from DPRSTOLOTS checkIt 
                                                 Where checkit.DTLDPRRECNO = Delprice.DprRecNo 
                                                 and checkit.DTLLITITENO = Itesto.istlitno)
                                        GROUP BY delprice.dprrecno, itesto.istlitno, delprice.delprice, delnettvalue, delprice.delfreeofchg, delprice.dprdelrecno;
                                        
        UPDATE DPRSTOLOTS
        SET ISTRANSDEL = 1
        WHERE EXISTS(SELECT * FROM TRANSFEROWNER WHERE DTLDELRECNO = TROTRANDELRECNO AND ISTRANSHIPONLY = 0)
          AND DTLDPRRECNO = DPRRECNOS_IN(DPRREC);
                                      
        INSERT INTO DPRSTOLOTSCHGS(
                                     DTLCHGSICHNO
                                    ,DTLCHGSDTLRECNO
                                    ,DTLCHGSRAWAPP 
                                    ,DTLCHGSBASEAPP
                                    ,DTLCHGSEXCLFROMPL
                                    ,DTLCHGSCTYNO
                                    ,DTLCHGSCHARGECLASS)
                                    (Select IchRecNo
                                    ,DTLRECNO
                                    ,Case When (EXCTOBASERATE = 1.00 or EXCTOBASERATE < 0.000009) then NVL(ICHAPPAMT,0) else  Round(NVL(ICHAPPAMT,0) / EXCTOBASERATE,2) end RawAppAmt
                                    ,ICHAPPAMT
                                    ,NVL(EXPCHA.EXCRECOVFROMPL, 0)
                                    ,CHGTYP.CTYNO
                                    ,CHGTYP.CHARGECLASS
                                    from Itechg,ExpCha,Itesto, PURORD, DPRSTOLOTS, CHGTYP
                                    Where itechg.dprrecno = DPRRECNOS_IN(DPRREC)
                                    And IchIstRecNo = Itesto.IstRecNo
                                    And Itechg.ExcRecNo = ExpCha.ExcChaRec
                                    And Itesto.IstPoNo = PURORD.PorNo
                                    And CHGTYP.CTYNO = ITECHG.CTYNO
                                    And Abs(NVL(IchAppAmt,0)) > 0.009
                                    And DPRSTOLOTS.DTLDPRRECNO = itechg.dprrecno
                                    And DPRSTOLOTS.DTLLITITENO = Itesto.IstLitNo
                                    AND NOT exists (Select 1 
                                                    from DPRSTOLOTSCHGS Checkit 
                                                    Where CHECKIT.DTLCHGSDTLRECNO =  DPRSTOLOTS.DTLRECNO
                                                    And CHECKIT.DTLCHGSICHNO = Itechg.IchRecNo));
                            
      
              
                              
        INSERT INTO DPRSTOLOTSCHGS(
                                    DTLCHGSICHNO
                                    ,DTLCHGSDTLRECNO
                                    ,DTLCHGSRAWAPP
                                    ,DTLCHGSBASEAPP
                                    ,DTLCHGSEXCLFROMPL
                                    ,DTLCHGSCTYNO
                                    ,DTLCHGSCHARGECLASS)
                                    Select IchRecNo
                                    ,DTLRECNO
                                    ,RawAppAmtPerBulkLot
                                    ,AppAmtPerBulkLot
                                    ,EXCRECOVFROMPL
                                    ,CTYNO
                                    ,CHARGECLASS
                                    From(
                                          Select PreChgs.IchRecNo
                                          ,PreChgs.LitIteNo
                                          ,PreChgs.dprrecno
                                          ,PreChgs.ICHAPPAMT
                                          ,PreChgs.RawAppAmt
                                          ,PreChgs.DPRQTYTHIS
                                          ,PreChgs.disqty
                                          ,DPRSTOLOTS.DTLRECNO
                                          , Round(Case When NVL(DPRISPRICEADJONLY,0) = 1
                                            then
                                              Case When Abs(PreChgs.disnettvalue) > 0 then (NVL(IchAppAmt,0) * Abs(PreChgs.DPRBASEVALTHIS)) / Abs(PreChgs.disnettvalue)  else 0 end 
                                            else
                                              Case When Abs(PreChgs.disqty) > 0 then (NVL(IchAppAmt,0) * Abs(PreChgs.DPRQTYTHIS)) / Abs(PreChgs.disqty)  else 0 end 
                                            end,2) AppAmtPerBulkLot         
                                          ,Round(Case When NVL(DPRISPRICEADJONLY,0) = 1
                                            then
                                              Case When Abs(PreChgs.disnettvalue) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DPRBASEVALTHIS)) / Abs(PreChgs.disnettvalue)  else 0 end 
                                            else
                                              Case When Abs(PreChgs.disqty) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DPRQTYTHIS)) / Abs(PreChgs.disqty)  else 0 end 
                                            end,2)  RawAppAmtPerBulkLot
                                          ,PreChgs.EXCRECOVFROMPL
                                          ,PreChgs.CTYNO
                                          ,PreChgs.CHARGECLASS
                                          From(
                                                Select IchRecNo
                                                ,bulkLotite.LitIteNo
                                                ,Itechg.dprrecno
                                                ,NVL(ICHAPPAMT,0) ICHAPPAMT
                                                ,Case When (EXCTOBASERATE = 1.00 or EXCTOBASERATE < 0.000009) then NVL(ICHAPPAMT,0) else  Round(NVL(ICHAPPAMT,0) / EXCTOBASERATE,2) end RawAppAmt
                                                ,NVL(PREPALINOUTSALES.DPRQTYTHIS,0) DPRQTYTHIS
                                                ,NVL(PREPALINOUTSALES.DPRBASEVALTHIS,0) DPRBASEVALTHIS
                                                ,NVL(deltoist.disqty, 0) disqty
                                                ,NVL(deltoist.disnettvalue, 0) disnettvalue
                                                ,NVL(EXPCHA.EXCRECOVFROMPL, 0) EXCRECOVFROMPL
                                                ,CHGTYP.CTYNO
                                                ,CHGTYP.CHARGECLASS
                                                ,delprice.DPRISPRICEADJONLY
                                                from Itechg,ExpCha,Itesto prepIst, Lotite PrepLot, Prepalinout, PREPALINOUTSALES, Itesto BulkIst, Lotite bulkLotite, Deltoist,Delprice,CHGTYP
                                                Where Itechg.IchIstRecNo = prepIst.IstRecNo
                                                And Itechg.dprrecno = DPRRECNOS_IN(DPRREC)
                                                And  Itechg.IchIstRecNo = DELTOIST.DISISTRECNO
                                                And Itechg.dprrecno = Delprice.Dprrecno 
                                                And DELTOIST.DISDPRRECNO = Itechg.dprrecno
                                                And Itechg.ExcRecNo = ExpCha.ExcChaRec
                                                And Itechg.CtyNo = ChgTyp.CtyNo
                                                And prepIst.IstLitNo = PrepLot.LITITENO
                                                And PrepLot.LitWoRecNo = Prepalinout.PALOUTWORECNO
                                                And Prepalinout.prepalrecno = prepalinoutsales.prepalinoutrecno
                                                And prepalinoutsales.delprcrecno = Itechg.dprrecno
                                                And prepalinout.palinbulkistrec = BulkIst.IstRecNo
                                                And BulkIst.IstLitNo = bulkLotite.LitIteNo
                                                And Abs(NVL(IchAppAmt,0)) > 0.009) Prechgs,DPRSTOLOTS
                                          WHERE DPRSTOLOTS.DTLDPRRECNO = PreChgs.dprrecno
                                          And DPRSTOLOTS.DTLLITITENO = PreChgs.LitIteNo
                                          And NOT exists (Select 1 
                                                          from DPRSTOLOTSCHGS Checkit 
                                                          Where CHECKIT.DTLCHGSDTLRECNO =  DPRSTOLOTS.DTLRECNO
                                                          And CHECKIT.DTLCHGSICHNO = PreChgs.IchRecNo));
                                                          
                                                          
      INSERT INTO DPRSTOLOTSCHGS(
                                   DTLCHGSICHNO
                                  ,DTLCHGSDTLRECNO
                                  ,DTLCHGSRAWAPP
                                  ,DTLCHGSBASEAPP
                                  ,DTLCHGSEXCLFROMPL
                                  ,DTLCHGSCTYNO
                                  ,DTLCHGSCHARGECLASS)
                                  Select PreChgs.IchRecNo
                                  ,PreChgs.DTLRECNO
                                  , Round(Case When NVL(DPRISPRICEADJONLY,0) = 1
                                          then
                                            Case When Abs(PreChgs.DTLSALESVALUE) > 0 then (NVL(ICHAPPAMT,0) * Abs(PreChgs.DTLSALESVALUE)) / Abs(PreChgs.delnettvalue)  else 0 end
                                          else
                                            Case When Abs(PreChgs.DTLSOLDSALESQTY) > 0 then (NVL(ICHAPPAMT,0) * Abs(PreChgs.DTLSOLDSALESQTY)) / Abs(PreChgs.delprcqty)  else 0 end 
                                          end,2) AppAmtPerBulkLot
                                          
                                  , Round(Case When NVL(DPRISPRICEADJONLY,0) = 1
                                          then
                                            Case When Abs(PreChgs.DTLSALESVALUE) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DTLSALESVALUE)) / Abs(PreChgs.delnettvalue)  else 0 end
                                          else
                                            Case When Abs(PreChgs.DTLSOLDSALESQTY) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DTLSOLDSALESQTY)) / Abs(PreChgs.delprcqty)  else 0 end  
                                          end, 2) RawAppAmtPerBulkLot
                                  ,PreChgs.EXCRECOVFROMPL
                                  ,PreChgs.CTYNO
                                  ,PreChgs.CHARGECLASS
                                  From (
                                  Select DTLRECNO
                                  , DTLDPRRECNO
                                  , DTLLITITENO
                                  , DTLSOLDSALESQTY
                                  , delprcqty
                                  , delprice.delnettvalue
                                  , IchRecNo
                                  ,Case When (EXCTOBASERATE = 1.00 or EXCTOBASERATE < 0.000009) then NVL(ICHAPPAMT,0) else  Round(NVL(ICHAPPAMT,0) / EXCTOBASERATE,2) end RawAppAmt
                                  ,ICHAPPAMT
                                  ,NVL(EXPCHA.EXCRECOVFROMPL,0) EXCRECOVFROMPL
                                  ,CHGTYP.CTYNO
                                  ,CHGTYP.CHARGECLASS
                                  ,DELPRICE.Dprrecno
                                  ,DTLSALESVALUE
                                  ,NVL(DPRISPRICEADJONLY,0) DPRISPRICEADJONLY
                                  from Itechg,ExpCha, DELPRICE, DPRSTOLOTS, CHGTYP
                                  Where IchIstRecNo IS NULL
                                  And Itechg.ExcRecNo = ExpCha.ExcChaRec
                                  And Itechg.CtyNo = CHGTYP.CTYNO
                                  And Itechg.Dprrecno = DELPRICE.Dprrecno
                                  And Itechg.Dprrecno = DPRRECNOS_IN(DPRREC)
                                  And Abs(NVL(IchAppAmt,0)) > 0.009
                                  And DPRSTOLOTS.DTLDPRRECNO = itechg.dprrecno
                                  AND NOT exists (Select 1 
                                                  from DPRSTOLOTSCHGS Checkit 
                                                  Where CHECKIT.DTLCHGSDTLRECNO =  DPRSTOLOTS.DTLRECNO
                                                  And CHECKIT.DTLCHGSICHNO = Itechg.IchRecNo)
                                  
                                  
                                  )PreChgs;
                                  
                                  
                      UPDATE DPRSTOLOTSCHGS
                      SET DTLCHGSBASEAPP = NVL(DTLCHGSBASEAPP,0) + (Select NVL(Itechg.IchAppAmt,0) - SUM(NVL(checkit.DTLCHGSBASEAPP,0)) 
                                                                    FROM Itechg, DPRSTOLOTSCHGS checkit
                                                                    Where checkit.DTLCHGSICHNO = ITECHG.ICHRECNO
                                                                    And DPRSTOLOTSCHGS.DTLCHGSICHNO = checkit.DTLCHGSICHNO
                                                                    group by Itechg.ICHRECNO, Itechg.ICHAPPAMT
                                                                    having abs(NVL(Itechg.ICHAPPAMT,0) - SUM(checkit.DTLCHGSBASEAPP)) > 0.009)
                      WHERE EXISTS (Select 1
                                    FROM Itechg, DPRSTOLOTSCHGS checkit
                                    Where checkit.DTLCHGSICHNO = ITECHG.ICHRECNO
                                    And DPRSTOLOTSCHGS.DTLCHGSICHNO = checkit.DTLCHGSICHNO
                                    group by Itechg.ICHRECNO, Itechg.ICHAPPAMT
                                    having abs(NVL(Itechg.ICHAPPAMT,0) - SUM(checkit.DTLCHGSBASEAPP)) > 0.009)											  
                      AND DPRSTOLOTSCHGS.DTLCHGSRECNO =  (SELECT Max(Checkit.DTLCHGSRECNO)
                                                          FROM DPRSTOLOTSCHGS Checkit
                                                          WHERE Checkit.DTLCHGSICHNO = DPRSTOLOTSCHGS.DTLCHGSICHNO)
                      AND DTLCHGSDTLRECNO IN (SELECT DTLRECNO
                                              FROM DPRSTOLOTS
                                              Where DPRSTOLOTS.DTLDPRRECNO = DPRRECNOS_IN(DPRREC));
    
      COMMIT; 
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
      ROLLBACK;
  END GETSALES_INT;
    
  PROCEDURE GETSALES(DPRRECNO_IN DELPRICE.DPRRECNO%TYPE)
  IS
    PARAMETER_LIST    FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    DPRRECNOS_IN      RECORD_NUMBERS;
  BEGIN
    IF DPRRECNO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'DPRRECNOS_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(DPRRECNO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;
    
    DPRRECNOS_IN := RECORD_NUMBERS(DPRRECNO_IN);
  
    GETSALES_INT(DPRRECNOS_IN);
  EXCEPTION
    WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
    ROLLBACK;
  END GETSALES;
    
  PROCEDURE GETSALES IS
    DPRRECNOS_IN      RECORD_NUMBERS := RECORD_NUMBERS();
    TOTALCOUNT        INTEGER := 0;
    COUNTINT          INTEGER := 0; 
    NOOFRECS          INTEGER := 0;
  BEGIN  
    SELECT COUNT(*) INTO NOOFRECS FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.GETSALES = 1;
    FOR DPRREC IN (SELECT * FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.GETSALES = 1)LOOP
      DPRRECNOS_IN.EXTEND();
      DPRRECNOS_IN(DPRRECNOS_IN.COUNT) := DPRREC.DPRRECNO;
      TOTALCOUNT:= TOTALCOUNT+1;
      COUNTINT := COUNTINT + 1;      
      IF (COUNTINT = 1000 or TOTALCOUNT = NOOFRECS) THEN     
        GETSALES_INT(DPRRECNOS_IN);
        DPRRECNOS_IN.DELETE;
        COUNTINT := 0;
      END IF;
	   END LOOP;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN 
      NULL;
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END GETSALES;  
  
END FT_PK_GETSALES;
/
