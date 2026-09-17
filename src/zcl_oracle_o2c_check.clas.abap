CLASS zcl_oracle_o2c_check DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS sales_order_exists
      IMPORTING iv_customer_reference TYPE bstnk
      RETURNING VALUE(rs_result)      TYPE za_oracle_o2c_result.

    CLASS-METHODS goods_issue_posted
      IMPORTING iv_customer_reference TYPE bstnk
      RETURNING VALUE(rs_result)      TYPE za_oracle_o2c_result.

  PRIVATE SECTION.
    CONSTANTS mc_sd_document_category TYPE c LENGTH 1 VALUE 'C'.
    CONSTANTS mc_goods_movement_done  TYPE c LENGTH 1 VALUE 'C'.

    CLASS-METHODS sign_result
      IMPORTING iv_payload   TYPE string
      CHANGING  cs_result    TYPE za_oracle_o2c_result.
ENDCLASS.


CLASS zcl_oracle_o2c_check IMPLEMENTATION.

  METHOD sales_order_exists.
    IF iv_customer_reference IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM i_salesorder
      FIELDS @abap_true
      WHERE purchaseorderbycustomer = @iv_customer_reference
      INTO @rs_result-processstate.

    IF sy-subrc <> 0.
      CLEAR rs_result.
    ENDIF.

    DATA(lv_payload) = |\{"customerReference":"{ iv_customer_reference }",| &&
                        |"processState":{ COND string( WHEN rs_result-processstate = abap_true THEN 'true' ELSE 'false' ) }\}|.

    sign_result( EXPORTING iv_payload = lv_payload CHANGING cs_result = rs_result ).
  ENDMETHOD.

  METHOD goods_issue_posted.
    IF iv_customer_reference IS INITIAL.
      RETURN.
    ENDIF.

    " Belegkette Kundenauftrag -> Lieferung -> Materialbeleg, Status schuetzt gegen Storno
    SELECT FROM i_salesorder AS so
           INNER JOIN i_deliverydocumentitem AS di
             ON di~referencesddocument = so~salesorder
           INNER JOIN i_deliverydocument AS dh
             ON dh~deliverydocument = di~deliverydocument
           INNER JOIN i_materialdocumentheader AS mh
             ON mh~deliverydocument = di~deliverydocument
      FIELDS dh~actualgoodsmovementdate AS actualgoodsmovementdate
      WHERE so~purchaseorderbycustomer     = @iv_customer_reference
        AND di~referencesddocumentcategory = @mc_sd_document_category
        AND dh~overallgoodsmovementstatus  = @mc_goods_movement_done
      ORDER BY dh~actualgoodsmovementdate DESCENDING
      INTO TABLE @DATA(lt_movements)
      UP TO 1 ROWS.

    IF sy-subrc = 0 AND lt_movements IS NOT INITIAL.
      rs_result-processstate            = abap_true.
      rs_result-actualgoodsmovementdate = lt_movements[ 1 ]-actualgoodsmovementdate.
    ENDIF.

    DATA(lv_date_str) = COND string( WHEN rs_result-actualgoodsmovementdate IS NOT INITIAL
                                      THEN |{ rs_result-actualgoodsmovementdate DATE = ISO }|
                                      ELSE '' ).

    DATA(lv_payload) = |\{"customerReference":"{ iv_customer_reference }",| &&
                        |"processState":{ COND string( WHEN rs_result-processstate = abap_true THEN 'true' ELSE 'false' ) },| &&
                        |"actualGoodsMovementDate":"{ lv_date_str }"\}|.

    sign_result( EXPORTING iv_payload = lv_payload CHANGING cs_result = rs_result ).
  ENDMETHOD.

  METHOD sign_result.
    cs_result-payload = iv_payload.
    zcl_oracle_o2c_sign=>sign_and_extract(
      EXPORTING iv_payload  = iv_payload
      IMPORTING ev_attr_der = cs_result-attrder
                ev_r        = cs_result-r
                ev_s        = cs_result-s
    ).
  ENDMETHOD.

ENDCLASS.

