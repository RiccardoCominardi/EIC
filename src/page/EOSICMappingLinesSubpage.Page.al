namespace EOS.Solutions.Intercompany;
page 67011 "EOS IC Mapping Lines Subpage"
{
    Caption = 'IC Mapping Lines (EIC)';
    AutoSplitKey = true;
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "EOS IC Mapping Lines";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Source Field No."; Rec."Source Field No.")
                {
                    ApplicationArea = All;
                }
                field("Source Field Name"; Rec."Source Field Name")
                {
                    ApplicationArea = All;
                }
                field("Target Field No."; Rec."Target Field No.")
                {
                    ApplicationArea = All;
                }
                field("Target Field Name"; Rec."Target Field Name")
                {
                    ApplicationArea = All;
                }
                field("Source Value"; Rec."Source Value")
                {
                    ApplicationArea = All;
                }
                field("Mapping Type"; Rec."Mapping Type")
                {
                    ApplicationArea = All;
                }
                field("Target Value"; Rec."Target Value")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.InitFromHeader();
    end;
}
