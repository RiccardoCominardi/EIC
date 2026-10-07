namespace EOS.Solutions.Intercompany;

enum 67006 "EOS IC Companies" implements "EOS IC Document Handler"
{
    Extensible = true;

    value(0; Default)
    {
        Caption = 'Default';
        Implementation = "EOS IC Document Handler" = "EOS IC Default Doc. Handler";
    }
}