namespace EOS.Solutions.Intercompany;

table 67012 "EOS IC Stg. Shpt. Line"
{
    DataClassification = CustomerContent;
    Caption = 'IC Staging Shipment Line (EIC)';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
            TableRelation = "EOS IC Stg. Shpt. Header"."Entry No.";
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
        field(8; "Location Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Location Code';
        }
        field(9; "Variant Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Variant Code';
        }
        field(10; "Order No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Order No.';
        }
        field(11; "Order Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Order Line No.';
        }
    }

    keys
    {
        key(Key1; "Entry No.", "Line No.") { Clustered = true; }
    }
}
