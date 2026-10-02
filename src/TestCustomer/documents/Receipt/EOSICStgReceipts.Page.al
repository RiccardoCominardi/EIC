namespace EOS.Solutions.Intercompany;

page 67023 "EOS IC Stg. Receipts"
{
    Caption = 'IC Staging Receipts (EIC)';
    PageType = List;
    SourceTable = "EOS IC Stg. Rcpt. Header";
    CardPageId = "EOS IC Stg. Receipt";
    UsageCategory = Lists;
    ApplicationArea = All;
    InsertAllowed = false;
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
                field("Posting Date"; Rec."Posting Date") { }
                field("Order No."; Rec."Order No.") { }
                field("Vendor Shipment No."; Rec."Vendor Shipment No.") { }
                field("Location Code"; Rec."Location Code") { }
            }
        }
    }
}
