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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
            group(Settings)
            {
                Caption = 'Settings';

                field("Flow Pair Id"; Rec."Flow Pair Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                }
                field("Relation Table Id"; Rec."Relation Table Id")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Relation Table Name"; Rec."Relation Table Name")
                {
                    ApplicationArea = All;
                }
                field("Relation Option Type"; Rec."Relation Option Type")
                {
                    ApplicationArea = All;
                    Editable = false;
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
                }
                group(Inbound)
                {
                    ShowCaption = false;
                    Visible = Rec.Direction = Rec.Direction::Inbound;
                    field("Auto Process"; Rec."Auto Process")
                    {
                        ApplicationArea = All;
                    }
                    field("Auto Create Documents"; Rec."Auto Create Documents")
                    {
                        ApplicationArea = All;
                    }
                }
                group(Outbound)
                {
                    ShowCaption = false;
                    Visible = Rec.Direction = Rec.Direction::Outbound;
                    field("Auto Send"; Rec."Auto Send")
                    {
                        ApplicationArea = All;
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