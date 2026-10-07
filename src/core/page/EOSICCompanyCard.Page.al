namespace EOS.Solutions.Intercompany;
page 67004 "EOS IC Company Card"
{
    Caption = 'IC Company Card (EIC)';
    PageType = Document;
    UsageCategory = None;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Companies";

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
                field("Interface"; Rec."Interface")
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
            group(RemoteEnvironment)
            {
                Caption = 'Remote Environment';
                field("Connection Code"; Rec."Connection Code")
                {
                    ApplicationArea = All;
                }
                field("Remote Company Id"; Rec."Remote Company Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Remote Company Name"; Rec."Remote Company Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetCompanyInfos)
            {
                ApplicationArea = All;
                Caption = 'Get Company Infos';
                Image = CompanyInformation;
                trigger OnAction()
                var
                    ICFunctions: Codeunit "EOS IC Functions";
                begin
                    ICFunctions.GetCompanyInfos(Rec);
                end;
            }
            action(Flows)
            {
                ApplicationArea = All;
                Caption = 'Flows';
                Image = Flow;
                RunObject = page "EOS IC Flows";
                RunPageLink = "Company Code" = field(Code);
            }
        }
        area(Promoted)
        {
            actionref(GetCompanyInfos_Promoted; GetCompanyInfos) { }
            actionref(Flows_Promoted; Flows) { }
        }
    }
}