namespace EOS.Solutions.Intercompany;

page 67034 "EOS IC String Transformations"
{
    ApplicationArea = All;
    Caption = 'IC String Transformations (EIC)';
    CardPageId = "EOS IC String Transform Card";
    Editable = false;
    PageType = List;
    SourceTable = "EOS IC String Transform Header";
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
        }
    }
}
