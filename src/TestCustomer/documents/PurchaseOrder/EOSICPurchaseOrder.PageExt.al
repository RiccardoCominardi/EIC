namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Document;

pageextension 67003 "EOS IC Purchase Order" extends "Purchase Order"
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
}
