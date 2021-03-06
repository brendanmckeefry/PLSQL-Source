--########################################################################################################
-- FT_V_DLV (View)
-- 
-- Developer view to display sales order details
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE FORCE VIEW FT_V_DLV
(
   ORDRECNO,
   ACTCSTCODE,
   ORDSMNNO,
   ORDCUSTORDNO,
   DLVORDNO,
   DLVSHPDATE,
   DLVDELDATE,
   DLVRELINV,
   DLVSALTYP,
   DLVDLTRECNO,
   DLVSTKLOC,
   DLVSALOFFNO,
   DELRECNO,
   DELQTY,
   DELWEIGHT,
   DELCLTPRDNO,
   DELQTYPER,
   DELPRICEPER,
   DELNETTWEIGHT,
   DELPRCPRDNO,
   PRCREF1,
   PRCREF2,
   PRCREF3,
   PRCREF4,
   PRCREF5,
   PRCREF6,
   DELSMNNO,
   DELSTKSTATUS,
   DPRRECNO,
   DELPRCQTY,
   DELPRICE,
   DELFREEOFCHG,
   DELPRCWEIGHT,
   DELNETTVALUE,
   DELVATVALUE,
   DELTOBASERATE,
   DELBASENETTVAL,
   DELBASEVATVALUE,
   DELTOEURORATE,
   DELEURONETTVAL,
   DELEUROVATVALUE,
   DELINVSTATUS,
   DELVATRECNO,
   DELVATRATE,
   DELVATRATE2,
   DPRCREATIONDATE,
   DPRISPRICEADJONLY,
   ADJBY,
   DELINVRECNO
)
AS
   SELECT orders.OrdRecNo,
          orders.ActCstCode,
          orders.OrdSmnNo,
          orders.OrdCustOrdNo,
          delhed.DlvOrdNo,
          delhed.DlvShpDate,
          delhed.DlvDelDate,
          delhed.DlvRelInv,
          delhed.DlvSalTyp,
          delhed.DlvDltRecNo,
          delhed.DlvStkLoc,
          delhed.DlvSalOffNo,
          deldet.DelRecNo,
          deldet.DelQty,
          deldet.DelWeight,
          deldet.DelCltPrdNo,
          deldet.DelQtyPer,
          deldet.DelPricePer,
          deldet.DelNettWeight,
          deldet.DelPrcPrdNo,
          prdrec.PrcRef1,
          prdrec.PrcRef2,
          prdrec.PrcRef3,
          prdrec.PrcRef4,
          prdrec.PrcRef5,
          prdrec.PrcRef6,
          deldet.DelSmnNo,
          deldet.DelStkStatus,
          delprice.DprRecNo,
          delprice.DelPrcQty,
          delprice.DelPrice,
          delprice.DelFreeOfChg,
          delprice.DelPrcWeight,
          delprice.DelNettValue,
          delprice.DelVatValue,
          delprice.DelToBaseRate,
          delprice.DelBaseNettVal,
          delprice.DelBaseVatValue,
          delprice.DelToEuroRate,
          delprice.DelEuroNettVal,
          delprice.DelEuroVatValue,
          delprice.DelInvStatus,
          delprice.DelVatRecNo,
          delprice.DelVatRate,
          delprice.DelVatRate2,
          delprice.DprCreationDate,
          delprice.DprIsPriceAdjOnly,
          delprice.AdjBy,
          delprice.DelInvRecNo
     FROM ORDERS
          INNER JOIN DELHED
             ON delhed.DlvOrdRecNo = orders.OrdRecNo
          INNER JOIN DELDET
             ON deldet.DelDlvOrdNo = delhed.DlvOrdNo
          INNER JOIN DELPRICE
             ON delprice.DprDelRecNo = deldet.DelRecNo
          INNER JOIN PRDREC
             ON prdrec.PrcPrdNo = deldet.DelPrcPrdNo
   WITH READ ONLY;
