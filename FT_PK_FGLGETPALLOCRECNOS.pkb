CREATE OR REPLACE PACKAGE BODY FT_PK_FGLGETPALLOCRECNOS AS

  cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number


  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2
  IS
  BEGIN
    IF  IN_BODYORSPEC = CONST.C_SPEC THEN
         RETURN cSpecVersionControlNo;
    ELSE  
        RETURN cVersionControlNo;
    END IF;        
        
  END CURRENTVERSION;
  

  PROCEDURE MAINPROC
  AS
  BEGIN
        DECLARE
            CNT_NOTUSEDPALLETS   NUMBER(10);            
        BEGIN

        BEGIN
            SELECT COUNT(*) INTO CNT_NOTUSEDPALLETS FROM  PALNOLOCTMP_KEY_NEW WHERE NOTUSED = 0;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
            WHEN OTHERS THEN            
                FT_PK_ERRORS.LOG_AND_STOP;
        END;  
                            
    
        DELETEUSEDPALLOCRECNOS();
        
        IF CNT_NOTUSEDPALLETS < 200000 THEN
            POPULATEPALLOCRECNOS();                    
        END IF;
                    
        END;
  END MAINPROC;

  
  PROCEDURE POPULATEPALLOCRECNOS
AS
BEGIN

     DECLARE

       LOOPCOUNTERSTART NUMBER(10);
       LOOPCOUNTERSTARTMAX NUMBER(10);
       LOOPCOUNTEREND NUMBER(10) :=  2147478013;
       --CONTINUEVAR BOOLEAN := TRUE;
       ERR_RAISE EXCEPTION;
       NUMRECSFOUND NUMBER(5) := 0;
      
     BEGIN
     

     BEGIN          
          SELECT MAX(NEXTPALRECNO)+ 1   INTO LOOPCOUNTERSTART   FROM PALNOLOCTMP_KEY_NEW;

          IF SQL%ROWCOUNT <> 1 OR LOOPCOUNTERSTART IS NULL THEN
            RAISE ERR_RAISE;
          END IF;

     EXCEPTION
        WHEN ERR_RAISE
        THEN
            FT_PK_ERRORS.LOG_AND_STOP;
        WHEN OTHERS
        THEN
            FT_PK_ERRORS.LOG_AND_STOP;
     END;
     

      BEGIN

          LOOPCOUNTERSTARTMAX := LOOPCOUNTERSTART + 2000000;

          IF LOOPCOUNTERSTARTMAX > LOOPCOUNTEREND
          THEN
                LOOPCOUNTERSTARTMAX := LOOPCOUNTEREND;
          END IF;

          WHILE LOOPCOUNTERSTART < LOOPCOUNTERSTARTMAX
          LOOP
                NUMRECSFOUND := 0;

                SELECT COUNT(*) INTO NUMRECSFOUND FROM PALNOLOC WHERE PALLOCRECNO = LOOPCOUNTERSTART;

                IF NUMRECSFOUND = 0
                THEN
                    BEGIN

                        INSERT INTO PALNOLOCTMP_KEY_NEW(NEXTPALRECNO, NOTUSED)
                        VALUES(LOOPCOUNTERSTART, 0);

                        COMMIT;

                    EXCEPTION
                        WHEN OTHERS
                        THEN
                            FT_PK_ERRORS.LOG_AND_STOP;
                    END;
                END IF;

                LOOPCOUNTERSTART := LOOPCOUNTERSTART + 1;
          END LOOP;
     END;    
END;
END POPULATEPALLOCRECNOS;

PROCEDURE DELETEUSEDPALLOCRECNOS
    AS
    BEGIN
         DECLARE
            CURSOR V_PAL_CURSOR  IS     SELECT NEXTPALRECNO  FROM  PALNOLOCTMP_KEY_NEW WHERE NOTUSED = 1;
         BEGIN
            FOR V_PAL_RECORD IN V_PAL_CURSOR  LOOP  
                BEGIN
                     DELETE FROM PALNOLOCTMP_KEY_NEW WHERE NEXTPALRECNO = V_PAL_RECORD.NEXTPALRECNO;
                     COMMIT;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     NULL;
                WHEN OTHERS THEN
                     FT_PK_ERRORS.LOG_AND_STOP;
                END;
            END LOOP;            
         EXCEPTION
            WHEN OTHERS THEN
                FT_PK_ERRORS.LOG_AND_STOP(); 
         END;

END DELETEUSEDPALLOCRECNOS;

END FT_PK_FGLGETPALLOCRECNOS ;
/
