namespace EOS.Solutions.Intercompany;

page 67024 "EOS IC Stg. Receipt"
{
    Caption = 'IC Staging Receipt (EIC)';
    PageType = Document;
    SourceTable = "EOS IC Stg. Rcpt. Header";
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
                field("No."; Rec."No.") { }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.") { }
                field("Posting Date"; Rec."Posting Date") { }
                field("Order No."; Rec."Order No.") { }
                field("Vendor Shipment No."; Rec."Vendor Shipment No.") { }
                field("Location Code"; Rec."Location Code") { }
            }
            part(Lines; "EOS IC Stg. Rcpt. Lines Sub")
            {
                Caption = 'Lines';
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }
}
