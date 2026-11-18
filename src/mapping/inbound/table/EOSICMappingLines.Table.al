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
            ToolTip = 'Specifies the inbound mapping that contains this line.';
            TableRelation = "EOS IC Mapping Headers"."Code";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
            ToolTip = 'Specifies the sequence number of the mapping line.';
        }
        field(3; "Json Path"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Json Path';
            ToolTip = 'Specifies the path of the value to read from the incoming JSON payload.';
            trigger OnValidate()
            var
                ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
            begin
                Rec."Json Path" := CopyStr(ICJsonPathMgt.NormalizePath(Rec."Json Path"), 1, MaxStrLen(Rec."Json Path"));
                Rec.UpdateJsonPathInfo();
                CheckDuplicatedPath();
            end;
        }
        field(4; "Value Type"; Enum "EOS IC Value Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Value Type';
            ToolTip = 'Specifies whether the staging value comes from the JSON payload, a constant, or a transformation.';

            trigger OnValidate()
            begin
                Rec.Validate("Transliteration Code");
                Rec.Validate("String Replacement Code");
            end;
        }
        field(11; "Array Context"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Array Context';
            ToolTip = 'Specifies the innermost JSON array context associated with this path.';
            Editable = false;
        }
        field(12; Indentation; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Indentation';
            ToolTip = 'Specifies the depth of this JSON path in the mapping tree.';
            Editable = false;
        }
        field(13; "Is Structure"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Structure';
            ToolTip = 'Specifies whether this line represents a JSON structure rather than a mapped value.';
            Editable = false;
        }
        field(15; "Transliteration Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Transliteration Code';
            ToolTip = 'Specifies the character-transliteration setup applied to the mapped text value.';
            TableRelation = "EOS IC String Transform Header"."Code" where("Transformation Type" = const("Character Transliteration"));

            trigger OnValidate()
            var
                Field: Record Field;
                MustNotBeLbl: Label 'must not be %1.', Comment = '%1 = mapping type';
                MustBeTextLbl: Label 'must be a field of type Text or Code.';
            begin
                if Rec."Transliteration Code" = '' then
                    exit;

                if Rec."Value Type" = Rec."Value Type"::Constant then
                    Rec.FieldError("Value Type", StrSubstNo(MustNotBeLbl, Rec."Value Type"));

                if Field.Get(Database::"EOS IC Staging", Rec."Staging Field No.") then
                    if not (Field.Type in [Field.Type::Text, Field.Type::Code]) then
                        Rec.FieldError("Staging Field No.", MustBeTextLbl);
            end;
        }
        field(16; "String Replacement Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'String Replacement Code';
            ToolTip = 'Specifies the complete-string replacement setup applied to the mapped text value.';
            TableRelation = "EOS IC String Transform Header"."Code" where("Transformation Type" = const("Complete String Replacement"));

            trigger OnValidate()
            var
                Field: Record Field;
                MustNotBeLbl: Label 'must not be %1.', Comment = '%1 = mapping type';
                MustBeTextLbl: Label 'must be a field of type Text or Code.';
            begin
                if Rec."String Replacement Code" = '' then
                    exit;

                if Rec."Value Type" = Rec."Value Type"::Constant then
                    Rec.FieldError("Value Type", StrSubstNo(MustNotBeLbl, Rec."Value Type"));

                if Field.Get(Database::"EOS IC Staging", Rec."Staging Field No.") then
                    if not (Field.Type in [Field.Type::Text, Field.Type::Code]) then
                        Rec.FieldError("Staging Field No.", MustBeTextLbl);
            end;
        }
        field(17; "Transformation Order"; Enum "EOS IC Transformation Order")
        {
            DataClassification = CustomerContent;
            Caption = 'Transformation Order';
            ToolTip = 'Specifies whether transliteration or string replacement is applied first.';
        }
        field(18; "Staging Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Staging Field No.';
            ToolTip = 'Specifies the typed staging field that receives the mapped value.';
            BlankZero = true;
            TableRelation = Field."No." where(TableNo = const(Database::"EOS IC Staging"));

            trigger OnValidate()
            var
                Field: Record Field;
                StagingMgt: Codeunit "EOS IC Staging Mgt.";
                AvailableFieldNos: List of [Integer];
                UnsupportedFieldErr: Label 'The field %1 cannot be used in unified staging.', Comment = '%1 = field name';
                FieldNotAvailableErr: Label 'The staging field %1 is not available for this mapping line.', Comment = '%1 = field name';
            begin
                if Rec."Staging Field No." = 0 then begin
                    Rec."Show in Staging List" := false;
                    exit;
                end;

                Field.Get(Database::"EOS IC Staging", Rec."Staging Field No.");
                if (Field.Class <> Field.Class::Normal) or (Field.Type in [Field.Type::Blob, Field.Type::Media, Field.Type::MediaSet]) then
                    Error(UnsupportedFieldErr, Field."Field Caption");

                StagingMgt.GetAssignableStagingFieldNos(Rec, AvailableFieldNos);
                if not AvailableFieldNos.Contains(Rec."Staging Field No.") then
                    Error(FieldNotAvailableErr, Field."Field Caption");
            end;

            trigger OnLookup()
            var
                StagingMgt: Codeunit "EOS IC Staging Mgt.";
                AvailableFieldNos: List of [Integer];
                NewFieldNo: Integer;
            begin
                StagingMgt.GetAssignableStagingFieldNos(Rec, AvailableFieldNos);
                if LookupAvailableFieldsID(NewFieldNo, Database::"EOS IC Staging", Rec."Staging Field No.", AvailableFieldNos) then
                    Rec.Validate("Staging Field No.", NewFieldNo);
            end;
        }
        field(19; "Staging Field Name"; Text[80])
        {
            Caption = 'Staging Field Name';
            ToolTip = 'Specifies the name of the selected staging field.';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = const(Database::"EOS IC Staging"), "No." = field("Staging Field No.")));
            Editable = false;
        }
        field(20; "Staging Caption"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Staging Caption';
            ToolTip = 'Specifies the caption displayed for this value in the staging record.';
        }
        field(21; "Enum/Option Source Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum/Option Source Table No.';
            ToolTip = 'Specifies the table that defines the enum or option values for the staging field.';
            BlankZero = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                if Rec."Enum/Option Source Table No." <> xRec."Enum/Option Source Table No." then
                    Rec."Enum/Option Source Field No." := 0;
            end;
        }
        field(22; "Enum/Option Source Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Enum/Option Source Field No.';
            ToolTip = 'Specifies the field that defines the enum or option values for the staging field.';
            BlankZero = true;
            TableRelation = Field."No." where(TableNo = field("Enum/Option Source Table No."));

            trigger OnValidate()
            var
                Field: Record Field;
                SourceFieldRequiredErr: Label 'The source field must be an Enum or Option field.';
            begin
                if Rec."Enum/Option Source Field No." = 0 then
                    exit;

                Rec.TestField("Enum/Option Source Table No.");
                Field.Get(Rec."Enum/Option Source Table No.", Rec."Enum/Option Source Field No.");
                if Field.Type <> Field.Type::Option then
                    Error(SourceFieldRequiredErr);
            end;

            trigger OnLookup()
            var
                NewFieldNo: Integer;
            begin
                Rec.TestField("Enum/Option Source Table No.");
                if LookupEnumSourceFieldID(NewFieldNo, Rec."Enum/Option Source Table No.", Rec."Enum/Option Source Field No.") then
                    Rec.Validate("Enum/Option Source Field No.", NewFieldNo);
            end;
        }
        field(23; "Show in Staging List"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Show in Staging List';
            ToolTip = 'Specifies whether the mapped value is included in the staging tree summary.';

            trigger OnValidate()
            begin
                if not Rec."Show in Staging List" then
                    exit;

                Rec.TestField("Staging Field No.");
                Rec.TestField("Staging Caption");
            end;
        }
        field(24; "Constant Text"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Constant Text';
            ToolTip = 'Specifies the fixed text value assigned to this mapping line.';
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

    procedure LookupAvailableFieldsID(var NewFieldNo: Integer; TableNo: Integer; FieldNo: Integer; AvailableFieldNos: List of [Integer]): Boolean
    var
        Field: Record Field;
        FieldsLookup: Page "Fields Lookup";
        AvailableFieldNo: Integer;
        FieldNoFilter: Text;
    begin
        if AvailableFieldNos.Count() = 0 then
            exit(false);

        foreach AvailableFieldNo in AvailableFieldNos do begin
            if FieldNoFilter <> '' then
                FieldNoFilter += '|';
            FieldNoFilter += Format(AvailableFieldNo, 0, 9);
        end;

        if AvailableFieldNos.Contains(FieldNo) then
            if Field.Get(TableNo, FieldNo) then
                FieldsLookup.SetRecord(Field);

        Field.FilterGroup(2);
        Field.SetRange(TableNo, TableNo);
        Field.SetFilter("No.", FieldNoFilter);
        Field.FilterGroup(0);
        FieldsLookup.SetTableView(Field);
        FieldsLookup.LookupMode := true;
        if FieldsLookup.RunModal() = Action::LookupOK then begin
            FieldsLookup.GetRecord(Field);
            NewFieldNo := Field."No.";
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupEnumSourceFieldID(var NewFieldNo: Integer; TableNo: Integer; FieldNo: Integer): Boolean
    var
        Field: Record Field;
        FieldsLookup: Page "Fields Lookup";
    begin
        if Field.Get(TableNo, FieldNo) then;

        Field.FilterGroup(2);
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(Type, Field.Type::Option);
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
