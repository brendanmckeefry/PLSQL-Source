--------------------------------------------------------
--  DDL for Trigger FT_TG_AccCat_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_AccCat_LASTUSED" 
after update OR INSERT or DELETE on AccCat
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_AccCat;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.CATCLARECNO;
       REC_NO2 := :NEW.CLACLASS;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.CATCLARECNO;
       REC_NO2 := :NEW.CLACLASS;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.CATCLARECNO;
       REC_NO2 := :OLD.CLACLASS;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_AccCat_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_AccClass_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_AccClass_LASTUSED" 
after update OR INSERT or DELETE on AccClass
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_AccClass;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO := :NEW.CLARECNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO := :NEW.CLARECNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.CLARECNO;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_AccClass_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_AccToSalOff_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_AccToSalOff_LASTUSED" 
after update OR INSERT or DELETE on AccToSalOff
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_AccToSalOff;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.ACSCLARECNO;
       REC_NO2 := :NEW.ACSSALOFFNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.ACSCLARECNO;
       REC_NO2 := :NEW.ACSSALOFFNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.ACSCLARECNO;
       REC_NO2 := :OLD.ACSSALOFFNO;
    END CASE;

 IF ((REC_NO2 > 0) AND (REC_NO2 < 32000)) THEN
    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 END IF;
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_AccToSalOff_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_ALLOCATE_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_ALLOCATE_LASTUSED" 
after update OR INSERT or DELETE on ALLOCATE
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_ALLOCATE;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.ALLOCNO;       
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.ALLOCNO;       
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.ALLOCNO;      
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_ALLOCATE_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_DEPARTMENTS_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_DEPARTMENTS_LASTUSED" 
after update OR INSERT or DELETE on DEPARTMENTS
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_DEPARTMENTS;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO := :NEW.DPTRECNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO := :NEW.DPTRECNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.DPTRECNO;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_DEPARTMENTS_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_DlvType_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_DlvType_LASTUSED" 
after update OR INSERT or DELETE on DlvType
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_DlvType;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.DLTRECNO;       
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.DLTRECNO;       
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.DLTRECNO;      
    END CASE;

    IF REC_NO > 0 THEN
       FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
    END IF;
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_DlvType_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_DptToSmn_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_DptToSmn_LASTUSED" 
after update OR INSERT or DELETE on DepartmentsToSmn
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_DepartmentsToSmn;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.DPTRECNO;
       REC_NO2 := :NEW.SMNNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.DPTRECNO;
       REC_NO2 := :NEW.SMNNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.DPTRECNO;
       REC_NO2 := :OLD.SMNNO;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_DptToSmn_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_HH_GUID_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_HH_GUID_LASTUSED" 
after update on HH_GUID
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_HH_GUID;
Begin
    /* TV 20May16 Only need updates to GUID so that linked tables can be updated */
    CASE
    --WHEN INSERTING THEN
    --   OP_TYPE := FT_PK_HH.C_CREATE;
    --   REC_NO  := :NEW.FTTABLEID;  
    --   REC_NO2  := :NEW.FTTABLEKEY;  
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.FTTABLEID;  
       REC_NO2  := :NEW.FTTABLEKEY;  
    --WHEN DELETING THEN
    --   OP_TYPE := FT_PK_HH.C_DELETE;
    --   REC_NO  := :OLD.FTTABLEID;  
    --   REC_NO2  := :OLD.FTTABLEKEY;  
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_HH_GUID_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_LOGONS_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_LOGONS_LASTUSED" 
after update OR INSERT or DELETE on LOGONS
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_LOGONS;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO := :NEW.LOGONNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO := :NEW.LOGONNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.LOGONNO;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE); 
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_LOGONS_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_LOGTOSALOFF_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_LOGTOSALOFF_LASTUSED" 
after update OR INSERT or DELETE on LOGTOSALOFF
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_LOGTOSALOFF;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.LOGONNO;
       REC_NO2 := :NEW.SALOFFNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.LOGONNO;
       REC_NO2 := :NEW.SALOFFNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.LOGONNO;
       REC_NO2 := :OLD.SALOFFNO;
    END CASE;

    IF ((REC_NO2 > 0) AND (REC_NO2 < 32000)) THEN
       FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
    END IF;
    
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_LOGTOSALOFF_LASTUSED" DISABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_LOOKUPS_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_LOOKUPS_LASTUSED" 
after update OR INSERT or DELETE on LOOKUPS
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   LKUPTABLE VARCHAR2 (50) := '';
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_LOOKUPS;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       LKUPTABLE := :NEW.LKUPTABLE;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       LKUPTABLE := :NEW.LKUPTABLE;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       LKUPTABLE := :OLD.LKUPTABLE;
    END CASE;

    LKUPTABLE := TRIM(LKUPTABLE);

    IF ((LKUPTABLE = 'ACCCLASS') OR (LKUPTABLE = 'ACCCAT') OR (LKUPTABLE = 'CASHTIKPAY'))  THEN
      FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
    END IF;
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_LOOKUPS_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_PRDALLDESCS_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_PRDALLDESCS_LASTUSED" 
after update OR INSERT or DELETE on PRDALLDESCS
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_PRDALLDESCS;
Begin
  IF FT_PK_HH.C_USES_HANDHELD THEN 
     CASE
     WHEN INSERTING THEN
        OP_TYPE := FT_PK_HH.C_CREATE;
        REC_NO := :NEW.ALLPREFNO;
     WHEN UPDATING THEN
        OP_TYPE := FT_PK_HH.C_UPDATE;
        REC_NO := :NEW.ALLPREFNO;
     WHEN DELETING THEN
        OP_TYPE := FT_PK_HH.C_DELETE;
        REC_NO := :OLD.ALLPREFNO;
     END CASE;

     FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE); 
  END IF;
end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_PRDALLDESCS_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_PRDREC_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_PRDREC_LASTUSED" 
after update OR INSERT or DELETE on PRDREC
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_PRDREC;
Begin
  CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO := :NEW.PRCPRDNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO := :NEW.PRCPRDNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.PRCPRDNO;
  END CASE;

  FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE); 
end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_PRDREC_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_PrdRecToSo_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_PrdRecToSo_LASTUSED" 
after update OR INSERT or DELETE on PrdRecToSo
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_PrdRecToSo;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.SALOFFNO;
       REC_NO2 := :NEW.PRCPRDNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.SALOFFNO;
       REC_NO2 := :NEW.PRCPRDNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.SALOFFNO;
       REC_NO2 := :OLD.PRCPRDNO;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_PrdRecToSo_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_SALOFFNO_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_SALOFFNO_LASTUSED" 
after update OR INSERT or DELETE on SALOFFNO
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_SALOFFNO;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO := :NEW.SALOFFNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO := :NEW.SALOFFNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.SALOFFNO;
    END CASE;

    IF ((REC_NO > 0) AND (REC_NO < 32000)) THEN
       FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
    END IF;
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_SALOFFNO_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_SMN_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_SMN_LASTUSED" 
after update OR INSERT or DELETE on SMN
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_SMN;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO := :NEW.SMNNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO := :NEW.SMNNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.SMNNO;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_SMN_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_SMNToLogon_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_SMNToLogon_LASTUSED" 
after update OR INSERT or DELETE on SMNToLogon
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_SMNToLogon;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.SMNNO;
       REC_NO2 := :NEW.LOGONNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.SMNNO;
       REC_NO2 := :NEW.LOGONNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.SMNNO;
       REC_NO2 := :OLD.LOGONNO;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_SMNToLogon_LASTUSED" DISABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_SofToStcLoc_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_SofToStcLoc_LASTUSED" 
after update OR INSERT or DELETE on SofToStcLoc
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_SofToStcLoc;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.SALOFFNO;
       REC_NO2 := :NEW.STCLOC;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.SALOFFNO;
       REC_NO2 := :NEW.STCLOC;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.SALOFFNO;
       REC_NO2 := :OLD.STCLOC;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_SofToStcLoc_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_TKTBK_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_TKTBK_LASTUSED" 
after update OR INSERT or DELETE on TKTBK
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   USED_FOR INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_TKTBK;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO  := :NEW.TBKRECNO;       
       USED_FOR := :NEW.TBKUSEDFOR;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO  := :NEW.TBKRECNO;       
       USED_FOR := :NEW.TBKUSEDFOR;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.TBKRECNO;      
       USED_FOR := :OLD.TBKUSEDFOR;
    END CASE;

    IF USED_FOR = 2 THEN
       FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
    END IF;
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_TKTBK_LASTUSED" ENABLE;
--------------------------------------------------------
--  DDL for Trigger FT_TG_Vatrates_LASTUSED
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TPUKLIVE"."FT_TG_Vatrates_LASTUSED" 
after update OR INSERT or DELETE on Vatrates
For each row
Declare
   OP_TYPE VARCHAR2 (1) := '?';
   REC_NO INTEGER := -1;
   REC_NO2 INTEGER := -1;
   TBL_FLAG VARCHAR2 (2) := FT_PK_HH.C_Vatrates;
Begin
    CASE
    WHEN INSERTING THEN
       OP_TYPE := FT_PK_HH.C_CREATE;
       REC_NO := :NEW.VATRECNO;
    WHEN UPDATING THEN
       OP_TYPE := FT_PK_HH.C_UPDATE;
       REC_NO := :NEW.VATRECNO;
    WHEN DELETING THEN
       OP_TYPE := FT_PK_HH.C_DELETE;
       REC_NO := :OLD.VATRECNO;
    END CASE;

    FT_PK_HH.INSERT_LASTUSED(REC_NO, REC_NO2, TBL_FLAG, OP_TYPE);
 end;
/
ALTER TRIGGER "TPUKLIVE"."FT_TG_Vatrates_LASTUSED" ENABLE;
