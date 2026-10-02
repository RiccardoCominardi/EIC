namespace EOS.Solutions.Intercompany;

page 67020 "EOS IC Stg. Shipments"
{
    Caption = 'IC Staging Shipments (EIC)';
    PageType = List;
    SourceTable = "EOS IC Stg. Shpt. Header";
    CardPageId = "EOS IC Stg. Shipment";
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
                field("Sell-to Customer No."; Rec."Sell-to Customer No.") { }
                field("Posting Date"; Rec."Posting Date") { }
                field("Order No."; Rec."Order No.") { }
                field("External Document No."; Rec."External Document No.") { }
                field("Location Code"; Rec."Location Code") { }
            }
        }
    }
}
