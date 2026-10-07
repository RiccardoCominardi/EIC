namespace EOS.Solutions.Intercompany;
page 67009 "EOS IC Mapping List"
{
    Caption = 'IC Mappings (EIC)';
    CardPageID = "EOS IC Mapping Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Mapping Headers";
    UsageCategory = None;
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
                field("Header Table ID"; Rec."Header Table ID")
                {
                    ApplicationArea = All;
                }
                field("Lines Table ID"; Rec."Lines Table ID")
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
}
