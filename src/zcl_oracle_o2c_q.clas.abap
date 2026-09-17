CLASS zcl_oracle_o2c_q DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_oracle_state,
             oracleid TYPE c LENGTH 10,
           END OF ty_oracle_state.
    TYPES ty_oracle_states TYPE STANDARD TABLE OF ty_oracle_state WITH EMPTY KEY.

    CONSTANTS mc_oracle_id TYPE c LENGTH 10 VALUE 'ORACLE'.
ENDCLASS.


CLASS zcl_oracle_o2c_q IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA(lt_result) = VALUE ty_oracle_states( ( oracleid = mc_oracle_id ) ).

    IF io_request->is_total_numb_of_rec_requested( ) = abap_true.
      io_response->set_total_number_of_records( lines( lt_result ) ).
    ENDIF.

    IF io_request->is_data_requested( ) = abap_false.
      RETURN.
    ENDIF.

    DATA(lo_paging)    = io_request->get_paging( ).
    DATA(lv_offset)    = lo_paging->get_offset( ).
    DATA(lv_page_size) = lo_paging->get_page_size( ).

    IF lv_offset > 0.
      DELETE lt_result FROM 1 TO lv_offset.
    ENDIF.

    IF lv_page_size <> if_rap_query_paging=>page_size_unlimited AND lines( lt_result ) > lv_page_size.
      DELETE lt_result FROM lv_page_size + 1 TO lines( lt_result ).
    ENDIF.

    io_response->set_data( lt_result ).
  ENDMETHOD.

ENDCLASS.

