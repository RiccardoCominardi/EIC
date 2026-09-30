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
                    Rec.TestField("EOS IC Company");
                    ICEntriesMgt.CreateEntry(Rec, Rec."EOS IC Company");
                end;
            }
        }
    }
}
