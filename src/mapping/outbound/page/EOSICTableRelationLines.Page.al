namespace EOS.Solutions.Intercompany;

page 67033 "EOS IC Table Relation Lines"
{
    Caption = 'IC Table Relation Lines (EIC)';
    AutoSplitKey = true;
    PageType = ListPart;
    SourceTable = "EOS IC Table Relation Line";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Source Table No."; Rec."Source Table No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the table that contains the source field.';
                }
                field("Source Field No."; Rec."Source Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number used to match source records.';
                }
                field("Source Field Name"; Rec."Source Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the selected source field.';
                }
                field("Target Table No."; Rec."Target Table No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the related table that contains the target field.';
                }
                field("Target Field No."; Rec."Target Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number matched against the source field.';
                }
                field("Target Field Name"; Rec."Target Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the selected target field.';
                }
            }
        }
    }
}
