namespace EOS.Solutions.Intercompany;

table 67010 "EOS IC Stg. Purch. Line"
{
    DataClassification = CustomerContent;
    Caption = 'IC Staging Purchase Line (EIC)';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
            TableRelation = "EOS IC Stg. Purch. Header"."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(3; Type; Text[30])
        {
            DataClassification = CustomerContent;
            Caption = 'Type';
        }
        field(4; "No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No.';
        }
        field(5; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(6; Quantity; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Unit of Measure Code';
        }
        field(8; "Direct Unit Cost"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 2 : 5;
        }
        field(9; "Line Discount %"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Line Discount %';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Line Amount"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Line Amount';
            DecimalPlaces = 2 : 2;
        }
        field(11; "Location Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Location Code';
        }
        field(12; "Requested Receipt Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Requested Receipt Date';
        }
        field(13; "Variant Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Variant Code';
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Line No.") { Clustered = true; }
    }
}
