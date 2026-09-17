CLASS lhc_oraclestate DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR OracleState RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ OracleState RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK OracleState.

    METHODS salesorderexists FOR READ
      IMPORTING keys FOR FUNCTION OracleState~SalesOrderExists RESULT result.

    METHODS goodsissueposted FOR READ
      IMPORTING keys FOR FUNCTION OracleState~GoodsIssuePosted RESULT result.
ENDCLASS.


CLASS lhc_oraclestate IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD salesorderexists.
    DATA ls_result LIKE LINE OF result.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR ls_result.
      ls_result-%param = zcl_oracle_o2c_check=>sales_order_exists( ls_key-%param-customerreference ).
      APPEND ls_result TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD goodsissueposted.
    DATA ls_result LIKE LINE OF result.

    LOOP AT keys INTO DATA(ls_key).
      CLEAR ls_result.
      ls_result-%param = zcl_oracle_o2c_check=>goods_issue_posted( ls_key-%param-customerreference ).
      APPEND ls_result TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
