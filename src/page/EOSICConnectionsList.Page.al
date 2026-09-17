namespace EOS.Solutions.Intercompany;
page 67001 "EOS IC Connections List"
{
    Caption = 'IC Connections List (EIC)';
    CardPageID = "EOS IC Connection Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Connections";
    UsageCategory = Lists;
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
                field("Environment Type"; Rec."Environment Type")
                {
                    ApplicationArea = All;
                }
                field("Environment Name"; Rec."Environment Name")
                {
                    ApplicationArea = All;
                }
                field("Authentication Type"; Rec."Authentication Type")
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
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Test Connection';
                Image = TestDatabase;
                trigger OnAction()
                var
                    ICAuthentication: Interface "EOS IC Authentication";
                begin
                    ICAuthentication := Rec."Authentication Type";
                    ICAuthentication.TestConnection(Rec);
                end;
            }
        }
        area(Promoted)
        {
            actionref(TestConnection_Promoted; TestConnection) { }
        }
    }
}