--
-- FT_AUTOCOSTING  (Package) 
--
CREATE OR REPLACE PACKAGE FT_AUTOCOSTING AS

  PROCEDURE ENQUEUE_LITRECS(LITRECS_IN RECORD_NUMBERS, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE);
  
  PROCEDURE ENQUEUE_DPRRECS(DPRRECS_IN RECORD_NUMBERS, COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE);
  
  PROCEDURE ENQUEUE_LIT(LITITENO_IN AUTOCOSTSTODO.LITITENO%TYPE,
                        COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE);
  
  PROCEDURE ENQUEUE_DPR(DPRRECNO_IN AUTOCOSTSTODO.DPRRECNO%TYPE,
                        COSTCHNGTYPE_IN AUTOCOSTTYPES.COSTCHNGTYPENO%TYPE);
                        
  PROCEDURE PRIORITISE_LITRECS(LITRECS_IN RECORD_NUMBERS);
  
  PROCEDURE PRIORITISE_LIT(LITITENO_IN AUTOCOSTSTODO.LITITENO%TYPE);
  
  PROCEDURE PRIORITISE_DPRRECS(DPRRECS_IN RECORD_NUMBERS);
  
  PROCEDURE PRIORITISE_DPR(DPRRECNO_IN AUTOCOSTSTODO.DPRRECNO%TYPE);
  
  PROCEDURE PRIORITISE_SALOFF(SALOFFNO_IN SALOFFNO.SALOFFNO%TYPE);                    
  
  PROCEDURE PRIORITISE_ALL; 
                        
  PROCEDURE SET_IN_PROGRESS;
  
  PROCEDURE REMOVE_RECS;
  
  PROCEDURE TRANSFORM_LOTS;
  
  PROCEDURE TRANSFORM_LOTS_JIT;
                
END FT_AUTOCOSTING;
/
