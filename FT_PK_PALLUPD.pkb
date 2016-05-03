SET DEFINE OFF;

 
CREATE OR REPLACE PACKAGE BODY  FT_PK_PALLUPD AS


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



  PROCEDURE LOADTEMPALLOCNEW(IN_TMPTABNAME IN VARCHAR2,
                             --IN_SQLSTRING IN CLOB,   
                             --IN_SQLSTRING2 IN CLOB,   
                             IN_DALRECORDTYPE IN DELTOALL.DALRECORDTYPE%TYPE,
                             IN_ISFROMTKTBK IN NUMBER,
                             IN_ALLOCTRANIN IN VARCHAR2,
                             IN_NOTDPTNO IN NUMBER,
                             IN_SMNNO IN NUMBER,
                             IN_QTYPER IN DELTOALL.QTYPER%TYPE,
                             ) AS  PRAGMA AUTONOMOUS_TRANSACTION;
    V_CONT                  NUMBER(1) := 1;
    V_SQLSTR                VARCHAR(32675);
    
    V_TMPFIELDSTR           VARCHAR(20);

  BEGIN

---- 1  
--   IF IN_SQLSTRING IS NOT NULL THEN
--   BEGIN
--        V_SQLSTR := substr(IN_SQLSTRING, 1, 32675);
--         EXECUTE IMMEDIATE V_SQLSTR;
--        COMMIT;
--    EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--                NULL;
--            WHEN OTHERS THEN
--                FT_PK_ERRORS.LOG_AND_STOP;

--    END;
--    END IF; 

---- 2
--    IF IN_SQLSTRING2 IS NOT NULL THEN
--   BEGIN
--        V_SQLSTR := substr(IN_SQLSTRING2, 1, 32675);
--         EXECUTE IMMEDIATE V_SQLSTR;
--        COMMIT;
--    EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--                NULL;
--            WHEN OTHERS THEN
--                FT_PK_ERRORS.LOG_AND_STOP;

--    END;
--    END IF;
  
-- 3
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ' SET (ALLOCQCNARDESC, PPWASTEPERC) = ' ||
                      '     (SELECT PALQCNAR.QCNARRATIVE, PALQCNAR.PPWASTEPERC' ||
                      ' FROM PALQCNAR ' ||
                      ' WHERE TMPTAB.ALLOCQCCLASS = PALQCNAR.QCNARRECNO) ' ||
                      ' WHERE TMPTAB.ALLOCQCCLASS IS NOT NULL ' ||
                      ' AND EXISTS ' ||
                      ' (SELECT PALQCNAR.QCNARRATIVE ' ||
                      ' FROM PALQCNAR ' ||
                      ' WHERE TMPTAB.ALLOCQCCLASS = PALQCNAR.QCNARRECNO)' ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    
-- 4    
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ' SET TRAYCODE = ' ||
                      '     (SELECT PREANCIL.PANCODE ' ||
                      '     FROM PREANCIL ' ||
                      '     WHERE TMPTAB.ALLOCCONTAINERPANRECNO = PREANCIL.PANRECNO) ' ||
                      ' WHERE TMPTAB.ALLOCCONTAINERPANRECNO IS NOT NULL ' ||
                      ' AND EXISTS ' ||
                      '     (SELECT PREANCIL.PANRECNO ' ||
                      '     FROM PREANCIL ' ||
                      '     WHERE TMPTAB.ALLOCCONTAINERPANRECNO = PREANCIL.PANRECNO) '           
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;
    END;
 
-- 5   
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ' SET PALLETCODE =  ' ||
                      '     (SELECT PREANCIL.PANCODE ' ||
                      '     FROM PREANCIL ' ||
                      '     WHERE TMPTAB.ALLOCPALTYPERECNO = PREANCIL.PANRECNO) ' ||
                      ' WHERE TMPTAB.ALLOCPALTYPERECNO IS NOT NULL ' ||
                      ' AND EXISTS ' ||
                      '     (SELECT PREANCIL.PANRECNO ' ||
                      '     FROM PREANCIL ' ||
                      '     WHERE TMPTAB.ALLOCPALTYPERECNO = PREANCIL.PANRECNO) '
                      ;             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    
-- 6    
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ' SET (ALLOCSUPCODE, SUPACCNAME) = ' || 
                      '     (SELECT (BSDL_PKAGE_ACCOUNTS.GETACCCODE(ACCCLASS.CLARECNO, 2)) CLAACCCODE, ACCOUNTS.ACCNAME ' ||
                      '     FROM ACCCLASS, ACCOUNTS ' ||
                      '     WHERE TMPTAB.ALLOCSENCODE = ACCCLASS.CLARECNO ' ||
                      '     AND       ACCCLASS.CLAACCNO  = ACCOUNTS.ACCRECNO) ' ||
                      ' WHERE TMPTAB.ALLOCSENCODE IS NOT NULL ' ||
                      ' AND EXISTS ' ||
                      '     (SELECT ACCCLASS.CLARECNO ' ||
                      '     FROM ACCCLASS ' ||
                      '     WHERE TMPTAB.ALLOCSENCODE = ACCCLASS.CLARECNO) '       
                      ;             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    
-- 7    
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ' Set StcLocDesc =     (Select StocLoc.StcLocDesc     From StocLoc     Where TMPTAB.AllocStcLoc = StocLoc.StcRecNo) ' ||
                      ' Where Exists ' ||
                      '     (Select StocLoc.StcRecNo    From StocLoc    Where TMPTAB.AllocStcLoc = StocLoc.StcRecNo) ' 
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    
    
-- 8    
    --  Reduce Physical & expected by Qtys in hidden areas for everything
    --  and In prepack area in if not prepack        
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ' SET ALLOCQTY = ALLOCQTY - ' ||
                      '     (SELECT NVL(SUM(NVL(ALLTOARE.AAREPHYSQTY, 0)), 0) ' ||
                      '     FROM ALLTOARE ' ||
                      '     WHERE TMPTAB.ALLOCNO = ALLTOARE.AAREALLOCNO ' ||
                      '     AND (EXISTS ' ||
                      '             (SELECT ALLOCAREALMT.VIEWINALLOCBAYREC ' ||
                      '             FROM ALLOCAREALMT ' ||
                      '             WHERE ALLTOARE.AAREBAYRECNO = ALLOCAREALMT.VIEWINALLOCBAYREC) '; 
                      
         IF NVL(IN_DALRECORDTYPE,0) <> 2 THEN
         BEGIN
            V_SQLSTR := V_SQLSTR || '          OR EXISTS (SELECT STOCLOC.DEFPREPACKAREAIN FROM STOCLOC WHERE ALLTOARE.AAREBAYRECNO = STOCLOC.DEFPREPACKAREAIN)  '; 
         END;
         
         IF NVL(IN_QTYPER,0) = 1  THEN
         BEGIN
         -- if we are looking at stock for boxes and they have set up a default split in area then do not show 
            V_SQLSTR := V_SQLSTR || '          OR EXISTS (SELECT STOCLOC.DEFSPLITAREAIN FROM STOCLOC WHERE ALLTOARE.AAREBAYRECNO = STOCLOC.DEFSPLITAREAIN)  '; 
         END;
         ELSE
         BEGIN
          -- if we are looking at stock for splits and they have set up a default split in area then ONLY not show the split area stock 
            V_SQLSTR := V_SQLSTR || '          OR NOT EXISTS (SELECT STOCLOC.DEFSPLITAREAIN FROM STOCLOC WHERE ALLTOARE.AAREBAYRECNO = STOCLOC.DEFSPLITAREAIN)  '; 
         END;
         
         END IF; 
         
         V_SQLSTR := V_SQLSTR || '     )) ' 
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    
    
-- 9    
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||
                      '         SET ALLOCEXP = ALLOCEXP -  ' ||
                      '     (SELECT  NVL(SUM(NVL(ALLTOARE.AAREEXPQTY, 0)), 0) ' ||
                      '     FROM ALLTOARE ' ||
                      '     WHERE TMPTAB.ALLOCNO = ALLTOARE.AAREALLOCNO ' ||
                      '     AND (EXISTS (SELECT ALLOCAREALMT.VIEWINALLOCBAYREC FROM ALLOCAREALMT WHERE ALLTOARE.AAREBAYRECNO = ALLOCAREALMT.VIEWINALLOCBAYREC) ';
        IF NVL(IN_DALRECORDTYPE,0) <> 2 THEN
        BEGIN
                               
            V_SQLSTR := V_SQLSTR || '                   OR EXISTS (SELECT STOCLOC.DEFPREPACKAREAIN FROM STOCLOC WHERE ALLTOARE.AAREBAYRECNO = STOCLOC.DEFPREPACKAREAIN) ';
        END;
        END IF; 
         
        V_SQLSTR := V_SQLSTR || '     )) '
        ;
             
        EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    
-- 10
    IF NVL(IN_DALRECORDTYPE,0) = 2 THEN       --  for prepack lines    
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ' SET AVAILINPHOUSE = ' ||
                      '     (SELECT  NVL(SUM(NVL(ALLTOARE.AAREPHYSQTY, 0) - NVL(ALLTOARE.AAREALLOCQTY, 0)), 0) ' ||
                      '     FROM ALLTOARE, WHINTLOC, WHINAREA ' ||
                      '     WHERE ALLOCNO = ALLTOARE.AAREALLOCNO ' ||
                      '     AND ALLTOARE.AAREBAYRECNO = WHINTLOC.STCBAYRECNO ' ||
                      '     AND WHINTLOC.STCLOC = WHINAREA.STCLOC ' ||
                      '     AND WHINTLOC.STCAREACODE = WHINAREA.WHIAREA ' ||
                      '     AND NVL(WHINAREA.WHISHOWINPAK, 0) = 1) ' ||
                      '     WHERE EXISTS ' ||
                      '     (SELECT ALLTOARE.AAREBAYRECNO ' ||
                      '     FROM ALLTOARE, WHINTLOC, WHINAREA ' ||
                      '     WHERE ALLOCNO = ALLTOARE.AAREALLOCNO ' ||
                      '     AND ALLTOARE.AAREBAYRECNO = WHINTLOC.STCBAYRECNO ' ||
                      '     AND WHINTLOC.STCLOC = WHINAREA.STCLOC ' ||
                      '     AND WHINTLOC.STCAREACODE = WHINAREA.WHIAREA ' ||
                      '     AND NVL(WHINAREA.WHISHOWINPAK, 0) = 1) ' 
         ;             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;

-- 11
    IF NVL(IN_DALRECORDTYPE,0) = 3 THEN       --  for RESERVATION LINES    
    BEGIN
        V_TMPFIELDSTR := ' TMPINPQTY ';    
    END;    
    ELSE
    BEGIN
        V_TMPFIELDSTR := ' TMPISSQTY ';
    END;
    END IF;



    
-- 12    
    IF NVL(IN_DALRECORDTYPE,0) > 0
    AND LENGTH(TRIM(NVL(IN_ALLOCTRANIN, ''))) > 0 THEN  
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ';              
        
        IF IN_ISFROMTKTBK = 1 THEN
        BEGIN
        --     REALALLOCQTY_SPLIT holds the DELTOALL.DALQTY for any lines - this is needed in TKTBL when the  TmpIssQty is overwritten by the split avail
        --     the TmpIssQty will hold the split qty from ACTSPLITQTY

            V_SQLSTR := V_SQLSTR || ' SET ('|| V_TMPFIELDSTR ||', REALALLOCQTY_SPLIT) =  ' ||
                      ' (SELECT  NVL(SUM((CASE WHEN NVL(ACTSPLITQTY,0) > 0 THEN NVL(ACTSPLITQTY,0) ELSE NVL(DELTOALL.DALQTY, 0) END)), 0), ' || 
                      ' NVL(SUM(NVL(DELTOALL.DALQTY, 0)), 0) ';
        END;
        ELSE
        BEGIN
            V_SQLSTR := V_SQLSTR || ' SET '|| V_TMPFIELDSTR ||' = (SELECT  NVL (SUM(NVL(DELTOALL.DALQTY, 0)), 0) ';        
        END;
        END IF;                  
            
        V_SQLSTR := V_SQLSTR || ' FROM DELTOALL ' ||
                      ' WHERE DELTOALL.DALRECORDTYPE = ' || TO_CHAR(IN_DALRECORDTYPE) ||
                      ' AND DELTOALL.DALTYPERECNO  ' || TRIM(IN_ALLOCTRANIN) ||
                      ' AND ALLOCNO = DELTOALL.DALALLOCNO) ' ||
                      ' WHERE EXISTS ' ||
                      '     (SELECT DALTYPERECNO ' ||
                      '     FROM DELTOALL ' ||
                      '     WHERE DELTOALL.DALRECORDTYPE = ' || TO_CHAR(IN_DALRECORDTYPE) ||
                      '     AND DELTOALL.DALTYPERECNO   ' || TRIM(IN_ALLOCTRANIN) ||
                      '     AND ALLOCNO = DELTOALL.DALALLOCNO) ' 
                    
         ;    
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;


-- 13
-- this query works out any qty of allocated splits that we might have - split being apport to wgt, each or inner
-- it also takes those allocated splits and calc the numb of splits that this would create so we have a fig of already created splits
    
    IF IN_ISFROMTKTBK = 1 THEN
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ' SET (ACTSPLITQTY_BOX, ACTSPLITQTY_WGT, ACTSPLITQTY_EACH, ACTSPLITQTY_INNER) =  ' ||
                      '     (SELECT   ' ||
                      '     SUM(NVL((CASE WHEN NVL(DELTOALL.QTYPER,1) = 1 THEN NVL(DELTOALL.DALQTY, 0) ELSE 0 END),0)) SUMACTSPLITQTY_BOX, ' ||
                      '     SUM(NVL((CASE WHEN DELTOALL.QTYPER = 2 THEN NVL(DELTOALL.ACTSPLITQTY, 0) ELSE 0 END),0)) SUMACTSPLITQTY_WGT, ' ||
                      '     SUM(NVL((CASE WHEN DELTOALL.QTYPER = 3 THEN NVL(DELTOALL.ACTSPLITQTY, 0) ELSE 0 END),0)) SUMACTSPLITQTY_EACH, ' ||
                      '     SUM(NVL((CASE WHEN DELTOALL.QTYPER = 4 THEN NVL(DELTOALL.ACTSPLITQTY, 0) ELSE 0 END),0)) SUMACTSPLITQTY_INNER ' ||
                      ' FROM DELTOALL ' ||
                      ' WHERE TMPTAB.ALLOCNO = DELTOALL.DALALLOCNO) ' 
                      ;             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;

-- 14
    --   if we have Splits created in the Ticket Book routines then we will have left-over qtys on those split lines that are available to sell
    --   these lines will not be picked up in the extracted above as their ALLOCBY > 0
    --   i want to pick them up here and get ther values and then they are available in ENTTKTORD_DETS to display
    
    IF IN_ISFROMTKTBK = 1 THEN      
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||
                      ' SET (ALRDY_SPLITQTY_WGT, ALRDY_SPLITQTY_EACH, ALRDY_SPLITQTY_INNER) =  ' || 
                      '     (SELECT  ' ||
                      '      SUM(NVL((CASE WHEN  ALLOCBY = 2 THEN NVL(ALLOCQTY,0) - NVL(ALLOCALLOC,0) ELSE 0 END ),0))  WGT, ' ||
                      '      SUM(NVL((CASE WHEN  ALLOCBY = 3 THEN NVL(ALLOCQTY,0) - NVL(ALLOCALLOC,0) ELSE 0 END ),0))  EACH, ' ||
                      '      SUM(NVL((CASE WHEN  ALLOCBY = 4 THEN NVL(ALLOCQTY,0) - NVL(ALLOCALLOC,0) ELSE 0 END ),0))  INNER  ' ||
                      --'     FROM ALLOCATE  ' ||
                      --'     WHERE ALLOCPRDNO    = TMPTAB.ALLOCPRDNO ' ||
                      --'     AND ALLOCPONO       = TMPTAB.ALLOCPONO    ' ||
                      --'     AND ALLOCLITID      = TMPTAB.ALLOCLITID   ' ||
                      --'     AND ALLOCSTCLOC     = TMPTAB.ALLOCSTCLOC  ' ||
                      --'     AND NVL(ALLOCATE.ALLOCBY, 0) > 1 ' ||
                      '      FROM ALLOCATESPLITS, ALLOCATE  ' ||
                      '       WHERE TMPTAB.ALLOCNO  = ALLOCATESPLITS.BOXALLOCNO  ' ||
                      '       AND  ALLOCATESPLITS.SPLITALLOCNO = ALLOCATE.ALLOCNO ' ||                                           
                      '     AND NVL(ALLOCQTY,0) > NVL(ALLOCALLOC,0) ' ||
                      '     ) '                                                     
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;


-- 15
    IF NVL(IN_DALRECORDTYPE,0) > 0
    AND LENGTH(TRIM(NVL(IN_ALLOCTRANIN, ''))) > 0 THEN  
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||          
                      ' SET DETAILEDLO = 1  ' ||
                      ' WHERE EXISTS  ' ||
                      ' (SELECT DALTYPERECNO  ' ||
                      '     FROM DELTOALL  ' ||
                      '     WHERE DELTOALL.DALRECORDTYPE = ' || TO_CHAR(IN_DALRECORDTYPE) ||
                      '     AND DELTOALL.DALTYPERECNO  ' || IN_ALLOCTRANIN ||
                      '     AND TMPTAB.ALLOCNO = DELTOALL.DALALLOCNO  ' ||
                      '     AND DELTOALL.DALPALLOCRECNO IS NOT NULL)  '              
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;



-- 16
    IF NVL(IN_DALRECORDTYPE,0) > 0
    AND LENGTH(TRIM(NVL(IN_ALLOCTRANIN, ''))) > 0 THEN  
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||        
                      ' SET DALWIZUNIQUEID =   ' ||
                      '     (SELECT MIN(DELTOALL.DALWIZUNIQUEID)  ' ||
                      '     FROM DELTOALL  ' ||
                      '     WHERE DELTOALL.DALRECORDTYPE =  ' || TO_CHAR(IN_DALRECORDTYPE) ||
                      '     AND DELTOALL.DALTYPERECNO   ' || IN_ALLOCTRANIN ||
                      '     AND TMPTAB.ALLOCNO = DELTOALL.DALALLOCNO)  ' ||
                      ' WHERE EXISTS  ' ||
                      '     (SELECT DELTOALL.DALWIZUNIQUEID  ' ||
                      '     FROM DELTOALL  ' ||
                      '     WHERE DELTOALL.DALRECORDTYPE =  ' || TO_CHAR(IN_DALRECORDTYPE) ||
                      '     AND DELTOALL.DALTYPERECNO   ' || IN_ALLOCTRANIN ||
                      '     AND TMPTAB.ALLOCNO = DELTOALL.DALALLOCNO  ' ||
                      '     AND DELTOALL.DALPALLOCRECNO IS NULL)  '                
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF; 

-- 17
    IF NVL(IN_DALRECORDTYPE,0) = 1 
    AND LENGTH(TRIM(NVL(IN_ALLOCTRANIN, ''))) > 0 THEN  
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||        
                      ' SET QCFLAGGED = 1  ' ||
                      ' WHERE EXISTS  ' ||
                      '     (SELECT DELTOALL.DALWIZUNIQUEID  ' ||
                      '     FROM DELTOALL  ' ||
                      '     WHERE DELTOALL.DALRECORDTYPE = ' || TO_CHAR(IN_DALRECORDTYPE) ||
                      '     AND DELTOALL.DALTYPERECNO  ' || IN_ALLOCTRANIN ||
                      '     AND TMPTAB.ALLOCNO = DELTOALL.DALALLOCNO  ' ||
                      '     AND NVL(DELTOALL.QCFLAGGED, 0) > 0) '
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF ;

-- 18  
    IF IN_ISFROMTKTBK = 0 THEN
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||        
                      ' SET RELAXEDPICKQTY =   ' ||
                      '     (SELECT  NVL(SUM(NVL(PALINDET.QTYBOXES,0)), 0)  ' ||
                      '     FROM PALINDET, PALNOLOC, DELTOLOC  ' ||
                      '     WHERE TMPTAB.ALLOCNO = DELTOLOC.LOCALLOCNO  ' ||
                      '     AND DELTOLOC.LOCRECNO = PALINDET.DELLOCRECNO  ' ||
                      '     AND PALINDET.PALLOCRECNO = PALNOLOC.PALLOCRECNO  ' ||
                      '    AND  PALNOLOC.PALLOCALLNO <> TMPTAB.ALLOCNO)  ' ||
                      ' WHERE EXISTS  ' ||
                      '     (SELECT DELTOLOC.LOCALLOCNO  ' ||
                      '     FROM PALINDET, PALNOLOC, DELTOLOC  ' ||
                      '     WHERE TMPTAB.ALLOCNO = DELTOLOC.LOCALLOCNO  ' ||
                      '     AND DELTOLOC.LOCRECNO = PALINDET.DELLOCRECNO  ' ||
                      '     AND PALINDET.PALLOCRECNO = PALNOLOC.PALLOCRECNO  ' ||
                      '    AND  PALNOLOC.PALLOCALLNO <> TMPTAB.ALLOCNO)'      
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;


-- 19
    IF IN_ISFROMTKTBK = 1 THEN
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||
                      ' SET LOTNO = SUBSTR(ALLOCLITID, 1, INSTR(ALLOCLITID, ''/'') -1) ' ||
                      '  WHERE INSTR(ALLOCLITID, ''/'') > 0 ' ||
                      '  AND ALLOCISPREPPACK = 0 ' ||
                      '  AND NVL(LITITENO,0) < 1 '           
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;


-- 20
    IF IN_ISFROMTKTBK = 1 THEN
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      '  SET LITITENO = (SELECT MIN(LOTITE.LITITENO) FROM LOTDET, LOTITE  ' ||
                      '                               WHERE  LOTDET.DETRECNO = LOTITE.LITDETNO ' || 
                      '                               AND LOTDET.DETLHERECNO = TMPTAB.LOTNO   ' ||
                      '                               AND LOTITE.LITID  = TMPTAB.ALLOCLITID) ' || 
                      '  WHERE NVL(TMPTAB.LITITENO,0) < 1 ' 
                      ;             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;
  
-- 21
    IF IN_ISFROMTKTBK = 1 THEN
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||        
                      '  SET (LITID2, LITGUIDEPRICE, AVGGROSSPRC, LITRCVDATE, LITQTYRCV) = (SELECT LITID2, LITGUIDEPRICE, AVGGROSSPRC, LITRCVDATE, ' || 
                      '   (CASE WHEN NVL(LITRCVIND, ''N'') = ''Y'' THEN LITQTYRCV ELSE LITORGEXP END) FROM LOTITE  ' ||
                      '                              WHERE  LOTITE.LITITENO      = TMPTAB.LITITENO) ' ||
                      '   WHERE NVL(LITITENO,0) > 0 '                
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;



-- 22
--     I'VE MADE THIS 'MIN' AS THERE MAY POSSIBLY BE MULTIPLE DEPARTMENTS SET UP AGAINST A BUYER ( THOU THEY SHOULD NOT BE)

    IF IN_ISFROMTKTBK = 1 THEN
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||
                      '   SET DPTRECNO = (SELECT MIN(DEPARTMENTSTOSMN.DPTRECNO) FROM LOTITE, DEPARTMENTSTOSMN ' || 
                      '                            WHERE  LOTITE.LITITENO      = TMPTAB.LITITENO ' ||
                      '                           AND LOTITE.LITBUYER             = DEPARTMENTSTOSMN.SMNNO) ' ||
                      '    WHERE NVL(DPTRECNO,0) < 0 ' ||
                      '    AND  NVL(LITITENO,0) > 0 '                
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;

 

-- 23
    IF IN_ISFROMTKTBK = 1 THEN
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||   
                      '    SET DEPT_DESC = (SELECT DEPARTMENTS.DPT_DESC FROM DEPARTMENTS  WHERE  DEPARTMENTS.DPTRECNO = TMPTAB.DPTRECNO) ' ||
                      '     WHERE NVL(DPTRECNO,0) > 0 '             
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;
    END;
    END IF;


  

-- 24
    IF IN_ISFROMTKTBK = 1 
    AND NVL(IN_NOTDPTNO, 0) > 0 THEN
    BEGIN
        V_SQLSTR := ' DELETE FROM ' || TRIM(IN_TMPTABNAME) || ' WHERE DPTRECNO =  ' || TO_CHAR(IN_NOTDPTNO)               
                      ;             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;

-- 25
    IF IN_ISFROMTKTBK = 1 
    AND NVL(IN_SMNNO, 0) > 0 THEN
    BEGIN
        V_SQLSTR := ' DELETE FROM ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||
                      '    WHERE DPTRECNO > 0 ' ||
                      '     AND NOT EXISTS (SELECT 1 FROM DEPARTMENTSTOSMN WHERE SMNNO = '|| TO_CHAR(IN_SMNNO)||' AND DEPARTMENTSTOSMN.DPTRECNO = TMPTAB.DPTRECNO) ' ||
                      '     AND NVL(TMPTAB.TMPISSQTY,0) = 0'                       
                      ;             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;
    END IF;

  
/*
-- 26
    IF IN_ISFROMTKTBK = 1 THEN
    BEGIN
        V_SQLSTR := ' UPDATE  ' || TRIM(IN_TMPTABNAME) || ' TMPTAB ' ||               
                      ;
             
         EXECUTE IMMEDIATE V_SQLSTR;
        
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;


*/  

    BEGIN
        COMMIT;
    EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP;

    END;

  END LOADTEMPALLOCNEW;
  
  
  

END FT_PK_PALLUPD ;
/


