namespace EOS.Solutions.Intercompany;

enum 67011 "EOS IC Attribute Type"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "Field")
    {
        Caption = 'Field';
    }
    value(2; Constant)
    {
        Caption = 'Constant';
    }
    value(3; "Function")
    {
        Caption = 'Function';
    }
}
