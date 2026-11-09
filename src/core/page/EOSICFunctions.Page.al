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
                field("Sales Order Creation Flow"; Rec."Sales Order Creation Flow")
                {
                    ApplicationArea = All;
                }
                field("Purchase Order Creation Flow"; Rec."Purchase Order Creation Flow")
                {
                    ApplicationArea = All;
                }
                field("Confirm Sales Order Flow"; Rec."Confirm Sales Order Flow")
                {
                    ApplicationArea = All;
                }
                field("Confirm Purchase Order Flow"; Rec."Confirm Purchase Order Flow")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}