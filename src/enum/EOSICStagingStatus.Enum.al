namespace EOS.Solutions.Intercompany;

enum 67007 "EOS IC Staging Status"
{
    Extensible = true;

    value(0; None)
    {
        Caption = ' ';
    }
    value(1; Pending)
    {
        Caption = 'Pending';
    }
    value(2; Processed)
    {
        Caption = 'Processed';
    }
}
