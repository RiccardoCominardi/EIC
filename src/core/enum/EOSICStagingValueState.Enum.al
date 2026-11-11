namespace EOS.Solutions.Intercompany;

enum 67014 "EOS IC Staging Value State"
{
    Extensible = false;

    value(0; Missing)
    {
        Caption = 'Missing';
    }
    value(1; Null)
    {
        Caption = 'Null';
    }
    value(2; Value)
    {
        Caption = 'Value';
    }
}