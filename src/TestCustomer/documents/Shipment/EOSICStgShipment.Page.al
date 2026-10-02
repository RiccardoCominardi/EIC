namespace EOS.Solutions.Intercompany;

page 67021 "EOS IC Stg. Shipment"
{
    Caption = 'IC Staging Shipment (EIC)';
    PageType = Document;
    SourceTable = "EOS IC Stg. Shpt. Header";
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
                field("Sell-to Customer No."; Rec."Sell-to Customer No.") { }
                field("Posting Date"; Rec."Posting Date") { }
                field("Order No."; Rec."Order No.") { }
                field("External Document No."; Rec."External Document No.") { }
                field("Location Code"; Rec."Location Code") { }
            }
            part(Lines; "EOS IC Stg. Shpt. Lines Sub")
            {
                Caption = 'Lines';
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }
}
