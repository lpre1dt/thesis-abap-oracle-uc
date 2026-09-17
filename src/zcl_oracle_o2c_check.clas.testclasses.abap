CLASS ltc_oracle_o2c_check DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS mc_ref_with_goods_issue TYPE bstnk VALUE '4500045090'.
    CONSTANTS mc_ref_bd9              TYPE bstnk VALUE 'BD9 OR 3'.
    CONSTANTS mc_ref_without_delivery TYPE bstnk VALUE 'DD Repl'.
    CONSTANTS mc_ref_unknown          TYPE bstnk VALUE 'KEIN_AUFTRAG_XYZ'.

    CONSTANTS mc_date_goods_issue     TYPE dats VALUE '20180321'.
    CONSTANTS mc_date_bd9             TYPE dats VALUE '20191104'.

    METHODS sales_order_found        FOR TESTING.
    METHODS sales_order_not_found    FOR TESTING.
    METHODS sales_order_empty_input  FOR TESTING.
    METHODS goods_issue_found        FOR TESTING.
    METHODS goods_issue_date_bd9     FOR TESTING.
    METHODS goods_issue_not_posted   FOR TESTING.
ENDCLASS.


CLASS ltc_oracle_o2c_check IMPLEMENTATION.

  METHOD sales_order_found.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_oracle_o2c_check=>sales_order_exists( mc_ref_with_goods_issue )-processstate
      exp = abap_true
      msg = 'Kundenauftrag mit bekannter Kundenreferenz muss gefunden werden' ).
  ENDMETHOD.

  METHOD sales_order_not_found.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_oracle_o2c_check=>sales_order_exists( mc_ref_unknown )-processstate
      exp = abap_false
      msg = 'Unbekannte Kundenreferenz darf keinen Auftrag liefern' ).
  ENDMETHOD.

  METHOD sales_order_empty_input.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_oracle_o2c_check=>sales_order_exists( space )-processstate
      exp = abap_false
      msg = 'Leere Kundenreferenz darf nicht true liefern' ).
  ENDMETHOD.

  METHOD goods_issue_found.
    DATA(ls_result) = zcl_oracle_o2c_check=>goods_issue_posted( mc_ref_with_goods_issue ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-processstate
      exp = abap_true
      msg = 'Gebuchter Warenausgang muss ueber die Belegkette gefunden werden' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-actualgoodsmovementdate
      exp = mc_date_goods_issue
      msg = 'Warenausgangsdatum muss aus dem Lieferbeleg stammen' ).
  ENDMETHOD.

  METHOD goods_issue_date_bd9.
    DATA(ls_result) = zcl_oracle_o2c_check=>goods_issue_posted( mc_ref_bd9 ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-actualgoodsmovementdate
      exp = mc_date_bd9
      msg = 'Warenausgangsdatum des BD9-Referenzprozesses' ).
  ENDMETHOD.

  METHOD goods_issue_not_posted.
    DATA(ls_result) = zcl_oracle_o2c_check=>goods_issue_posted( mc_ref_without_delivery ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-processstate
      exp = abap_false
      msg = 'Auftrag ohne Lieferung darf keinen Warenausgang melden' ).

    cl_abap_unit_assert=>assert_initial(
      act = ls_result-actualgoodsmovementdate
      msg = 'Ohne Warenausgang darf kein Datum geliefert werden' ).
  ENDMETHOD.

ENDCLASS.
