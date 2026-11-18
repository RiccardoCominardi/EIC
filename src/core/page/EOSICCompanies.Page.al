namespace EOS.Solutions.Intercompany;
page 67003 "EOS IC Companies"
{
    Caption = 'IC Companies (EIC)';
    CardPageID = "EOS IC Company Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Companies";
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
                field("Connection Code"; Rec."Connection Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the connection used to access the remote company.';
                }
                field("Remote Company Name"; Rec."Remote Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the company in the remote Business Central environment.';
                }
                field("Remote Company Id"; Rec."Remote Company Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the company in the remote Business Central environment.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this intercompany company is available for use.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
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
            actionref(Flows_Promoted; Flows) { }
            actionref(Functions_Promoted; Functions) { }
        }
    }
}