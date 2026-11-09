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
        }
    }
}
