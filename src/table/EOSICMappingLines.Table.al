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
        field(6; "Target Table ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Table ID';
            Editable = false;
        }
        field(9; "Target Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Field No.';
            BlankZero = true;
            trigger OnLookup()
            var
                NewFieldID: Integer;
            begin
                if LookupFieldsID(NewFieldID, Rec."Target Table ID", Rec."Target Field No.") then
                    Rec.Validate("Target Field No.", NewFieldID);
            end;
        }
        field(10; "Target Field Name"; Text[80])
        {
            Caption = 'Target Field Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Target Table ID"), "No." = field("Target Field No.")));
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
        field(14; Section; Enum "EOS IC Mapping Section")
        {
            DataClassification = CustomerContent;
            Caption = 'Section';
            trigger OnValidate()
            begin
                if Rec.Section <> xRec.Section then begin
                    InitFromHeader();
                    Rec."Target Field No." := 0;
                end;
            end;
        }
        field(15; "JSON Tag"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'JSON Tag';
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
        case Section of
            Section::Header:
                "Target Table ID" := ICMappingHeaders."Header Table ID";
            Section::Lines:
                begin
                    ICMappingHeaders.TestField("Lines Table ID");
                    "Target Table ID" := ICMappingHeaders."Lines Table ID";
                end;
        end;
    end;

    procedure LookupFieldsID(var NewFieldNo: Integer; TableNo: Integer; FieldNo: Integer): Boolean
    var
        Field: Record Field;
        FieldsLookup: Page "Fields Lookup";
    begin
        if Field.Get(TableNo, FieldNo) then;

        Field.FilterGroup(2);
        Field.SetRange(TableNo, TableNo);
        Field.FilterGroup(0);
        FieldsLookup.SetRecord(Field);
        FieldsLookup.SetTableView(Field);
        FieldsLookup.LookupMode := true;
        if FieldsLookup.RunModal() = Action::LookupOK then begin
            FieldsLookup.GetRecord(Field);
            NewFieldNo := Field."No.";
            exit(true);
        end;
        exit(false);
    end;
}
