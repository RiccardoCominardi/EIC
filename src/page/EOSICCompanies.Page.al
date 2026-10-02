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
                }
                field("Interface"; Rec."Interface")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Connection Code"; Rec."Connection Code")
                {
                    ApplicationArea = All;
                }
                field("Remote Company Name"; Rec."Remote Company Name")
                {
                    ApplicationArea = All;
                }
                field("Remote Company Id"; Rec."Remote Company Id")
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
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
            actionref(Flows_Promoted; Flows) { }
        }
    }
}