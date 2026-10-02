namespace EOS.Solutions.Intercompany;

page 67016 "EOS IC Stg. Sales Lines Sub"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "EOS IC Stg. Sales Line";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
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
                field("Unit Price"; Rec."Unit Price") { }
                field("Line Discount %"; Rec."Line Discount %") { }
                field("Line Amount"; Rec."Line Amount") { }
                field("Location Code"; Rec."Location Code") { }
                field("Requested Delivery Date"; Rec."Requested Delivery Date") { }
                field("Variant Code"; Rec."Variant Code") { }
            }
        }
    }
}
