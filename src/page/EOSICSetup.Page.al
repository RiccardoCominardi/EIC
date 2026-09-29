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
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(IntegrationEntries)
            {
                ApplicationArea = All;
                Caption = 'Integration Entries';
                Image = Log;
                RunObject = page "EOS IC Integration Entries";
            }
        }
        area(Promoted)
        {
            actionref(IntegrationEntries_Promoted; IntegrationEntries) { }
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