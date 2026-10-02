namespace EOS.Solutions.Intercompany;

page 67017 "EOS IC Stg. Purch. Orders"
{
    Caption = 'IC Staging Purchase Orders (EIC)';
    PageType = List;
    SourceTable = "EOS IC Stg. Purch. Header";
    CardPageId = "EOS IC Stg. Purch. Order";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("IC Entry No."; Rec."IC Entry No.") { }
                field("No."; Rec."No.") { }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.") { }
                field("Order Date"; Rec."Order Date") { }
                field("Posting Date"; Rec."Posting Date") { }
                field("Document Date"; Rec."Document Date") { }
                field("Requested Receipt Date"; Rec."Requested Receipt Date") { }
                field("Currency Code"; Rec."Currency Code") { }
                field("Vendor Order No."; Rec."Vendor Order No.") { }
                field("Your Reference"; Rec."Your Reference") { }
                field("Payment Terms Code"; Rec."Payment Terms Code") { }
                field("Shipment Method Code"; Rec."Shipment Method Code") { }
                field("Location Code"; Rec."Location Code") { }
            }
        }
    }
}
