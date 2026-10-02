namespace EOS.Solutions.Intercompany;

using System.Security.User;

page 67022 "EOS IC Stg. Shpt. Lines Sub"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "EOS IC Stg. Shpt. Line";
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.") { }
                field(Type; Rec.Type) { }
                field("No."; Rec."No.") { }
                field(Description; Rec.Description) { }
                field(Quantity; Rec.Quantity) { }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { }
                field("Location Code"; Rec."Location Code") { }
                field("Variant Code"; Rec."Variant Code") { }
                field("Order No."; Rec."Order No.") { }
                field("Order Line No."; Rec."Order Line No.") { }
            }
        }
    }
}
