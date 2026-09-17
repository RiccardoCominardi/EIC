namespace EOS.Solutions.Intercompany;

enum 67001 "EOS IC Flow Document Types"
{
    Extensible = true;

    value(0; "Sales Order")
    {
        Caption = 'Sales Order';
    }
    value(1; "Purchase Order")
    {
        Caption = 'Purchase Order';
    }
    value(2; Shipment)
    {
        Caption = 'Shipment';
    }
    value(3; Receipt)
    {
        Caption = 'Receipt';
    }
    value(4; Item)
    {
        Caption = 'Item';
    }
}