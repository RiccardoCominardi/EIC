namespace EOS.Solutions.Intercompany;

page 67031 "EOS IC Table Relation List"
{
    ApplicationArea = All;
    Caption = 'IC Table Relations (EIC)';
    CardPageId = "EOS IC Table Relation Card";
    Editable = false;
    PageType = List;
    SourceTable = "EOS IC Table Relation Header";
    UsageCategory = None;

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
                field("Source Table No."; Rec."Source Table No.")
                {
                    ApplicationArea = All;
                }
                field("Source Table Name"; Rec."Source Table Name")
                {
                    ApplicationArea = All;
                }
                field("Target Table No."; Rec."Target Table No.")
                {
                    ApplicationArea = All;
                }
                field("Target Table Name"; Rec."Target Table Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
