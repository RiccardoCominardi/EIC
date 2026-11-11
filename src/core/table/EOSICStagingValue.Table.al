namespace EOS.Solutions.Intercompany;

table 67012 "EOS IC Staging Value"
{
    DataClassification = CustomerContent;
    Caption = 'IC Staging Value (EIC)';

    fields
    {
        field(1; "Staging Record ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Staging Record ID';
            TableRelation = "EOS IC Staging"."Staging Record ID";
        }
        field(2; "Staging Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Staging Field No.';
        }
        field(3; "Value State"; Enum "EOS IC Staging Value State")
        {
            DataClassification = CustomerContent;
            Caption = 'Value State';
        }
        field(4; "Json Path"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Json Path';
        }
        field(5; "Original Json Value"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Original Json Value';
        }
        field(6; "Enum/Option Source Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum/Option Source Table No.';
        }
        field(7; "Enum/Option Source Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum/Option Source Field No.';
        }
        field(8; "Enum Type ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum Type ID';
        }
        field(9; "Enum App ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum App ID';
        }
        field(10; "Enum Namespace"; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Enum Namespace';
        }
        field(11; "Enum Type Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Enum Type Name';
        }
        field(12; "Is Option"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Option';
        }
        field(13; "Option Members"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Option Members';
        }
        field(14; "IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry No.';
        }
        field(15; "Mapping Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Line No.';
        }
    }

    keys
    {
        key(Key1; "Staging Record ID", "Staging Field No.") { Clustered = true; }
        key(EntryField; "IC Entry No.", "Staging Record ID", "Staging Field No.") { }
        key(MappingOrder; "Staging Record ID", "Mapping Line No.") { }
    }
}