create or replace PACKAGE BODY FT_PK_GOODS_COSTS AS

  cVersionControlNo   VARCHAR2(12) := '1.0.1'; -- Current Version Number

  SYS_USEACCCOMMHAND      BOOLEAN := TO_BOOLEAN(FT_PK_UTILS.GET_SYSPREF('USEACCCOMMHAND'));
    
  TYPE COST_CRITERIA IS RECORD (
      ICHRECNO          ITECHG.ICHRECNO%TYPE, 
      LITRECNO          ITECHG.LITRECNO%TYPE,
      ICHRAWAPPAMT      ITECHG.ICHRAWAPPAMT%TYPE,
      EXCSENCODE        EXPCHA.EXCSENCODE%TYPE,
      EXCSALOFF         EXPCHA.EXCSALOFF%TYPE
  );
  
  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN cSpecVersionControlNo;
    ELSE  
      RETURN cVersionControlNo;
    END IF;                
  END CURRENTVERSION;
  
  PROCEDURE WRITE_GOODS_COST(GOODS_COST_REC COST_CRITERIA)
  IS
    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    ITECHG_REC          ITECHG%ROWTYPE;
    EXPCHA_REC          EXPCHA%ROWTYPE;
  BEGIN  
    IF GOODS_COST_REC.ICHRAWAPPAMT IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'GOODS_COST_REC.ICHRAWAPPAMT';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(GOODS_COST_REC.ICHRAWAPPAMT);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;    
    
    IF GOODS_COST_REC.ICHRECNO IS NOT NULL THEN
      FT_PK_COST_WRITES.UPDATE_ICHRAWAPPAMT(GOODS_COST_REC.ICHRECNO, GOODS_COST_REC.ICHRAWAPPAMT);
    ELSE
      IF GOODS_COST_REC.LITRECNO IS NULL THEN
        PARAMETER_LIST('#PARAMNAME') := 'GOODS_COST_REC.LITRECNO';
        PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(GOODS_COST_REC.LITRECNO);
        FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
      END IF;
      
      IF GOODS_COST_REC.EXCSENCODE IS NULL THEN
        PARAMETER_LIST('#PARAMNAME') := 'GOODS_COST_REC.EXCSENCODE';
        PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(GOODS_COST_REC.EXCSENCODE);
        FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
      END IF;
      
      IF GOODS_COST_REC.EXCSALOFF IS NULL THEN
        PARAMETER_LIST('#PARAMNAME') := 'GOODS_COST_REC.EXCSALOFF';
        PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(GOODS_COST_REC.EXCSALOFF);
        FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
      END IF;  
      
      ITECHG_REC.LITRECNO         := GOODS_COST_REC.LITRECNO;
      ITECHG_REC.ICHRAWAPPAMT     := GOODS_COST_REC.ICHRAWAPPAMT;
      ITECHG_REC.CTYNO            := CONST.CTYGOODS;
      EXPCHA_REC.EXCSENCODE       := GOODS_COST_REC.EXCSENCODE;
      EXPCHA_REC.EXCSALOFF        := GOODS_COST_REC.EXCSALOFF;
      
      FT_PK_COST_WRITES.INSERT_ITECHG(ITECHG_REC, EXPCHA_REC);
    END IF;
  END WRITE_GOODS_COST;

  PROCEDURE CALC_GOODS_SALES(LITITENO_IN INTEGER)
  IS
    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    L_GOODS_AMT         FLOAT := 0.0;
    L_PURCHASE_COST     FLOAT := 0.0;
    L_COMMISSION        FLOAT := 0.0;
    L_HANDLING          FLOAT := 0.0;
    L_COMMISSION_SALES  FLOAT := 0.0;
    L_RCV_QTY           INTEGER;
    L_SOLD_QTY          INTEGER;
    L_MINPRICE          FLOAT := 0.0;
    GOODS_COST_REC      COST_CRITERIA;
  
    CURSOR GOODS_SALES_CUR(LITITENO_IN INTEGER)
    IS
    SELECT 	PO_VIEW.LITITENO,
            PO_VIEW.PORSALOFF,
            PO_VIEW.LHESENCODE,
            PO_VIEW.LHEPAYTYP,
            PO_VIEW.LITORGEXP,
            PO_VIEW.LITQTYRCV,
            PO_VIEW.LITRCVCOMPLETE,
            NVL(PO_VIEW.MGPRICE, 0.0) AS MGPRICE,
            NVL(ACCOUNTS.ACCAPDEFCOMM, 0.0) AS ACCAPDEFCOMM,
            NVL(ACCOUNTS.ACCAPDEFHAND, 0.0) AS ACCAPDEFHAND,
            (SELECT MIN(COST_VIEW.ICHRECNO) FROM FT_V_COSTS COST_VIEW WHERE COST_VIEW.LITRECNO = PO_VIEW.LITITENO AND COST_VIEW.CTYNO = CONST.CTYGOODS AND COST_VIEW.ICHISTRECNO IS NULL) AS GOODS_ICHRECNO,
            NVL(SALES_VIEW.SALES_VALUE, 0.0) AS SALES_VALUE,
            NVL(SALES_VIEW.SALES_VALUE, 0.0) - NVL(SALES_VIEW.SALES_COST, 0.0) AS NETT_SALES,
            NVL(SALES_VIEW.DISCOUNT_AMT, 0.0) AS DISCOUNT_AMT,
            NVL(SALES_VIEW.REBATE_AMT, 0.0) AS REBATE_AMT,
            NVL(SALES_VIEW.EXPL_SALES_COST, 0.0) AS EXPL_SALES_COST,
            NVL(SALES_VIEW.BULK_SALES_QTY, 0.0) AS BULK_SALES_QTY,
            NVL(SALES_VIEW.OPEN_PRICE, 0.0) AS OPEN_PRICE,
            NVL((SELECT SUM(COST_VIEW.ICHAPPAMT) FROM FT_V_COSTS COST_VIEW WHERE COST_VIEW.CTYNO <> CONST.CTYGOODS AND COST_VIEW.CHARGECLASS <> CONST.C_GOODSREBATE AND COST_VIEW.LITRECNO = PO_VIEW.LITITENO), 0.0) AS PURCHASE_COST,
            NVL((SELECT SUM(COST_VIEW.ICHAPPAMT) FROM FT_V_COSTS COST_VIEW WHERE COST_VIEW.CHARGECLASS IN(CONST.C_COMMISSION, CONST.C_HANDLING) AND COST_VIEW.EXCRECOVFROMPL = CONST.C_FALSE AND COST_VIEW.LITRECNO = PO_VIEW.LITITENO), 0.0) AS EXTERN_PUR_COMM_HAND,
            NVL(SALES_VIEW.EXTERN_SALES_COMM_HAND, 0.0) AS EXTERN_SALES_COMM_HAND
    FROM FT_V_PO PO_VIEW
    LEFT OUTER JOIN FT_V_PROFITPERLOT SALES_VIEW
      ON PO_VIEW.LITITENO = SALES_VIEW.LITITENO
    INNER JOIN ACCCLASS
      ON ACCCLASS.CLARECNO = PO_VIEW.LHESENCODE
    INNER JOIN ACCOUNTS
      ON ACCOUNTS.ACCRECNO = ACCCLASS.CLAACCNO
    WHERE PO_VIEW.PROFITISED = CONST.C_FALSE
      AND PO_VIEW.ONRESERVE = CONST.C_FALSE
      AND PO_VIEW.ISEXCEPTION = CONST.C_FALSE
      AND PO_VIEW.LHEPAYTYP IN(CONST.C_GOODSAGREED, CONST.C_ACCOUNTSALE, CONST.C_SELFINV)
      AND NOT EXISTS (SELECT * FROM LOTRETURNPRICES WHERE LOTRETURNPRICES.LITITENO = PO_VIEW.LITITENO)
      AND NOT EXISTS (SELECT * FROM FT_V_COSTS COST_VIEW WHERE COST_VIEW.LITRECNO = PO_VIEW.LITITENO AND COST_VIEW.CTYNO = CONST.CTYGOODS AND COST_VIEW.ICHISTRECNO IS NULL AND COST_VIEW.ICHAPPAMT > 0.009 AND COST_VIEW.ICHHASACCRUAL = 0) 
      AND PO_VIEW.LITITENO = LITITENO_IN;
      
      GOODS_SALES_REC       GOODS_SALES_CUR%ROWTYPE;
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;
    
    OPEN GOODS_SALES_CUR(LITITENO_IN);
    
    FETCH GOODS_SALES_CUR INTO GOODS_SALES_REC;
    
    IF GOODS_SALES_CUR%FOUND THEN
      IF GOODS_SALES_REC.LitRcvComplete = CONST.C_YES THEN
        L_RCV_QTY := GOODS_SALES_REC.LitOrgExp;
      ELSE
        L_RCV_QTY := GOODS_SALES_REC.LitQtyRcv;
      END IF;
      
      L_SOLD_QTY := GOODS_SALES_REC.BULK_SALES_QTY - GOODS_SALES_REC.OPEN_PRICE;
      
      IF L_SOLD_QTY > 0 THEN
        L_GOODS_AMT := GOODS_SALES_REC.NETT_SALES - GOODS_SALES_REC.EXPL_SALES_COST;
        
        IF GOODS_SALES_REC.LhePayTyp = CONST.C_ACCOUNTSALE THEN
          L_GOODS_AMT := L_GOODS_AMT + GOODS_SALES_REC.EXTERN_PUR_COMM_HAND + GOODS_SALES_REC.EXTERN_SALES_COMM_HAND;
        END IF;
        
        L_GOODS_AMT := L_GOODS_AMT * (L_RCV_QTY / TO_NUMBER(L_SOLD_QTY));
      END IF; 
          
      L_PURCHASE_COST := GOODS_SALES_REC.PURCHASE_COST;
          
      IF SYS_USEACCCOMMHAND THEN
        IF GOODS_SALES_REC.AccAPDefComm > 0.0 THEN
          L_COMMISSION_SALES := GOODS_SALES_REC.SALES_VALUE - GOODS_SALES_REC.REBATE_AMT - GOODS_SALES_REC.DISCOUNT_AMT;
          
          IF L_SOLD_QTY = 0 THEN
            L_COMMISSION_SALES := 0.0;
          ELSE
            L_COMMISSION_SALES := L_COMMISSION_SALES * (L_RCV_QTY / TO_NUMBER(L_SOLD_QTY));
          END IF;
          
          L_COMMISSION := L_COMMISSION_SALES * (GOODS_SALES_REC.AccAPDefComm / 100.0);
        END IF;
          
        IF GOODS_SALES_REC.AccAPDefComm > 0.0 THEN
          L_HANDLING := L_RCV_QTY * GOODS_SALES_REC.AccAPDefHand;
        END IF;
      END IF;
          
      IF GOODS_SALES_REC.LHEPAYTYP = CONST.C_ACCOUNTSALE THEN
        L_GOODS_AMT := L_GOODS_AMT - L_COMMISSION - L_HANDLING;
      ELSE
        L_GOODS_AMT := L_GOODS_AMT - L_COMMISSION - L_HANDLING - L_PURCHASE_COST;
      END IF;          
          
      IF L_GOODS_AMT < 0.0 THEN
        L_GOODS_AMT := 0.0;
      END IF;
        
      IF GOODS_SALES_REC.MGPrice > 0.009 THEN
        L_MINPRICE := FT_PK_COST_WRITES.GET_GOODS_AMT(GOODS_SALES_REC.LITITENO, GOODS_SALES_REC.MGPrice);
        
        IF L_GOODS_AMT < L_MINPRICE THEN
          L_GOODS_AMT := L_MINPRICE;
        END IF;
      END IF;
      
      L_GOODS_AMT := ROUND(L_GOODS_AMT, 2);
      
      GOODS_COST_REC.ICHRECNO           := GOODS_SALES_REC.GOODS_ICHRECNO;        
      GOODS_COST_REC.LITRECNO           := GOODS_SALES_REC.LITITENO;
      GOODS_COST_REC.ICHRAWAPPAMT       := L_GOODS_AMT;
      GOODS_COST_REC.EXCSENCODE         := GOODS_SALES_REC.LHESENCODE;
      GOODS_COST_REC.EXCSALOFF          := GOODS_SALES_REC.PORSALOFF;
      
      WRITE_GOODS_COST(GOODS_COST_REC);
    END IF;
        
    CLOSE GOODS_SALES_CUR;
  EXCEPTION
    WHEN OTHERS THEN
      IF GOODS_SALES_CUR%ISOPEN THEN
        CLOSE GOODS_SALES_CUR;
      END IF;
      FT_PK_ERRORS.LOG_AND_STOP(); 
  END CALC_GOODS_SALES;
  
  PROCEDURE CALC_GOODS_REPORTED(LITITENO_IN INTEGER)
  IS
    PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
    L_GOODS_AMT         FLOAT := 0.0;
    L_RET_AVG_PRICE     FLOAT := 0.0;
    GOODS_COST_REC      COST_CRITERIA;
  
    CURSOR GOODS_REPORTED_CUR(LITITENO_IN INTEGER)
    IS
    SELECT  PO_VIEW.LITITENO,
            PO_VIEW.LITQTYRCV,
            PO_VIEW.LHESENCODE,
            PO_VIEW.PORSALOFF,
            PO_VIEW.LHEPAYTYP, 
            SUM(LOTRETURNPRICES.LOTRETURNQTY) AS LOTRETURNQTY,
            SUM(LOTRETURNPRICES.LOTRETURNVALUE) AS LOTRETURNVALUE,   
            (SELECT MIN(COST_VIEW.ICHRECNO) FROM FT_V_COSTS COST_VIEW WHERE COST_VIEW.LITRECNO = PO_VIEW.LITITENO AND COST_VIEW.CTYNO = CONST.CTYGOODS AND COST_VIEW.ICHISTRECNO IS NULL) AS GOODS_ICHRECNO,
            NVL((SELECT SUM(COST_VIEW.ICHAPPAMT) FROM FT_V_COSTS COST_VIEW WHERE COST_VIEW.CHARGECLASS IN(CONST.C_COMMISSION, CONST.C_HANDLING) AND COST_VIEW.LITRECNO = PO_VIEW.LITITENO), 0.0) AS PUR_COMM_HAND,
            NVL((SELECT SUM(COST_VIEW.ICHAPPAMT) FROM FT_V_COSTS COST_VIEW WHERE COST_VIEW.CHARGECLASS IN(CONST.C_COMMISSION, CONST.C_HANDLING) AND COST_VIEW.EXCRECOVFROMPL = CONST.C_FALSE AND COST_VIEW.LITRECNO = PO_VIEW.LITITENO), 0.0) AS EXTERN_PUR_COMM_HAND
    FROM FT_V_PO PO_VIEW
    INNER JOIN LOTRETURNPRICES
      ON LOTRETURNPRICES.LITITENO = PO_VIEW.LITITENO
    WHERE PO_VIEW.PROFITISED = CONST.C_FALSE
      AND PO_VIEW.ONRESERVE = CONST.C_FALSE
      AND PO_VIEW.ISEXCEPTION = CONST.C_FALSE
      AND PO_VIEW.LHEPAYTYP IN(CONST.C_GOODSAGREED, CONST.C_ACCOUNTSALE, CONST.C_SELFINV)
      AND NOT EXISTS (SELECT * FROM FT_V_COSTS COST_VIEW WHERE COST_VIEW.LITRECNO = PO_VIEW.LITITENO AND COST_VIEW.CTYNO = CONST.CTYGOODS AND COST_VIEW.ICHISTRECNO IS NULL AND COST_VIEW.ICHAPPAMT > 0.009 AND COST_VIEW.ICHHASACCRUAL = 0) 
      AND PO_VIEW.LITITENO = LITITENO_IN
    GROUP BY  PO_VIEW.LITITENO,
              PO_VIEW.LITQTYRCV,
              PO_VIEW.LHESENCODE,
              PO_VIEW.PORSALOFF,
              PO_VIEW.LHEPAYTYP;
              
    GOODS_RPTD_REC      GOODS_REPORTED_CUR%ROWTYPE;
  BEGIN
    IF LITITENO_IN IS NULL THEN
      PARAMETER_LIST('#PARAMNAME') := 'LITITENO_IN';
      PARAMETER_LIST('#PARAMVALUE') := TO_CHAR(LITITENO_IN);
      FT_PK_ERRORS.RAISE_ERROR(FT_PK_ERRNUMS.FT_PARAMETER, PARAMETER_LIST);
    END IF;
    
    OPEN GOODS_REPORTED_CUR(LITITENO_IN);
    
    FETCH GOODS_REPORTED_CUR INTO GOODS_RPTD_REC;
    
    IF GOODS_REPORTED_CUR%FOUND THEN
      IF GOODS_RPTD_REC.LotReturnQty = GOODS_RPTD_REC.LitQtyRcv THEN
        L_GOODS_AMT := GOODS_RPTD_REC.LotReturnValue;
      ELSE
        IF GOODS_RPTD_REC.LotReturnQty = 0 THEN
          L_RET_AVG_PRICE := 0.0;
        ELSE
          L_RET_AVG_PRICE := GOODS_RPTD_REC.LotReturnValue / TO_NUMBER(GOODS_RPTD_REC.LotReturnQty);
        END IF;
        
        IF GOODS_RPTD_REC.LotReturnQty = 0 THEN
          L_GOODS_AMT := 0.0;
        ELSE 
          L_GOODS_AMT := L_RET_AVG_PRICE * GOODS_RPTD_REC.LitQtyRcv;
        END IF;
      END IF;
            
      L_GOODS_AMT := L_GOODS_AMT - GOODS_RPTD_REC.PUR_COMM_HAND + GOODS_RPTD_REC.EXTERN_PUR_COMM_HAND;
      
      IF L_GOODS_AMT < 0.0 THEN
        L_GOODS_AMT := 0.0;
      END IF;
    
      L_GOODS_AMT := ROUND(L_GOODS_AMT, 2);      
      
      GOODS_COST_REC.ICHRECNO           := GOODS_RPTD_REC.GOODS_ICHRECNO;        
      GOODS_COST_REC.LITRECNO           := GOODS_RPTD_REC.LITITENO;
      GOODS_COST_REC.ICHRAWAPPAMT       := L_GOODS_AMT;
      GOODS_COST_REC.EXCSENCODE         := GOODS_RPTD_REC.LHESENCODE;
      GOODS_COST_REC.EXCSALOFF          := GOODS_RPTD_REC.PORSALOFF;
      
      WRITE_GOODS_COST(GOODS_COST_REC);      
    END IF;
    CLOSE GOODS_REPORTED_CUR;
  EXCEPTION
    WHEN OTHERS THEN
      IF GOODS_REPORTED_CUR%ISOPEN THEN
        CLOSE GOODS_REPORTED_CUR;
      END IF;
      FT_PK_ERRORS.LOG_AND_STOP();     
  END CALC_GOODS_REPORTED;
  				
  PROCEDURE CALCULATEGOODSCOST
  IS
  BEGIN
    FOR LITREC IN (SELECT AUTOCOSTS_PROCESS.LITITENO FROM AUTOCOSTS_PROCESS WHERE AUTOCOSTS_PROCESS.CALCULATEGOODSCOST = CONST.C_TRUE) LOOP
      CALCULATEGOODSCOST(LITREC.LITITENO);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END CALCULATEGOODSCOST;
  
  PROCEDURE CALCULATEGOODSCOST(LITITENO_IN LOTITE.LITITENO%TYPE)
  IS
  BEGIN    
    FT_PK_COSTING.AUTO_PO_COSTS(LITITENO_IN);
    CALC_GOODS_SALES(LITITENO_IN);
    CALC_GOODS_REPORTED(LITITENO_IN);
  EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
  END CALCULATEGOODSCOST;  

END FT_PK_GOODS_COSTS;
/