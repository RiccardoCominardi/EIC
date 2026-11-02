namespace EOS.Solutions.Intercompany;

page 67020 "EOS IC Entry Created Docs"
{
    Caption = 'IC Entry Created Documents (EIC)';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    PageType = List;
    SourceTable = "EOS IC Entry Created Document";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Target Flow Type"; Rec."Flow Type")
                {
                    ApplicationArea = All;
                }
                field("Target Document No."; Rec."Document No.")
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