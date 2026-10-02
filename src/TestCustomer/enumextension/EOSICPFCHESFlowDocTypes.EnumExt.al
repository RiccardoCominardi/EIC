namespace EOS_Solutions.EOS_Intercompany;

using EOS.Solutions.Intercompany;

enumextension 67001 "EOS IC PFCH ES Flow Doc. Types" extends "EOS IC Document Types"
{
    value(67000; "ES Sales Order")
    {
        Caption = 'ES Sales Order';
    }
    value(67001; "ES Purchase Order")
    {
        Caption = 'ES Purchase Order';
    }
    value(67002; "ES Shipment")
    {
        Caption = 'ES Shipment';
    }
    value(67003; "ES Receipt")
    {
        Caption = 'ES Receipt';
    }
    value(67004; "ES Item")
    {
        Caption = 'ES Item';
    }
}