namespace EOS.Solutions.Intercompany;

page 67035 "EOS IC String Transform Card"
{
    Caption = 'IC String Transformation Card (EIC)';
    PageType = Card;
    SourceTable = "EOS IC String Transform Header";
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
                field("Transformation Type"; Rec."Transformation Type")
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "EOS IC String Transform Lines")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = Code = field(Code);
                UpdatePropagation = Both;
            }
        }
    }
}
