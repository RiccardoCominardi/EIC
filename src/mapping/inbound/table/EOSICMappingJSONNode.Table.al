namespace EOS.Solutions.Intercompany;

table 67018 "EOS IC Mapping Json Node"
{
    DataClassification = CustomerContent;
    Caption = 'IC Mapping Json Node (EIC)';

    fields
    {
        field(1; "Mapping Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Code';
            TableRelation = "EOS IC Mapping Headers"."Code";
        }
        field(2; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(3; "Parent Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Entry No.';
        }
        field(4; Indentation; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Indentation';
        }
        field(5; Name; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Name';
        }
        field(6; Path; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Path';
        }
        field(7; "Node Type"; Enum "EOS IC Json Node Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Node Type';
        }
        field(8; "Has Value"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Has Value';
        }
        field(9; "Sample Value"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Sample Value';
        }
        field(10; "Array Depth"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Array Depth';
            BlankZero = true;
        }
    }

    keys
    {
        key(Key1; "Mapping Code", "Entry No.") { Clustered = true; }
        key(ParentKey; "Mapping Code", "Parent Entry No.", "Entry No.") { }
    }
}
