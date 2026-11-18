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
            ToolTip = 'Specifies the mapping that contains this JSON node.';
            TableRelation = "EOS IC Mapping Headers"."Code";
        }
        field(2; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique sequence number of the JSON node.';
        }
        field(3; "Parent Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Entry No.';
            ToolTip = 'Specifies the sequence number of the parent JSON node.';
        }
        field(4; Indentation; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Indentation';
            ToolTip = 'Specifies the node depth used to display the JSON structure.';
        }
        field(5; Name; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Name';
            ToolTip = 'Specifies the name of the JSON property or array node.';
        }
        field(6; Path; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Path';
            ToolTip = 'Specifies the full JSON path to this node in the imported sample.';
        }
        field(7; "Node Type"; Enum "EOS IC Json Node Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Node Type';
            ToolTip = 'Specifies whether the JSON node is an object, array, or value.';
        }
        field(8; "Has Value"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Has Value';
            ToolTip = 'Specifies whether the JSON node contains a sample value.';
        }
        field(9; "Sample Value"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Sample Value';
            ToolTip = 'Specifies the value found for this node in the imported JSON sample.';
        }
        field(10; "Array Depth"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Array Depth';
            ToolTip = 'Specifies the number of nested arrays containing this node.';
            BlankZero = true;
        }
    }

    keys
    {
        key(Key1; "Mapping Code", "Entry No.") { Clustered = true; }
        key(ParentKey; "Mapping Code", "Parent Entry No.", "Entry No.") { }
    }
}
