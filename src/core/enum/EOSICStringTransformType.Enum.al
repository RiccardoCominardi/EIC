namespace EOS.Solutions.Intercompany;

enum 67001 "EOS IC String Transform Type"
{
    Extensible = false;

    value(0; "Character Transliteration")
    {
        Caption = 'Character Transliteration';
    }
    value(1; "Complete String Replacement")
    {
        Caption = 'Complete String Replacement';
    }
}