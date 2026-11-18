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
                    ToolTip = 'Specifies the unique code of the intercompany company.';
                }
                field("Interface"; Rec."Interface")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the interface used to exchange intercompany data with this company.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the intercompany company.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this intercompany company is available for use.';
                }
            }
            group(RemoteEnvironment)
            {
                Caption = 'Remote Environment';
                field("Connection Code"; Rec."Connection Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the connection used to access the remote company.';
                }
                field("Remote Company Id"; Rec."Remote Company Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the company in the remote Business Central environment.';
                }
                field("Remote Company Name"; Rec."Remote Company Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the name of the company in the remote Business Central environment.';
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
                ToolTip = 'Retrieves the available companies from the selected remote connection.';
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
                ToolTip = 'Opens the flows configured for this intercompany company.';
                Image = Flow;
                RunObject = page "EOS IC Flows";
                RunPageLink = "Company Code" = field(Code);
            }
            action(Functions)
            {
                ApplicationArea = All;
                Caption = 'Functions';
                ToolTip = 'Opens the intercompany functions configured for this company.';
                Image = Action;
                RunObject = page "EOS IC Functions";
                RunPageLink = "Company Code" = field(Code);
            }
        }
        area(Promoted)
        {
            actionref(GetCompanyInfos_Promoted; GetCompanyInfos) { }
            actionref(Flows_Promoted; Flows) { }
            actionref(Functions_Promoted; Functions) { }
        }
    }
}