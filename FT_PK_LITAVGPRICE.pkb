CREATE OR REPLACE PACKAGE BODY            FT_PK_LITAVGPRICE
AS

   cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number

---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  GETS ALL THE ACTIVE LOTS IN THE ALLOCATE AND UPDATES THEIR GUIDE PRICE      
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-                  

PROCEDURE UPDATEACTIVELOTS IS
        CURSOR ACTIVELOTS_CURSOR  IS (SELECT  DISTINCT ALLOCATE.ALLOCLITITENO FROM ALLOCATE);
        --CURSOR ACTIVELOTS_CURSOR  IS (SELECT  LITITENO ALLOCLITITENO FROM LOTITE);
        ACTIVELOTSRECORD     ACTIVELOTS_CURSOR %ROWTYPE;        
  BEGIN
    
            OPEN ACTIVELOTS_CURSOR() ;
            LOOP
                FETCH ACTIVELOTS_CURSOR INTO  ACTIVELOTSRECORD;
                EXIT WHEN ACTIVELOTS_CURSOR%NOTFOUND;
                    BEGIN
                        UPDATE LOTITE SET AVGGROSSPRC = FT_PK_LITAVGPRICE.LITAVGPRICE_MAIN(LITITENO, 0)
                        WHERE LITITENO = ACTIVELOTSRECORD.ALLOCLITITENO;
                        COMMIT;
                    EXCEPTION             
                        WHEN NO_DATA_FOUND THEN
                            NULL;                                                 
                        WHEN OTHERS THEN
                            NULL;
                            --RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_LITAVGPRICE - UPDATEACTIVELOTS() '); 
                            FT_PK_ERRORS.LOG_AND_STOP;                        
                    END;
            END LOOP;
            CLOSE ACTIVELOTS_CURSOR;


    END UPDATEACTIVELOTS; 


---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  get the average price for a Lotite      
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-                  
FUNCTION LITAVGPRICE_MAIN  (V_LITRECNO IN NUMBER, IS_NETT NUMBER) RETURN  FLOAT IS V_AVEPRICE FLOAT:= 0;
    
    VAR_LCONT                   NUMBER(1) := 1;
    VAR_LITSALESVAL             FLOAT; 
    VAR_LITSALESQTY             NUMBER;
    VAR_LITSALESVAL_TMP             FLOAT; 
    VAR_LITSALESQTY_TMP             NUMBER;
        
    BEGIN 

    VAR_LITSALESVAL := 0;
    VAR_LITSALESQTY_TMP := 0;
        
    IF VAR_LCONT = 1 THEN
        BEGIN
            VAR_LITSALESVAL := 0;
            VAR_LITSALESQTY := 0;
            
            IF NVL(V_LITRECNO,0) <=1 THEN
                VAR_LCONT := 0;
            END IF;            
        END;
    END IF;
    
    -- GET THE DELTOALL DETAILS     
    IF VAR_LCONT = 1 THEN
        LITAVGPRICE_DELTOALL(V_LITRECNO, VAR_LITSALESVAL_TMP, VAR_LITSALESQTY_TMP, IS_NETT);
        VAR_LITSALESVAL := VAR_LITSALESVAL  + NVL(VAR_LITSALESVAL_TMP,0);
        VAR_LITSALESQTY := VAR_LITSALESQTY  + NVL(VAR_LITSALESQTY_TMP,0);        
    END IF;  
    
    -- GET THE DELIVERY DETAILS  - FOR BULK LINES     
    IF VAR_LCONT = 1 THEN
        LITAVGPRICE_DELDET_PO(V_LITRECNO, VAR_LITSALESVAL_TMP, VAR_LITSALESQTY_TMP, IS_NETT);
        VAR_LITSALESVAL := VAR_LITSALESVAL  + NVL(VAR_LITSALESVAL_TMP,0);
        VAR_LITSALESQTY := VAR_LITSALESQTY  + NVL(VAR_LITSALESQTY_TMP,0);        
    END IF;
     
    -- GET THE DELIVERY DETAILS  - FOR PREPACK LINES     
    IF VAR_LCONT = 1 THEN
        LITAVGPRICE_DELDET_WO(V_LITRECNO, VAR_LITSALESVAL_TMP, VAR_LITSALESQTY_TMP,IS_NETT);
        VAR_LITSALESVAL := VAR_LITSALESVAL  + NVL(VAR_LITSALESVAL_TMP,0);
        VAR_LITSALESQTY := VAR_LITSALESQTY  + NVL(VAR_LITSALESQTY_TMP,0);        
    END IF;
             
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_LITSALESQTY,0) > 0 THEN
            V_AVEPRICE :=   ROUND((VAR_LITSALESVAL/VAR_LITSALESQTY),2);                      
        END IF;
    END IF;  
             
        
    
    RETURN V_AVEPRICE;

END LITAVGPRICE_MAIN ;

---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  This processes the DELTOALL that exist for that Lotite
-- note this fails miserably if the ALLOCATE has multiple lotites on it       
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-                  

PROCEDURE LITAVGPRICE_DELTOALL(V_LITRECNO IN NUMBER, OUT_VALUE OUT  FLOAT, OUT_QTY OUT NUMBER, IS_NETT NUMBER) IS
        VAR_LCONT                NUMBER(1) := 1;
        V_USERNO                 NUMBER(10);
        V_DD_VALUE               FLOAT; 
        V_DD_QTY                 NUMBER;

        CURSOR DELTOALLDETS_CURSOR (V_INS_LITITENO NUMBER) IS
             SELECT 
             /* INDEX(DELTOALL, DELTOALL_DALALLOCNO2IDX) USE_NL(DELTOALL) 
                INDEX(DELDET, PK_DELDET) USE_NL(DELDET)*/
            
            ALLOCATE.ALLOCLITITENO, DELTOALL.DALWIZUNIQUEID,             
            DELDET.DELDLVORDNO,  DELDET.DELRECNO, DELDET.DELQTYPER, DELDET.DELQTY,   
            (CASE WHEN NVL(ALLOCATE.ALLOCBY,0) > 1   
                 THEN DELTOALL.DALQTY
                 ELSE (CASE WHEN NVL(DELTOALL.ACTSPLITQTY,0) > 0  THEN DELTOALL.ACTSPLITQTY ELSE NVL(DELTOALL.DALQTY,0) END )        
                 END) QTY,
            (CASE WHEN NVL(ALLOCATE.ALLOCBY,0) > 1   
                 THEN ALLOCATE.ALLOCBY
                 ELSE (CASE WHEN NVL(DELTOALL.ACTSPLITQTY,0) > 0  THEN NVL(DELTOALL.QTYPER,1) ELSE 1 END )        
                 END) QTYPER,                     
            NVL((SELECT SUM(NVL(DELPRICE.DELFREEOFCHG,0)) FROM DELPRICE WHERE DELPRICE.DPRDELRECNO =  DELDET.DELRECNO),0) DELFREEOFCHG,
            NVL((SELECT MAX(DELPRICE)  FROM DELPRICE WHERE DELPRICE.DPRDELRECNO =  DELDET.DELRECNO AND NVL(DELPRICE.DELPRICE,0) > 0),0) DELPRICE,
            PRCWEIGHT, PRCBOXQTY, INNERQTY  
            FROM ALLOCATE, DELTOALL, DELDET, PRDREC
            WHERE ALLOCATE.ALLOCNO = DELTOALL.DALALLOCNO
            AND DELTOALL.DALTYPERECNO =  DELDET.DELRECNO
            AND PRDREC.PRCPRDNO = DELDET.DELPRCPRDNO             
            AND DELTOALL.DALRECORDTYPE= 1
            AND ALLOCATE.ALLOCLITITENO = V_INS_LITITENO;
        DELTOALLDETS_RECORD     DELTOALLDETS_CURSOR %ROWTYPE;        
  BEGIN
    OUT_QTY := 0;
    OUT_VALUE := 0;
  
     
    IF VAR_LCONT = 1 THEN  
        IF NVL(V_LITRECNO,0) = 0  THEN
        BEGIN            
            VAR_LCONT := 0 ;
        END;
        END IF;        
    END IF; 
    
    --IF VAR_LCONT = 1 THEN  
    --BEGIN            
    --    WRITEMISSINGALLOCDETS();
    --END;                
    --END IF; 
    
    

    IF VAR_LCONT = 1 THEN
        BEGIN
            OPEN DELTOALLDETS_CURSOR(V_LITRECNO) ;
            LOOP
                FETCH DELTOALLDETS_CURSOR INTO  DELTOALLDETS_RECORD;
                EXIT WHEN DELTOALLDETS_CURSOR%NOTFOUND;
                    BEGIN
                        -- IGNORE THE OPEN PRICED LINES IN OUR CALCULATIONS
                        IF DELTOALLDETS_RECORD.DELPRICE > 0.009 OR DELTOALLDETS_RECORD.DELFREEOFCHG = 1 THEN
                        BEGIN 
                            
                            V_DD_VALUE := DELTOALLDETS_RECORD.QTY * NVL(DELTOALLDETS_RECORD.DELPRICE,0);
                            V_DD_QTY   := DELTOALLDETS_RECORD.QTY;
                            
                            -- SUBTRACT THE DISCOUNTS, REBATES AND OTH_CHARGES FROM THE SALES VALUE
                            IF  IS_NETT = 1 THEN
                            BEGIN                           
                                V_DD_VALUE := V_DD_VALUE 
                                        -  FT_PK_LITAVGPRICE.RET_REBATE_APP( DELTOALLDETS_RECORD.DELRECNO, NULL, DELTOALLDETS_RECORD.DELQTY, DELTOALLDETS_RECORD.QTY)
                                        -    FT_PK_LITAVGPRICE.RET_DISC_APP( DELTOALLDETS_RECORD.DELRECNO, NULL, DELTOALLDETS_RECORD.DELQTY, DELTOALLDETS_RECORD.QTY)
                                        - FT_PK_LITAVGPRICE.RET_OTHCHGS_APP( DELTOALLDETS_RECORD.DELRECNO, NULL, DELTOALLDETS_RECORD.DELQTY, DELTOALLDETS_RECORD.QTY)
                                        - FT_PK_LITAVGPRICE.RET_OTHCHGS_APP_DD( DELTOALLDETS_RECORD.DELRECNO, DELTOALLDETS_RECORD.DELQTY, DELTOALLDETS_RECORD.QTY);
                            END;
                            END IF;
                                        
                                        
                                        
                            -- IF OUR DELTOALL RECORD IS NOT A BOX LINE THEN WE NEED TO CONVERT OUR QTY TO A BOX LINE  
                            IF DELTOALLDETS_RECORD.QTYPER > 1 THEN
                            BEGIN 
                                V_DD_QTY   := ROUND(V_DD_QTY/ RET_MULTI(DELTOALLDETS_RECORD.QTYPER, DELTOALLDETS_RECORD.PRCWEIGHT , DELTOALLDETS_RECORD.PRCBOXQTY , DELTOALLDETS_RECORD.INNERQTY) 
                                                  , 2);
                            END;
                            END IF;
                            
                            OUT_QTY := OUT_QTY + V_DD_QTY; 
                            OUT_VALUE := OUT_VALUE + ROUND(V_DD_VALUE,2) ;                            
                            
                        END;
                        END IF;
                        
                        
                        
                     END;
                
            END LOOP;
            CLOSE DELTOALLDETS_CURSOR;
        END;
    END IF;


    END LITAVGPRICE_DELTOALL; 


    





---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  This processes the DELTOISTS that exist for thIS Lotite       
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-                  
PROCEDURE LITAVGPRICE_DELDET_PO(V_LITRECNO IN NUMBER, OUT_VALUE OUT  FLOAT, OUT_QTY OUT NUMBER, IS_NETT NUMBER) IS
        VAR_LCONT                NUMBER(1) := 1;
        V_USERNO                 NUMBER(10);
        V_DD_VALUE               FLOAT; 
        V_DD_QTY                 NUMBER;

        CURSOR DELDETDETS_CURSOR (V_INS_LITITENO NUMBER) IS
             SELECT 
                                    /*
                                    INDEX(ITESTO, ITESTO_TOLOTITE) USE_NL(ITESTO) 
                                    INDEX(DELTOIST, DELTOIST_TOITESTO) USE_NL(DELTOIST) 
                                    INDEX(DELPRICE, PK_DELPRICE) USE_NL(DELPRICE)
                                    INDEX(DELDET, PK_DELDET) USE_NL(DELDET)
                                    INDEX(DELHED, PK_DELHED) USE_NL(DELHED)
                                    */
                                     DELHED.DLVORDRECNO, DELHED.DLVORDNO, DELDET.DELRECNO, DELDET.DELQTYPER, DELDET.DELQTY, 
                                     DELPRICE.DPRRECNO, NVL(DELPRICE.DELPRICE,0) DELPRICE, DELPRICE.DELPRCQTY, NVL(DELPRICE.DELFREEOFCHG,0) DELFREEOFCHG, DELPRICE.DELINVSTATUS, DELPRICE.DPRISPRICEADJONLY, 
                                     NVL(SUM(NVL(DELTOIST.DISSTKQTY,0)),0) DISSTKQTY, 
                                     NVL(SUM(NVL(DELTOIST.DISNETTVALUE,0)),0) DISNETTVALUE,
                                     (SELECT ACCCLASS.CLAACCCSTSUP FROM  ORDERS, ACCCLASS
                                        WHERE DELHED.DLVORDRECNO      = ORDERS.ORDRECNO
                                        AND ORDERS.ACTCSTCODE       = ACCCLASS.CLARECNO) CLAACCCSTSUP  
                                     FROM ITESTO, DELTOIST, DELPRICE, DELDET, DELHED  
                                     WHERE DELTOIST.DISISTRECNO = ITESTO.ISTRECNO
                                     AND DELTOIST.DISDPRRECNO = DELPRICE.DPRRECNO
                                     AND DELPRICE.DPRDELRECNO = DELDET.DELRECNO
                                     AND DELDET.DELDLVORDNO =  DELHED.DLVORDNO
                                     AND ITESTO.ISTLITNO = V_INS_LITITENO
                                     AND DELINVSTATUS IN (1, 2, 3, 11, 12, 13)
                                     AND NVL(DELHED.DLVTRANSSHIP ,0) = 0
                                     AND NVL(DELHED.TRANSFERFLG ,0) = 0 
               --  all lines against this lotite should only be for QTY PER = 1 (box) so this code is not really required but i am putting it in 
                                     AND NVL(DELDET.DELQTYPER, 1) = 1 
                                     AND NVL(DELPRICE.DELPRCQTY,0) <> 0
                                     GROUP BY DELHED.DLVORDRECNO, DELHED.DLVORDNO, DELDET.DELRECNO, DELDET.DELQTYPER, DELDET.DELQTY, DELPRICE.DPRRECNO, DELPRICE.DELPRICE, DELPRICE.DELPRCQTY, DELPRICE.DELFREEOFCHG, DELPRICE.DELINVSTATUS, DELPRICE.DPRISPRICEADJONLY;
        DELDETDETS_RECORD     DELDETDETS_CURSOR %ROWTYPE;        
  BEGIN
    OUT_QTY := 0;
    OUT_VALUE := 0;
  
     
    IF VAR_LCONT = 1 THEN  
        IF NVL(V_LITRECNO,0) = 0  THEN
        BEGIN            
            VAR_LCONT := 0 ;
        END;
        END IF;        
    END IF; 

    IF VAR_LCONT = 1 THEN
        BEGIN
            OPEN DELDETDETS_CURSOR(V_LITRECNO) ;
            LOOP
                FETCH DELDETDETS_CURSOR INTO  DELDETDETS_RECORD;
                EXIT WHEN DELDETDETS_CURSOR%NOTFOUND;
                    BEGIN
                        -- IGNORE THE OPEN PRICED LINES IN OUR CALCULATIONS
                        IF DELDETDETS_RECORD.DELPRICE > 0.009 OR DELDETDETS_RECORD.DELFREEOFCHG = 1 THEN
                        BEGIN 
                            V_DD_QTY := 0; 
                            --V_DD_VALUE := DELDETDETS_RECORD.DISSTKQTY * NVL(DELDETDETS_RECORD.DELPRICE,0);
                            V_DD_VALUE := DELDETDETS_RECORD.DISNETTVALUE;
                            
                            
                            -- THE QTY IS IRRELEVANT FOR NON-STOCK AGJUSTING CREDITS/DEBITS                             
                            IF NVL(DELDETDETS_RECORD.DPRISPRICEADJONLY,0) = 0  THEN
                            BEGIN
                                V_DD_QTY   := DELDETDETS_RECORD.DISSTKQTY;
                            END;
                            END IF;
                            
                            -- FOR WRITES-OFF WE DO NOT WANT THE CHARGES, DISCOUNTS, REBATES PICKED UP
                            IF  IS_NETT = 1 THEN                             
                                IF DELDETDETS_RECORD.CLAACCCSTSUP <> 3 THEN
                                BEGIN
                                    V_DD_VALUE := V_DD_VALUE 
                                            -  FT_PK_LITAVGPRICE.RET_REBATE_APP( NULL, DELDETDETS_RECORD.DPRRECNO, DELDETDETS_RECORD.DELPRCQTY, DELDETDETS_RECORD.DISSTKQTY)
                                            -  FT_PK_LITAVGPRICE.RET_DISC_APP(   NULL, DELDETDETS_RECORD.DPRRECNO, DELDETDETS_RECORD.DELPRCQTY, DELDETDETS_RECORD.DISSTKQTY)
                                            -  FT_PK_LITAVGPRICE.RET_OTHCHGS_APP( NULL, DELDETDETS_RECORD.DPRRECNO, DELDETDETS_RECORD.DELPRCQTY, DELDETDETS_RECORD.DISSTKQTY)
                                            -  FT_PK_LITAVGPRICE.RET_OTHCHGS_APP_DD( DELDETDETS_RECORD.DELRECNO, DELDETDETS_RECORD.DELQTY, DELDETDETS_RECORD.DISSTKQTY);
                                END;
                                END IF;
                            END IF;
                            
                            /*            
                            -- IF OUR DELTOALL RECORD IS NOT A BOX LINE THEN WE NEED TO CONVERT OUR QTY TO A BOX LINE  
                            IF DELTOALLDETS_RECORD.QTYPER > 1 THEN
                            BEGIN 
                                V_DD_QTY   := ROUND(V_DD_QTY/ RET_MULTI(DELTOALLDETS_RECORD.QTYPER, DELTOALLDETS_RECORD.PRCWEIGHT , DELTOALLDETS_RECORD.PRCBOXQTY , DELTOALLDETS_RECORD.INNERQTY) 
                                                  , 2);
                            END;
                            END IF;
                            */
                            
                            OUT_QTY := OUT_QTY + V_DD_QTY; 
                            OUT_VALUE := OUT_VALUE + ROUND(V_DD_VALUE,2) ;                            
                            
                        END;
                        END IF;
                        
                        
                        
                     END;
                
            END LOOP;
            CLOSE DELDETDETS_CURSOR;
        END;
    END IF;


    END LITAVGPRICE_DELDET_PO; 
    
    
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  This processes and PREPACK DELIVERIES that exist for thIS Lotite       
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-                  
PROCEDURE LITAVGPRICE_DELDET_WO(V_LITRECNO IN NUMBER, OUT_VALUE OUT  FLOAT, OUT_QTY OUT NUMBER, IS_NETT NUMBER) IS
        VAR_LCONT                NUMBER(1) := 1;
        V_USERNO                 NUMBER(10);
        V_PP_DD_VALUE               FLOAT; 
        V_PP_DD_QTY                 NUMBER;

        CURSOR PP_DELDETDETS_CURSOR (V_INS_LITITENO NUMBER) IS
        
        (SELECT                 
                 DELHED.DLVORDRECNO, DELHED.DLVORDNO, DELDET.DELRECNO, DELDET.DELQTYPER, DELDET.DELQTY, 
                 DELPRICE.DPRRECNO, DELPRICE.DELPRICE, DELPRICE.DELFREEOFCHG, DELPRICE.DELINVSTATUS, DELPRICE.DPRISPRICEADJONLY, DELPRICE.DELPRCQTY,                                      
                 NVL(SUM(NVL(PREPALINOUTSALES.BULKQTYEQUIV,0)),0) BULKQTY, 
                 NVL(SUM(NVL(PREPALINOUTSALES.DPRQTYTHIS,0)),0) DPRQTYTHIS,                                  
                 NVL(SUM(NVL(PREPALINOUTSALES.DPRBASEVALTHIS,0)),0) BASEVALUE,
                 PRDREC.PRCWEIGHT, PRDREC.PRCBOXQTY, PRDREC.INNERQTY,
                 (SELECT ACCCLASS.CLAACCCSTSUP FROM  ORDERS, ACCCLASS
                                        WHERE DELHED.DLVORDRECNO      = ORDERS.ORDRECNO
                                        AND ORDERS.ACTCSTCODE       = ACCCLASS.CLARECNO) CLAACCCSTSUP 
                                     
                 
                 FROM ITESTO, PREPALINOUT, PREPALINOUTSALES, DELPRICE,  DELDET, DELHED, PRDREC  
                 WHERE PREPALINOUT.PALINBULKISTREC = ITESTO.ISTRECNO
                 AND PREPALINOUTSALES.PREPALINOUTRECNO     = PREPALINOUT.PREPALRECNO
                 AND DELPRICE.DPRRECNO = PREPALINOUTSALES.DELPRCRECNO
                 AND DELPRICE.DPRDELRECNO = DELDET.DELRECNO
                 AND DELDET.DELDLVORDNO =  DELHED.DLVORDNO
                 AND ITESTO.ISTPRDNO = PRDREC.PRCPRDNO 
                 AND ITESTO.ISTLITNO   = V_INS_LITITENO
                 AND DELINVSTATUS IN (1, 2, 3, 11, 12, 13)                  
                 AND NVL(DELHED.DLVTRANSSHIP ,0) = 0
                 AND NVL(DELHED.TRANSFERFLG ,0) = 0 
                 AND NVL(DELPRICE.DELPRCQTY,0) <> 0
                 GROUP BY DELHED.DLVORDRECNO, DELHED.DLVORDNO, DELDET.DELRECNO, DELDET.DELQTYPER, DELDET.DELQTY,
                 DELPRICE.DPRRECNO, DELPRICE.DELPRICE, DELPRICE.DELFREEOFCHG, 
                 DELPRICE.DELINVSTATUS, DELPRICE.DPRISPRICEADJONLY, DELPRICE.DELPRCQTY,
                 PRDREC.PRCWEIGHT, PRDREC.PRCBOXQTY, PRDREC.INNERQTY);
        
        PP_DELDETDETS_RECORD     PP_DELDETDETS_CURSOR %ROWTYPE;        
  BEGIN
    OUT_QTY := 0;
    OUT_VALUE := 0;
  
     
    IF VAR_LCONT = 1 THEN  
        IF NVL(V_LITRECNO,0) = 0  THEN
        BEGIN            
            VAR_LCONT := 0 ;
        END;
        END IF;        
    END IF; 

    IF VAR_LCONT = 1 THEN
        BEGIN
            OPEN PP_DELDETDETS_CURSOR(V_LITRECNO) ;
            LOOP
                FETCH PP_DELDETDETS_CURSOR INTO  PP_DELDETDETS_RECORD;
                EXIT WHEN PP_DELDETDETS_CURSOR%NOTFOUND;
                    BEGIN
                        -- IGNORE THE OPEN PRICED LINES IN OUR CALCULATIONS
                        IF PP_DELDETDETS_RECORD.DELPRICE > 0.009 OR PP_DELDETDETS_RECORD.DELFREEOFCHG = 1 THEN
                        BEGIN 
                            V_PP_DD_QTY   := 0;
                            V_PP_DD_VALUE := PP_DELDETDETS_RECORD.BASEVALUE;
                            
                            -- THE QTY IS IRRELEVANT FOR NON-STOCK AGJUSTING CREDITS/DEBITS                             
                            IF NVL(PP_DELDETDETS_RECORD.DPRISPRICEADJONLY,0) = 0  THEN
                            BEGIN
                                IF PP_DELDETDETS_RECORD.DELQTYPER > 1 THEN
                                BEGIN
                                    -- FOR SPLIT LINES WE NEED TO CALC THE EQUIVALENT BULK PRODUCT  
                                    V_PP_DD_QTY   := (PP_DELDETDETS_RECORD.DPRQTYTHIS/ RET_MULTI(PP_DELDETDETS_RECORD.DELQTYPER, PP_DELDETDETS_RECORD.PRCWEIGHT , PP_DELDETDETS_RECORD.PRCBOXQTY , PP_DELDETDETS_RECORD.INNERQTY)) 
                                                  ;
                                END;
                                ELSE
                                BEGIN
                                    V_PP_DD_QTY   := PP_DELDETDETS_RECORD.DPRQTYTHIS; 
                                END;
                                END IF;
                            END;                                
                            END IF;
                            
                            -- FOR WRITES-OFF WE DO NOT WANT THE CHARGES, DISCOUNTS, REBATES PICKED UP
                            IF  IS_NETT = 1 THEN                                                                                  
                                IF PP_DELDETDETS_RECORD.CLAACCCSTSUP <> 3 THEN
                                BEGIN
                                    V_PP_DD_VALUE := V_PP_DD_VALUE 
                                        -  FT_PK_LITAVGPRICE.RET_REBATE_APP(  NULL, PP_DELDETDETS_RECORD.DPRRECNO, PP_DELDETDETS_RECORD.DELPRCQTY, PP_DELDETDETS_RECORD.DPRQTYTHIS)
                                        -  FT_PK_LITAVGPRICE.RET_DISC_APP(    NULL, PP_DELDETDETS_RECORD.DPRRECNO, PP_DELDETDETS_RECORD.DELPRCQTY, PP_DELDETDETS_RECORD.DPRQTYTHIS)
                                        -  FT_PK_LITAVGPRICE.RET_OTHCHGS_APP( NULL, PP_DELDETDETS_RECORD.DPRRECNO, PP_DELDETDETS_RECORD.DELPRCQTY, PP_DELDETDETS_RECORD.DPRQTYTHIS)
                                        -  FT_PK_LITAVGPRICE.RET_OTHCHGS_APP_DD(    PP_DELDETDETS_RECORD.DELRECNO, PP_DELDETDETS_RECORD.DELQTY,    PP_DELDETDETS_RECORD.DPRQTYTHIS);
                                END;
                                END IF;
                            END IF;
                            
                            OUT_QTY := OUT_QTY + V_PP_DD_QTY; 
                            OUT_VALUE := OUT_VALUE + ROUND(V_PP_DD_VALUE,2) ;                            
                            
                        END;
                        END IF;
                        
                        
                        
                     END;
                     
                
            END LOOP;
            CLOSE PP_DELDETDETS_CURSOR;
        END;
    END IF;


    END LITAVGPRICE_DELDET_WO; 
    



FUNCTION RET_MULTI  ( V_ALLOCBY in NUMBER, V_PRCWEIGHT in NUMBER, V_PRCBOXQTY in NUMBER, V_INNERQTY in NUMBER)            
        RETURN  NUMBER IS V_RET_MULTI NUMBER(10,2):= 0;
    
    VAR_LCONT                   NUMBER(1) := 1;
        
    BEGIN
    
    V_RET_MULTI := 1;
    
    IF VAR_LCONT = 1 THEN
        IF  NVL(V_ALLOCBY,0) = 2 THEN   -- WEIGHT
            IF NVL(V_PRCWEIGHT,0) > 0.009 THEN
                V_RET_MULTI := V_PRCWEIGHT;                 
            END IF;                
        ELSIF  NVL(V_ALLOCBY,0) = 3 THEN    -- EACH     
            IF NVL(V_PRCBOXQTY,0) > 1 THEN
                V_RET_MULTI := V_PRCBOXQTY;                 
            END IF;                              
        ELSIF  NVL(V_ALLOCBY,0) = 4 THEN    -- INNER     
            IF NVL(V_INNERQTY,0) > 1 THEN
                V_RET_MULTI := V_INNERQTY;                 
            END IF;                               
        ELSE
           V_RET_MULTI := 1;                    
        END IF;
        
    END IF;  
             
        
    
    RETURN V_RET_MULTI;
             
END RET_MULTI;


 
 
 
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  get the discount amount for the deldet and apportion it across our qty     
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-                  
FUNCTION RET_DISC_APP     ( V_DELRECNO in NUMBER, V_DPRRECNO in NUMBER, V_TOTQTY in NUMBER, V_APPQTY in NUMBER)   RETURN  FLOAT IS V_AMOUNT FLOAT:= 0;
    
    VAR_LCONT                   NUMBER(1) := 1;
    VAR_DISC                   FLOAT := 0;
        
    BEGIN 

    IF VAR_LCONT = 1 THEN
        IF NVL(V_DELRECNO,0) <= 0 AND NVL(V_DPRRECNO,0) <= 0 THEN
        BEGIN
            VAR_LCONT := 1; 
        END;
        END IF;
    END IF;
    
    -- GET THE DISCOUNT AMOUNT FOR THE WHOLE DELDET     
    IF VAR_LCONT = 1 THEN
        IF NVL(V_DELRECNO,0) > 0 THEN
            BEGIN
                SELECT NVL(SUM(NVL(ICHAPPAMT,0)),0)
                INTO VAR_DISC 
                FROM ITECHG, DELPRICE 
                WHERE DELPRICE.DPRDELRECNO =  V_DELRECNO 
                AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO 
                AND  ITECHG.CTYNO = 97;
            EXCEPTION             
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_DISC := 0;                 
                WHEN OTHERS THEN
                    NULL;
                    --RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_LITAVGPRICE - RET_DISC_APP '); 
                    FT_PK_ERRORS.LOG_AND_STOP;                        
                    VAR_LCONT := 0;
            END;
        ELSE
            BEGIN
                SELECT NVL(SUM(NVL(ICHAPPAMT,0)),0)
                INTO VAR_DISC 
                FROM ITECHG
                WHERE ITECHG.DPRRECNO = V_DPRRECNO
                AND  ITECHG.CTYNO = 97;
            EXCEPTION             
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_DISC := 0;                 
                WHEN OTHERS THEN
                    NULL;
                    --RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_LITAVGPRICE - RET_DISC_APP-DPRRECNO '); 
                    FT_PK_ERRORS.LOG_AND_STOP;                        
                    VAR_LCONT := 0;
            END;
            
        END IF;
    END IF;  
             
    -- APPORTION THE DISCOUNT AMOUNT IF NEED BE     
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_DISC,0) > 0 THEN
            IF (NVL(V_TOTQTY,0) > 0 AND NVL(V_APPQTY,0) > 0)   -- DO WE HAVE VALID QTYIES 
            AND (NVL(V_TOTQTY,0) > NVL(V_APPQTY,0) )  THEN     -- OUR APPORTION QTY SHOULD BE LESS THAN THE TOT QTY        
               BEGIN
                    VAR_DISC := ROUND(((VAR_DISC/V_TOTQTY) * V_APPQTY),2);
                END;
            END IF;
        END IF;
    END IF;  
             
        
    
    RETURN NVL(VAR_DISC,0);

END RET_DISC_APP;
 
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  get the rebate amount for the deldet and apportion it across our qty     
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-                  
FUNCTION RET_REBATE_APP     ( V_DELRECNO in NUMBER, V_DPRRECNO in NUMBER, V_TOTQTY in NUMBER, V_APPQTY in NUMBER)   RETURN  FLOAT IS V_AMOUNT FLOAT:= 0;
    
    VAR_LCONT                   NUMBER(1) := 1;
    VAR_REBATE                   FLOAT := 0;
        
    BEGIN 
    
    
    IF VAR_LCONT = 1 THEN
        IF NVL(V_DELRECNO,0) <= 0 AND NVL(V_DPRRECNO,0) <= 0 THEN
        BEGIN
            VAR_LCONT := 1; 
        END;
        END IF;
    END IF;


    -- GET THE REBATE AMOUNT FOR THE WHOLE DELDET     
    IF VAR_LCONT = 1 THEN
        IF NVL(V_DELRECNO,0) > 0 THEN
            BEGIN
                SELECT NVL(SUM(NVL(ICHAPPAMT,0)),0) 
                INTO VAR_REBATE 
                FROM ITECHG, DELPRICE 
                WHERE DELPRICE.DPRDELRECNO =  V_DELRECNO 
                AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO 
                AND  ITECHG.CTYNO = 98;
            EXCEPTION             
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_REBATE := 0;                 
                WHEN OTHERS THEN
                    NULL;
                    --RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_LITAVGPRICE - RET_REBATE_APP '); 
                    FT_PK_ERRORS.LOG_AND_STOP;                        
                    VAR_LCONT := 0;
            END;
        ELSE
            BEGIN
                SELECT NVL(SUM(NVL(ICHAPPAMT,0)),0) 
                INTO VAR_REBATE 
                FROM ITECHG 
                WHERE ITECHG.DPRRECNO = V_DPRRECNO                 
                AND  ITECHG.CTYNO = 98;
            EXCEPTION             
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_REBATE := 0;                 
                WHEN OTHERS THEN
                    NULL;
                    --RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_LITAVGPRICE - RET_REBATE_APP- DPRRECNO '); 
                    FT_PK_ERRORS.LOG_AND_STOP;                        
                    VAR_LCONT := 0;
            END;
        
        
        END IF;
    END IF;  
             
    -- APPORTION THE REBATE AMOUNT IF NEED BE     
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_REBATE,0) > 0 THEN
            IF (NVL(V_TOTQTY,0) > 0 AND NVL(V_APPQTY,0) > 0)   -- DO WE HAVE VALID QTYIES 
            AND (NVL(V_TOTQTY,0) > NVL(V_APPQTY,0) )  THEN     -- OUR APPORTION QTY SHOULD BE LESS THAN THE TOT QTY        
               BEGIN
                    VAR_REBATE := ROUND(((VAR_REBATE/V_TOTQTY) * V_APPQTY),2);
                END;
            END IF;
        END IF;
    END IF;  
             
        
    
    RETURN NVL(VAR_REBATE,0);

END RET_REBATE_APP;
    
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  get the OTHER CHARGES amount for the deldet and apportion it across our qty     
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
FUNCTION RET_OTHCHGS_APP     ( V_DELRECNO in NUMBER, V_DPRRECNO in NUMBER, V_TOTQTY in NUMBER, V_APPQTY in NUMBER)   RETURN  FLOAT IS V_AMOUNT FLOAT:= 0;
    
    VAR_LCONT                   NUMBER(1) := 1;
    VAR_OTHCHGS                 FLOAT := 0;
        
    BEGIN 
    
    
    IF VAR_LCONT = 1 THEN
        IF NVL(V_DELRECNO,0) <= 0 AND NVL(V_DPRRECNO,0) <= 0 THEN
        BEGIN
            VAR_LCONT := 1; 
        END;
        END IF;
    END IF;


    -- GET THE OTHER CHARGES AMOUNT FOR THE WHOLE DELDET ( these are the ones against the DELPRICE     
    IF VAR_LCONT = 1 THEN
        IF NVL(V_DELRECNO,0) > 0 THEN
            BEGIN
                SELECT NVL(SUM(NVL(ICHAPPAMT,0)),0) 
                INTO VAR_OTHCHGS 
                FROM EXPCHA, ITECHG, DELPRICE 
                WHERE DELPRICE.DPRDELRECNO =  V_DELRECNO 
                AND ITECHG.DPRRECNO = DELPRICE.DPRRECNO 
                AND ITECHG.EXCRECNO = EXPCHA.EXCCHAREC
                AND ITECHG.CTYNO NOT IN(97, 98)
                AND NVL(EXPCHA.EXCRECOVFROMPL,0) = 0;
            EXCEPTION             
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_OTHCHGS := 0;                 
                WHEN OTHERS THEN
                    NULL;
                    --RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_LITAVGPRICE - RET_OTHCHGS_APP '); 
                    FT_PK_ERRORS.LOG_AND_STOP;                        
                    VAR_LCONT := 0;
            END;
        ELSE
            BEGIN
                SELECT NVL(SUM(NVL(ICHAPPAMT,0)),0) 
                INTO VAR_OTHCHGS 
                FROM EXPCHA, ITECHG 
                WHERE ITECHG.DPRRECNO = V_DPRRECNO 
                AND ITECHG.EXCRECNO = EXPCHA.EXCCHAREC
                AND ITECHG.CTYNO NOT IN(97, 98)
                AND NVL(EXPCHA.EXCRECOVFROMPL,0) = 0;
            EXCEPTION             
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_OTHCHGS := 0;                 
                WHEN OTHERS THEN
                    NULL;
                    --RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_LITAVGPRICE - RET_OTHCHGS_APP -DPRRECNO '); 
                    FT_PK_ERRORS.LOG_AND_STOP;                        
                    VAR_LCONT := 0;
            END;            
        END IF;
    END IF; 
    
    
    -- APPORTION THE OTHER CHARGES AMOUNT IF NEED BE     
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_OTHCHGS,0) > 0 THEN
            IF (NVL(V_TOTQTY,0) > 0 AND NVL(V_APPQTY,0) > 0)   -- DO WE HAVE VALID QTYIES 
            AND (NVL(V_TOTQTY,0) > NVL(V_APPQTY,0) )  THEN     -- OUR APPORTION QTY SHOULD BE LESS THAN THE TOT QTY        
               BEGIN
                    VAR_OTHCHGS := ROUND(((VAR_OTHCHGS/V_TOTQTY) * V_APPQTY),2);
                END;
            END IF;
        END IF;
    END IF;  
             
        
    
    RETURN NVL(VAR_OTHCHGS,0);

END RET_OTHCHGS_APP;

---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  get the OTHER CHARGES amount for the deldet and apportion it across our qty     
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
FUNCTION RET_OTHCHGS_APP_DD     ( V_DELRECNO in NUMBER, V_TOTQTY in NUMBER, V_APPQTY in NUMBER)   RETURN  FLOAT IS V_AMOUNT FLOAT:= 0;
    
    VAR_LCONT                   NUMBER(1) := 1;
    VAR_OTHCHGS_DD              FLOAT := 0;
        
    BEGIN 
    
    
    IF VAR_LCONT = 1 THEN
        IF NVL(V_DELRECNO,0) <= 0 THEN
        BEGIN
            VAR_LCONT := 1; 
        END;
        END IF;
    END IF;


    -- GET THE OTHER CHARGES AMOUNT FOR THE WHOLE DELDET ( these are the ones against the DELDET )
    IF VAR_LCONT = 1 THEN
        IF NVL(V_DELRECNO,0) > 0 THEN
            BEGIN
                SELECT SUM(NVL(ICHAPPAMT,0)) 
                INTO VAR_OTHCHGS_DD 
                FROM ITECHG
                WHERE ITECHG.DELRECNO = V_DELRECNO;
            EXCEPTION             
                WHEN NO_DATA_FOUND THEN
                    NULL;
                    VAR_OTHCHGS_DD := 0;                 
                WHEN OTHERS THEN
                    NULL;
                    --RAISE_APPLICATION_ERROR(-20002, 'Oracle Package -FT_PK_LITAVGPRICE - VAR_OTHCHGS_DD '); 
                    FT_PK_ERRORS.LOG_AND_STOP;                        
                    VAR_LCONT := 0;
            END;
        END IF;
    END IF;  
     
    
    -- APPORTION THE OTHER CHARGES AMOUNT IF NEED BE     
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_OTHCHGS_DD,0) > 0 THEN
            IF (NVL(V_TOTQTY,0) > 0 AND NVL(V_APPQTY,0) > 0)   -- DO WE HAVE VALID QTYIES 
            AND (NVL(V_TOTQTY,0) > NVL(V_APPQTY,0) )  THEN     -- OUR APPORTION QTY SHOULD BE LESS THAN THE TOT QTY        
               BEGIN
                    VAR_OTHCHGS_DD := ROUND(((VAR_OTHCHGS_DD/V_TOTQTY) * V_APPQTY),2);
                END;
            END IF;
        END IF;
    END IF;  
             
        
    
    RETURN NVL(VAR_OTHCHGS_DD,0);

END RET_OTHCHGS_APP_DD;

---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
--  get the average price for a Lotite      
---*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-                  
FUNCTION LITAVGPRICE_FRIG  (V_LITRECNO IN NUMBER, IS_NETT NUMBER) RETURN  VARCHAR2 IS V_AVEPRICE VARCHAR2(300):= '';
    
    VAR_LCONT                   NUMBER(1) := 1;
    VAR_LITSALESVAL             FLOAT; 
    VAR_LITSALESQTY             NUMBER;
    VAR_LITSALESVAL_TOT         FLOAT; 
    VAR_LITSALESQTY_TOT         NUMBER;
 
    V_AVEPRICE_TMP              FLOAT;
        
    BEGIN 

    VAR_LITSALESVAL_TOT     := 0; 
    VAR_LITSALESQTY_TOT     := 0;
 
    IF VAR_LCONT = 1 THEN
        BEGIN
            IF NVL(V_LITRECNO,0) <=1 THEN
                VAR_LCONT := 0;
            END IF;            
        END;
    END IF;
    
    -- GET THE DELTOALL DETAILS     
    IF VAR_LCONT = 1 THEN
        LITAVGPRICE_DELTOALL(V_LITRECNO, VAR_LITSALESVAL, VAR_LITSALESQTY,  IS_NETT);
        VAR_LITSALESVAL_TOT := VAR_LITSALESVAL_TOT  + NVL(VAR_LITSALESVAL,0);
        VAR_LITSALESQTY_TOT := VAR_LITSALESQTY_TOT  + NVL(VAR_LITSALESQTY,0);        
    END IF;  
             
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_LITSALESQTY,0) > 0 THEN
            V_AVEPRICE :=   'DTA:'||TO_CHAR(VAR_LITSALESVAL) ||'  ' ||TO_CHAR(VAR_LITSALESQTY);          
        END IF;
    END IF;  
             
     -- GET THE DELIVERY DETAILS  - FOR BULK LINES     
    IF VAR_LCONT = 1 THEN
        LITAVGPRICE_DELDET_PO(V_LITRECNO, VAR_LITSALESVAL, VAR_LITSALESQTY,  IS_NETT);
        VAR_LITSALESVAL_TOT := VAR_LITSALESVAL_TOT  + NVL(VAR_LITSALESVAL,0);
        VAR_LITSALESQTY_TOT := VAR_LITSALESQTY_TOT  + NVL(VAR_LITSALESQTY,0);                
    END IF;
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_LITSALESQTY,0) > 0 THEN
            V_AVEPRICE :=   V_AVEPRICE||'   PO:'||TO_CHAR(VAR_LITSALESVAL) ||'  ' ||TO_CHAR(VAR_LITSALESQTY);          
        END IF;
    END IF;  
     
    -- GET THE DELIVERY DETAILS  - FOR PREPACK LINES     
    IF VAR_LCONT = 1 THEN
        LITAVGPRICE_DELDET_WO(V_LITRECNO, VAR_LITSALESVAL, VAR_LITSALESQTY,  IS_NETT);
        VAR_LITSALESVAL_TOT := VAR_LITSALESVAL_TOT  + NVL(VAR_LITSALESVAL,0);
        VAR_LITSALESQTY_TOT := VAR_LITSALESQTY_TOT  + NVL(VAR_LITSALESQTY,0);                
    END IF;
       
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_LITSALESQTY,0) > 0 THEN
            V_AVEPRICE :=   V_AVEPRICE||'   WO:'||TO_CHAR(VAR_LITSALESVAL) ||'  ' ||TO_CHAR(VAR_LITSALESQTY);          
        END IF;
    END IF;
    
    IF VAR_LCONT = 1 THEN
        IF NVL(VAR_LITSALESQTY_TOT,0) > 0 THEN
            --V_AVEPRICE :=   ROUND((VAR_LITSALESVAL/VAR_LITSALESQTY_TOT),2);          
            V_AVEPRICE_TMP :=   ROUND(((VAR_LITSALESVAL_TOT/VAR_LITSALESQTY_TOT)),2)           ;
            V_AVEPRICE :=   V_AVEPRICE||'   AVG:'||TO_CHAR(V_AVEPRICE_TMP);
        END IF;
    END IF;  
    
    RETURN V_AVEPRICE;

END LITAVGPRICE_FRIG ;
    
---*******************************************************************************************************************************************    
-- THIS IS A FRIG THAT POPUALTES ANY ALLOCLITITENO, VALUES IN ALLOCATE THAT MAY HAVE BEEN MISSED
-- I WOULD HOPE THAT IT PICKS NOTHING UP
-- DO NOT THINK THE PREPACK STUFF IS RELAVENT BUT THIS COULD PROVE WRONG IN THE LONG TERM      
---*******************************************************************************************************************************************    
    PROCEDURE WRITEMISSINGALLOCDETS   IS
    BEGIN
        BEGIN
            UPDATE ALLOCATE
            SET ALLOCLITITENO = (SELECT MIN(ITESTO.ISTLITNO) FROM PALNOLOC, ITESTO WHERE PALNOLOC.PALLOCALLNO = ALLOCNO AND PALNOLOC.PALLOCISTRECNO = ITESTO.ISTRECNO) 
            WHERE NVL(ALLOCLITITENO,0) = 0
            AND NVL(ALLOCISPREPPACK,0) = 0;
                    
            COMMIT;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
               NULL;
           WHEN OTHERS THEN
                NULL;
                --RAISE_APPLICATION_ERROR(-20001, 'Oracle Package -FT_PK_LITAVGPRICE- WRITEMISSINGALLOCDETS');
                FT_PK_ERRORS.LOG_AND_STOP;                        
        END;
    END WRITEMISSINGALLOCDETS;  


                  
           
END FT_PK_LITAVGPRICE;

/
