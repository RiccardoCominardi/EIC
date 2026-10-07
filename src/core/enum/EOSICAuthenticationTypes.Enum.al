namespace EOS.Solutions.Intercompany;

enum 67002 "EOS IC Authentication Types" implements "EOS IC Authentication"
{
    Extensible = true;
    value(0; "OAuth 2.0")
    {
        Caption = 'OAuth 2.0', Locked = true;
        Implementation = "EOS IC Authentication" = "EOS IC OAuth 2.0 Auth.";
    }
}