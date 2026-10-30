namespace EOS.Solutions.Intercompany;

enum 67001 "EOS IC Flow Types"
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
    value(2; "Confirm Sales Order")
    {
        Caption = 'Confirm Sales Order';
    }
    value(3; "Confirm Purchase Order")
    {
        Caption = 'Confirm Purchase Order';
    }
    value(4; "Item")
    {
        Caption = 'Item';
    }
}