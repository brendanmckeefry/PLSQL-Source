CREATE OR REPLACE PACKAGE FT_PK_AUTOCOSTING AS
  
  cSpecVersionControlNo VARCHAR2(12) := '1.0.1';

  TYPE T_INTEGER_ARRAY IS TABLE OF INTEGER INDEX BY PLS_INTEGER;
  
  FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER ) RETURN VARCHAR2;

  PROCEDURE ENQUEUE_LITRECS(LITRECS_IN RECORD_NUMBERS, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE);
  
  PROCEDURE ENQUEUE_DPRRECS(DPRRECS_IN RECORD_NUMBERS, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE);
  
  PROCEDURE ENQUEUE_LIT(LITITENO_IN AUTOCOSTSTODO.LITITENO%TYPE, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE);
  
  PROCEDURE ENQUEUE_DPR(DPRRECNO_IN AUTOCOSTSTODO.DPRRECNO%TYPE, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE);
                        
  PROCEDURE ENQUEUE_DPRRECS_AA(DPRRECS_IN T_INTEGER_ARRAY, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE); 
                        
  PROCEDURE PRIORITISE_LITRECS(LITRECS_IN RECORD_NUMBERS);
  
  PROCEDURE PRIORITISE_LIT(LITITENO_IN AUTOCOSTSTODO.LITITENO%TYPE);
  
  PROCEDURE PRIORITISE_DPRRECS(DPRRECS_IN RECORD_NUMBERS);
  
  PROCEDURE PRIORITISE_DPR(DPRRECNO_IN AUTOCOSTSTODO.DPRRECNO%TYPE);
  
  PROCEDURE PRIORITISE_SALOFF(SALOFFNO_IN SALOFFNO.SALOFFNO%TYPE);                    
  
  PROCEDURE PRIORITISE_ALL; 
  
  PROCEDURE PROCESS_ALL;
                        
  PROCEDURE SET_IN_PROGRESS;
  
  PROCEDURE REMOVE_RECS;
  
  FUNCTION PENDING_REC_CNT_SESSION RETURN INTEGER;
  
  FUNCTION PENDING_REC_CNT_OTHER RETURN INTEGER;
  
  PROCEDURE RESET_DEAD_SESSIONS;
  
  PROCEDURE TRANSFORM_LOTS_TO_DPR;
  
  PROCEDURE INCLUDE_ALL_LOTS;
  
  PROCEDURE OVERRIDE_SESSION;
                
END FT_PK_AUTOCOSTING;
/
