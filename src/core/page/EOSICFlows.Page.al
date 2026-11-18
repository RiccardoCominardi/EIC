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
                    ToolTip = 'Specifies the unique code of the flow within the company.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the flow.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the flow sends data to or receives data from another company.';
                }
                field("Relation Table Id"; Rec."Relation Table Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the table containing the source documents for this flow.';
                }
                field("Relation Table Name"; Rec."Relation Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the table containing the source documents for this flow.';
                }
                field("Relation Option Type"; Rec."Relation Option Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the option value used to identify the source document type for this flow.';
                }
                field("Mapping Code"; Rec."Mapping Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the mapping used to translate data for this flow.';
                }
                field("Flow Pair Id"; Rec."Flow Pair Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identifier used to pair this flow with a flow in the remote company.';
                }
                field("Auto Send"; Rec."Auto Send")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether outbound entries using this flow are sent automatically.';
                }
                field("Auto Process"; Rec."Auto Process")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether inbound entries using this flow are processed automatically.';
                }
                field("Auto Create Documents"; Rec."Auto Create Documents")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether documents are created automatically from inbound staging data.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the flow is available for processing.';
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
                ToolTip = 'Pairs this flow with a compatible flow in the remote company.';
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
                ToolTip = 'Removes the pairing between this flow and the remote flow.';
                Image = UnLinkAccount;
                trigger OnAction()
                var
                    ICFunctions: Codeunit "EOS IC Functions";
                begin
                    ICFunctions.UnpairFlow(Rec);
                    CurrPage.Update(false);
                end;
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
        }
    }
}