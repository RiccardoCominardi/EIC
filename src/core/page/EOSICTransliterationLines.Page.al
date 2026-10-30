namespace EOS.Solutions.Intercompany;

page 67036 "EOS IC Transliteration Lines"
{
    Caption = 'IC Transliteration Lines (EIC)';
    AutoSplitKey = true;
    PageType = ListPart;
    SourceTable = "EOS IC Transliteration Line";
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
                    ToolTip = 'Specifies the character, or the sequence of characters, to be replaced. Upper and lower case are different characters.';
                }
                field(Transformation; Rec.Transformation)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the text that replaces the character. Leave it blank to remove the character.';
                }
            }
        }
    }
}
