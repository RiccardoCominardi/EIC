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
                    ToolTip = 'Specifies the unique code of the connection.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the connection.';
                }
                field("Environment Type"; Rec."Environment Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the remote Business Central environment is online or on-premises.';
                }
                field("Authentication Type"; Rec."Authentication Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the authentication method used to connect to the remote environment.';
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
                ToolTip = 'Checks whether the connection settings can reach the remote Business Central environment.';
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