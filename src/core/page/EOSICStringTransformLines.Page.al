namespace EOS.Solutions.Intercompany;

page 67036 "EOS IC String Transform Lines"
{
    Caption = 'IC String Transformation Lines (EIC)';
    AutoSplitKey = true;
    PageType = ListPart;
    SourceTable = "EOS IC String Transform Line";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Character; Rec.Character)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source string to be matched. In character-transliteration mode, new entries can contain at most two characters. Matching is case-sensitive.';
                }
                field(Transformation; Rec.Transformation)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the text that replaces the source string. Leave it blank to remove the matched text.';
                }
            }
        }
    }
}
