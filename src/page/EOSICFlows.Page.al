namespace EOS.Solutions.Intercompany;
page 67005 "EOS IC Flows"
{
    Caption = 'IC Flows (EIC)';
    CardPageID = "EOS IC Flow Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Flows";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                }
                field("Local Document Type"; Rec."Local Document Type")
                {
                    ApplicationArea = All;
                }
                field("External Document Type"; Rec."External Document Type")
                {
                    ApplicationArea = All;
                }
                field("Flow Pair Id"; Rec."Flow Pair Id")
                {
                    ApplicationArea = All;
                }
                field("Auto Send"; Rec."Auto Send")
                {
                    ApplicationArea = All;
                }
                field("Auto Process"; Rec."Auto Process")
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(PairFlow)
            {
                ApplicationArea = All;
                Caption = 'Pair Flow';
                Image = LinkAccount;
                trigger OnAction()
                var
                    ICFunctions: Codeunit "EOS IC Functions";
                begin
                    ICFunctions.PairFlow(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(UnpairFlow)
            {
                ApplicationArea = All;
                Caption = 'Unpair Flow';
                Enabled = Rec."Flow Pair Id" <> '';
                Image = UnLinkAccount;
                trigger OnAction()
                var
                    ICFunctions: Codeunit "EOS IC Functions";
                begin
                    ICFunctions.UnpairFlow(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Mapping)
            {
                ApplicationArea = All;
                Caption = 'Mapping';
                Enabled = Rec.Direction = Rec.Direction::Inbound;
                Image = MapAccounts;
                RunObject = page "EOS IC Mapping List";
                RunPageLink = "Company Code" = field("Company Code"), "Flow Code" = field(Code);
            }
        }
        area(Promoted)
        {
            group(FlowGroup)
            {
                Caption = 'PairFlow';
                ShowAs = SplitButton;
                actionref(PairFlow_Promoted; PairFlow) { }
                actionref(UnpairFlow_Promoted; UnpairFlow) { }
            }
            actionref(Mapping_Promoted; Mapping) { }
        }
    }
}