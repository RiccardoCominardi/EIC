namespace EOS.Solutions.Intercompany;

page 67035 "EOS IC Transliteration Card"
{
    Caption = 'IC Transliteration Card (EIC)';
    PageType = Card;
    SourceTable = "EOS IC Transliteration Header";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "EOS IC Transliteration Lines")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = Code = field(Code);
                UpdatePropagation = Both;
            }
        }
    }
}
