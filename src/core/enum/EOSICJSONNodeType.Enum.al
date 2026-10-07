namespace EOS.Solutions.Intercompany;

enum 67009 "EOS IC Json Node Type"
{
    Extensible = false;

    value(0; Value)
    {
        Caption = 'Value';
    }
    value(1; "Object")
    {
        Caption = 'Object';
    }
    value(2; "Array")
    {
        Caption = 'Array';
    }
}
