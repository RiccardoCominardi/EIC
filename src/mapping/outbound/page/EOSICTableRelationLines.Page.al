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
                }
                field("Source Field No."; Rec."Source Field No.")
                {
                    ApplicationArea = All;
                }
                field("Source Field Name"; Rec."Source Field Name")
                {
                    ApplicationArea = All;
                }
                field("Target Table No."; Rec."Target Table No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Target Field No."; Rec."Target Field No.")
                {
                    ApplicationArea = All;
                }
                field("Target Field Name"; Rec."Target Field Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
