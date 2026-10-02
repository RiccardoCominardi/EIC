namespace EOS.Solutions.Intercompany;

using Microsoft.Inventory.Item;

pageextension 67004 "EOS IC Item Card" extends "Item Card"
{
    actions
    {
        addlast(Processing)
        {
            action("EOS IC Send")
            {
                ApplicationArea = All;
                Caption = 'Send Intercompany (EIC)';
                Image = SendTo;
                ToolTip = 'Creates the intercompany entry for this item and sends it to the selected intercompany company.';

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
