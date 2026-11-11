namespace EOS.Solutions.Intercompany;
page 67022 "EOS IC Functions"
{
    Caption = 'IC Functions (EIC)';
    PageType = List;
    SourceTable = "EOS IC Functions";
    UsageCategory = None;
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                }
                field("Send Create Sales Order"; Rec."Send Create Sales Order")
                {
                    ApplicationArea = All;
                }
                field("Send Create Purch. Order"; Rec."Send Create Purch. Order")
                {
                    ApplicationArea = All;
                }
                field("Send Rec. Confirm Sales Order"; Rec."Send Rec. Confirm Sales Order")
                {
                    ApplicationArea = All;
                }
                field("Send Rec. Confirm Purch. Order"; Rec."Send Rec. Confirm Purch. Order")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}