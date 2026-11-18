namespace EOS.Solutions.Intercompany;

using System.IO;
using System.Reflection;

table 67019 "EOS IC Out. Mapping Lines"
{
    DataClassification = CustomerContent;
    Caption = 'IC Outbound Mapping Lines (EIC)';

    fields
    {
        field(1; "Mapping Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Code';
            ToolTip = 'Specifies the outbound mapping that contains this line.';
            TableRelation = "EOS IC Mapping Headers"."Code" where(Direction = const(Outbound));
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
            ToolTip = 'Specifies the unique number of this mapping line.';
        }
        field(3; "Sort No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Sort No.';
            ToolTip = 'Specifies the order in which this line is written to the JSON output.';
        }
        field(4; "Line Type"; Enum "EOS IC Mapping Line Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Type';
            ToolTip = 'Specifies whether the line creates a JSON record or an attribute.';

            trigger OnValidate()
            var
                ICOutMappingLinesMgt: Codeunit "EOS IC Out. Mapping Lines Mgt.";
            begin
                case Rec."Line Type" of
                    Rec."Line Type"::Record:
                        begin
                            Rec.Validate("Attribute Type", Rec."Attribute Type"::" ");
                            Rec.Validate("Is Array", true);
                        end;
                    Rec."Line Type"::Attribute:
                        if xRec."Line Type" = xRec."Line Type"::Record then
                            ICOutMappingLinesMgt.CheckIfChildRecordExists(Rec);
                end;

                Rec.Validate("Encode to Base64");
                Rec.Validate("Transliteration Code");
                Rec.Validate("String Replacement Code");
            end;
        }
        field(5; "Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Table No.';
            ToolTip = 'Specifies the table used to create the record for this mapping line.';
            BlankZero = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(6; "Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Field No.';
            ToolTip = 'Specifies the source field used to create this JSON attribute.';
            BlankZero = true;

            trigger OnLookup()
            var
                Field: Record Field;
                FieldsLookup: Page "Fields Lookup";
            begin
                Rec.TestField("Parent Table No.");
                Field.SetRange(TableNo, Rec."Parent Table No.");
                Field.SetFilter(Class, '%1|%2', Field.Class::Normal, Field.Class::FlowField);

                FieldsLookup.SetTableView(Field);
                FieldsLookup.LookupMode(true);
                if FieldsLookup.RunModal() = Action::LookupOK then begin
                    FieldsLookup.GetRecord(Field);
                    Rec.Validate("Field No.", Field."No.");
                end;
            end;

            trigger OnValidate()
            var
                Field: Record Field;
            begin
                Clear(Rec."Field Type");
                if Field.Get(Rec."Table No.", Rec."Field No.") then
                    Rec."Field Type" := CopyStr(Format(Field.Type, 0, 9), 1, MaxStrLen(Rec."Field Type"));

                Rec.Validate("Encode to Base64");
                Rec.Validate("Transliteration Code");
                Rec.Validate("String Replacement Code");
            end;
        }
        field(7; "Field Name"; Text[80])
        {
            Caption = 'Field Name';
            ToolTip = 'Specifies the name of the source field selected for this attribute.';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."), "No." = field("Field No.")));
            Editable = false;
        }
        field(8; "Parent Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Line No.';
            ToolTip = 'Specifies the line number of the parent record in the mapping tree.';
        }
        field(9; Level; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Level';
            ToolTip = 'Specifies the nesting level of this line in the JSON structure.';
        }
        field(10; "Record Relation"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Record Relation';
            ToolTip = 'Specifies the table relation used to find records related to the parent record.';
            TableRelation = "EOS IC Table Relation Header"."Code" where("Source Table No." = field("Parent Table No."), "Target Table No." = field("Table No."));
        }
        field(11; "Parent Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Table No.';
            ToolTip = 'Specifies the table that contains the parent record.';
        }
        field(12; "Attribute Type"; Enum "EOS IC Attribute Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Attribute Type';
            ToolTip = 'Specifies whether the attribute value comes from a field, a constant, or a function.';

            trigger OnValidate()
            var
                Field: Record Field;
            begin
                if Rec."Line Type" <> Rec."Line Type"::Record then
                    Rec.TestField("Line Type", Rec."Line Type"::Attribute);

                Clear(Rec."Field Type");
                case Rec."Attribute Type" of
                    Rec."Attribute Type"::Field:
                        begin
                            Rec."Table No." := Rec."Parent Table No.";
                            if not Field.Get(Rec."Table No.", Rec."Field No.") then
                                Rec."Field No." := 0;
                        end;
                    Rec."Attribute Type"::Constant:
                        begin
                            Rec."Table No." := 0;
                            Rec."Field No." := 0;
                        end;
                end;
                Rec.Validate("Field No.");
                Rec.Validate("Encode to Base64");
                Rec.Validate("Transliteration Code");
                Rec.Validate("String Replacement Code");

                if Rec."Attribute Type" <> Rec."Attribute Type"::Constant then
                    Rec."Constant Type" := Rec."Constant Type"::" ";
            end;
        }
        field(13; "Table Filter"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Table Filter';
            ToolTip = 'Specifies the filter applied to records included in this JSON array.';
        }
        field(14; "Table Name"; Text[249])
        {
            Caption = 'Table Name';
            ToolTip = 'Specifies the name of the table used by this record line.';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Table No.")));
            Editable = false;
        }
        field(15; "Json Tag"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Json Tag';
            ToolTip = 'Specifies the JSON property name written for this attribute or record.';
        }
        field(16; "Is Array"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Is Array';
            ToolTip = 'Specifies whether the records created by this line are written as a JSON array.';
        }
        field(17; Constant; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Constant';
            ToolTip = 'Specifies the fixed value written when the attribute type is Constant.';
        }
        field(18; "Function"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Function';
            ToolTip = 'Specifies the function used to calculate the attribute value.';
        }
        field(19; "Blank as null"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Blank as null';
            ToolTip = 'Specifies whether a blank value is written as JSON null.';
        }
        field(20; "Field Type"; Text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Field Type';
            ToolTip = 'Specifies the data type of the selected source field.';
        }
        field(21; Length; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Length';
            ToolTip = 'Specifies the maximum length of the value written to JSON.';
            MinValue = 0;
        }
        field(23; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
            ToolTip = 'Specifies a description of this mapping line.';
        }
        field(24; "Transformation Rule"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Transformation Rule';
            ToolTip = 'Specifies the standard transformation rule applied to the source value.';
            TableRelation = "Transformation Rule";
        }
        field(30; "Function Parameters"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Function Parameters';
            ToolTip = 'Specifies the parameters passed to the selected function.';
        }
        field(50; "Encode to Base64"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Encode to Base64';
            ToolTip = 'Specifies whether the text or code value is encoded as Base64.';

            trigger OnValidate()
            var
                Field: Record Field;
                MustBeLbl: Label 'must be %1 if %2 is %3.', Comment = '%1 = required value, %2 = field caption, %3 = field value';
                OrLbl: Label '%1 or %2', Comment = '%1 = first value, %2 = second value';
            begin
                if not Rec."Encode to Base64" then
                    exit;

                if Rec."Line Type" <> Rec."Line Type"::Attribute then
                    Rec.FieldError("Line Type", StrSubstNo(MustBeLbl, Rec."Line Type"::Attribute, Rec.FieldCaption("Encode to Base64"), Rec."Encode to Base64"));

                if Rec."Attribute Type" <> Rec."Attribute Type"::Field then
                    Rec.FieldError("Attribute Type", StrSubstNo(MustBeLbl, Rec."Attribute Type"::Field, Rec.FieldCaption("Encode to Base64"), Rec."Encode to Base64"));

                if not (Rec."Field Type" in [Format(Field.Type::Code, 0, 9), Format(Field.Type::Text, 0, 9)]) then
                    Rec.FieldError("Field Type", StrSubstNo(MustBeLbl, StrSubstNo(OrLbl, Field.Type::Code, Field.Type::Text), Rec.FieldCaption("Encode to Base64"), Rec."Encode to Base64"));
            end;
        }
        field(61; "Constant Type"; Enum "EOS IC Constant Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Constant Type';
            ToolTip = 'Specifies the data type of the constant value.';

            trigger OnValidate()
            begin
                if Rec."Constant Type" <> Rec."Constant Type"::" " then
                    Rec.TestField("Attribute Type", Rec."Attribute Type"::Constant);
            end;
        }
        field(62; "Transliteration Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Transliteration Code';
            ToolTip = 'Specifies the character-transliteration setup applied to the output value.';
            TableRelation = "EOS IC String Transform Header"."Code" where("Transformation Type" = const("Character Transliteration"));

            trigger OnValidate()
            var
                Field: Record Field;
                MustBeLbl: Label 'must be %1 if %2 is %3.', Comment = '%1 = required value, %2 = field caption, %3 = field value';
                OrLbl: Label '%1 or %2', Comment = '%1 = first value, %2 = second value';
            begin
                if Rec."Transliteration Code" = '' then
                    exit;

                if Rec."Line Type" <> Rec."Line Type"::Attribute then
                    Rec.FieldError("Line Type", StrSubstNo(MustBeLbl, Rec."Line Type"::Attribute, Rec.FieldCaption("Transliteration Code"), Rec."Transliteration Code"));

                if Rec."Attribute Type" <> Rec."Attribute Type"::Field then
                    Rec.FieldError("Attribute Type", StrSubstNo(MustBeLbl, Rec."Attribute Type"::Field, Rec.FieldCaption("Transliteration Code"), Rec."Transliteration Code"));

                if not (Rec."Field Type" in [Format(Field.Type::Code, 0, 9), Format(Field.Type::Text, 0, 9)]) then
                    Rec.FieldError("Field Type", StrSubstNo(MustBeLbl, StrSubstNo(OrLbl, Field.Type::Code, Field.Type::Text), Rec.FieldCaption("Transliteration Code"), Rec."Transliteration Code"));
            end;
        }
        field(63; "String Replacement Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'String Replacement Code';
            ToolTip = 'Specifies the complete-string replacement setup applied to the output value.';
            TableRelation = "EOS IC String Transform Header"."Code" where("Transformation Type" = const("Complete String Replacement"));

            trigger OnValidate()
            var
                Field: Record Field;
                MustBeLbl: Label 'must be %1 if %2 is %3.', Comment = '%1 = required value, %2 = field caption, %3 = field value';
                OrLbl: Label '%1 or %2', Comment = '%1 = first value, %2 = second value';
                MustBeFieldOrFunctionLbl: Label 'must be %1 or %2.', Comment = '%1 = Field, %2 = Function';
            begin
                if Rec."String Replacement Code" = '' then
                    exit;

                if Rec."Line Type" <> Rec."Line Type"::Attribute then
                    Rec.FieldError("Line Type", StrSubstNo(MustBeLbl, Rec."Line Type"::Attribute, Rec.FieldCaption("String Replacement Code"), Rec."String Replacement Code"));

                if Rec."Attribute Type" = Rec."Attribute Type"::Field then begin
                    if not (Rec."Field Type" in [Format(Field.Type::Code, 0, 9), Format(Field.Type::Text, 0, 9)]) then
                        Rec.FieldError("Field Type", StrSubstNo(MustBeLbl, StrSubstNo(OrLbl, Field.Type::Code, Field.Type::Text), Rec.FieldCaption("String Replacement Code"), Rec."String Replacement Code"));
                end else
                    if Rec."Attribute Type" <> Rec."Attribute Type"::"Function" then
                        Rec.FieldError("Attribute Type", StrSubstNo(MustBeFieldOrFunctionLbl, Rec."Attribute Type"::Field, Rec."Attribute Type"::"Function"));
            end;
        }
        field(64; "Transformation Order"; Enum "EOS IC Transformation Order")
        {
            DataClassification = CustomerContent;
            Caption = 'Transformation Order';
            ToolTip = 'Specifies whether transliteration or string replacement is applied first.';
        }
    }

    keys
    {
        key(Key1; "Mapping Code", "Line No.") { Clustered = true; }
        key(SortKey; "Mapping Code", "Sort No.") { }
    }

    trigger OnInsert()
    begin
        TestMappingNotEnabled();
    end;

    trigger OnModify()
    begin
        TestMappingNotEnabled();
    end;

    trigger OnDelete()
    var
        ICOutMappingLinesMgt: Codeunit "EOS IC Out. Mapping Lines Mgt.";
        FirstLoop: Boolean;
    begin
        TestMappingNotEnabled();

        FirstLoop := true;
        ICOutMappingLinesMgt.DeleteRecurr(Rec, FirstLoop);
    end;

    local procedure TestMappingNotEnabled()
    var
        ICMappingHeader: Record "EOS IC Mapping Headers";
    begin
        if ICMappingHeader.Get(Rec."Mapping Code") then
            ICMappingHeader.TestField(Enabled, false);
    end;

    // Stored as language-independent view (field numbers) so that it does not depend on the user language.
    procedure SetTableFilter(TableFilterText: Text)
    var
        RecRef: RecordRef;
        OutStr: OutStream;
    begin
        Clear(Rec."Table Filter");
        if TableFilterText = '' then
            exit;

        RecRef.Open(Rec."Table No.");
        RecRef.SetView(TableFilterText);
        Rec."Table Filter".CreateOutStream(OutStr);
        OutStr.WriteText(RecRef.GetView(false));
    end;

    procedure GetTableFilter() TableFilterText: Text
    var
        InStr: InStream;
        LineText: Text;
    begin
        Rec.CalcFields("Table Filter");
        if not Rec."Table Filter".HasValue() then
            exit;

        Rec."Table Filter".CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(LineText);
            TableFilterText += LineText;
        end;
    end;
}
