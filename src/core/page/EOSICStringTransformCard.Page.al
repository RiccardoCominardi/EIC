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
                    ToolTip = 'Specifies the unique code of the string transformation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the string transformation.';
                }
                field("Transformation Type"; Rec."Transformation Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the transformation matches individual characters or complete strings.';
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
