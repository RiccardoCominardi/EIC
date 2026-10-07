namespace EOS.Solutions.Intercompany;

enum 67005 "EOS IC Entry Status"
{
    Extensible = true;

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Processing)
    {
        Caption = 'Processing';
    }
    value(2; Completed)
    {
        Caption = 'Completed';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
}
