namespace EOS.Solutions.Intercompany;

using Microsoft.Sales.Document;

pageextension 67002 "EOS IC Sales Order" extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            field("EOS IC Company"; Rec."EOS IC Company")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the intercompany company associated with this document.';
            }
            field("EOS IC Entry No."; Rec."EOS IC Entry No.")
            {
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies the number of intercompany entries linked to this document. Click to see them.';

                trigger OnDrillDown()
                var
                    ICEntriesMgt: Codeunit "EOS IC Entries Management";
                begin
                    ICEntriesMgt.ShowDocumentEntries(Rec);
                end;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("EOS IC Send")
            {
                ApplicationArea = All;
                Caption = 'Send Intercompany (EIC)';
                Image = SendTo;
                ToolTip = 'Creates the intercompany entry for this order and sends it to the intercompany company.';
                trigger OnAction()
                var
                    ICFunctions: Record "EOS IC Functions";
                    ICFlows: Record "EOS IC Flows";
                    ICEntriesMgt: Codeunit "EOS IC Entries Management";
                begin
                    ICFunctions.Get(Rec."EOS IC Company", ICFunctions.Direction::Outbound);
                    ICFlows.Get(Rec."EOS IC Company", ICFunctions."Sales Order Creation Flow");
                    ICEntriesMgt.CreateEntry(Rec, ICFlows);
                    CurrPage.Update(false);
                end;
            }
            action("EOS IC Send Confirmation")
            {
                ApplicationArea = All;
                Caption = 'Send Confirmation Intercompany (EIC)';
                Image = SendTo;
                ToolTip = 'Creates the intercompany confirmation entry for this order and sends it to the intercompany company.';
                trigger OnAction()
                var
                    ICFunctions: Record "EOS IC Functions";
                    ICFlows: Record "EOS IC Flows";
                    ICEntriesMgt: Codeunit "EOS IC Entries Management";
                begin
                    ICFunctions.Get(Rec."EOS IC Company", ICFunctions.Direction::Outbound);
                    ICFlows.Get(Rec."EOS IC Company", ICFunctions."Confirm Sales Order Flow");
                    ICEntriesMgt.CreateEntry(Rec, ICFlows);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
