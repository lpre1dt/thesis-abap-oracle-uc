CLASS zcl_oracle_o2c_sign DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS sign_and_extract
      IMPORTING iv_payload  TYPE string
      EXPORTING ev_attr_der TYPE xstring
                ev_r        TYPE xstring
                ev_s        TYPE xstring.

  PRIVATE SECTION.
    CLASS-METHODS sign_payload
      IMPORTING if_payload    TYPE string
      RETURNING VALUE(rf_sig) TYPE xstring.

    CLASS-METHODS extract_oracle_data
      IMPORTING if_sig      TYPE xstring
      EXPORTING ef_attr_der TYPE xstring
                ef_r        TYPE xstring
                ef_s        TYPE xstring.

    CLASS-METHODS find_child_by_tag
      IMPORTING io_node         TYPE REF TO cl_asn1_parser
                if_tag_class    TYPE i
                if_tag_number   TYPE i
      RETURNING VALUE(ro_child) TYPE REF TO cl_asn1_parser.

    CLASS-METHODS der_length
      IMPORTING if_length       TYPE i
      RETURNING VALUE(rf_bytes) TYPE xstring.

    CLASS-METHODS strip_leading_zero
      IMPORTING if_val        TYPE xstring
      RETURNING VALUE(rf_val) TYPE xstring.

ENDCLASS.


CLASS zcl_oracle_o2c_sign IMPLEMENTATION.

  METHOD sign_and_extract.
    DATA(lv_sig) = sign_payload( iv_payload ).
    extract_oracle_data(
      EXPORTING if_sig      = lv_sig
      IMPORTING ef_attr_der = ev_attr_der
                ef_r        = ev_r
                ef_s        = ev_s
    ).
  ENDMETHOD.

  METHOD sign_payload.
    DATA: lv_sig_b64 TYPE string,
          lv_result  TYPE abap_bool.

    cl_sec_sxml_dsignature=>sign_string(
      EXPORTING
        if_ssf_app             = 'SSO2'
        if_incluce_certs       = abap_true
        if_detached            = abap_true
        if_ssf_hash_algorithm  = 'SHA256'
        if_string              = if_payload
      IMPORTING
        ef_signature      = rf_sig
        ef_signature_b64  = lv_sig_b64
        ef_result         = lv_result
    ).
  ENDMETHOD.

  METHOD extract_oracle_data.
    " ContentInfo SEQUENCE { OID pkcs7-signedData, [0] EXPLICIT SignedData }
    DATA(lo_root) = NEW cl_asn1_parser( if_blob = if_sig ).
    DATA(lo_content_wrapper) = lo_root->get_from_sequence( 2 ).       " [0] EXPLICIT

    DATA(lt_wrapper_children) = lo_content_wrapper->get_value_constructed( ).
    DATA(lo_signed_data) = lt_wrapper_children[ 1 ].                  " SignedData SEQUENCE

    " SignedData-Kinder: version, digestAlgorithms, contentInfo, [0]certs?, [1]crls?, signerInfos.
    " signerInfos ist immer das LETZTE Element.
    DATA(lt_signed_data_children) = lo_signed_data->get_value_constructed( ).
    DATA(lo_signer_infos) = lt_signed_data_children[ lines( lt_signed_data_children ) ]. " SET

    DATA(lt_signer_infos_children) = lo_signer_infos->get_value_constructed( ).
    DATA(lo_signer_info) = lt_signer_infos_children[ 1 ].             " erster (einziger) Signer

    " authenticatedAttributes: [0] IMPLICIT, context-specific, tag number 0
    DATA(lo_auth_attrs) = find_child_by_tag(
      io_node       = lo_signer_info
      if_tag_class  = cl_asn1_parser=>co_tag_class_context_specific
      if_tag_number = 0
    ).

    " Value-Bytes (ohne [0]-Header) holen und als SET (Universal, Tag 17 = 0x31) re-taggen -
    " CMS-Spezifikum: signedAttrs sind [0] IMPLICIT kodiert, muessen fuers Hashing aber
    " als SET OF Attribute (0x31) behandelt werden.
    DATA(ls_tag_info) = lo_auth_attrs->get_tag_info( ).
    DATA(lv_full_tlv) = lo_auth_attrs->get_tag_xstring( ).
    DATA(lv_attr_value) = lv_full_tlv+ls_tag_info-header_length(ls_tag_info-content_length).

    DATA(lv_set_tag) = CONV xstring( '31' ).
    ef_attr_der = lv_set_tag && der_length( ls_tag_info-content_length ) && lv_attr_value.

    " encryptedDigest: einziges primitives OCTET STRING direkt unter SignerInfo
    DATA(lo_enc_digest) = find_child_by_tag(
      io_node       = lo_signer_info
      if_tag_class  = cl_asn1_parser=>co_tag_class_universal
      if_tag_number = cl_asn1_parser=>co_tag_number_octet_string
    ).
    DATA(lv_enc_digest_value) = lo_enc_digest->get_value_primitive( ).

    " enc_digest ist selbst eine DER SEQUENCE { r INTEGER, s INTEGER } (DSA-Signaturformat)
    DATA(lo_rs) = NEW cl_asn1_parser( if_blob = lv_enc_digest_value ).
    DATA(lo_r) = lo_rs->get_from_sequence( 1 ).
    DATA(lo_s) = lo_rs->get_from_sequence( 2 ).

    ef_r = strip_leading_zero( lo_r->get_value_primitive( ) ).
    ef_s = strip_leading_zero( lo_s->get_value_primitive( ) ).
  ENDMETHOD.

  METHOD find_child_by_tag.
    LOOP AT io_node->get_value_constructed( ) INTO DATA(lo_child).
      IF lo_child->get_tag_class( )  = if_tag_class AND
         lo_child->get_tag_number( ) = if_tag_number.
        ro_child = lo_child.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD der_length.
    " DER-Laengenkodierung: Short Form (<128) oder Long Form (>=128, hier: 2-Byte-Laengenfeld,
    " ausreichend fuer die in diesem PoC vorkommenden Groessenordnungen).
    DATA: lv_byte1 TYPE x LENGTH 1,
          lv_byte2 TYPE x LENGTH 2.

    IF if_length < 128.
      lv_byte1 = if_length.
      rf_bytes = lv_byte1.
    ELSE.
      lv_byte2 = if_length.
      rf_bytes = |82| && lv_byte2.
    ENDIF.
  ENDMETHOD.

  METHOD strip_leading_zero.
    IF xstrlen( if_val ) = 21 AND if_val(1) = '00'.
      rf_val = if_val+1(20).
    ELSE.
      rf_val = if_val.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
