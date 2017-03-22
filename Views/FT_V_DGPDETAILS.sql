CREATE OR REPLACE FORCE VIEW "FT_V_DGPDETAILS" ("DGP_EXTRACTION_DATE", "TRANSACTION_NUMBER", "DELIVERY_DATE", "SALES_OFFICE_NUMBER", "DELIVERY_NUMBER", 
"TICKET_NUMBER", "INVOICE_NUMBER", "CUSTOMER_NUMBER", "SUPPLIER_NUMBER", "PRODUCT_NUMBER", "SOLD_PRODUCT_NUMBER","STOCK_DEPT_NUMBER", "PO_NUMBER", "LOT_NUMBER", 
"LOT_LINE_NUMBER", "LOT_PURCHASE_TYPE", "SALESMAN_NUMBER", "PACKS_MOVE", "GROSS_SALEVALUE_MOVE", "REBATE_MOVE", "DISCOUNT_MOVE", "OTHER_SALESCOST_MOVE", 
"DELIVERED_GOODS_COST", "NEW_TRANSACTION_FLAG", "DELQTYPER", "SALES_PACKS_MOVE", "DELRECNO", "PRICE_LIST_PRICE", "DELIVERY_TYPE", "DELIVERY_TYPE_DESC")
AS
SELECT DGPhead.DGPEXTRACTDATE DGP_Extraction_Date ,
    DGPDetails.DGPDETRECNO Transaction_Number ,
    DGPDetails.DGPDLVDATE Delivery_Date ,
    DGPhead.DGPSALOFFNO Sales_Office_Number ,
    DGPDetails.DGPDLVNO Delivery_Number,
    TNTNO Ticket_Number,
    AtrRef Invoice_Number,
    DGPDetails.DGPCLARECNO Customer_Number ,
    Lotite.LitSenCode Supplier_Number ,
    DGPPRDNO Product_Number,
    DGPISTPRDNO Sold_Product_Number,	
    (SELECT DPTRECNO
    FROM DEPARTMENTSTOSMN
    WHERE Lotite.LitBuyer = DEPARTMENTSTOSMN.SMNNO
    ) Stock_Dept_Number ,
    PorNo PO_Number ,
    Lothed.LHERECNO Lot_Number ,
    Lotite.LITID Lot_Line_Number ,
    NVL(LITPAYTYP, LHEPAYTYP) Lot_Purchase_Type ,
    Orders.ORDSMNNO Salesman_Number ,
    CASE
      WHEN ABS(NVL(DGPCLOSFINDECQTY,0) - NVL(DGPOPENFINDECQTY,0)) > 0.009
      THEN NVL(DGPCLOSFINDECQTY,0)     - NVL(DGPOPENFINDECQTY,0)
      ELSE NVL(DGPCLOSEFINQTY,0)       - NVL(DGPOPENFINQTY,0)
    END Packs_Move ,
    NVL(DGPCLOSEDELAMM,0)  - NVL(DGPOPENDELAMM,0) Gross_SaleValue_Move ,
    NVL(DGPCLOSEONDISC,0)  - NVL(DGPOPENONDISC,0) Rebate_Move ,
    NVL(DGPCLOSEOFFDISC,0) - NVL(DGPOPENOFFDISC,0) Discount_Move ,
    NVL(DGPCLOSEOTHERS,0)  - NVL(DGPOPENOTHERS,0) Other_SalesCost_Move ,
    CASE
      WHEN ABS(NVL(DGPCLOSDECPRDCOST,0) - NVL(DGPOPENDECPRDCOST,0)) > 0.009
      THEN NVL(DGPCLOSDECPRDCOST,0)     - NVL(DGPOPENDECPRDCOST,0)
      ELSE NVL(DGPCLOSDLVPRDCOST,0)     - NVL(DGPOPENDLVPRDCOST,0)
    END Delivered_Goods_Cost ,
    CASE
      WHEN (ABS(NVL(DGPOPENFINDECQTY,0)) < 0.009
      AND ABS(NVL(DGPOPENFINQTY,0))      <0.009
      AND ABS(NVL(DGPOPENDELAMM,0))      <0.009
      AND ABS(NVL(DGPOPENONDISC,0))      <0.009
      AND ABS(NVL(DGPOPENOFFDISC,0))     <0.009
      AND ABS(NVL(DGPOPENOTHERS,0))      <0.009
      AND ABS(NVL(DGPOPENDECPRDCOST,0))  <0.009
      AND ABS(NVL(DGPOPENDLVPRDCOST,0))  <0.009)
      THEN 1
      ELSE 0
    END New_Transaction_Flag,
    Deldet.DELQTYPER,
    NVL(DGPCLOSEFINQTY,0) - NVL(DGPOPENFINQTY,0) Sales_Packs_Move,
    Deldet.DELRECNO, 
	Case When (Select USENEWPRICELISTS from saloffno where saloffno = DlvSalOffNo) = 1 
		 then Case When
					   (Select Count(*) 
					   from PriceListProfileHead 
					   Where PriceListProfileHead.PROFILEHEADRECNO = DelDet.PROFILEHEADRECNO
					   And  Nvl(PriceListProfileHead.PROFILEPRICE, 0) > 0.009) > 0
				  then
					   (Select PriceListProfileHead.PROFILEPRICE 
					   from PriceListProfileHead 
					   Where PriceListProfileHead.PROFILEHEADRECNO = DelDet.PROFILEHEADRECNO
					   And  Nvl(PriceListProfileHead.PROFILEPRICE, 0) > 0.009)
				  else
				   	 (Select PrcnewList.PRLPRICE from PrcnewList Where deldet.PRLLINENO = PrcnewList.PRLLINENO)  
				  end
				  
		 else Case When
					  (select count(*) 
					  from PriceListProfileHead
					  Where PriceListProfileHead.PROFILEHEADRECNO = DelDet.PROFILEHEADRECNO
					  And  Nvl(PriceListProfileHead.PROFILEPRICE, 0) > 0.009) > 0
				  then
					   (Select PriceListProfileHead.PROFILEPRICE 
					   from PriceListProfileHead 
					   Where PriceListProfileHead.PROFILEHEADRECNO = DelDet.PROFILEHEADRECNO)
				  else
				   	Case when (Select count(*) 
				 	  	   		 from PrcnewList 
								 Where deldet.PRLLINENO = PrcnewList.PRLLINENO 
								 and Nvl(PrcnewList.PRLSPCLPRICE,0) > 0.009) > 0 
				   then (Select PrcnewList.PRLSPCLPRICE from PrcnewList Where deldet.PRLLINENO = PrcnewList.PRLLINENO) 
				   else (Select PrcnewList.PRLPRICE from PrcnewList Where deldet.PRLLINENO = PrcnewList.PRLLINENO)  
				   end
				  end

		 end Price_List_Price,
   Delhed.DLVDLTRECNO Delivery_Type,
  (Select DELIVERYCONDITIONDESC from dlvtype Where dlvtype.DLTRECNO = Delhed.DLVDLTRECNO) Delivery_Type_Desc
  FROM DGPDetails,
    DGPhead,
    Lotite,
    PurOrd,
    LotDet,
    Lothed,
    Delhed,
    Orders,
    TKTNT,
    Delprice,
    Acctrnfil,
    Deldet
  WHERE DGPDetails.DGPDETHEDNO = DGPHead.DGPHEDRECNO
  AND DGPDetails.DgpLitRecNo   = Lotite.LititeNo
  AND Lotite.LitPorrec         = Purord.PorRecNo
  AND Lotite.LITDETNO          = LotDet.DETRECNO
  AND LotDet.DETLHERECNO       = Lothed.LHERECNO
  AND DgpDetails.DGPDLVNO      = Delhed.DlvOrdNo
  AND Delhed.DlvOrdRecNo       = Orders.OrdRecNo
  AND DgpDprRecNO              = DprrecNo
  AND Delprice.DprDelRecNo     = Deldet.DelRecNo
  AND DelInvRecNo              = AtrRecNo(+)
  AND DGPDetails.DGPDLVNO      = TNTDLVORDNO(+)
  AND NVL(DGPhead.DGPCLOSED,0) = 1;