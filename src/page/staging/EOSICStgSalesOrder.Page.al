namespace EOS.Solutions.Intercompany;

page 67015 "EOS IC Stg. Sales Order"
{
    Caption = 'IC Staging Sales Order (EIC)';
    PageType = Document;
    SourceTable = "EOS IC Stg. Sales Header";
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
                field("Sell-to Customer No."; Rec."Sell-to Customer No.") { }
                field("Order Date"; Rec."Order Date") { }
                field("Posting Date"; Rec."Posting Date") { }
                field("Document Date"; Rec."Document Date") { }
                field("Requested Delivery Date"; Rec."Requested Delivery Date") { }
                field("Currency Code"; Rec."Currency Code") { }
                field("External Document No."; Rec."External Document No.") { }
                field("Your Reference"; Rec."Your Reference") { }
                field("Payment Terms Code"; Rec."Payment Terms Code") { }
                field("Shipment Method Code"; Rec."Shipment Method Code") { }
                field("Location Code"; Rec."Location Code") { }
            }
            part(Lines; "EOS IC Stg. Sales Lines Sub")
            {
                Caption = 'Lines';
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }
}
