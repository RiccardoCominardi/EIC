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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Environment Type"; Rec."Environment Type")
                {
                    ApplicationArea = All;
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
                    }
                    field("Server Port"; Rec."Server Port")
                    {
                        ApplicationArea = All;
                        BlankZero = true;
                    }
                    field("Instance Name"; Rec."Instance Name")
                    {
                        ApplicationArea = All;
                    }
                }
                group(SaaS)
                {
                    ShowCaption = false;
                    Visible = Rec."Environment Type" = Rec."Environment Type"::SaaS;
                    field("SaaS API Base Url"; Rec."API Base Url")
                    {
                        ApplicationArea = All;
                    }
                    field("Environment Name"; Rec."Environment Name")
                    {
                        ApplicationArea = All;
                    }
                }
            }
            group(Authentication)
            {
                Caption = 'Authentication';
                field("Authentication Type"; Rec."Authentication Type")
                {
                    ApplicationArea = All;
                }

                group("OAuth2.0")
                {
                    Caption = 'OAuth2.0', Locked = true;
                    Visible = Rec."Authentication Type" = Rec."Authentication Type"::"OAuth 2.0";
                    field("Tenant ID"; Rec."Tenant ID")
                    {
                        ApplicationArea = All;
                    }
                    field("Client Id"; Rec."Client Id")
                    {
                        ApplicationArea = All;
                        trigger OnValidate()
                        begin
                            Rec.DeleteToken(Rec."Secret Id");
                        end;
                    }
                    field("EOS Secret Id"; SecretId)
                    {
                        ApplicationArea = All;
                        Caption = 'Secret Id', Locked = true;
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
                    }
                    field("Redirect Url"; Rec."Redirect Url")
                    {
                        ApplicationArea = All;
                    }
                    field(Scope; Rec.Scope)
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