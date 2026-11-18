namespace EOS.Solutions.Intercompany;
page 67006 "EOS IC Flow Card"
{
    Caption = 'IC Flow Card (EIC)';
    PageType = Document;
    UsageCategory = None;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Flows";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
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
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the flow is available for processing.';
                }
            }
            group(Settings)
            {
                Caption = 'Settings';

                field("Flow Pair Id"; Rec."Flow Pair Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the identifier used to pair this flow with a flow in the remote company.';
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
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Relation Table Name"; Rec."Relation Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the table containing the source documents for this flow.';
                }
                field("Relation Option Type"; Rec."Relation Option Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the option value used to identify the source document type for this flow.';
                    trigger OnDrillDown()
                    var
                        ICFunctions: Codeunit "EOS IC Functions";
                    begin
                        ICFunctions.AssistTableOptionTypeList(Rec);
                    end;
                }
                field("Mapping Code"; Rec."Mapping Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the mapping used to translate data for this flow.';
                }
                group(Inbound)
                {
                    ShowCaption = false;
                    Visible = Rec.Direction = Rec.Direction::Inbound;
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
                }
                group(Outbound)
                {
                    ShowCaption = false;
                    Visible = Rec.Direction = Rec.Direction::Outbound;
                    field("Auto Send"; Rec."Auto Send")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies whether outbound entries using this flow are sent automatically.';
                    }
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