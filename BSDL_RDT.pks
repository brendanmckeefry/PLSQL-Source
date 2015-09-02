create or replace
PACKAGE BSDL_RDT


AS

-- Global Variables
   DEBUG   Boolean	:= False; -- set this to cause errors to be raised.  False just returns error codes.
   cSpecVersionControlNo   VARCHAR2(12) := '11.1.1'; -- Current Version Number

FUNCTION  CHECKPICKRELAX(  In_UserName        IN VARCHAR2,
                           In_DelDetRecNo     IN INTEGER,
                           In_PalLocRecNo     IN INTEGER       )
          RETURN INTEGER;

FUNCTION  PICKPALLET(      In_UserName        IN VARCHAR2,
                           In_DelDetRecNo     IN INTEGER,
                           In_PalLocRecNo     IN INTEGER,
						   In_BoxQty          IN INTEGER       )
          RETURN INTEGER;


FUNCTION  PALLETAUDIT(     In_UserName        IN VARCHAR2,
                           In_PalLocRecNo     IN INTEGER,
						   In_AuditType       IN INTEGER,
						   In_FromValue		  IN VARCHAR2,
						   In_ToValue		  IN VARCHAR2,
						   In_FormNumber      IN INTEGER := 999      )
          RETURN INTEGER;

FUNCTION CURRENTVERSION(IN_BODYORSPEC IN INTEGER default CONST.C_SPEC)
         RETURN VARCHAR2;


END BSDL_RDT;
/
