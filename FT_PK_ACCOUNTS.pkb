CREATE OR REPLACE PACKAGE BODY            FT_PK_ACCOUNTS
AS

   cVersionControlNo   VARCHAR2(12) := '1.0.2'; -- Current Version Number

FUNCTION  GETACCCODE(  In_ClaRecNo     IN NUMBER,
                       In_SalOffNo     IN NUMBER       )
                                                                --RETURN ACCCLASS.CLAACCCODE%TYPE IS V_ACCCODE ACCCLASS.CLAACCCODE%TYPE :=NULL ;
                                                                RETURN VARCHAR2  IS V_ACCCODE VARCHAR2(8)  :=NULL ;


    L_UseACCTOSALOFF    NUMBER(1) := 0;
    V_SalOffNo          NUMBER(5) := -32000;
    BEGIN


        IF In_SalOffNo > 0 THEN
        -- this just ensures that if the saloffno is blank then we use the ALL Option
            V_SalOffNo := In_SalOffNo;
        END IF;

        IF In_ClaRecNo > 0 THEN
            IF V_SO_SPECIFIC_ACCCODE = 1 THEN
                IF In_SalOffNo > 0 AND In_SalOffNo <> 32767 THEN
                    L_UseACCTOSALOFF :=1;
                END IF;
            END IF;
        END IF;

        IF L_UseACCTOSALOFF <> 0 THEN
            BEGIN
                SELECT TRIM(ACSACCCODE) INTO V_ACCCODE
                FROM ACCTOSALOFF
                WHERE ACCTOSALOFF.ACSCLARECNO =  In_ClaRecNo
                AND ACCTOSALOFF.ACSSALOFFNO = In_SalOffNo;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
                V_ACCCODE := NULL;
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20001, 'BSDL_PKAGE_ACCOUNTS - GETACCCODE(ACCTOSALOFF) = '|| SQLCODE || '~'||SQLERRM);
                V_ACCCODE := NULL;
            END;
        END IF;

        -- this code will be called if
        -- (1) the syspref for specific account codes is false
        -- (2) if the code in  ACCTOSALOFF is blank -it really should not be
        -- (3) if the user is set up to see all suppliers and the sales office, clarecno combination is not in ACCTOSALOFF
        -- in the above circumstances we use he CODE from accclass
        IF V_ACCCODE IS NULL THEN
            BEGIN
                SELECT TRIM(CLAACCCODE) INTO V_ACCCODE FROM ACCCLASS WHERE CLARECNO = In_ClaRecNo;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
                V_ACCCODE := NULL;
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20001, 'BSDL_PKAGE_ACCOUNTS - GETACCCODE(ACCCLASS) = '|| SQLCODE || '~'||SQLERRM);
                V_ACCCODE := NULL;
            END;
        END IF ;

    RETURN V_ACCCODE;



END GETACCCODE;

FUNCTION GETEXCLRECOVFLAG(CLARECNO_IN ACCCLASS.CLARECNO%TYPE) RETURN BOOLEAN
IS
  RET_EXCLFROMPL      BOOLEAN := FALSE;
  PARAMETER_LIST      FT_PK_STRING_UTILS.TYPE_STRING_TOKENS;
  L_GLTYPEEXCPL       GLTYPESEXCFROMPL.GLTYPEEXCPL%TYPE;
BEGIN
  BEGIN
    SELECT GLTYPESEXCFROMPL.GLTYPEEXCPL
    INTO L_GLTYPEEXCPL
    FROM ACCCLASS
    INNER JOIN ACCOUNTS
    ON ACCCLASS.CLAACCNO = ACCOUNTS.ACCRECNO
    INNER JOIN GLTYPESEXCFROMPL
    ON ACCOUNTS.ACCGLANL = GLTYPESEXCFROMPL.GLTYPELKUPNO
    WHERE ACCCLASS.CLARECNO = CLARECNO_IN
    AND ACCCLASS.CLAACCCSTSUP  = CONST.C_RECOVERY;

    IF L_GLTYPEEXCPL = CONST.C_TRUE THEN
      RET_EXCLFROMPL := TRUE;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RET_EXCLFROMPL := FALSE;
    WHEN OTHERS THEN
      RAISE;
  END;

  RETURN RET_EXCLFROMPL;
EXCEPTION
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
END GETEXCLRECOVFLAG;

FUNCTION ISRECOVCLASS(CLARECNO_IN ACCCLASS.CLARECNO%TYPE) RETURN BOOLEAN
IS
  RET_ISRECOVCLASS      BOOLEAN := FALSE;
  V_CLAACCCSTSUP      ACCCLASS.CLAACCCSTSUP %TYPE;
BEGIN
  BEGIN
    SELECT CLAACCCSTSUP 
    INTO V_CLAACCCSTSUP 
    FROM ACCCLASS
    WHERE ACCCLASS.CLARECNO = CLARECNO_IN;
    
    IF V_CLAACCCSTSUP  = CONST.C_RECOVERY THEN
      RET_ISRECOVCLASS := TRUE;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RET_ISRECOVCLASS := FALSE;
    WHEN OTHERS THEN
      RAISE;
  END;

  RETURN RET_ISRECOVCLASS;
EXCEPTION
  WHEN OTHERS THEN
    FT_PK_ERRORS.LOG_AND_STOP;
END ISRECOVCLASS;


    FUNCTION  CURRENTVERSION
          RETURN VARCHAR2 IS Ret_Version VARCHAR(12);
   -- Returns the current version number so that calling programs can detect if a version is out of date
   -- As with the rest of Freshtrade the version number is in the format nn.nn.nn so it has to be returned as
   -- a string
    BEGIN

        RETURN cVersionControlNo;

    END CURRENTVERSION;

-- initialisation section
BEGIN
    BEGIN
        SELECT COUNT(*) INTO V_SO_SPECIFIC_ACCCODE FROM WIZSYSPREF WHERE SYSPREFNAME = 'SALOFFACCCODE' AND UPPER(SYSPREFVALUE) = 'TRUE';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
            V_SO_SPECIFIC_ACCCODE := 0;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'BSDL_PKAGE_ACCOUNTS -INIT');
            V_SO_SPECIFIC_ACCCODE := 0;
    END;



END FT_PK_ACCOUNTS;
/
