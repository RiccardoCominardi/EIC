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
            ToolTip = 'Specifies the staging record that owns this value metadata.';
            TableRelation = "EOS IC Staging"."Staging Record ID";
        }
        field(2; "Staging Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Staging Field No.';
            ToolTip = 'Specifies the number of the staging field that stores this value.';
        }
        field(3; "Value State"; Enum "EOS IC Staging Value State")
        {
            DataClassification = CustomerContent;
            Caption = 'Value State';
            ToolTip = 'Specifies whether the staging value is missing, null, blank, or populated.';
        }
        field(4; "Json Path"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Json Path';
            ToolTip = 'Specifies the JSON path from which the staging value was read.';
        }
        field(5; "Original Json Value"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Original Json Value';
            ToolTip = 'Stores the original JSON value before any manual changes.';
        }
        field(6; "Enum/Option Source Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum/Option Source Table No.';
            ToolTip = 'Specifies the table that defines the enum or option values for this staging field.';
        }
        field(7; "Enum/Option Source Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum/Option Source Field No.';
            ToolTip = 'Specifies the field that defines the enum or option values for this staging field.';
        }
        field(8; "Enum Type ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum Type ID';
            ToolTip = 'Specifies the ID of the enum type used by this staging value.';
        }
        field(9; "Enum App ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum App ID';
            ToolTip = 'Specifies the application ID that owns the enum type.';
        }
        field(10; "Enum Namespace"; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Enum Namespace';
            ToolTip = 'Specifies the namespace of the enum type used by this staging value.';
        }
        field(11; "Enum Type Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Enum Type Name';
            ToolTip = 'Specifies the name of the enum type used by this staging value.';
        }
        field(12; "Is Option"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Option';
            ToolTip = 'Specifies whether the source value is an option rather than an enum.';
        }
        field(13; "Option Members"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Option Members';
            ToolTip = 'Stores the option members available for this staging value.';
        }
        field(14; "IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry No.';
            ToolTip = 'Specifies the intercompany entry associated with this staging value.';
        }
        field(15; "Mapping Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Line No.';
            ToolTip = 'Specifies the mapping line order used to display this staging value.';
        }
    }

    keys
    {
        key(Key1; "Staging Record ID", "Staging Field No.") { Clustered = true; }
        key(EntryField; "IC Entry No.", "Staging Record ID", "Staging Field No.") { }
        key(MappingOrder; "Staging Record ID", "Mapping Line No.") { }
    }
}