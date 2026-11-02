namespace EOS.Solutions.Intercompany;

enum 67001 "EOS IC Flow Types"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "Sales Order Creation")
    {
        Caption = 'Sales Order Creation';
    }
    value(2; "Purchase Order Creation")
    {
        Caption = 'Purchase Order Creation';
    }
    value(3; "Confirm Sales Order")
    {
        Caption = 'Confirm Sales Order';
    }
    value(4; "Confirm Purchase Order")
    {
        Caption = 'Confirm Purchase Order';
    }
}