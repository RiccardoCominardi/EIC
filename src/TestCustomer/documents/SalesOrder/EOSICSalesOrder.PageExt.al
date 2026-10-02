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
                    ICEntriesMgt: Codeunit "EOS IC Entries Management";
                begin
                    ICEntriesMgt.CreateEntry(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
