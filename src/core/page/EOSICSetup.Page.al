namespace EOS.Solutions.Intercompany;

using System.Text;

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
                    ToolTip = 'Specifies whether the intercompany functionality is enabled.';
                }
                field("Company Code"; Rec."Company Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code that identifies this company to intercompany partners.';
                }
            }
            group(DocumentFields)
            {
                Caption = 'Document Fields';
                field("Company Code Field No."; Rec."Company Code Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number that stores the intercompany company code on documents.';
                }
                field("IC Entry Field No."; Rec."IC Entry Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field number that stores the linked intercompany entry count on documents.';
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
                ToolTip = 'Opens the list of intercompany entries.';
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