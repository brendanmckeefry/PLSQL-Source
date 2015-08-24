SET DEFINE OFF;

CREATE OR REPLACE PACKAGE BODY FT_PK_ALLOCATE_CHECK
AS
  CVERSIONCONTROLNO VARCHAR2(12) := '1.0.0'; -- CURRENT VERSION NUMBER
  
    ---*******************************************************************************************************************************************
  -- THIS METHOD CALLS ALL THE OTHERS TO DO A FULL REPAIR OF THE TABLES
  ---*******************************************************************************************************************************************
  PROCEDURE REPAIR_MAIN
  IS
  BEGIN
    BEGIN      
      -- REPAIR THE DELTOALL FIGURES FIRST
      REPAIR_DELTOALL_FULL();
      -- AFTER THE DELTOALL FIGURES ARE REPAIRED THEN DO THE ALLOCALLOC ONES
      REPAIR_ALLOCALLOC();
    EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
    END;
  END REPAIR_MAIN;
  
  ---*******************************************************************************************************************************************
  -- THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE DELTOALL
  ---*******************************************************************************************************************************************
  PROCEDURE REPAIR_DELTOALL_FULL
  IS
  BEGIN
    BEGIN      
    
      REPAIR_DELTOALL_MIN();
      
      ---***---***---***---***---***---***---***---***---***---***---***---***      
      -- WIZCHKSTMT 800 REMOVE ANY DELTOALLS FOR DELDETS THAT DO NOT EXIST      
      ---***---***---***---***---***---***---***---***---***---***---***---***      
      DELETE FROM DELTOALL  WHERE DALRECORDTYPE = 1 AND NOT EXISTS ( SELECT 1 FROM DELDET WHERE  DALTYPERECNO = DELDET.DELRECNO); 
      COMMIT;

      ---***---***---***---***---***---***---***---***---***---***---***---***      
      -- WIZCHKSTMT 800 REMOVE ANY DELTOALLS FOR PRERECONS THAT DO NOT EXIST      
      ---***---***---***---***---***---***---***---***---***---***---***---***      
      DELETE FROM DELTOALL  WHERE DALRECORDTYPE = 2 AND NOT EXISTS ( SELECT 1 FROM PRERECON WHERE  DALTYPERECNO = PRERECON.PHRRECNO); 
      COMMIT;

      ---***---***---***---***---***---***---***---***---***---***---***---***      
      -- WIZCHKSTMT 800 REMOVE ANY DELTOALLS FOR PRGDETS THAT DO NOT EXIST      
      ---***---***---***---***---***---***---***---***---***---***---***---***      
      DELETE FROM DELTOALL  WHERE DALRECORDTYPE = 3 AND NOT EXISTS ( SELECT 1 FROM PRGDET WHERE  DALTYPERECNO = PRGDET.DALALLRECNO);  
      COMMIT;

      ---***---***---***---***---***---***---***---***---***---***---***---***      
      -- WIZCHKSTMT 800 REMOVE ANY DELTOALLS FOR PALNOLOCS THAT DO NOT EXIST      
      ---***---***---***---***---***---***---***---***---***---***---***---***      
      DELETE FROM DELTOALL  DELTOALL WHERE DALPALLOCRECNO IS NOT NULL AND NOT EXISTS ( SELECT 1 FROM PALNOLOC WHERE   DALPALLOCRECNO = PALNOLOC.PALLOCRECNO);
      COMMIT;
      
      ---***---***---***---***---***---***---***---***---***---***---***---***
      ---    IF THE DELDET QTY IS 0 THEN DELETE THE DELTOALLS
      ---***---***---***---***---***---***---***---***---***---***---***---***
      DELETE FROM DELTOALL
      WHERE DALWIZUNIQUEID IN
        (SELECT DALWIZUNIQUEID FROM
          (SELECT DALWIZUNIQUEID, DALTYPERECNO, SUM(NVL(DALQTY,0)) DALQTY ,            
            (SELECT SUM(NVL(DELQTY,0)) FROM DELDET WHERE DALTYPERECNO = DELDET.DELRECNO) DELQTY
           FROM DELTOALL
          WHERE DALRECORDTYPE = 1
          GROUP BY DALWIZUNIQUEID, DALTYPERECNO          
          )
        WHERE DALQTY > DELQTY
        AND DELQTY   = 0
        );
      COMMIT;
      
    EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
    END;
  END REPAIR_DELTOALL_FULL;
  ---*******************************************************************************************************************************************
  -- THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE DELTOALL
  ---*******************************************************************************************************************************************
  PROCEDURE REPAIR_DELTOALL_MIN
  IS
  BEGIN
    BEGIN      
      ---***---***---***---***---***---***---***---***---***---***---***---***      
      -- WIZCHKSTMT 800 REMOVE ANY DELTOALLS FOR ALLOCATES THAT DO NOT EXIST      
      ---***---***---***---***---***---***---***---***---***---***---***---***      
      DELETE FROM DELTOALL  WHERE NOT EXISTS (SELECT 1 FROM ALLOCATE WHERE ALLOCNO = DELTOALL.DALALLOCNO);
      COMMIT;
      
      ---***---***---***---***---***---***---***---***---***---***---***---***
      ---    REMOVE ANY NEGATIVES OR ZEROS IN DELTOALL 
      ---***---***---***---***---***---***---***---***---***---***---***---***     
      -- WIZCHKSTMT 802
      UPDATE DELTOALL SET DALQTY = 0 WHERE NVL(DALQTY,0) <0 ;
      COMMIT;
      
      UPDATE DELTOALL SET ACTSPLITQTY = 0 WHERE NVL(ACTSPLITQTY,0) <0 ;
      COMMIT;
      
      -- WIZCHKSTMT 803
      DELETE FROM DELTOALL WHERE NVL(DALQTY,0) = 0 AND NVL(ACTSPLITQTY,0) = 0;
      COMMIT;
      
      
    EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
    END;
  END REPAIR_DELTOALL_MIN;
  
  ---*******************************************************************************************************************************************
  -- THIS METHOD FIXES ANY ISSUES THAT MAY BE IN THE ALLOCALLOC
  ---*******************************************************************************************************************************************
  PROCEDURE REPAIR_ALLOCALLOC
  IS
  BEGIN
    BEGIN
    
    ---***---***---***---***---***---***---***---***---***---***---***---***       
    ---    ANY ALLOCATE RECORDS WITH NEGATIVE QTIES
    ---***---***---***---***---***---***---***---***---***---***---***---***       

    -- WIZCHKSTMT 150        
      UPDATE ALLOCATE SET ALLOCALLOC = 0 WHERE ALLOCALLOC < 0;
      COMMIT;
    
      UPDATE ALLOCATE SET ALLOCQTY_SPLIT  = 0 WHERE ALLOCQTY_SPLIT  < 0;
      COMMIT;
    
      -- WIZCHKSTMT 160 AND 161
      UPDATE ALLOCATE
      SET ALLOCALLOC =        (SELECT SUM(NVL(DALQTY,0)) FROM DELTOALL WHERE DELTOALL.DALALLOCNO = ALLOCATE.ALLOCNO)
      WHERE ALLOCNO IN        (SELECT DALALLOCNO FROM
                                (SELECT DALALLOCNO,SUM(NVL(DALQTY,0)) SUMDALQTY,NVL(ALLOCALLOC,0) ALLOCALLOC
                                  FROM DELTOALL,ALLOCATE
                                  WHERE DELTOALL.DALALLOCNO = ALLOCATE.ALLOCNO
                                  GROUP BY DALALLOCNO,ALLOCALLOC 
                                ) TMPTAB
                              WHERE SUMDALQTY <> ALLOCALLOC
                              );
      COMMIT;
      
      UPDATE ALLOCATE
      SET ALLOCQTY_SPLIT= NVL((SELECT SUM(NVL(ACTSPLITQTY,0))FROM DELTOALL WHERE DELTOALL.DALALLOCNO = ALLOCATE.ALLOCNO AND NVL(QTYPER, 1)        > 1),0)
      WHERE ALLOCNO IN        (SELECT DALALLOCNO FROM
                                (SELECT DALALLOCNO, SUM(NVL(ACTSPLITQTY,0)) SUMACTSPLITQTY, NVL(ALLOCQTY_SPLIT,0) ALLOCQTY_SPLIT
                                  FROM DELTOALL,ALLOCATE
                                  WHERE DELTOALL.DALALLOCNO = ALLOCATE.ALLOCNO
                                  AND NVL(QTYPER, 1)        > 1
                                  GROUP BY DALALLOCNO,  ALLOCQTY_SPLIT
                                )
                              WHERE SUMACTSPLITQTY <> ALLOCQTY_SPLIT
                              );
      COMMIT;
      
      
      ---***---***---***---***---***---***---***---***---***---***---***---***
      ---    ENSURE THE ALLOCALLOC QTY IS ZERO IF WE HAVE NO DELTOALLS
      ---***---***---***---***---***---***---***---***---***---***---***---***       
      --161
      UPDATE ALLOCATE
      SET ALLOCALLOC =     0
      WHERE ALLOCNO NOT IN     (SELECT DALALLOCNO   FROM DELTOALL)
      AND ALLOCALLOC <> 0;
      COMMIT;

      UPDATE ALLOCATE
      SET ALLOCQTY_SPLIT =     0
      WHERE ALLOCNO NOT IN     (SELECT DALALLOCNO   FROM DELTOALL WHERE NVL(QTYPER, 1) > 1)
      AND ALLOCQTY_SPLIT <> 0;
      COMMIT;
      
    EXCEPTION
    WHEN OTHERS THEN
      FT_PK_ERRORS.LOG_AND_STOP;
    END;
  END REPAIR_ALLOCALLOC;
  
  FUNCTION CURRENTVERSION(
      IN_BODYORSPEC IN INTEGER )
    RETURN VARCHAR2
  IS
  BEGIN
    IF IN_BODYORSPEC = CONST.C_SPEC THEN
      RETURN CSPECVERSIONCONTROLNO;
    ELSE
      RETURN CVERSIONCONTROLNO;
    END IF;
  END CURRENTVERSION;
--
--    -- INITIALISATION SECTION
--    BEGIN
--        BEGIN
--
--            SELECT (CASE WHEN UPPER(SYSPREFVALUE) = 'TRUE' THEN 1 ELSE 0 END) LUSELITPAYTYP
--            INTO V_USELITPAYTYP
--            FROM WIZSYSPREF WHERE SYSPREFNAME = 'LUSELITPAYTYP' ;
--        EXCEPTION
--            WHEN OTHERS THEN
--               FT_PK_ERRORS.LOG_AND_STOP;
--               V_USELITPAYTYP  := 0;
--        END;
END FT_PK_ALLOCATE_CHECK;
