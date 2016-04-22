CREATE OR REPLACE PACKAGE BODY FT_PK_PRODUCTS AS

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

FUNCTION  GETPRDSHORTCODE(  In_PrcPrdNo     IN NUMBER,
                            In_SalOffNo     IN NUMBER       )
            --RETURN PRDREC.PRCSHORTDESC%TYPE IS V_PRDSHORTCODE PRDREC.PRCSHORTDESC%TYPE :=NULL ;
            RETURN VARCHAR2  IS V_PRDSHORTCODE VARCHAR2(10)  :=NULL ;

    L_UsePRDRECTOSO    NUMBER(1) := 0;
    V_SalOffNo          NUMBER(5) := -32000;

    BEGIN

        IF In_SalOffNo > 0 THEN
            -- this just ensures that if the saloffno is blank then we use the ALL Option
            V_SalOffNo := In_SalOffNo;
        END IF;

        IF In_PrcPrdNo > 0 THEN
            IF V_SO_SPECIFIC_PRDSHORTCODE = 1 THEN
                IF In_SalOffNo > 0 AND In_SalOffNo <> 32767 THEN
                    L_UsePRDRECTOSO :=1;
                END IF;
            END IF;
        END IF;

        IF L_UsePRDRECTOSO <> 0 THEN
            BEGIN
                SELECT TRIM(SOSHORTCODE) INTO V_PRDSHORTCODE
                FROM PRDRECTOSO
                WHERE PRDRECTOSO.PRCPRDNO   = In_PrcPrdNo
                AND PRDRECTOSO.SALOFFNO     = IN_SALOFFNO
                AND PRDRECTOSO.ACTIVE = 1
                ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
                V_PRDSHORTCODE := NULL;
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20001, 'FT_PK_PRODUCTS - GETPRDSHORTCODE(V_PRDSHORTCODE) (PRDRECTOSO) '|| SQLCODE || '~'||SQLERRM);
                V_PRDSHORTCODE := NULL;
            END;
        END IF;

        -- this code will be called if
        -- (1) the syspref for specific product short codes is false
        -- (2) if the code in  PRDRECTOSO is blank -it really should not be
        -- (3) If the user is looking at this from an 'all sales office' view
        -- in the above circumstances we use he CODE from PRDREC
        IF V_PRDSHORTCODE IS NULL THEN
            BEGIN
                SELECT TRIM(PRCSHORTDESC) INTO V_PRDSHORTCODE FROM PRDREC WHERE PRCPRDNO = In_PrcPrdNo;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
                V_PRDSHORTCODE := NULL;
            WHEN OTHERS THEN

                RAISE_APPLICATION_ERROR(-20001, 'FT_PK_PRODUCTS - GETPRDSHORTCODE(V_PRDSHORTCODE) (PRDREC) '|| SQLCODE || '~'||SQLERRM);
                V_PRDSHORTCODE := NULL;
            END;
        END IF ;


    RETURN V_PRDSHORTCODE;

END GETPRDSHORTCODE;




FUNCTION  ISPRDFORSALESOFFICE(  In_PrcPrdNo     IN NUMBER,
                            In_SalOffNo     IN NUMBER       )
            --RETURN PRDREC.PRCSHORTDESC%TYPE IS V_PRDSHORTCODE PRDREC.PRCSHORTDESC%TYPE :=NULL ;
            RETURN NUMBER  IS V_ISFORSO NUMBER(1)  := 0 ;

    L_UsePRDRECTOSO     NUMBER(1) := 0;
    V_SalOffNo          NUMBER(5) := -32000;
    L_Cont              NUMBER(1) := 1;

    BEGIN

        IF L_Cont = 1 THEN
            IF In_SalOffNo <=0  OR In_SalOffNo >= 32767  THEN
                V_ISFORSO := 1;
                L_Cont := 0;
            ELSE
                V_SalOffNo := In_SalOffNo;
            END IF;
        END IF;

        IF L_Cont = 1 THEN
            IF In_PrcPrdNo <= 0 THEN
                V_ISFORSO := 1;
                L_Cont := 0;
            END IF;
        END IF;

        IF L_Cont = 1 THEN
            IF V_SO_PRODLIMITBYSALOFF = 0 THEN
                V_ISFORSO := 1;
                L_Cont := 0;
            END IF;
        END IF;

        IF L_Cont = 1 THEN
            BEGIN
                SELECT DISTINCT  1 INTO V_ISFORSO
                FROM PRDRECTOSO
                WHERE PRDRECTOSO.PRCPRDNO   = In_PrcPrdNo
                AND PRDRECTOSO.SALOFFNO     = IN_SALOFFNO
                AND PRDRECTOSO.ACTIVE = 1
                ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20001, 'FT_PK_PRODUCTS - ISPRDFORSALESOFFICE(V_PRDSHORTCODE) (PRDRECTOSO) '|| SQLCODE || '~'||SQLERRM);
            END;
        END IF;

    RETURN V_ISFORSO;

END ISPRDFORSALESOFFICE;

-- initialisation section
BEGIN
    BEGIN
        SELECT COUNT(*) INTO V_SO_SPECIFIC_PRDSHORTCODE FROM WIZSYSPREF WHERE SYSPREFNAME = 'PRODSHORTCODEBYSALOFF' AND UPPER(SYSPREFVALUE) = 'TRUE';
        SELECT COUNT(*) INTO V_SO_PRODLIMITBYSALOFF FROM WIZSYSPREF WHERE SYSPREFNAME = 'PRODLIMITBYSALOFF' AND UPPER(SYSPREFVALUE) = 'TRUE';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
            V_SO_SPECIFIC_PRDSHORTCODE := 0;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'FT_PK_PRODUCTS -INIT');
            V_SO_SPECIFIC_PRDSHORTCODE := 0;
    END;

    IF V_SO_SPECIFIC_PRDSHORTCODE > 1 THEN
    BEGIN
        V_SO_SPECIFIC_PRDSHORTCODE := 1;
    END;
    END IF;


END FT_PK_PRODUCTS;
/