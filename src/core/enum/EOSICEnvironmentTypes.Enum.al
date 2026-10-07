namespace EOS.Solutions.Intercompany;

enum 67003 "EOS IC Environment Types"
{
    Extensible = true;

    value(0; SaaS)
    {
        Caption = 'SaaS', Locked = true;
    }
    value(1; OnPrem)
    {
        Caption = 'OnPrem', Locked = true;
    }
}