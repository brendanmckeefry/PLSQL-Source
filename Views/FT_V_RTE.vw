/* Formatted on 25/09/2014 10:02:59 (QP5 v5.149.1003.31008) */
--
-- FT_V_RTE  (View)
--

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
