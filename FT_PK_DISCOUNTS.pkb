CREATE OR REPLACE PACKAGE BODY FT_PK_DISCOUNTS AS
  --#region Global Body Variables
  cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number
  RATEBYBOX CONSTANT NUMBER(1) :=1;
  RATEBYPERC CONSTANT NUMBER(1) :=2;
  RATEBYSTAND CONSTANT NUMBER(1) :=3;
  CTYDISCOUNT CONSTANT NUMBER(2) := 97;
  CTYREBATE CONSTANT NUMBER(2) := 98;
  AUDTYPDISCOUNT CONSTANT NUMBER(2) := 36;
  AUDTYPREBATE CONSTANT NUMBER(2) := 37;
  RATEBYINVOICE CONSTANT NUMBER(1) :=1;
  RATEBYPAYMENT CONSTANT NUMBER(1) :=2;
  RATEBYRETRO CONSTANT NUMBER(1) :=3;
  ITEBOXDISC CONSTANT NUMBER(5):=100;
  ITESTDUNITDISC CONSTANT NUMBER(5):=200;

  TYPE DELIVERYDETAIL_RECORD is RECORD(
      DELPRCPRDNO       DelDet.DelPrcPrdNo%TYPE,
      DELRECNO          DelDet.DelRecNo%TYPE,
      ACTCSTCODE        Orders.ActCstCode%TYPE,
      DLVSTCLOC         Delhed.DlvStkLoc%TYPE,
      DELDATE           Delhed.DlvDelDate%TYPE,
      DLVSALOFFNO       Delhed.DlvSalOffNo%TYPE,
      DPRISPRICEADJONLY Delprice.DprIsPriceAdjOnly%TYPE,
      DELFREEOFCHG      DelPrice.DELFREEOFCHG%TYPE,
      DELBASENETTVAL    Delprice.DelBaseNettVal%TYPE,
      DELPRCQTY         DelPrice.DelPrcQty%TYPE,
      DELQTYPER         DelDet.DelQtyPer%TYPE,
      DELINVSTATUS      DelPrice.DelInvStatus%TYPE,
      DPRRECNO          DelPrice.DprRecNo%TYPE,
      PRICE             DELPRICE.DELPRICE%TYPE
  );

  TYPE DISCOUNT_RATE_RECORD is RECORD(
      IchPcntOrRate     IteChg.IchPcntOrRate%TYPE,
      BoxPercUnit       integer
  );

  TYPE STANDARD_RATE_RECORD is RECORD(
      AllPStndUnit      PrdAllDescs.AllPStndUnit%TYPE
  );
  
  TYPE COUNT_DelToCdt is RECORD(
      NoOf            integer
  );

  TYPE DELTOCDT_RECORD is RECORD(
      OrgDprRecNo          DelPrice.DprRecNo%TYPE
  );

  TYPE ITECHG_RECORD is RECORD(
       IchRecNo           IteChg.IchRecNo%TYPE,
       CtyNo              IteChg.CtyNo%TYPE,
       IchAppAmt          IteChg.IchAppAmt%TYPE,
       IchAuthAmm         IteChg.IchAuthAmm%TYPE,
       IchAppFac          IteChg.IchAppFac%TYPE,
       IchChaCalc         IteChg.IchChaCalc%TYPE,
       IchDisType         IteChg.IchDisType%TYPE,
       IchPcntOrRate      IteChg.IchPcntOrRate%TYPE,
       IchRealDisType     IteChg.IchRealDisType%TYPE,
       IchOnPayment       IteChg.IchOnPayment%TYPE,
       DiscDedStr         IchDiscTyp.DiscDedStr%TYPE,
       DiscGrpGlRecNo     IchDiscTyp.DiscGrpGlRecNo%TYPE
  );

  CURSOR DISCOUNT_RATES(IN_DRARECNO DISRATES.DRARECNO%TYPE)
      is
        Select DisRates.DraRecNo
        , DisRates.ThisSeqNo
        , Case When Abs(NVL(DisRates.ThisRate, 0)) > 0.009 Then DisRates.ThisRate
             When Abs(NVL(DisRates.ThisPercRate, 0)) > 0.009 Then DisRates.ThisPercRate
             When Abs(NVL(DisRates.THISSTNDUNITRATE, 0)) > 0.009 Then DisRates.THISSTNDUNITRATE
             Else 0
             End IchPcntOrRate
        , DisRates.ThisOn   -- 1 = Invoice, 2 Payment, 3 = Retro
        , Case When Abs(NVL(DisRates.ThisRate, 0)) > 0.009 Then 1
             When Abs(NVL(DisRates.ThisPercRate, 0)) > 0.009 Then 2
             When Abs(NVL(DisRates.THISSTNDUNITRATE, 0)) > 0.009 Then 3
             End BoxPercUnit -- ; 1 = Box, 2 = Perc, 3 = StandardUnit
        , DisRates.ThisDedStr, DisRates.DisGlRecNo
        , Disgrps.ApplyRebsToFoc
        From DisRates, DiscPrds, DisGrps
        Where DisRates.DraRecNo = IN_DRARECNO
        And DisRates.DraRecNo = DiscPrds.DraRecNo
        And DiscPrds.DraDisGrpRecNo = DisGrps.DisGrpRecNo
        Order By Length(DisRates.ThisDedstr), DisRates.ThisDedstr;

  CURSOR DISCOUNT_ITECHG(IN_DPRRECNO DELPRICE.DPRRECNO%TYPE)
    is
      SELECT IteChg.IchRecNo,
             IteChg.CtyNo,
             IteChg.IchAppAmt,
             IteChg.IchAuthAmm,
             IteChg.IchAppFac,
             IteChg.IchChaCalc,
             IteChg.IchDisType,
             IteChg.IchPcntOrRate,
             IteChg.IchRealDisType,
             IteChg.IchOnPayment,
             IchDiscTyp.DiscDedStr,
             IchDiscTyp.DiscGrpGlRecNo
      FROM IteChg,
             IchDiscTyp
      WHERE IteChg.DprRecNo = IN_DPRRECNO
      AND IteChg.IchRecNo = IchDiscTyp.IchRecNo ;

  TYPE DISCOUNT_RECS IS TABLE OF DISCOUNT_RATES%ROWTYPE;
  TYPE ITECHG_RECS IS TABLE OF ITECHG%ROWTYPE;
  TYPE ICHDISCTYP_RECS IS TABLE OF ICHDISCTYP%ROWTYPE;
  TYPE AUDITRECORD_RECS IS TABLE OF AUDITRECORD%ROWTYPE;
  TYPE REBDISCAUDIT_RECS IS TABLE OF REBDISCAUDIT%ROWTYPE;
  TYPE DELAUDIT_RECS is TABLE OF DELAUDIT%ROWTYPE;
  --#endregion Global Body Variables
  -- CURRENTVERSION public method returns the Version number of the header or body
  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2 IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE
      RETURN cVersionControlNo;
    END IF;
  END CURRENTVERSION;
  -- FIND_BEST_DISCOUNT best fits query to determine the discounts to be applied
  FUNCTION FIND_BEST_DISCOUNT(IN_DELIVERYDETAIL IN DELIVERYDETAIL_RECORD) RETURN INTEGER IS
    DRARECNO INTEGER;

    CURSOR BEST_DISCOUNT(DELIVERYDETAIL IN DELIVERYDETAIL_RECORD)
    IS
      Select DiscPrds.DraRecNo,
        1 + Case When (DiscPrds.DraPrcRef1 = -32000 Or DiscPrds.DraPrcRef1 = 0) Then 0 Else 1 End
         + Case When DiscPrds.DraPrcRef2 = 0 Then 0 Else 1 End
         + Case When DiscPrds.DraPrcRef3 = 0 Then 0 Else 1 End
           + Case When DiscPrds.DraPrcRef4 = 0 Then 0 Else 1 End
         + Case When DiscPrds.DraPrcRef5 = 0 Then 0 Else 1 End
         + Case When DiscPrds.DraPrcRef6 = 0 Then 0 Else 1 End
         + Case When DiscPrds.DraStcLoc = -32000 Then 0 Else 3 End-- ; Weight it for stock location
         + Case When DiscPrds.DraSalOffNo = -32000 Then 0 Else 3 End AS NoOfMatches --; Weight it for sales office
        From PrdRec, Discsts, DiscPrds, DisGrps
        Where PrdRec.PrcPrdNo = DELIVERYDETAIL.DELPRCPRDNO
        And Discsts.DisCstCode = DELIVERYDETAIL.ACTCSTCODE
        And Discsts.CstDisGrpRecNo = DiscPrds.DraDisGrpRecNo
        And DisGrps.DisGrpRecNo = Discsts.CstDisGrpRecNo
        And ((DiscPrds.DraPrcRef1 = -32000 Or DiscPrds.DraPrcRef1 = 0) Or DiscPrds.DraPrcRef1 = NVL(PrdRec.PrcRef1, -32000))
        And (DiscPrds.DraPrcRef2 = 0 Or DiscPrds.DraPrcRef2 = NVL(PrdRec.PrcRef2, -32000))
        And (DiscPrds.DraPrcRef3 = 0 Or DiscPrds.DraPrcRef3 = NVL(PrdRec.PrcRef3, -32000))
        And (DiscPrds.DraPrcRef4 = 0 Or DiscPrds.DraPrcRef4 = NVL(PrdRec.PrcRef4, -32000))
        And (DiscPrds.DraPrcRef5 = 0 Or DiscPrds.DraPrcRef5 = NVL(PrdRec.PrcRef5, -32000))
        And (DiscPrds.DraPrcRef6 = 0 Or DiscPrds.DraPrcRef6 = NVL(PrdRec.PrcRef6, -32000))
        And (DiscPrds.DraStcLoc = -32000 Or DiscPrds.DraStcLoc = NVL(DELIVERYDETAIL.DLVSTCLOC, -32000))
        And (DiscPrds.DraSalOffNo = -32000 Or DiscPrds.DraSalOffNo = NVL(DELIVERYDETAIL.DLVSALOFFNO, -32000))
        And DiscPrds.SchemeCanc = 0
        And DisGrps.IsActive = 1
        And DiscPrds.DraTypOf = 1
        And DELIVERYDETAIL.DELDATE Between Discprds.StartDate And NVL(Discprds.FinishDate, (DELIVERYDETAIL.DELDATE +(365 * 30)))
        And Exists
        (Select DisRates.DraRecNo
          From DisRates
          Where DiscPrds.DraRecNo = DisRates.DraRecNo)
        ORDER BY 2 DESC;

    BEST_DISCOUNT_REC BEST_DISCOUNT%ROWTYPE;
  BEGIN
    OPEN BEST_DISCOUNT(IN_DELIVERYDETAIL);
    FETCH BEST_DISCOUNT into BEST_DISCOUNT_REC;
    DRARECNO := 0;
    IF BEST_DISCOUNT%FOUND THEN
      DRARECNO := BEST_DISCOUNT_REC.DraRecNo;
    END IF;
    CLOSE BEST_DISCOUNT;
    return DRARECNO;
  EXCEPTION
  WHEN OTHERS THEN
    IF BEST_DISCOUNT%ISOPEN THEN
      CLOSE BEST_DISCOUNT;
    END IF;
    FT_PK_ERRORS.LOG_AND_STOP();
  END FIND_BEST_DISCOUNT;
  -- GET_DISCOUNTRATE returns the query on CURSOR DISCOUNT_RATES to be inserted into the table
  FUNCTION GET_DISCOUNTRATE(IN_DRARECNO DiscPrds.DraRecNo%type) RETURN DISCOUNT_RECS AS
    RET_DISCRATES     DISCOUNT_RECS := DISCOUNT_RECS();
  BEGIN
    -- DiscRates has a multiple PK so need to loop
    FOR DISCREC IN DISCOUNT_RATES(IN_DRARECNO) LOOP
      RET_DISCRATES.EXTEND(1);
      RET_DISCRATES(RET_DISCRATES.COUNT) := DISCREC;
    END LOOP;

    RETURN RET_DISCRATES;
  EXCEPTION -- adding an exception here as there should always be data found as this is a PK
  WHEN NO_DATA_FOUND THEN
    IF DISCOUNT_RATES%ISOPEN THEN
      CLOSE DISCOUNT_RATES;
    END IF;
    FT_PK_ERRORS.LOG_AND_STOP;
  WHEN OTHERS THEN
    IF DISCOUNT_RATES%ISOPEN THEN
      CLOSE DISCOUNT_RATES;
    END IF;
    FT_PK_ERRORS.LOG_AND_STOP;
  END GET_DISCOUNTRATE;
  -- GET_BOX_RATE calculates the discount amount when Abs(NVL(DisRates.ThisRate, 0)) > 0.009
  FUNCTION GET_BOX_RATE(InIchPcntOrRate IN IteChg.IchPcntOrRate%TYPE, InDelPrcQty IN DelPrice.DelPrcQty%Type, AMOUNT OUT FLOAT) RETURN BOOLEAN AS
    Reqd  BOOLEAN;
  BEGIN
    Reqd := true;
    IF Reqd THEN
      AMOUNT := InDelPrcQty * InIchPcntOrRate;
    END IF;
    Return Reqd;
  END GET_BOX_RATE;
  -- GET_PERCENTAGE_RATE calculates the discount amount when Abs(NVL(DisRates.ThisPercRate, 0)) > 0.009
  FUNCTION GET_PERCENTAGE_RATE(InIchPcntOrRate IN IteChg.IchPcntOrRate%TYPE, InDelBaseNettVal IN Delprice.DelBaseNettVal%TYPE, AMOUNT OUT FLOAT) RETURN BOOLEAN AS
    Reqd  BOOLEAN;
  BEGIN
    Reqd := true;
    AMOUNT := ((InDelBaseNettVal * InIchPcntOrRate)/100.00);
    Return Reqd;
  END GET_PERCENTAGE_RATE;
  -- GET_STANDARD_RATE calculates the discount amount when Abs(NVL(DisRates.ThisUnitRate, 0)) > 0.009
  FUNCTION GET_STANDARD_RATE(InIchPcntOrRate IN IteChg.IchPcntOrRate%TYPE, DeliveryDetail IN DELIVERYDETAIL_RECORD, AMOUNT OUT FLOAT) RETURN BOOLEAN AS
    Reqd  BOOLEAN;
    StandardRate  STANDARD_RATE_RECORD;
  BEGIN
    Reqd := true;
    SELECT NVL(PrdAllDescs.AllPStndUnit,0) AllPStndUnit into StandardRate
    FROM PrdRec,
         PrdAllDescs
    WHERE PrdRec.PrcPrdNo = DeliveryDetail.DelPrcPrdNo
    AND PrdRec.PrcRef1  = PrdAllDescs.AllPRefNo;
    -- The Paradox method has the additional line below however using the NVL set to 0 allows us to ignore the exception that may be thrown due to no data returned
    -- If there is no data now then there is a problem with PrdRec.PrcPrdNo = DeliveryDetail.DelPrcPrdNo which we need to know about
    -- AND ABS(NVL(PrdallDescs.AllPStndUnit, 0)) > 0.009;
    AMOUNT := DeliveryDetail.DelPrcQty * InIchPcntOrRate * StandardRate.AllPStndUnit;
    Return Reqd;
  END GET_STANDARD_RATE;
  -- GET_MULTIDISCOUNT where Length(DISCRECS.ThisDedstr) > 1 we need to find which rate each of the multi rates are for
  FUNCTION GET_MULTIDISCOUNT(IN_DRARECNO IN DisRates.DraRecNo%TYPE, IN_SEQNO IN DisRates.ThisSeqNo%TYPE, NEWRATE IN out DISCOUNT_RATE_RECORD) RETURN BOOLEAN AS
  BEGIN
    -- Query the data and place the result in NEWRATE if nothing is returned carry on as doesn't matter setup is wrong
    SELECT
      Case When Abs(NVL(DisRates.ThisRate, 0)) > 0.009 Then DisRates.ThisRate
         When Abs(NVL(DisRates.ThisPercRate, 0)) > 0.009 Then DisRates.ThisPercRate
         When Abs(NVL(DisRates.THISSTNDUNITRATE, 0)) > 0.009 Then DisRates.THISSTNDUNITRATE
         Else 0
         End IchPcntOrRate,  -- 1 = Invoice, 2 Payment, 3 = Retro
      Case When Abs(NVL(DisRates.ThisRate, 0)) > 0.009 Then 1
         When Abs(NVL(DisRates.ThisPercRate, 0)) > 0.009 Then 2
         When Abs(NVL(DisRates.THISSTNDUNITRATE, 0)) > 0.009 Then 3
         End BoxPercUnit -- 1 = Box, 2 = Perc, 3 = StandardUnit
    into NEWRATE
    FROM DisRates
    WHERE DisRates.DraRecNo = IN_DRARECNO
    AND DisRates.ThisSeqNo = IN_SEQNO;
    RETURN true;
  EXCEPTION -- this may be valid as there is no record potentially but this will allow us to continue around the loop
  WHEN NO_DATA_FOUND THEN
    RETURN false;
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
  END GET_MULTIDISCOUNT;
  -- DO_DEDUCTION_STRING_CALC determines if multiple discounts are applicable and calculates the amount accordingly
  FUNCTION DO_DEDUCTION_STRING_CALC(DISCRECS IN DISCOUNT_RATES%ROWTYPE, DeliveryDetail IN DELIVERYDETAIL_RECORD, AMOUNT OUT FLOAT) RETURN BOOLEAN AS
    Reqd      BOOLEAN;
    l_count   binary_integer;
    l_array   dbms_utility.lname_array;
    multiRate DISCOUNT_RATE_RECORD;
    DeductAmount    Float;
  BEGIN
    -- This method is only called When Abs(NVL(DisRates.ThisPercRate, 0)) > 0.009
    Reqd := true;
    -- First need to check the length of DisRates.ThisDedstr if length > 1 then multiple calculations are needed and it gets funky
    IF Length(DISCRECS.ThisDedstr) = 1 then
      -- Easy part
      Reqd := GET_PERCENTAGE_RATE(DISCRECS.IchPcntOrRate,DeliveryDetail.DelBaseNettVal,AMOUNT);
    ELSE
      -- the string should be in the format 0,1,2  etc
      -- first assign the amount to the total
      AMOUNT := DeliveryDetail.DelBaseNettVal;
      -- next need to break the string appart and assign it to an array the function does not work with numbers
      -- so need to prefix the elements with x so use a regular expression
      dbms_utility.comma_to_table
      ( list   => regexp_replace(DISCRECS.ThisDedstr,'(^|,)','\1x')
        , tablen => l_count
        , tab    => l_array
      );
      DeductAmount := 0.00;
      for i in 1 .. l_count loop
        if ABS(DeductAmount) > 0.00 then
          AMOUNT := AMOUNT-DeductAmount;
        End IF;
        DeductAmount := 0.00;
        Reqd := true;
        IF Reqd THEN
          IF GET_MULTIDISCOUNT(DISCRECS.draRecNo, i, multiRate) THEN
            IF multiRate.BoxPercUnit = RATEBYBOX THEN
              Reqd := GET_BOX_RATE(MultiRate.IchPcntOrRate,AMOUNT, DeductAmount);
            ELSIF multiRate.BoxPercUnit = RATEBYPERC THEN
              Reqd := GET_PERCENTAGE_RATE(multiRate.IchPcntOrRate,AMOUNT,DeductAmount);
            ELSIF multiRate.BoxPercUnit = RATEBYSTAND THEN
              Reqd := GET_STANDARD_RATE(multiRate.IchPcntOrRate,DeliveryDetail,DeductAmount);
            Else
              Reqd := False;
            END If;
          END IF;
        END IF;
      end loop;
      -- Reqd may have been set incorrectly on the last iteration so check if Ammount > 0.00 if it isn't we needn't write the record anyway
      if abs(AMOUNT) > 0.00 then
        Reqd := true;
        AMOUNT := AMOUNT * (DISCRECS.IchPcntOrRate/100);
      else
        Reqd := False;
      end if;
    END IF;
    Return Reqd;
  END DO_DEDUCTION_STRING_CALC;
  -- Adds the Audit to be written to the DB to the AUDITRECORD_RECS collection
  PROCEDURE WRITE_AUDITRECORDS(IN_AUDITRECORD_RECS IN OUT AUDITRECORD_RECS, InIchrecNo IN itechg.ichRecNo%Type, InDprrecNo IN DelPrice.DPRRecNo%Type,  auditfrom IN string, auditto IN string ) AS
    CurrUpdates   Integer;
    CurrAuditRecord Auditrecord%RowType;
  BEGIN
    CurrUpdates  := IN_AUDITRECORD_RECS.Count();
    -- If this is a new Itechg this will be null
    CurrAuditRecord.AUDITLINKRECNO1   := InIchrecNo;
    CurrAuditRecord.AUDITTYPENO       := 26;
    CurrAuditRecord.AUDITLINKRECNO2   := InDprrecNo;
    CurrAuditRecord.AUDITCHANGEDFROM  := auditfrom;
    CurrAuditRecord.AUDITCHANGEDTO    := auditto;
    CurrAuditRecord.AuditFormNo       := -1215; -- There is no formno so making it the negative of the Bestfits to distinguish it
    IN_AUDITRECORD_RECS(CurrUpdates) := CurrAuditRecord;

  END WRITE_AUDITRECORDS;

  PROCEDURE WRITE_REBDISCAUDIT(InsertRebDiscAudit IN OUT REBDISCAUDIT_RECS, InIchRecno IN Itechg.Ichrecno%Type, InDprRecNo IN Delprice.DPRRecno%Type, InDraRecNo In DiscPrds.DraRecNo%Type,
                                InCtyNo In Itechg.CtyNo%Type, InAuditFrom In String, InAuditTo In String, InDPRQty In Delprice.DELPRCQTY%Type, InIchPcntOrRate In integer,
                                InBoxPercUnit IN integer, InDiscDedStr In IchDiscTyp.DiscDedStr%Type, InThisOn IN DisRates.ThisOn%Type, InIchRealDisType In Itechg.IchRealDisType%Type,
                                InAuditType IN RebDiscAudit.RDAuditTyp%Type) As
    CurrUpdates   Integer;
    CurrAuditRecord RebDiscAudit%RowType;
  BEGIN
    CurrUpdates := InsertRebDiscAudit.Count();
    CurrAuditRecord.RDAuditIteChgRecNo  := InIchRecno;
    CurrAuditRecord.RDAuditDprRecNo     := InDprRecNo;
    CurrAuditRecord.RDAuditDraRecNo     := InDraRecNo;
    CurrAuditRecord.RDAuditTyp          := InAuditType;
    CurrAuditRecord.RDAuditRebDisc      := InCtyNo;
    CurrAuditRecord.RDAuditFrom         := InAuditFrom;
    CurrAuditRecord.RDAuditTo           := InAuditTo;
    CurrAuditRecord.RDAuditAmt          := 0; -- this is how it is written in the library
    CurrAuditRecord.RDAuditQty          := InDPRQty;
    CurrAuditRecord.RDAuditRate         := InIchPcntOrRate;
    CurrAuditRecord.RDAuditStdUnit      := 0; -- this is how it is written in the library
    CurrAuditRecord.RDAuditBoxPercUnit  := InBoxPercUnit;
    CurrAuditRecord.RDAuditThisDedStr   := InDiscDedStr;
    CurrAuditRecord.RDAuditThisOn       := InThisOn;
    CurrAuditRecord.RDAuditThisSeqNo    := InIchRealDisType;
    CurrAuditRecord.RDAuditFormNo       := -1215; -- There is no formno so making it the negative of the Bestfits to distinguish it
    InsertRebDiscAudit(CurrUpdates) := CurrAuditRecord;
  END WRITE_REBDISCAUDIT;


  PROCEDURE WRITE_DELAUDIT(InDelAudit_Recs IN OUT DELAUDIT_RECS,audtype DelAudit.DelAudTyp%Type, AudFrom In DelAudit.DelAudFrom%Type, AudTo In DelAudit.DelAudTo%Type,
                            InDelRecNo in DelDet.Delrecno%Type, InDPRRecNo IN DelPrice.DPRRecno%Type) as
    DelAudit_Rec    DelAudit%ROWTYPE;
    DelAuds         Integer;
  BEGIN
    DelAuds := InDelAudit_Recs.Count();
    DelAudit_Rec.DelAudDelRecNo := InDelRecNo;
    DelAudit_Rec.DprRecNo := InDPRRecNo;
    DelAudit_Rec.DprToAction := 1;
    DelAudit_Rec.DelAudTyp := audType;
    DelAudit_Rec.DelAudFrom := AudFrom;
    DelAudit_Rec.DelAudTo := AudTo;
    DelAudit_Rec.FormNo := -1215; -- There is no formno so making it the negative of the Bestfits to distinguish it
    InDelAudit_Recs(DelAuds) := DelAudit_Rec;
  END WRITE_DELAUDIT;
  -- FIND_ITECHG checks if the itechg exists and adds it to the table for updating the db
  FUNCTION FIND_ITECHG(ThisOnSi IN DisRates.ThisOn%TYPE, inSeqNo IN DisRates.ThisSeqNo%Type, DeliveryDetail IN DELIVERYDETAIL_RECORD,
                        InIchPcntOrRate IN Itechg.IchPcntOrRate%type, Amount IN float, IteChgUpdates IN OUT ITECHG_RECS, InsertAuditrecs IN OUT AUDITRECORD_RECS,
                        InsertRebDiscAudit IN OUT REBDISCAUDIT_RECS, InBoxPercUnit In Integer, InDraRecNo In DiscPrds.DraRecNo%type, InDiscDedStr IN IchDiscTyp.DiscDedStr%type,
                        InDelAudit_Recs IN OUT DELAUDIT_RECS) RETURN Boolean AS
    ctyNoToUse    Itechg.CtyNo%Type;
    Itechg_Rec    Itechg%ROWTYPE;
    CurrUpdates   Integer;
    OldIchAppAmt  Itechg.IchAppAmt%type;
    delaudtype       DelAudit.DelAudTyp%Type;
    UseRDAuditTyp RebDiscAudit.RDAuditTyp%Type;
  BEGIN
    CurrUpdates := IteChgUpdates.Count();
    if ThisOnSi = 1
    then
      ctyNoToUse := CTYDISCOUNT ; -- Discount
      delaudtype := AUDTYPDISCOUNT;
      UseRDAuditTyp := AUDTYPDISCOUNT;
    else
      ctyNoToUse := CTYREBATE ; -- Rebate
      delaudtype := AUDTYPREBATE;
      UseRDAuditTyp := AUDTYPREBATE;
    end If;
    SELECT IteChg.* into Itechg_Rec
    FROM IteChg
    WHERE IteChg.DprRecNo   = DeliveryDetail.DprRecNo
    AND IteChg.CtyNo      = ctyNoToUse
    AND IteChg.IchDisType = inSeqNo;
    -- If this exists update it and add it to the UPDATE ITECHG_RECS
    OldIchAppAmt := Itechg_Rec.IchAppAmt;
    Itechg_Rec.IchAppAmt := Amount;
    Itechg_Rec.IchPcntOrRate := InIchPcntOrRate;
    IteChgUpdates.EXTEND(1);
    CurrUpdates := CurrUpdates +1;
    IteChgUpdates(CurrUpdates) := Itechg_Rec;
    InsertAuditrecs.EXTEND(1);
    -- add the rebate auditRecord to the collection
    WRITE_AUDITRECORDS(InsertAuditrecs, Itechg_Rec.IchRecNo, DeliveryDetail.DprRecNo,TO_CHAR(OldIchAppAmt),TO_CHAR(Amount));
    InsertRebDiscAudit.EXTEND(1);
    -- add the rebate audit to the collection
    WRITE_REBDISCAUDIT(InsertRebDiscAudit, Itechg_Rec.IchRecNo,Itechg_Rec.DprRecNo, InDraRecNo,Itechg_Rec.ctyNo, TO_CHAR(OldIchAppAmt), TO_CHAR(Amount),
                        DeliveryDetail.DelPrcQty, InIchPcntOrRate,InBoxPercUnit, InDiscDedStr,ThisOnSi,Itechg_Rec.IchRealDisType, UseRDAuditTyp);
    InDelAudit_Recs.EXTEND(1);
    -- add the delivery Audits
    WRITE_DELAUDIT(InDelAudit_Recs, delaudtype,TO_CHAR(OldIchAppAmt), TO_CHAR(Amount),DeliveryDetail.DelRecNo, DeliveryDetail.DprRecNo);
    RETURN True;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN false;
  END FIND_ITECHG;
  -- WRITE_ITECHG creates a new itechg record and adds it to the table for inserting into the db
  PROCEDURE WRITE_ITECHG(ThisOnSi IN DisRates.ThisOn%TYPE,ThisSeqNo In Itechg.IchDisType%type, InIchPcntOrRate IN itechg.IchPcntOrRate%type,
                    InIchRealDisType IN itechg.IchRealDisType%type, InDiscDedStr IN IchDiscTyp.DiscDedStr%type, InDiscGrpGlRecNo IN IchDiscTyp.DiscGrpGlRecNo%Type,
                    DeliveryDetail IN DELIVERYDETAIL_RECORD,Amount IN float, IteChgInsert IN OUT ITECHG_RECS, IchDisTypInsert IN OUT ICHDISCTYP_RECS,
                    InsertAuditrecs_New IN OUT AUDITRECORD_RECS, InsertRebDiscAudit_New IN OUT REBDISCAUDIT_RECS, InBoxPercUnit IN integer,
                    InDraRecNo In DiscPrds.DraRecNo%type, InDelAudit_Recs IN OUT DELAUDIT_RECS)  AS
    CurrChgs      integer;
    CurrTypes     integer;
    ctyNoToUse    Itechg.CtyNo%Type;
    Itechg_Rec    Itechg%ROWTYPE;
    IchDisTyp_Rec IchDiscTyp%ROWTYPE;
    ThisOnSiFlg   integer;
    UseRDAuditTyp RebDiscAudit.RDAuditTyp%Type;
    delaudtype       DelAudit.DelAudTyp%Type;
  BEGIN
    CurrChgs := IteChgInsert.Count();
    CurrTypes := IchDisTypInsert.Count();

    if ThisOnSi = 1
    then
      ctyNoToUse        := CTYDISCOUNT ; -- Discount
      UseRDAuditTyp     := AUDTYPDISCOUNT;
      delaudtype := AUDTYPDISCOUNT;
    else
      ctyNoToUse        := CTYREBATE ; -- Rebate
      UseRDAuditTyp     := AUDTYPREBATE;
      delaudtype := AUDTYPREBATE;
    end If;

    if InIchRealDisType = 2 or InIchRealDisType = 102
    then
      ThisOnSiFlg := 1;
    else
      ThisOnSiFlg := 0;
    end If;
    --Itechg_Rec.IchRecNo := 0;
    Itechg_Rec.DprRecNo := DeliveryDetail.DprRecNo;
    Itechg_Rec.CtyNo := ctyNoToUse;
    Itechg_Rec.IchAppAmt := Amount;
    Itechg_Rec.IchAuthAmm := 0.00;
    Itechg_Rec.IchAppFac := 1;
    Itechg_Rec.IchChaCalc := 1;
    Itechg_Rec.IchDisType := ThisSeqNo;
    Itechg_Rec.IchPcntOrRate := InIchPcntOrRate;
    Itechg_Rec.IchRealDisType := InIchRealDisType;
    Itechg_Rec.IchOnPayment := ThisOnSiFlg;
    IteChgInsert.EXTEND(1);
    CurrChgs := CurrChgs +1;
    IteChgInsert(CurrChgs) := Itechg_Rec;

    --IchDisTyp_Rec.IchRecNo := 0;
    IchDisTyp_Rec.DiscDedStr := InDiscDedStr;
    IchDisTyp_Rec.DiscGrpGlRecNo := InDiscGrpGlRecNo;
    CurrTypes := CurrTypes +1;
    IchDisTypInsert.EXTEND(1);
    IchDisTypInsert(CurrTypes) := IchDisTyp_Rec;
    -- Do the Auditrecords these will be the same position as the itechg so the
    -- link to itechg can be added when it is known
    InsertAuditrecs_New.EXTEND(1);
    WRITE_AUDITRECORDS(InsertAuditrecs_New, Itechg_Rec.IchRecNo, DeliveryDetail.DprRecNo,'0.00',TO_CHAR(Amount));
     -- Do the RebDiscAudit these will be the same position as the itechg so the
    -- link to itechg can be added when it is known
    InsertRebDiscAudit_New.Extend(1);
    WRITE_REBDISCAUDIT(InsertRebDiscAudit_New, Itechg_Rec.IchRecNo,Itechg_Rec.DprRecNo, InDraRecNo,ctyNoToUse, '0.00', TO_CHAR(Amount),
                        DeliveryDetail.DelPrcQty, InIchPcntOrRate,InBoxPercUnit, InDiscDedStr,ThisOnSiFlg,InIchRealDisType, UseRDAuditTyp);
    InDelAudit_Recs.EXTEND(1);
    -- add the delivery Audits
    WRITE_DELAUDIT(InDelAudit_Recs, delaudtype,'0.00', TO_CHAR(Amount),DeliveryDetail.DelRecNo, DeliveryDetail.DprRecNo);

  END WRITE_ITECHG;
  -- UPDATE an existing ITECHG
  PROCEDURE UPDATE_ITECHG(IN_ICHRECNO IN ITECHG.ICHRECNO%TYPE, IN_ICHAPPAMT IN ITECHG.ICHAPPAMT%TYPE, IN_ICHPCNTORRATE IN ITECHG.ICHPCNTORRATE%TYPE) AS
  BEGIN
    UPDATE IteChg
    SET IteChg.IchAppAmt = IN_ICHAPPAMT, IteChg.IchPcntOrRate = IN_ICHPCNTORRATE
    WHERE IteChg.IchRecNo = IN_ICHRECNO;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FT_PK_ERRORS.LOG_AND_STOP;
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
  END UPDATE_ITECHG;
  -- Used to get the delivery details ORDERS,DELHED,DELDET,DELPRICE
  PROCEDURE GET_DELIVERYDETAILS(DLV_DET OUT DELIVERYDETAIL_RECORD, IN_DPRRECNO IN DELPRICE.DPRRECNO%TYPE) AS
  BEGIN
    Select DelDet.DelPrcPrdNo, DelDet.DelRecNo, Orders.ActCstCode, Delhed.DlvStkLoc, Delhed.DlvDelDate, Delhed.DlvSalOffNo,
      NVL(Delprice.DprIsPriceAdjOnly, 0) as DprIsPriceAdjOnly, DelPrice.DELFREEOFCHG, NVL(Delprice.DelBaseNettVal, 0) DelBaseNettVal,
      DelPrice.DelPrcQty, DelDet.DelQtyPer, DelPrice.DelInvStatus, DelPrice.DprRecNo, DelPrice.DelPrice
      into DLV_DET
      From DelPrice
      Inner Join DelDet on DelPrice.DprDelRecNo = DelDet.DelRecNo
      Inner Join DelHed on DelDet.DelDlvOrdNo = DelHed.DlvOrdNo
      Inner Join  Orders on DelHed.DlvOrdRecNo = Orders.OrdRecNo
      Where DelPrice.DprRecNo = IN_DPRRECNO;
  END GET_DELIVERYDETAILS;

  -- DO_DISCOUNTS this is the public method that should be called replaces :LIB:BESTFITS:GetDiscRebsOneDpr
  PROCEDURE DO_DISCOUNTS1(IN_DPRRECNO IN DELPRICE.DPRRECNO%TYPE) AS
    DeliveryDetail          DELIVERYDETAIL_RECORD;
    DiscountRates           DISCOUNT_RECS;
    DRARECNO                DiscPrds.DraRecNo%type;
    ReqdRec                 Boolean;
    IchAppAmt               IteChg.IchAppAmt%TYPE;
    UpdateIteChg_Recs       ITECHG_RECS := ITECHG_RECS();
    InsertIteChg_Recs       ITECHG_RECS := ITECHG_RECS();
    InsertIchDiscTyp_recs   ICHDISCTYP_RECS := ICHDISCTYP_RECS();
    RealDisType             Itechg.IchRealDisType%Type;
    InsertRebDiscAudit_New  REBDISCAUDIT_RECS := REBDISCAUDIT_RECS();
    InsertRebDiscAudit_Upd  REBDISCAUDIT_RECS := REBDISCAUDIT_RECS();
    InsertDelAudit_Recs     DELAUDIT_RECS :=  DELAUDIT_RECS();
    InsertAuditrecs_New     AUDITRECORD_RECS := AUDITRECORD_RECS();
    InsertAuditrecs_Upd     AUDITRECORD_RECS := AUDITRECORD_RECS();
  BEGIN
    IchAppAmt := 0.00;
    ReqdRec := false;
    IF IN_DPRRECNO > 0 THEN
      GET_DELIVERYDETAILS(DeliveryDetail,IN_DPRRECNO);
      -- Use the DeliveryDetail record to find the best fit
      DRARECNO := FIND_BEST_DISCOUNT(DeliveryDetail);
      -- The line bellow is not in the Paradox method however we should not be writing/updating itechg if the delivery is invoiced
      if DeliveryDetail.DelInvStatus < 10 then
        IF DRARECNO > 0 THEN
          DiscountRates := GET_DISCOUNTRATE(DRARECNO);
          -- Multi PK for DisRates is DraRecNo && ThisSeqNo so may have multiples need to loop
          FOR Rate in 1.. DiscountRates.Count LOOP
            ReqdRec := true;
            IchAppAmt := 0.00;
            IF not DeliveryDetail.DELQTYPER = 1 THEN
              ReqdRec := False;
            ELSE
              IF ABS(DeliveryDetail.Price) < 0.009 THEN  -- if 0.00 then check if the delivery is FOC and the Rate is applicable
                IF NOT ((DeliveryDetail.DELFREEOFCHG = 1) AND (DiscountRates(Rate).ApplyRebsToFoc = 1)) then
                  ReqdRec := False;
                END IF;
              END IF;
            END IF;
            IF ReqdRec THEN
              IF DiscountRates(Rate).BoxPercUnit = RATEBYBOX THEN
                ReqdRec := GET_BOX_RATE(DiscountRates(Rate).IchPcntOrRate, DeliveryDetail.DelPrcQty,IchAppAmt);
              ELSIF DiscountRates(Rate).BoxPercUnit = RATEBYPERC THEN
                IF Length(TRIM(DiscountRates(Rate).ThisDedstr)) = 1 then
                  -- Easy part
                  ReqdRec := GET_PERCENTAGE_RATE(DiscountRates(Rate).IchPcntOrRate,DeliveryDetail.DelBaseNettVal,IchAppAmt);
                ELSE
                  ReqdRec := DO_DEDUCTION_STRING_CALC(DiscountRates(Rate), DeliveryDetail, IchAppAmt);
                END IF;
              ELSIF DiscountRates(Rate).BoxPercUnit = RATEBYSTAND THEN
                ReqdRec := GET_STANDARD_RATE(DiscountRates(Rate).IchPcntOrRate,DeliveryDetail,IchAppAmt);
              Else
                ReqdRec := False;
              END If; -- DiscountRates(Rate).BoxPercUnit Switch
            END IF;
            IF ReqdRec then
              IchAppAmt := ROUND(IchAppAmt,2);
              -- Need to write or update the IteChg Record now
              IF NOT FIND_ITECHG(DiscountRates(Rate).ThisOn, DiscountRates(Rate).ThisSeqNo,DeliveryDetail,DiscountRates(Rate).IchPcntOrRate,
                                    IchAppAmt,UpdateIteChg_Recs,InsertAuditrecs_Upd,InsertRebDiscAudit_Upd,DiscountRates(Rate).BoxPercUnit,DRARECNO,
                                    DiscountRates(Rate).ThisDedstr, InsertDelAudit_Recs) then
                -- No need to write an itechg that has a zero value
                IF (abs(IchAppAmt) > 0.009) THEN
                  RealDisType := ((DiscountRates(Rate).BoxPercUnit - 1) *100) + DiscountRates(Rate).ThisOn;
                  WRITE_ITECHG(DiscountRates(Rate).ThisOn,DiscountRates(Rate).ThisSeqNo, DiscountRates(Rate).IchPcntOrRate,
                              RealDisType,DiscountRates(Rate).ThisDedstr, DiscountRates(Rate).DisGlRecNo,
                              DeliveryDetail,IchAppAmt,InsertIteChg_Recs,InsertIchDiscTyp_recs,
                              InsertAuditrecs_New, InsertRebDiscAudit_New, DiscountRates(Rate).BoxPercUnit, DRARECNO,InsertDelAudit_Recs);
                END IF; -- abs(IchAppAmt) > 0.009
              END IF; -- NOT FIND_ITECHG
            END If; -- ReqdRec
          END LOOP; -- Rate in 1.. DiscountRates.Count
        END IF;  -- DRARECNO > 0
      END IF;  -- DeliveryDetail.DelInvStatus < 10
    END IF; -- IN_DPRRECNO > 0
    -- need to write the itechg records and the audits here FT_PK_COST_WRITES
    -- do the insert Itechg records first
    IF InsertIteChg_Recs.Count > 0 THEN
      FOR i in 1.. InsertIteChg_Recs.Count LOOP
        FT_PK_COST_WRITES.INSERT_DISCOUNT_ITECHG(InsertIteChg_Recs(i),InsertIchDiscTyp_recs(i));
        -- Now do the audits but first need to assign the ichrecno
        InsertAuditrecs_New(i).AUDITLINKRECNO1 := InsertIteChg_Recs(i).IchRecNo;
        InsertRebDiscAudit_New(i).RDAuditIteChgRecNo := InsertIteChg_Recs(i).IchRecNo;
        FT_PK_COST_WRITES.INSERT_AUDITRECORD(InsertAuditrecs_New(i));
        FT_PK_COST_WRITES.INSERT_REBDISCAUDIT_RECORD(InsertRebDiscAudit_New(i));
      END LOOP;
    END IF;
      -- Now do the Update records
    IF  UpdateIteChg_Recs.Count > 0 THEN
      FOR i in 1.. UpdateIteChg_Recs.Count LOOP
        FT_PK_COST_WRITES.UPDATE_DISCOUNT_ITECHG(UpdateIteChg_Recs(i));
        FT_PK_COST_WRITES.INSERT_AUDITRECORD(InsertAuditrecs_Upd(i));
        FT_PK_COST_WRITES.INSERT_REBDISCAUDIT_RECORD(InsertRebDiscAudit_Upd(i));
      END LOOP;
    END IF;
    IF InsertDelAudit_Recs.Count > 0 THEN
      -- now write the DelAudits
      FOR i in 1.. InsertDelAudit_Recs.Count LOOP
        FT_PK_COST_WRITES.INSERT_DELAUDIT_RECORD(InsertDelAudit_Recs(i));
      END LOOP;
    END IF;
    COMMIT;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FT_PK_ERRORS.LOG_AND_STOP;
    ROLLBACK;
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
    ROLLBACK;
  END DO_DISCOUNTS1;
  -- Find the Original DELPRICE record from the discount DPRRECNO
  FUNCTION GETDELTOCREDITDPR(IN_DPRRECNO IN DELPRICE.DPRRECNO%TYPE) RETURN DELPRICE.DPRRECNO%TYPE AS
    ORGDPR          DELPRICE.DPRRECNO%TYPE;
    DELTOCDT_REC    DELTOCDT_RECORD;
  BEGIN
    ORGDPR := -1;
    IF (IN_DPRRECNO > 0) THEN
      BEGIN
        SELECT OrgDprRecNo INTO DELTOCDT_REC
        FROM DelToCdt
        WHERE DelToCdt.CdtDprRecNo = IN_DPRRECNO;
        ORGDPR := DELTOCDT_REC.OrgDprRecNo;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Carry on this isn't a real Exception
        null;
      WHEN OTHERS THEN
        FT_PK_ERRORS.LOG_AND_STOP;
      END;
    END IF;
    RETURN ORGDPR;
  END GETDELTOCREDITDPR;

  PROCEDURE CHANGE_ITECHG(OldDeliveryDetail DELIVERYDETAIL_RECORD, NewDeliveryDetail DELIVERYDETAIL_RECORD) as
    NewIteChg       ITECHG_RECORD;
    ReqdRec         Boolean;
    NewIchAppAmt    IteChg.IchAppAmt%TYPE;
    OldIchAppAmt    IteChg.IchAppAmt%TYPE;
    BoxPercUnit     Number(1);
    ThisOn          DisRates.ThisOn%TYPE;
    UpdateIteChg_Recs       ITECHG_RECS := ITECHG_RECS();
    InsertIteChg_Recs       ITECHG_RECS := ITECHG_RECS();
    InsertIchDiscTyp_recs   ICHDISCTYP_RECS := ICHDISCTYP_RECS();
    InsertRebDiscAudit_recs REBDISCAUDIT_RECS := REBDISCAUDIT_RECS();
    InsertRebDiscAudit_New  REBDISCAUDIT_RECS := REBDISCAUDIT_RECS();
    InsertRebDiscAudit_Upd  REBDISCAUDIT_RECS := REBDISCAUDIT_RECS();
    InsertDelAudit_Recs     DELAUDIT_RECS :=  DELAUDIT_RECS();
    InsertAuditrecs_New     AUDITRECORD_RECS := AUDITRECORD_RECS();
    InsertAuditrecs_Upd     AUDITRECORD_RECS := AUDITRECORD_RECS();
  BEGIN

    FOR ITECHG IN DISCOUNT_ITECHG(OldDeliveryDetail.DPRRECNO) LOOP
      ReqdRec := true;
      NewIchAppAmt := 0.00;
      OldIchAppAmt := 0.00;
      IF NewDeliveryDetail.DPRISPRICEADJONLY > 0 then
        -- Check that this is for a Percentage discount
        IF ITECHG.IchDisType < ITEBOXDISC or ITECHG.IchDisType > ITESTDUNITDISC THEN
          ReqdRec := false;
        END IF;
      END IF;
      IF ReqdRec THEN
        -- Check that this is for a Percentage discount
        IF ITECHG.IchDisType < ITEBOXDISC or ITECHG.IchDisType > ITESTDUNITDISC THEN
          IF OldDeliveryDetail.DELPRCQTY = NewDeliveryDetail.DELPRCQTY THEN
            NewIchAppAmt := ITECHG.ICHAPPAMT;
          ELSE
            IF OldDeliveryDetail.DELPRCQTY <> 0 THEN
              NewIchAppAmt  := Round((ITECHG.ICHAPPAMT/OldDeliveryDetail.DELPRCQTY) * NewDeliveryDetail.DELPRCQTY,2);
            END IF;
            IF ITECHG.IchRealDisType < ITEBOXDISC then
              BoxPercUnit := RATEBYBOX;
            ELSE
              BoxPercUnit := RATEBYSTAND;
            END IF;
          END IF;
        ELSE
          -- This is a Percentage Discount
          IF OldDeliveryDetail.DelBaseNettVal <> 0.00 then
            NewIchAppAmt  := Round((ITECHG.ICHAPPAMT/OldDeliveryDetail.DelBaseNettVal) * NewDeliveryDetail.DelBaseNettVal,2);
          END IF;
          BoxPercUnit := RATEBYPERC;
        END IF;
      END IF;
      -- Now need to insert/update the itechg
      IF ReqdRec THEN
      Begin
        IF ITECHG.ctyno = CTYDISCOUNT THEN
          ThisOn := 1;
        ELSE
          ThisOn := 2;
        END IF;
        IF NOT FIND_ITECHG(ThisOn, ITECHG.IchDisType,NewDeliveryDetail,ITECHG.IchPcntOrRate,NewIchAppAmt,
                            UpdateIteChg_Recs, InsertAuditrecs_Upd, InsertRebDiscAudit_Upd,BoxPercUnit,
                            IteChg.DiscGrpGlRecNo,Itechg.DiscDedStr, InsertDelAudit_Recs) then
          -- No need to write an itechg that has a zero value
          IF (abs(NewIchAppAmt) > 0.009) THEN
            -- The second DiscGrpGlRecNo here is for the RebDiscAudit.RDAuditDraRecNo this is the way the library assigns it?
            WRITE_ITECHG(ThisOn,ITECHG.IchDisType, ITECHG.IchPcntOrRate,
                        Itechg.IchRealDisType,Itechg.DiscDedStr,Itechg.DiscGrpGlRecNo,
                        NewDeliveryDetail,NewIchAppAmt,InsertIteChg_Recs, InsertIchDiscTyp_recs,
                        InsertAuditrecs_New, InsertRebDiscAudit_New, BoxPercUnit,IteChg.DiscGrpGlRecNo, InsertDelAudit_Recs);
          END IF;
        END IF;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        FT_PK_ERRORS.LOG_AND_STOP;
      WHEN OTHERS THEN
        FT_PK_ERRORS.LOG_AND_STOP;
      END;
      END IF;
    END LOOP;
    IF InsertIteChg_Recs.Count > 0 THEN
      FOR i in 1.. InsertIteChg_Recs.Count LOOP
        FT_PK_COST_WRITES.INSERT_DISCOUNT_ITECHG(InsertIteChg_Recs(i),InsertIchDiscTyp_recs(i));
        -- Now do the audits but first need to assign the ichrecno
        InsertAuditrecs_New(i).AUDITLINKRECNO1 := InsertIteChg_Recs(i).IchRecNo;
        InsertRebDiscAudit_New(i).RDAuditIteChgRecNo := InsertIteChg_Recs(i).IchRecNo;
        FT_PK_COST_WRITES.INSERT_AUDITRECORD(InsertAuditrecs_New(i));
        FT_PK_COST_WRITES.INSERT_REBDISCAUDIT_RECORD(InsertRebDiscAudit_New(i));
      END LOOP;
    END IF;
    IF UpdateIteChg_Recs.Count > 0 THEN
      -- Now do the Update records
      FOR i in 1.. UpdateIteChg_Recs.Count LOOP
        FT_PK_COST_WRITES.UPDATE_DISCOUNT_ITECHG(UpdateIteChg_Recs(i));
        FT_PK_COST_WRITES.INSERT_AUDITRECORD(InsertAuditrecs_Upd(i));
        FT_PK_COST_WRITES.INSERT_REBDISCAUDIT_RECORD(InsertRebDiscAudit_Upd(i));
      END LOOP;
      -- now write the DelAudits
      FOR i in 1.. InsertDelAudit_Recs.Count LOOP
        FT_PK_COST_WRITES.INSERT_DELAUDIT_RECORD(InsertDelAudit_Recs(i));
      END LOOP;
    END IF;
    COMMIT;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FT_PK_ERRORS.LOG_AND_STOP;
    ROLLBACK;
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
    ROLLBACK;
  END CHANGE_ITECHG;

  -- DO_DISCOUNTS this is the public method that should be called replaces :LIB:BESTFITS:GetDiscRebsOneDprStkCdtDbtAdj
  PROCEDURE DO_DISCOUNTS_STKCDTDBT_ADJ(IN_DPRRECNO IN DELPRICE.DPRRECNO%TYPE) AS
    OldDeliveryDetail       DELIVERYDETAIL_RECORD;
    NewDeliveryDetail       DELIVERYDETAIL_RECORD;
    IchAppAmt               IteChg.IchAppAmt%TYPE;
    OrgDPRRECNO             DELPRICE.DPRRECNO%TYPE;
  BEGIN
    OrgDPRRECNO := GETDELTOCREDITDPR(IN_DPRRECNO);
    IchAppAmt := 0.00;
    IF OrgDPRRECNO > 0 THEN
      GET_DELIVERYDETAILS(OldDeliveryDetail,OrgDPRRECNO);
      GET_DELIVERYDETAILS(NewDeliveryDetail,IN_DPRRECNO);
      CHANGE_ITECHG(OldDeliveryDetail, NewDeliveryDetail);
    END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    FT_PK_ERRORS.LOG_AND_STOP;
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
  END DO_DISCOUNTS_STKCDTDBT_ADJ;
  
 -- DO_DISCOUNTS this is the public method that should be called replaces :LIB:BESTFITS:GetDiscRebsOneDpr
  PROCEDURE DO_DISCOUNTS(IN_DPRRECNO IN DELPRICE.DPRRECNO%TYPE) AS
    DelToCdtCount   COUNT_DelToCdt;
  BEGIN
    SELECT count(*) noof into DelToCdtCount
    FROM DelPrice, DelToCdt
    WHERE DelPrice.DprRecNo = 5761608
    AND DelPrice.DprRecNo = DelToCdt.CdtDprRecNo;
    
    if DelToCdtCount.NoOf > 0
    then
      DO_DISCOUNTS_STKCDTDBT_ADJ(IN_DPRRECNO);
    else
      DO_DISCOUNTS1(IN_DPRRECNO);
    end if;
    
  END DO_DISCOUNTS;

END FT_PK_DISCOUNTS;
/
