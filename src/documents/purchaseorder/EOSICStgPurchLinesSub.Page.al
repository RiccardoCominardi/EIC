namespace EOS.Solutions.Intercompany;

using System.Security.User;

page 67019 "EOS IC Stg. Purch. Lines Sub"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "EOS IC Stg. Purch. Line";
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
                field("Direct Unit Cost"; Rec."Direct Unit Cost") { }
                field("Line Discount %"; Rec."Line Discount %") { }
                field("Line Amount"; Rec."Line Amount") { }
                field("Location Code"; Rec."Location Code") { }
                field("Requested Receipt Date"; Rec."Requested Receipt Date") { }
                field("Variant Code"; Rec."Variant Code") { }
            }
        }
    }
}
