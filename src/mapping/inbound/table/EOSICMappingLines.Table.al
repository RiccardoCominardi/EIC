namespace EOS.Solutions.Intercompany;

using System.Reflection;

table 67017 "EOS IC Mapping Lines"
{
    DataClassification = CustomerContent;
    Caption = 'IC Mapping Lines (EIC)';

    fields
    {
        field(1; "Mapping Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Code';
            TableRelation = "EOS IC Mapping Headers"."Code";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(3; "Json Path"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Json Path';
            trigger OnValidate()
            var
                ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
            begin
                Rec."Json Path" := CopyStr(ICJsonPathMgt.NormalizePath(Rec."Json Path"), 1, MaxStrLen(Rec."Json Path"));
                Rec.UpdateJsonPathInfo();
                CheckDuplicatedPath();
            end;
        }
        field(4; "Mapping Type"; Enum "EOS IC Mapping Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Type';
        }
        field(5; "Target Table ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            BlankZero = true;
            trigger OnValidate()
            begin
                if Rec."Target Table ID" <> xRec."Target Table ID" then
                    Rec."Target Field No." := 0;
            end;
        }
        field(6; "Target Table Name"; Text[249])
        {
            Caption = 'Target Table Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Target Table ID")));
            Editable = false;
        }
        field(7; "Target Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Field No.';
            BlankZero = true;
            trigger OnValidate()
            var
                Field: Record Field;
                FieldNotFoundErr: Label 'The field %1 does not exist in the table %2.', Comment = '%1 = field no., %2 = table id';
            begin
                if Rec."Target Field No." = 0 then
                    exit;

                Rec.TestField("Target Table ID");
                if not Field.Get(Rec."Target Table ID", Rec."Target Field No.") then
                    Error(FieldNotFoundErr, Rec."Target Field No.", Rec."Target Table ID");
            end;

            trigger OnLookup()
            var
                NewFieldNo: Integer;
            begin
                Rec.TestField("Target Table ID");
                if LookupFieldsID(NewFieldNo, Rec."Target Table ID", Rec."Target Field No.") then
                    Rec.Validate("Target Field No.", NewFieldNo);
            end;
        }
        field(8; "Target Field Name"; Text[80])
        {
            Caption = 'Target Field Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Target Table ID"), "No." = field("Target Field No.")));
            Editable = false;
        }
        field(9; "Source Value"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Value';
        }
        field(10; "Target Value"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Target Value';
        }
        field(11; "Array Context"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Array Context';
            Editable = false;
        }
        field(12; Indentation; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Indentation';
            Editable = false;
        }
        field(13; "Is Structure"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Structure';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Mapping Code", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        CheckDuplicatedPath();
    end;

    trigger OnModify()
    begin
        if Rec."Json Path" <> xRec."Json Path" then
            CheckDuplicatedPath();
    end;

    // The array context ends at the innermost array; indentation counts the structural ancestors.
    procedure UpdateJsonPathInfo()
    var
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
    begin
        Rec."Array Context" := CopyStr(ICJsonPathMgt.GetArrayContext(Rec."Json Path"), 1, MaxStrLen(Rec."Array Context"));
        Rec.Indentation := ICJsonPathMgt.GetNodeLevel(Rec."Json Path");
    end;

    local procedure CheckDuplicatedPath()
    var
        ICMappingLines: Record "EOS IC Mapping Lines";
        DuplicatedPathErr: Label 'The Json path %1 is already used by the line %2 of the mapping %3.', Comment = '%1 = Json path, %2 = line no., %3 = mapping code';
    begin
        if (Rec."Json Path" = '') or Rec."Is Structure" then
            exit;

        ICMappingLines.SetRange("Mapping Code", Rec."Mapping Code");
        ICMappingLines.SetRange("Json Path", Rec."Json Path");
        ICMappingLines.SetRange("Is Structure", false);
        ICMappingLines.SetFilter("Line No.", '<>%1', Rec."Line No.");
        if ICMappingLines.FindFirst() then
            Error(DuplicatedPathErr, Rec."Json Path", ICMappingLines."Line No.", Rec."Mapping Code");
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
