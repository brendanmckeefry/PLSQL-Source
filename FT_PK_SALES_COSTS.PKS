create or replace PACKAGE FT_PK_SALES_COSTS  AS

  cSpecVersionControlNo VARCHAR2(12) := '1.0.1';
  --[ SRimen 04/03/2015 13676 ]
  --[ Replaces CostingLib.LotIteApportion_DelPrice() ]
  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2;
  --PROCEDURE TestArrays(IN_DLVORDNO IN NUMBER, IN_EXCRECNO IN NUMBER);
  PROCEDURE LOTITEAPPORTION_DELPRICE(IN_DLVORDNO IN NUMBER, IN_EXCRECNO IN NUMBER);    
  
  PROCEDURE DoAutCostAdHocChgs_Int(IN_DLVORDNO IN NUMBER, IN_EXCRECNO IN NUMBER);
  PROCEDURE GetTotalDeliveryUnits(VExcAppType EXPCHA.ExcAppType%Type, IN_DLVORDNO DELHED.DLVORDNO%Type, TotDelQtyOrWgt IN OUT Float);
  PROCEDURE DoAutCostAdHocChgs(IN_DLVORDNO INTEGER, IN_EXCRECNO IN NUMBER);
  PROCEDURE DoAutCostAdHocChgs; --(IN_DLVORDNO IN NUMBER, IN_EXCRECNO IN NUMBER); 
END FT_PK_SALES_COSTS;
/
