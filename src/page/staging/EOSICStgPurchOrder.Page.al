namespace EOS.Solutions.Intercompany;

page 67018 "EOS IC Stg. Purch. Order"
{
    Caption = 'IC Staging Purchase Order (EIC)';
    PageType = Document;
    SourceTable = "EOS IC Stg. Purch. Header";
    UsageCategory = None;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Entry No."; Rec."Entry No.") { }
                field("IC Entry No."; Rec."IC Entry No.") { }
                field(Status; Rec.Status) { }
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
            part(Lines; "EOS IC Stg. Purch. Lines Sub")
            {
                Caption = 'Lines';
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }
}
