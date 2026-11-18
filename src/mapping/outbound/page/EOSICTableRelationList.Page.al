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
                    ToolTip = 'Specifies the unique code of the table relation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the table relation.';
                }
                field("Source Table No."; Rec."Source Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table that contains the source records.';
                }
                field("Source Table Name"; Rec."Source Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the source table.';
                }
                field("Target Table No."; Rec."Target Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the related table whose records are selected.';
                }
                field("Target Table Name"; Rec."Target Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the related target table.';
                }
            }
        }
    }
}
