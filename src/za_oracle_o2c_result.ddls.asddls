@EndUserText.label: 'Oracle O2C - Ergebnis'
define abstract entity ZA_ORACLE_O2C_RESULT
{
  @EndUserText.label: 'Prozesszustand'
  ProcessState            : abap_boolean;

  @EndUserText.label: 'Warenausgangsdatum'
  ActualGoodsMovementDate : abap.dats;

  @EndUserText.label: 'Signierter Payload (JSON)'
  Payload                 : abap.string( 0 );

  @EndUserText.label: 'DER-kodierte SignedAttributes'
  AttrDer                 : abap.rawstring( 0 );

  @EndUserText.label: 'DSA-Signaturkomponente r'
  R                       : abap.rawstring( 0 );

  @EndUserText.label: 'DSA-Signaturkomponente s'
  S                       : abap.rawstring( 0 );
}
