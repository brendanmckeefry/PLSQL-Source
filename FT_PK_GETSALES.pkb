create or replace PACKAGE BODY FT_PK_GETSALES AS

  cVersionControlNo   VARCHAR2(12) := '1.0.3'; -- Current Version Number

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
                    From Dprstolots
                    Where DPRSTOLOTSCHGS.DTLCHGSDTLRECNO  = DPRSTOLOTS.DTLRECNO
                    And Dprstolots.Dtldprrecno = Dprrecnos_In(Dprrec));

      DELETE FROM DPRSTOLOTS WHERE DTLDPRRECNO = DPRRECNOS_IN(DPRREC);

      INSERT INTO DPRSTOLOTS( DTLDPRRECNO,
                              DTLLITITENO,
                              DTLDELRECNO,
                              DTLBULKSALESQTY,
                              DTLSOLDSALESQTY,
                              DTLSALESVALUE,
                              DTLOPENPRCQTY,
                              DTLDLVORDNO,
                              DTLSALOFFNO)
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
                   end) OpenPrcQty,
                   delhed.DlvOrdNo,
                   delhed.DlvSalOffNo
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
                              group by  delprice.dprrecno, Itesto.istlitno, delprice.delprice, delnettvalue, delfreeofchg, dprdelrecno, delhed.DlvOrdNo, delhed.DlvSalOffNo;


     Insert Into Dprstolots(Dtldprrecno,
                            Dtllititeno,
                            Dtldelrecno,
                            Dtlbulksalesqty,
                            Dtlsoldsalesqty,
                            Dtlsalesvalue,
                            Dtlopenprcqty,
                            Dtldlvordno,
                            Dtlsaloffno,
                            Dtlworecno)
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
                                      END),
                            delhed.DlvOrdNo,
                            delhed.DlvSalOffNo,
                            Prepalinout.PalOutWoRecNo
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
                          And Not Exists (Select 1
                                          from Dprstolots checkIt
                                          Where checkit.Dtldprrecno = Delprice.DprRecNo
                                          And Checkit.Dtllititeno = Itesto.Istlitno
                                          And Checkit.Dtlworecno = Prepalinout.Paloutworecno)
                          Group By Delprice.Dprrecno, Itesto.Istlitno, Delprice.Delprice, Delnettvalue, Delprice.Delfreeofchg
											    , delprice.dprdelrecno, delhed.DlvOrdNo, delhed.DlvSalOffNo, Prepalinout.PalOutWoRecNo;

        Update Dprstolots
        Set Istransdel = 1
        Where Exists(Select * From Transferowner Where Dtldelrecno = Trotrandelrecno And Istranshiponly = 0)
        And Dtldprrecno = Dprrecnos_In(Dprrec);

        Insert Into Dprstolotschgs(Dtlchgsichno
                                  ,Dtlchgsdtlrecno
                                  ,Dtlchgsrawapp
                                  ,Dtlchgsbaseapp
                                  ,Dtlchgsexclfrompl
                                  ,Dtlchgsctyno
                                  ,Dtlchgschargeclass
                                  ,Dtlchgstypno)
                                  (Select Ichrecno
                                  ,Dtlrecno
                                  ,Case When Abs(Dprstolots.Dtlopenprcqty) > 0.009
                                        Then
                                          0
                                        else
                                           Case When (Exctobaserate = 1.00 Or Exctobaserate < 0.000009)
                                                Then Nvl(Ichappamt,0)
                                                Else  Round(Nvl(Ichappamt,0) / Exctobaserate,2)
                                                End
                                        end Rawappamt
                                  ,Case When Abs(Dprstolots.Dtlopenprcqty) > 0.009
                                        Then
                                          0
                                        Else
                                          Nvl(Ichappamt,0)
                                        end Ichappamt
                                  ,Nvl(Expcha.Excrecovfrompl, 0)
                                  ,Chgtyp.Ctyno
                                  ,Chgtyp.Chargeclass
                                  ,1
                                  From Itechg,Expcha,Itesto, Purord, Dprstolots, Chgtyp
                                  Where Itechg.Dprrecno = Dprrecnos_In(Dprrec)
                                  And Ichistrecno = Itesto.Istrecno
                                  And Itechg.Excrecno = Expcha.Exccharec
                                  And Itesto.Istpono = Purord.Porno
                                  And Chgtyp.Ctyno = Itechg.Ctyno
                                  And Abs(Nvl(Ichappamt,0)) > 0.009
                                  And Dprstolots.Dtldprrecno = Itechg.Dprrecno
                                  And Dprstolots.Dtllititeno = Itesto.Istlitno
                                  And Dprstolots.Dtlworecno Is Null
                                  And Not Exists (Select 1
                                                  From Dprstolotschgs Checkit
                                                  Where Checkit.Dtlchgsdtlrecno =  Dprstolots.Dtlrecno
                                                  And Checkit.Dtlchgsichno = Itechg.Ichrecno));



        INSERT INTO DPRSTOLOTSCHGS( DTLCHGSICHNO
                                    ,DTLCHGSDTLRECNO
                                    ,DTLCHGSRAWAPP
                                    ,DTLCHGSBASEAPP
                                    ,DTLCHGSEXCLFROMPL
                                    ,DTLCHGSCTYNO
                                    ,Dtlchgschargeclass
                                    ,Dtlchgstypno)
                                    Select IchRecNo
                                    ,DTLRECNO
                                    ,Sum(Nvl(RawAppAmtPerBulkLot,0))
                                    ,Sum(Nvl(Appamtperbulklot,0))
                                    ,NVL(EXCRECOVFROMPL,0)
                                    ,CTYNO
                                    ,Chargeclass
                                    ,1
                                    From(Select PreChgs.IchRecNo
                                          ,PreChgs.LitIteNo
                                          ,PreChgs.dprrecno
                                          ,PreChgs.ICHAPPAMT
                                          ,PreChgs.RawAppAmt
                                          ,PreChgs.DPRQTYTHIS
                                          ,PreChgs.disqty
                                          ,DPRSTOLOTS.DTLRECNO
                                          ,Round(
                                            Case When Abs(Dprstolots.Dtlopenprcqty) > 0.009
                                            Then
                                              0
                                            else
                                              Case When NVL(DPRISPRICEADJONLY,0) = 1
                                              then
                                                Case When Abs(PreChgs.disnettvalue) > 0 then (NVL(IchAppAmt,0) * Abs(PreChgs.DPRBASEVALTHIS)) / Abs(PreChgs.disnettvalue)  else 0 end
                                              else
                                                Case When Abs(PreChgs.disqty) > 0 then (NVL(IchAppAmt,0) * Abs(PreChgs.DPRQTYTHIS)) / Abs(PreChgs.disqty)  else 0 end
                                              End
                                            End,2) Appamtperbulklot
                                          ,Round(
                                            Case When Abs(Dprstolots.Dtlopenprcqty) > 0.009
                                            Then
                                              0
                                            else
                                              Case When NVL(DPRISPRICEADJONLY,0) = 1
                                              then
                                                Case When Abs(PreChgs.disnettvalue) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DPRBASEVALTHIS)) / Abs(PreChgs.disnettvalue)  else 0 end
                                              else
                                                Case When Abs(PreChgs.disqty) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DPRQTYTHIS)) / Abs(PreChgs.disqty)  else 0 end
                                              End
                                            end,2)  RawAppAmtPerBulkLot
                                          ,PreChgs.EXCRECOVFROMPL
                                          ,PreChgs.CTYNO
                                          ,PreChgs.CHARGECLASS
                                          ,PreChgs.PalOutWoRecNo
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
                                                ,prepalinout.PalOutWoRecNo
                                                from Itechg,ExpCha,Itesto prepIst, Lotite PrepLot, Prepalinout, PREPALINOUTSALES, Itesto BulkIst, Lotite bulkLotite, Deltoist,Delprice,CHGTYP
                                                Where Itechg.IchIstRecNo = prepIst.IstRecNo
                                                And Itechg.dprrecno = Dprrecnos_In(Dprrec)
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
                                          And DPRSTOLOTS.DTLWORECNO = PreChgs.PalOutWoRecNo
                                          And NOT exists (Select 1
                                                          from DPRSTOLOTSCHGS Checkit
                                                          Where CHECKIT.DTLCHGSDTLRECNO =  DPRSTOLOTS.DTLRECNO
                                                          And Checkit.Dtlchgsichno = Prechgs.Ichrecno))
                                    Group by IchRecNo,DTLRECNO,EXCRECOVFROMPL,CTYNO,Chargeclass;


      INSERT INTO DPRSTOLOTSCHGS(
                                   DTLCHGSICHNO
                                  ,DTLCHGSDTLRECNO
                                  ,DTLCHGSRAWAPP
                                  ,DTLCHGSBASEAPP
                                  ,DTLCHGSEXCLFROMPL
                                  ,DTLCHGSCTYNO
                                  ,Dtlchgschargeclass
                                  ,Dtlchgstypno)
                                  Select PreChgs.IchRecNo
                                  ,PreChgs.DTLRECNO
                                  , Round(
                                          Case When Abs(PreChgs.Dtlopenprcqty) > 0.009
                                          Then
                                             0
                                          else
                                             Case When NVL(DPRISPRICEADJONLY,0) = 1
                                              Then
                                                Case When Abs(PreChgs.delnettvalue) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DTLSALESVALUE)) / Abs(PreChgs.delnettvalue)  else 0 end
                                              Else
                                                Case When Abs(PreChgs.delprcqty) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DTLSOLDSALESQTY)) / Abs(PreChgs.delprcqty)  else 0 end
                                              End
                                          end,2) RawAppAmtPerBulkLot

                                  , Round(Case When Abs(PreChgs.Dtlopenprcqty) > 0.009
                                          Then
                                             0
                                          Else
                                            Case When NVL(DPRISPRICEADJONLY,0) = 1
                                            Then
                                              Case When Abs(PreChgs.delnettvalue) > 0 then (NVL(ICHAPPAMT,0) * Abs(PreChgs.DTLSALESVALUE)) / Abs(PreChgs.delnettvalue)  else 0 end
                                            else
                                              Case When Abs(PreChgs.delprcqty) > 0 then (NVL(ICHAPPAMT,0) * Abs(PreChgs.DTLSOLDSALESQTY)) / Abs(PreChgs.delprcqty)  else 0 end
                                            End
                                          end, 2) AppAmtPerBulkLot
                                  ,PreChgs.EXCRECOVFROMPL
                                  ,PreChgs.CTYNO
                                  ,Prechgs.Chargeclass
                                  ,1
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
                                  ,Nvl(Dprispriceadjonly,0) Dprispriceadjonly
                                  ,Dtlopenprcqty
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

         INSERT INTO DPRSTOLOTSCHGS(
                                    DTLCHGSICHNO
                                   ,DTLCHGSDTLRECNO
                                   ,DTLCHGSRAWAPP
                                   ,DTLCHGSBASEAPP
                                   ,DTLCHGSEXCLFROMPL
                                   ,DTLCHGSCTYNO
                                   ,Dtlchgschargeclass
                                   ,Dtlchgstypno)
                                   Select PreChgs.IchRecNo
                                   ,PreChgs.DTLRECNO
                                   , Round(
                                           Case When Abs(PreChgs.Dtlopenprcqty) > 0.009
                                           Then
                                              0
                                           Else
                                              Case When NVL(DPRISPRICEADJONLY,0) = 1
                                               Then
                                                 Case When Abs(PreChgs.delnettvalue) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DTLSALESVALUE)) / Abs(PreChgs.delnettvalue)  else 0 end
                                               Else
                                                 Case When Abs(PreChgs.delprcqty) > 0 then (NVL(RawAppAmt,0) * Abs(PreChgs.DTLSOLDSALESQTY)) / Abs(PreChgs.delprcqty)  else 0 end
                                               End
                                           end,2) RawAppAmtPerBulkLot

                                   , Round(Case When Abs(PreChgs.Dtlopenprcqty) > 0.009
                                           Then
                                              0
                                           Else
                                             Case When NVL(DPRISPRICEADJONLY,0) = 1
                                             Then
                                               Case When Abs(PreChgs.delnettvalue) > 0 then (NVL(ICHAPPAMT,0) * Abs(PreChgs.DTLSALESVALUE)) / Abs(PreChgs.delnettvalue)  else 0 end
                                             else
                                               Case When Abs(PreChgs.delprcqty) > 0 then (NVL(ICHAPPAMT,0) * Abs(PreChgs.DTLSOLDSALESQTY)) / Abs(PreChgs.delprcqty)  else 0 end
                                             End
                                           end, 2) AppAmtPerBulkLot
                                   ,PreChgs.EXCRECOVFROMPL
                                   ,PreChgs.CTYNO
                                   ,Prechgs.Chargeclass
                                   ,1
                                   From (
                                   Select DTLRECNO
                                   , DTLDPRRECNO
                                   , DTLLITITENO
                                   , DTLSOLDSALESQTY
                                   , delprcqty
                                   , delprice.delnettvalue
                                   , IchRecNo
                                   ,Case When (DELTOBASERATE = 1.00 or DELTOBASERATE < 0.000009) then NVL(ICHAPPAMT,0) else  Round(NVL(ICHAPPAMT,0) / DELTOBASERATE,2) end RawAppAmt
                                   ,ICHAPPAMT
                                   ,0 EXCRECOVFROMPL
                                   ,CHGTYP.CTYNO
                                   ,CHGTYP.CHARGECLASS
                                   ,DELPRICE.Dprrecno
                                   ,DTLSALESVALUE
                                   ,Nvl(Dprispriceadjonly,0) Dprispriceadjonly
                                   ,Dtlopenprcqty
                                   from Itechg, DELPRICE, DPRSTOLOTS, CHGTYP
                                   Where IchIstRecNo IS NULL
                                   And Itechg.ExcRecNo IS NULL
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

        INSERT INTO DPRSTOLOTSCHGS(
                                   DTLCHGSICHNO
                                  ,DTLCHGSDTLRECNO
                                  ,DTLCHGSRAWAPP
                                  ,DTLCHGSBASEAPP
                                  ,DTLCHGSEXCLFROMPL
                                  ,DTLCHGSCTYNO
                                  ,Dtlchgschargeclass
                                  ,Dtlchgstypno)
                                  Select PreChgs.IchRecNo
                                  ,PreChgs.DTLRECNO
                                  , Round(
                                          Case When Abs(PreChgs.Dtlopenprcqty) > 0.009
                                          Then
                                             0
                                          Else
                                             Case When Abs(Prechgs.Delprcqty) > 0 Then (Nvl(Rawappamt,0) * Abs(Prechgs.Dtlsoldsalesqty)) / Abs(Prechgs.Delprcqty)  Else 0 End
                                          end,2) RawAppAmtPerBulkLot

                                  , Round(Case When Abs(PreChgs.Dtlopenprcqty) > 0.009
                                          Then
                                             0
                                          Else
                                             Case When Abs(Prechgs.Delprcqty) > 0 Then (Nvl(Ichappamt,0) * Abs(Prechgs.Dtlsoldsalesqty)) / Abs(Prechgs.Delprcqty)  Else 0 End
                                          end, 2) AppAmtPerBulkLot
                                  ,PreChgs.EXCRECOVFROMPL
                                  ,PreChgs.CTYNO
                                  ,Prechgs.Chargeclass
                                  ,3
                                  From (
                                  Select DTLRECNO
                                  , DTLDPRRECNO
                                  , DTLLITITENO
                                  , DTLSOLDSALESQTY
                                  , delprcqty
                                  , delprice.delnettvalue
                                  , IchRecNo

                                  , Case When Nvl(DelQty,0) > 0
                                         then
                                        (Case When (EXCTOBASERATE = 1.00 or EXCTOBASERATE < 0.000009)
                                             Then Nvl(Ichappamt,0)
                                             Else  Round(Nvl(Ichappamt,0) / Exctobaserate,2)
                                             end * NVL(Cast(delprcqty as Float),0)) / Cast(DelQty as Float)
                                     else 0
                                     End Rawappamt
                                  , Case  When NVl(DelQty,0) > 0
                                          then (NVL(ICHAPPAMT,0) * Nvl(Cast(delprcqty as Float),0)) / Cast(DelQty as Float)
                                          else 0
                                          end ICHAPPAMT---Split price issue resolved
                                  ,NVL(EXPCHA.EXCRECOVFROMPL,0) EXCRECOVFROMPL
                                  ,CHGTYP.CTYNO
                                  ,CHGTYP.CHARGECLASS
                                  ,DELPRICE.Dprrecno
                                  ,DTLSALESVALUE
                                  ,Nvl(Dprispriceadjonly,0) Dprispriceadjonly
                                  ,Dtlopenprcqty
                                  from Itechg,ExpCha, DELPRICE, DPRSTOLOTS, CHGTYP, DELDET
                                  Where IchIstRecNo IS NULL
                                  And Itechg.ExcRecNo = ExpCha.ExcChaRec
                                  And Itechg.CtyNo = CHGTYP.CTYNO
                                  And Itechg.DelRecNo = Deldet.DelRecNo
								  And DELPRICE.DprDelrecno  = DelDet.Delrecno
								  And NVL(DPRISPRICEADJONLY,0) = 0
								  And not exists (Select 1 from deltocdt where cdtDprrecno = DELPRICE.Dprrecno)
                                  And DELPRICE.Dprrecno = DPRRECNOS_IN(DPRREC)
                                  And Abs(NVL(IchAppAmt,0)) > 0.009
                                  And DPRSTOLOTS.DTLDPRRECNO = DELPRICE.dprrecno
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
                                              Where Dprstolots.Dtldprrecno = Dprrecnos_In(Dprrec)
                                              And Abs(Nvl(Dprstolots.Dtlopenprcqty,0)) < 0.009);

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

  PROCEDURE GETLOTS(LITITENO_IN LOTITE.LITITENO%TYPE)
  IS
    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    DELETE FROM BALTOLOTSCHGS
    WHERE BALTOLOTSCHGS.BTLRECNO IN(SELECT BALTOLOTS.BTLRECNO FROM BALTOLOTS WHERE BALTOLOTS.BTLLITITENO = LITITENO_IN);

    DELETE FROM BALTOLOTS
    WHERE BALTOLOTS.BTLLITITENO = LITITENO_IN;

    INSERT INTO BALTOLOTS(BTLLITITENO
                          ,BTLSALOFFNO
                          ,RCVQTY)
                          SELECT LITITENO
                          ,PORSALOFF
                          ,CASE WHEN LITRCVCOMPLETE = 'Y' THEN NVL(LITQTYRCV,0) ELSE NVL(LITORGEXP,0) END RCVQTY
                          FROM LOTITE, PURORD
                          WHERE LITPORREC = PORRECNO
                          AND  LOTITE.LITITENO = LITITENO_IN;

    UPDATE BALTOLOTS
    SET RCVQTY = NVL(RCVQTY,0) + (SELECT SUM(NVL(TRANSFERINQTY,0))
                                  FROM ITESTO
                                  WHERE TRNCALCMETH = 0
                                  AND BTLLITITENO = ISTLITNO
                                  AND BTLSALOFFNO = TRNSALOFFNO
                                  AND ITESTO.ISTLITNO = LITITENO_IN)
    WHERE EXISTS (SELECT 1
                    FROM ITESTO
                    WHERE TRNCALCMETH = 0
                    AND BTLLITITENO = ISTLITNO
                    AND BTLSALOFFNO = TRNSALOFFNO
                    AND ITESTO.ISTLITNO = LITITENO_IN);

    INSERT INTO BALTOLOTS(BTLLITITENO
                          ,BTLSALOFFNO
                          ,RCVQTY)
                          SELECT ISTLITNO
                          ,TRNSALOFFNO
                          ,SUM(NVL(TRANSFERINQTY,0))
                          FROM ITESTO
                          WHERE TRNCALCMETH = 0
                          AND ITESTO.ISTLITNO = LITITENO_IN
                          And TRNSALOFFNO IS not null
                          AND NOT EXISTS (SELECT 1
                                          FROM BALTOLOTS CHECKIT
                                          WHERE CHECKIT.BTLLITITENO = ITESTO.ISTLITNO
                                          AND CHECKIT.BTLSALOFFNO = ITESTO.TRNSALOFFNO)
                          GROUP BY ISTLITNO, TRNSALOFFNO;

    UPDATE BALTOLOTS
    SET ONSTOCKQTY = RCVQTY - NVL((SELECT SUM(DPRSTOLOTS.DTLBULKSALESQTY) FROM DPRSTOLOTS WHERE DPRSTOLOTS.DTLLITITENO = BALTOLOTS.BTLLITITENO AND DPRSTOLOTS.DTLSALOFFNO = BALTOLOTS.BTLSALOFFNO), 0)
    WHERE BTLLITITENO = LITITENO_IN;

    INSERT INTO BALTOLOTSCHGS(BTLRECNO, ICHRECNO, CTYNO, CHARGECLASS, EXCLFROMPL, RAWAPP, BASEAPP, RAWAUTH, BASEAUTH)
    SELECT  BALTOLOTS.BTLRECNO,
            ITECHG.ICHRECNO,
            CHGTYP.CTYNO,
            CHGTYP.CHARGECLASS,
            NVL(EXPCHA.EXCRECOVFROMPL, 0),
            NVL(ITECHG.ICHRAWAPPAMT, 0.0),
            NVL(ITECHG.ICHAPPAMT, 0.0),
            NVL(ITECHG.ICHRAWAUTHAMM, 0.0),
            NVL(ITECHG.ICHAUTHAMM, 0.0)
    FROM ITECHG
    INNER JOIN CHGTYP
      ON CHGTYP.CTYNO = ITECHG.CTYNO
    INNER JOIN EXPCHA
      ON EXPCHA.EXCCHAREC = ITECHG.EXCRECNO
    INNER JOIN BALTOLOTS
      ON BALTOLOTS.BTLLITITENO = ITECHG.LITRECNO AND BALTOLOTS.BTLSALOFFNO = EXPCHA.EXCSALOFF
    WHERE ITECHG.LITRECNO = LITITENO_IN;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP();
  END GETLOTS;

  PROCEDURE GETPURCHDPRSTOLOTS(LITITENO_IN LOTITE.LITITENO%TYPE)
  IS
    CURSOR GET_ROUNDING_TODO(LITITENO_IN INTEGER)
    IS
		SELECT MAXDTLCHGSRECNO, BaseDiff, RawDiff, RCVQTY, TOTBULKSOLDQTY
		FROM (
		SELECT BTLLITITENO, ITECHG.ICHRECNO, RCVQTY, MAX(DPRSTOLOTSCHGS.DTLCHGSRECNO) MAXDTLCHGSRECNO
		, SUM(NVL(DTLBULKSALESQTY,0)) TOTBULKSOLDQTY, SUM(NVL(DTLCHGSRAWAPP,0)) TOTRAWAPP, SUM(NVL(DTLCHGSBASEAPP,0)) TOTBASEAPP
		,ICHAPPAMT
		,Nvl(ICHAPPAMT,0) - SUM(NVL(DTLCHGSBASEAPP,0)) BaseDiff
		,CASE WHEN (EXCTOBASERATE = 1.00 OR EXCTOBASERATE < 0.000009) THEN NVL(ICHAPPAMT,0) ELSE  ROUND(NVL(ICHAPPAMT,0) / EXCTOBASERATE,2) END RAWAPPAMT
		,CASE WHEN (EXCTOBASERATE = 1.00 OR EXCTOBASERATE < 0.000009) THEN NVL(ICHAPPAMT,0) ELSE  ROUND(NVL(ICHAPPAMT,0) / EXCTOBASERATE,2) END - SUM(NVL(DTLCHGSRAWAPP,0)) RawDiff
		FROM BALTOLOTS, DPRSTOLOTS, DPRSTOLOTSCHGS, ITECHG, EXPCHA
		WHERE BALTOLOTS.BTLLITITENO = DPRSTOLOTS.DTLLITITENO
		AND BALTOLOTS.BTLSALOFFNO   = DPRSTOLOTS.DTLSALOFFNO
		AND DPRSTOLOTS.DTLRECNO     = DPRSTOLOTSCHGS.DTLCHGSDTLRECNO
		AND DPRSTOLOTSCHGS.DTLCHGSICHNO = ITECHG.ICHRECNO
		AND EXPCHA.EXCCHAREC = ITECHG.EXCRECNO
		AND DPRSTOLOTS.DTLLITITENO = LITITENO_IN
		AND DTLCHGSTYPNO = 2
		GROUP BY BTLLITITENO, ITECHG.ICHRECNO, RCVQTY, ITECHG.ICHAPPAMT,EXCTOBASERATE )
		WHERE ABS(RCVQTY - TOTBULKSOLDQTY) < 0.009
		AND (ABS(NVL(BASEDIFF,0)) > 0.009 OR  ABS(NVL(RAWDIFF,0)) > 0.009);

    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;

    DELETE FROM DPRSTOLOTSCHGS
    WHERE DPRSTOLOTSCHGS.DTLCHGSDTLRECNO IN(SELECT DPRSTOLOTS.DTLRECNO FROM DPRSTOLOTS WHERE DPRSTOLOTS.DTLLITITENO = LITITENO_IN)
	  AND DPRSTOLOTSCHGS.DTLCHGSTYPNO = 2;

	INSERT INTO DPRSTOLOTSCHGS(
            DTLCHGSICHNO
           ,DTLCHGSDTLRECNO
           ,DTLCHGSRAWAPP
           ,DTLCHGSBASEAPP
           ,DTLCHGSEXCLFROMPL
           ,DTLCHGSCTYNO
           ,DTLCHGSCHARGECLASS
		   ,DTLCHGSTYPNO)
		   SELECT
			 ICHRECNO
			,DTLRECNO
			,ROUND(CASE WHEN TOTQTY > 0 THEN (RAWAPPAMT * DTLBULKSALESQTY) /  TOTQTY ELSE 0 END, 2) LOTTODPRCHGAUTHAPPRAW
			,ROUND( CASE WHEN TOTQTY > 0 THEN (ICHAPPAMT * DTLBULKSALESQTY) /  TOTQTY ELSE 0 END, 2) LOTTODPRCHGAPPBASE
			,EXCRECOVFROMPL
			,CTYNO
			,CHARGECLASS
			,2
			FROM (
			SELECT ICHRECNO
			, DPRSTOLOTS.DTLRECNO
			,DPRSTOLOTS.DTLDPRRECNO
			,BALTOLOTS.BTLLITITENO
			,BALTOLOTS.RCVQTY TOTQTY
			,NVL(DTLBULKSALESQTY,0) DTLBULKSALESQTY
			,NVL(ICHAPPAMT,0) ICHAPPAMT
			,CASE WHEN (EXCTOBASERATE = 1.00 OR EXCTOBASERATE < 0.000009) THEN NVL(ICHAPPAMT,0) ELSE  ROUND(NVL(ICHAPPAMT,0) / EXCTOBASERATE,2) END RAWAPPAMT
			,NVL(EXPCHA.EXCRECOVFROMPL,0) EXCRECOVFROMPL
			,CHGTYP.CHARGECLASS
			,CHGTYP.CTYNO
			FROM ITECHG, BALTOLOTS,DPRSTOLOTS, EXPCHA, CHGTYP
			WHERE ITECHG.LITRECNO= DPRSTOLOTS.DTLLITITENO
			AND EXCRECNO = EXPCHA.EXCCHAREC
			AND BALTOLOTS.BTLSALOFFNO = DPRSTOLOTS.DTLSALOFFNO
			AND BALTOLOTS.BTLLITITENO = ITECHG.LITRECNO
			AND EXPCHA.EXCSALOFF = DPRSTOLOTS.DTLSALOFFNO
			AND ITECHG.CTYNO = CHGTYP.CTYNO
      AND ITECHG.LITRECNO = LITITENO_IN
			AND NOT EXISTS (SELECT 1
                            FROM DPRSTOLOTSCHGS CHECKIT
                            WHERE CHECKIT.DTLCHGSDTLRECNO =  DPRSTOLOTS.DTLRECNO
                            AND CHECKIT.DTLCHGSICHNO = ITECHG.ICHRECNO));


    FOR ROUNDING_REC_TODO IN GET_ROUNDING_TODO(LITITENO_IN) LOOP
      UPDATE DPRSTOLOTSCHGS
      SET DTLCHGSRAWAPP = DTLCHGSRAWAPP + ROUNDING_REC_TODO.RawDiff
      ,DTLCHGSBASEAPP = DTLCHGSBASEAPP + ROUNDING_REC_TODO.BASEDIFF
      WHERE DPRSTOLOTSCHGS.DTLCHGSRECNO = ROUNDING_REC_TODO.MAXDTLCHGSRECNO;
    END LOOP;

    UPDATE BALTOLOTSCHGS
    SET ONSTOCKRAWAPP = RAWAPP - NVL((SELECT SUM(NVL(DTLCHGSRAWAPP,0)) FROM DPRSTOLOTSCHGS WHERE BALTOLOTSCHGS.ICHRECNO = DPRSTOLOTSCHGS.DTLCHGSICHNO),0)
    , ONSTOCKBASEAPP = BASEAPP - NVL((SELECT SUM(NVL(DTLCHGSBASEAPP,0)) FROM DPRSTOLOTSCHGS WHERE BALTOLOTSCHGS.ICHRECNO = DPRSTOLOTSCHGS.DTLCHGSICHNO),0)
    WHERE BALTOLOTSCHGS.BTLRECNO in (Select BALTOLOTS.BTLRECNO
                                      FROM BALTOLOTS
                                      Where BALTOLOTS.BTLLITITENO = LITITENO_IN);

  COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      FT_PK_ERRORS.LOG_AND_STOP();

  END GETPURCHDPRSTOLOTS;

  PROCEDURE GETSALES
  IS
  BEGIN
    FOR AUTOCOSTSREC IN (SELECT AUTOCOSTS_PROCESS.DPRRECNO FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.GETSALES = 1 AND AUTOCOSTS_PROCESS.DPRRECNO > 0) LOOP
      GETSALES(AUTOCOSTSREC.DPRRECNO);
    END LOOP;

    FOR AUTOCOSTSREC IN (SELECT AUTOCOSTS_PROCESS.LITITENO FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.GETSALES = 1 AND AUTOCOSTS_PROCESS.LITITENO > 0) LOOP
      GETLOTS(AUTOCOSTSREC.LITITENO);
      GETPURCHDPRSTOLOTS(AUTOCOSTSREC.LITITENO);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END GETSALES;

END FT_PK_GETSALES;