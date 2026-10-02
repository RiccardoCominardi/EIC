namespace EOS.Solutions.Intercompany;
page 67029 "EOS IC Document Type List"
{
    Caption = 'IC Document Types (EIC)';
    CardPageID = "EOS IC Document Type";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Document Types";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
