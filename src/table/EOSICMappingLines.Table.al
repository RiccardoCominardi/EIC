namespace EOS.Solutions.Intercompany;

using System.Reflection;

table 67005 "EOS IC Mapping Lines"
{
    DataClassification = CustomerContent;
    Caption = 'IC Mapping Lines (EIC)';

    fields
    {
        field(1; "Company Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code';
            TableRelation = "EOS IC Companies".Code;
        }
        field(2; "Flow Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Flow Code';
            TableRelation = "EOS IC Flows"."Code" where("Company Code" = field("Company Code"));
        }
        field(3; "Mapping Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Code';
            TableRelation = "EOS IC Mapping Headers"."Code" where("Company Code" = field("Company Code"), "Flow Code" = field("Flow Code"));
        }
        field(4; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(5; "Source Table ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Table ID';
            Editable = false;
        }
        field(6; "Target Table ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Table ID';
            Editable = false;
        }
        field(7; "Source Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Field No.';
            TableRelation = Field."No." where(TableNo = field("Source Table ID"));
            BlankZero = true;
        }
        field(8; "Source Field Name"; Text[30])
        {
            Caption = 'Source Field Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Source Table ID"), "No." = field("Source Field No.")));
            Editable = false;
        }
        field(9; "Target Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Field No.';
            TableRelation = Field."No." where(TableNo = field("Target Table ID"));
            BlankZero = true;
        }
        field(10; "Target Field Name"; Text[30])
        {
            Caption = 'Target Field Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Target Table ID"), "No." = field("Target Field No.")));
            Editable = false;
        }
        field(11; "Source Value"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Value';
        }
        field(12; "Mapping Type"; Enum "EOS IC Mapping Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Type';
        }
        field(13; "Target Value"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Target Value';
        }
    }

    keys
    {
        key(Key1; "Company Code", "Flow Code", "Mapping Code", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        InitFromHeader();
    end;

    procedure InitFromHeader()
    var
        ICMappingHeaders: Record "EOS IC Mapping Headers";
    begin
        ICMappingHeaders.Get("Company Code", "Flow Code", "Mapping Code");
        "Source Table ID" := ICMappingHeaders."Source Table ID";
        "Target Table ID" := ICMappingHeaders."Target Table ID";
    end;
}
