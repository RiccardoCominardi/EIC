namespace EOS.Solutions.Intercompany;
page 67010 "EOS IC Mapping Card"
{
    Caption = 'IC Mapping Card (EIC)';
    PageType = Document;
    UsageCategory = None;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Mapping Headers";

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
                field("Source Table ID"; Rec."Source Table ID")
                {
                    ApplicationArea = All;
                }
                field("Target Table ID"; Rec."Target Table ID")
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "EOS IC Mapping Lines Subpage")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = "Company Code" = field("Company Code"), "Flow Code" = field("Flow Code"), "Mapping Code" = field(Code);
                UpdatePropagation = Both;
            }
        }
    }
}
