namespace EOS.Solutions.Intercompany;
page 67002 "EOS IC Connection Card"
{
    Caption = 'IC Connection Card (EIC)';
    PageType = Document;
    UsageCategory = None;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Connections";

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
                    trigger OnValidate()

                    begin
                        CleanEnvDatas()
                    end;
                }
                group(OnPrem)
                {
                    ShowCaption = false;
                    Visible = Rec."Environment Type" = Rec."Environment Type"::OnPrem;
                    field("OnPrem API Base Url"; Rec."API Base Url")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the base URL used for API requests to the on-premises Business Central environment.';
                    }
                    field("Server Port"; Rec."Server Port")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the port used to access the on-premises Business Central server.';
                        BlankZero = true;
                    }
                    field("Instance Name"; Rec."Instance Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the name of the on-premises Business Central server instance.';
                    }
                }
                group(SaaS)
                {
                    ShowCaption = false;
                    Visible = Rec."Environment Type" = Rec."Environment Type"::SaaS;
                    field("SaaS API Base Url"; Rec."API Base Url")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the base URL used for API requests to the online Business Central environment.';
                    }
                    field("Environment Name"; Rec."Environment Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the name of the remote Business Central environment.';
                    }
                }
            }
            group(Authentication)
            {
                Caption = 'Authentication';
                field("Authentication Type"; Rec."Authentication Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the authentication method used to connect to the remote environment.';
                }

                group("OAuth2.0")
                {
                    Caption = 'OAuth2.0', Locked = true;
                    Visible = Rec."Authentication Type" = Rec."Authentication Type"::"OAuth 2.0";
                    field("Tenant ID"; Rec."Tenant ID")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the Microsoft Entra tenant that contains the remote Business Central environment.';
                    }
                    field("Client Id"; Rec."Client Id")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the client ID of the Microsoft Entra authentication application';
                        trigger OnValidate()
                        begin
                            Rec.DeleteToken(Rec."Secret Id");
                        end;
                    }
                    field("EOS Secret Id"; SecretId)
                    {
                        ApplicationArea = All;
                        Caption = 'Secret Id', Locked = true;
                        ToolTip = 'Specifies the client secret of the Microsoft Entra authentication application';
                        ExtendedDatatype = Masked;
                        trigger OnValidate()
                        var
                            SecretIdValue: SecretText;
                        begin
                            SecretIdValue := SecretId;
                            Rec.SetToken(Rec."Secret Id", SecretIdValue);
                        end;
                    }
                    field("Token Url"; Rec."Token Url")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the OAuth 2.0 token endpoint of the Microsoft Entra authentication application. The endpoint indicates a directory to which tokens can be requested. In most scenarios this will be: https://login.microsoftonline.com/<tenantID>/oauth2/v2.0/token';
                    }
                    field("Redirect Url"; Rec."Redirect Url")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the redirect URL for the OAuth 2.0 authentication flow. In most OnPrem scenarios this will be: https://<serverName>/<instanceName>/OAuthLanding.htm . In most Cloud scenarios this will be: https://businesscentral.dynamics.com/OAuthLanding.htm';
                    }
                    field(Scope; Rec.Scope)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the OAuth scope required for authentication. In most scenarios this will be: https://api.businesscentral.dynamics.com/.default';
                    }
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

    trigger OnOpenPage()
    begin
        SecretId := ' ';
    end;

    local procedure CleanEnvDatas()
    begin
        Rec."API Base Url" := '';
        Rec."Environment Name" := '';
        Rec."Instance Name" := '';
        Rec."Server Port" := 0;
    end;

    var
        SecretId: Text;
}