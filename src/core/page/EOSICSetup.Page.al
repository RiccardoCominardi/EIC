namespace EOS.Solutions.Intercompany;

page 67000 "EOS IC Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "EOS IC Setup";
    Caption = 'IC Setup (EIC)';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("Company Code"; Rec."Company Code")
                {
                    ApplicationArea = All;
                }
                field("Interface Company"; Rec."Interface Company")
                {
                    ApplicationArea = All;
                }
            }
            group(DocumentFields)
            {
                Caption = 'Document Fields';
                field("Company Code Field No."; Rec."Company Code Field No.")
                {
                    ApplicationArea = All;
                }
                field("IC Entry Field No."; Rec."IC Entry Field No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ICEntries)
            {
                ApplicationArea = All;
                Caption = 'IC Entries';
                Image = Log;
                RunObject = page "EOS IC Entries";
            }
            action(StringTransformations)
            {
                ApplicationArea = All;
                Caption = 'String Transformations';
                Image = Translations;
                RunObject = page "EOS IC String Transformations";
                ToolTip = 'Shows the string transformations that can be assigned to the lines of the mappings.';
            }
        }
        area(Promoted)
        {
            actionref(ICEntries_Promoted; ICEntries) { }
            actionref(StringTransformations_Promoted; StringTransformations) { }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}