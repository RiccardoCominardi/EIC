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
                    ICCompanies: Record "EOS IC Companies";
                    ICEntriesMgt: Codeunit "EOS IC Entries Management";
                    ICCompaniesPage: Page "EOS IC Companies";
                begin
                    ICCompanies.SetRange(Enabled, true);
                    ICCompaniesPage.SetTableView(ICCompanies);
                    ICCompaniesPage.LookupMode(true);
                    if ICCompaniesPage.RunModal() <> Action::LookupOK then
                        exit;

                    ICCompaniesPage.GetRecord(ICCompanies);
                    ICEntriesMgt.CreateEntry(Rec, ICCompanies.Code);
                end;
            }
        }
    }
}
