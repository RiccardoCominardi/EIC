namespace EOS.Solutions.Intercompany;

enum 67001 "EOS IC Document Types"
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
    value(2; "Item")
    {
        Caption = 'Item';
    }
}