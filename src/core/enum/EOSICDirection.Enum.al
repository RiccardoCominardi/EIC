namespace EOS.Solutions.Intercompany;

enum 67000 "EOS IC Direction"
{
    Extensible = true;

    value(0; Inbound)
    {
        Caption = 'Inbound';
    }
    value(1; Outbound)
    {
        Caption = 'Outbound';
    }
}