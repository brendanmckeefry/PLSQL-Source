--
-- CONST  (Package) 
--
CREATE OR REPLACE PACKAGE CONST AS

  --cVersionControlNo   VARCHAR2(12) := '1.0.0'; -- Current Version Number

  -- Freshtrade Constants
  C_ALL           CONSTANT NUMBER(5)  := -32000;

  C_YES           CONSTANT VARCHAR(1) := 'Y';
  C_NO            CONSTANT VARCHAR(1) := 'N';

  C_TRUE          CONSTANT NUMBER(1) := 1;
  C_FALSE         CONSTANT NUMBER(1) := 0;

  -- Price/Qty Per
  PERBOX          CONSTANT INTEGER := 1;
  PERWGT          CONSTANT INTEGER := 2;
  PEREACH         CONSTANT INTEGER := 3;
  PERINNER        CONSTANT INTEGER := 4;

  --Payment Terms
  C_GOODSINV      CONSTANT INTEGER := 5;
  C_GOODSAGREED   CONSTANT INTEGER := 6;
  C_ACCOUNTSALE   CONSTANT INTEGER := 8;
  C_SELFINV       CONSTANT INTEGER := 11;

  -- CHGTYP Fixed CtyNo
  CTYGOODS        CONSTANT INTEGER := 1;

  -- CHGTYP Charge Class
  C_SERVICE       CONSTANT INTEGER := 2;
  C_INBOUNDHAUL   CONSTANT INTEGER := 3;
  C_GOODSREBATE   CONSTANT INTEGER := 4;
  C_COMMISSION    CONSTANT INTEGER := 5;
  C_HANDLING      CONSTANT INTEGER := 6;
  C_ADVANCES      CONSTANT INTEGER := 7;
  C_SUPCLAIM      CONSTANT INTEGER := 8;
  C_PREPACK       CONSTANT INTEGER := 9;
  C_DUTY          CONSTANT INTEGER := 10;

  CURBASE         CONSTANT INTEGER := 1;
  CUREURO         CONSTANT INTEGER := 2;

  -- Daybook Types
  C_SALES         CONSTANT INTEGER := 1;
  C_PURCHASES     CONSTANT INTEGER := 2;

  -- Acccount Classifications
  C_CUSTOMER      CONSTANT INTEGER := 1;
  C_SUPPLIER      CONSTANT INTEGER := 2;
  C_WRITEOFF      CONSTANT INTEGER := 3;
  C_RECOVERY      CONSTANT INTEGER := 4;
  C_FACTOR        CONSTANT INTEGER := 5;

  -- Charge Apportionment Types
  C_APP_BOX         CONSTANT INTEGER := 1;
  C_APP_WGT         CONSTANT INTEGER := 2;
  C_APP_PAL         CONSTANT INTEGER := 4;
  C_APP_PERCSALE    CONSTANT INTEGER := 6;
  C_APP_PERCRETURN  CONSTANT INTEGER := 7;
  C_APP_PERCCOST    CONSTANT INTEGER := 8;
  C_APP_CONTAINER   CONSTANT INTEGER := 9;
  C_APP_RNDPAL      CONSTANT INTEGER := 10;
  C_APP_DUTYWGT     CONSTANT INTEGER := 11;

  -- Charge Apportionment Over
  C_FOR_PO          CONSTANT INTEGER := 1;
  C_FOR_DAILY       CONSTANT INTEGER := 4;
  C_FOR_SALE        CONSTANT INTEGER := 5;
  C_FOR_SALEAREA    CONSTANT INTEGER := 6;
  C_FOR_COST        CONSTANT INTEGER := 9;
  C_FOR_GROSS       CONSTANT INTEGER := 10;
  C_FOR_RETURN      CONSTANT INTEGER := 14;
  C_FOR_CONTAINER   CONSTANT INTEGER := 15;

  -- String Constants
  CR            CONSTANT VARCHAR2  (1) := CHR (10);
  TAB           CONSTANT VARCHAR2  (1) := CHR (9);

END CONST;
/
