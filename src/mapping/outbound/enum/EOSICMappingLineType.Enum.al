namespace EOS.Solutions.Intercompany;

enum 67010 "EOS IC Mapping Line Type"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "Record")
    {
        Caption = 'Record';
    }
    value(2; Attribute)
    {
        Caption = 'Attribute';
    }
}
