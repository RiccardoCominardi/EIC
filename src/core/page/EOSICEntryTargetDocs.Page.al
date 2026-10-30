namespace EOS.Solutions.Intercompany;

page 67020 "EOS IC Entry Target Docs"
{
    Caption = 'IC Entry Target Documents (EIC)';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    PageType = List;
    SourceTable = "EOS IC Entry Target Document";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Target Flow Type"; Rec."Target Flow Type")
                {
                    ApplicationArea = All;
                }
                field("Target Document No."; Rec."Target Document No.")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        ICEntriesManagement: Codeunit "EOS IC Entries Management";
                    begin
                        ICEntriesManagement.ShowTargetDocument(Rec);
                    end;
                }
            }
        }
    }
}