namespace EOS.Solutions.Intercompany;

using System.Security.User;

page 67027 "EOS IC Stg. Item Card"
{
    Caption = 'IC Staging Item (EIC)';
    PageType = Card;
    SourceTable = "EOS IC Stg. Item";
    UsageCategory = None;
    ApplicationArea = All;
    InsertAllowed = false;
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
                field(Description; Rec.Description) { }
                field("Description 2"; Rec."Description 2") { }
                field(Type; Rec.Type) { }
                field("Base Unit of Measure"; Rec."Base Unit of Measure") { }
                field("Item Category Code"; Rec."Item Category Code") { }
                field(Blocked; Rec.Blocked) { }
                field(GTIN; Rec.GTIN) { }
            }
            group(Posting)
            {
                Caption = 'Posting';

                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group") { }
                field("Inventory Posting Group"; Rec."Inventory Posting Group") { }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group") { }
            }
            group(Prices)
            {
                Caption = 'Prices';

                field("Unit Price"; Rec."Unit Price") { }
                field("Unit Cost"; Rec."Unit Cost") { }
            }
        }
    }
}
