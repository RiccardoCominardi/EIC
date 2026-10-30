namespace EOS.Solutions.Intercompany;

page 67034 "EOS IC Transliterations"
{
    ApplicationArea = All;
    Caption = 'IC Transliterations (EIC)';
    CardPageId = "EOS IC Transliteration Card";
    Editable = false;
    PageType = List;
    SourceTable = "EOS IC Transliteration Header";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
