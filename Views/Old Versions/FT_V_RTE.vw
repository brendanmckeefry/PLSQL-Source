--########################################################################################################
-- FT_V_RTE (View)
-- 
-- Developer view to display route details
-- 
-- Version 1.0
--########################################################################################################

CREATE OR REPLACE FORCE VIEW FT_V_RTE
(
   RTHNO,
   RTHDATE,
   RTHCLARECNO,
   RTHSTKLOC,
   RTHSALOFFNO,
   RTHHAULREF,
   RTDRECNO,
   RTDCSTCLAREC,
   RTDDLVORDNO,
   RTDDELDETRECNO
)
AS
   SELECT rtehead.RthNo,
          rtehead.RthDate,
          rtehead.RthClaRecNo,
          rtehead.RthStkLoc,
          rtehead.RthSalOffNo,
          rtehead.RthHaulRef,
          rtedetai.RtdRecNo,
          rtedetai.RtdCstClaRec,
          rtedetai.RtdDlvOrdNo,
          rtedetai.RtdDelDetRecNo
     FROM RTEHEAD INNER JOIN RTEDETAI ON rtedetai.RtdRthRecNo = rtehead.RthNo
   WITH READ ONLY;
