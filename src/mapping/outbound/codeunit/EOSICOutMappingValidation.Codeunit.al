namespace EOS.Solutions.Intercompany;

using System.IO;
using System.Reflection;

codeunit 67019 "EOS IC Out. Mapping Validation"
{
    var
        TempMappingLine: Record "EOS IC Out. Mapping Lines" temporary;
        LineIssueLbl: Label 'Line %1: %2', Comment = '%1 = line no., %2 = problem';

    // Checks that the outbound mapping can be used to build a payload. The problems are returned as a list of readable messages.
    procedure ValidateMapping(MappingCode: Code[20]; var Issues: List of [Text]): Boolean
    var
        ICMapping: Record "EOS IC Mapping Headers";
        ICOutMappingLine: Record "EOS IC Out. Mapping Lines";
        TagLines: Dictionary of [Text, Integer];
        ParentsWithChildren: List of [Integer];
        MappingNotFoundErr: Label 'The mapping %1 does not exist.', Comment = '%1 = mapping code';
        NotOutboundErr: Label 'The mapping %1 is not an outbound mapping.', Comment = '%1 = mapping code';
        NoLinesErr: Label 'The mapping has no lines.';
        NoRootLinesErr: Label 'The mapping has no line at level 1.';
    begin
        Clear(Issues);

        if not ICMapping.Get(MappingCode) then begin
            Issues.Add(StrSubstNo(MappingNotFoundErr, MappingCode));
            exit(false);
        end;
        if ICMapping.Direction <> ICMapping.Direction::Outbound then begin
            Issues.Add(StrSubstNo(NotOutboundErr, MappingCode));
            exit(false);
        end;

        ValidateHeader(ICMapping, Issues);

        ICOutMappingLine.SetRange("Mapping Code", MappingCode);
        if not ICOutMappingLine.FindSet() then begin
            Issues.Add(NoLinesErr);
            exit(false);
        end;

        LoadLines(ICOutMappingLine, ParentsWithChildren);

        ICOutMappingLine.SetRange(Level, 1);
        if ICOutMappingLine.IsEmpty() then
            Issues.Add(NoRootLinesErr);
        ICOutMappingLine.SetRange(Level);

        ICOutMappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        ICOutMappingLine.FindSet();
        repeat
            ValidateLine(ICMapping, ICOutMappingLine, ParentsWithChildren, TagLines, Issues);
        until ICOutMappingLine.Next() = 0;

        exit(Issues.Count() = 0);
    end;

    local procedure LoadLines(var ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; var ParentsWithChildren: List of [Integer])
    begin
        TempMappingLine.Reset();
        TempMappingLine.DeleteAll();
        repeat
            TempMappingLine := ICOutMappingLine;
            TempMappingLine.Insert(false);
            if not ParentsWithChildren.Contains(ICOutMappingLine."Parent Line No.") then
                ParentsWithChildren.Add(ICOutMappingLine."Parent Line No.");
        until ICOutMappingLine.Next() = 0;
    end;

    local procedure ValidateHeader(ICMapping: Record "EOS IC Mapping Headers"; var Issues: List of [Text])
    var
        AllObjWithCaption: Record AllObjWithCaption;
        SourceTableMissingErr: Label 'The source table is missing.';
        SourceTableNotFoundErr: Label 'The source table %1 does not exist.', Comment = '%1 = table id';
        InvalidFilterErr: Label 'The table filter of the mapping is not valid for the table %1.', Comment = '%1 = table id';
    begin
        if ICMapping."Source Table No." = 0 then begin
            Issues.Add(SourceTableMissingErr);
            exit;
        end;

        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, ICMapping."Source Table No.") then begin
            Issues.Add(StrSubstNo(SourceTableNotFoundErr, ICMapping."Source Table No."));
            exit;
        end;

        if not TrySetView(ICMapping."Source Table No.", ICMapping.GetTableFilter()) then
            Issues.Add(StrSubstNo(InvalidFilterErr, ICMapping."Source Table No."));
    end;

    local procedure ValidateLine(ICMapping: Record "EOS IC Mapping Headers"; ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentsWithChildren: List of [Integer]; var TagLines: Dictionary of [Text, Integer]; var Issues: List of [Text])
    var
        ParentLine: Record "EOS IC Out. Mapping Lines";
        TransformationRule: Record "Transformation Rule";
        ParentTableNo: Integer;
        LineTypeMissingErr: Label 'The line type is missing.';
        InvalidLevelErr: Label 'The level must be 1 or greater.';
        ParentNotFoundErr: Label 'The parent line %1 does not exist.', Comment = '%1 = parent line no.';
        ParentLevelErr: Label 'The parent line %1 must be at level %2.', Comment = '%1 = parent line no., %2 = expected level';
        ParentNotRecordErr: Label 'The parent line %1 must be of type Record.', Comment = '%1 = parent line no.';
        ParentTableErr: Label 'The parent table %1 is different from the table %2 of the parent line.', Comment = '%1 = parent table no., %2 = table of the parent line';
        TransformationRuleNotFoundErr: Label 'The transformation rule %1 does not exist.', Comment = '%1 = transformation rule code';
        AttributeWithChildrenErr: Label 'A line of type Attribute cannot have child lines.';
    begin
        if ICOutMappingLine."Line Type" = ICOutMappingLine."Line Type"::" " then begin
            AddIssue(Issues, ICOutMappingLine, LineTypeMissingErr);
            exit;
        end;

        if ICOutMappingLine.Level < 1 then begin
            AddIssue(Issues, ICOutMappingLine, InvalidLevelErr);
            exit;
        end;

        if ICOutMappingLine.Level = 1 then
            ParentTableNo := ICMapping."Source Table No."
        else begin
            if not TempMappingLine.Get(ICOutMappingLine."Mapping Code", ICOutMappingLine."Parent Line No.") then begin
                AddIssue(Issues, ICOutMappingLine, StrSubstNo(ParentNotFoundErr, ICOutMappingLine."Parent Line No."));
                exit;
            end;
            ParentLine := TempMappingLine;
            ParentTableNo := ParentLine."Table No.";

            if ParentLine.Level <> ICOutMappingLine.Level - 1 then
                AddIssue(Issues, ICOutMappingLine, StrSubstNo(ParentLevelErr, ParentLine."Line No.", ICOutMappingLine.Level - 1));
            if ParentLine."Line Type" <> ParentLine."Line Type"::Record then
                AddIssue(Issues, ICOutMappingLine, StrSubstNo(ParentNotRecordErr, ParentLine."Line No."));
            if ICOutMappingLine."Parent Table No." <> ParentLine."Table No." then
                AddIssue(Issues, ICOutMappingLine, StrSubstNo(ParentTableErr, ICOutMappingLine."Parent Table No.", ParentLine."Table No."));
        end;

        case ICOutMappingLine."Line Type" of
            ICOutMappingLine."Line Type"::Record:
                ValidateRecordLine(ICMapping, ICOutMappingLine, Issues);
            ICOutMappingLine."Line Type"::Attribute:
                begin
                    ValidateAttributeLine(ICOutMappingLine, ParentTableNo, Issues);
                    if ParentsWithChildren.Contains(ICOutMappingLine."Line No.") then
                        AddIssue(Issues, ICOutMappingLine, AttributeWithChildrenErr);
                end;
        end;

        if ICOutMappingLine."Transformation Rule" <> '' then
            if not TransformationRule.Get(ICOutMappingLine."Transformation Rule") then
                AddIssue(Issues, ICOutMappingLine, StrSubstNo(TransformationRuleNotFoundErr, ICOutMappingLine."Transformation Rule"));

        CheckDuplicatedTag(ICOutMappingLine, TagLines, Issues);
    end;

    local procedure ValidateRecordLine(ICMapping: Record "EOS IC Mapping Headers"; ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; var Issues: List of [Text])
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TableMissingErr: Label 'The table is missing.';
        TableNotFoundErr: Label 'The table %1 does not exist.', Comment = '%1 = table id';
        RootTableErr: Label 'The table %1 of a line at level 1 must be the source table %2 of the mapping.', Comment = '%1 = table id, %2 = source table of the mapping';
        InvalidFilterErr: Label 'The table filter is not valid for the table %1.', Comment = '%1 = table id';
        JsonTagRequiredErr: Label 'The Json tag is required for a line that is an array.';
    begin
        if ICOutMappingLine."Is Array" and (ICOutMappingLine."Json Tag" = '') then
            AddIssue(Issues, ICOutMappingLine, JsonTagRequiredErr);

        if ICOutMappingLine."Table No." = 0 then begin
            AddIssue(Issues, ICOutMappingLine, TableMissingErr);
            exit;
        end;

        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, ICOutMappingLine."Table No.") then begin
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(TableNotFoundErr, ICOutMappingLine."Table No."));
            exit;
        end;

        if (ICOutMappingLine.Level = 1) and (ICOutMappingLine."Table No." <> ICMapping."Source Table No.") then
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(RootTableErr, ICOutMappingLine."Table No.", ICMapping."Source Table No."));

        if not TrySetView(ICOutMappingLine."Table No.", ICOutMappingLine.GetTableFilter()) then
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(InvalidFilterErr, ICOutMappingLine."Table No."));

        if ICOutMappingLine.Level > 1 then
            ValidateRelation(ICOutMappingLine, Issues);
    end;

    local procedure ValidateRelation(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; var Issues: List of [Text])
    var
        ICTableRelationHeader: Record "EOS IC Table Relation Header";
        ICTableRelationLine: Record "EOS IC Table Relation Line";
        RelationRequiredErr: Label 'The record relation is required for a line at level 2 or greater.';
        RelationNotFoundErr: Label 'The record relation %1 does not exist.', Comment = '%1 = relation code';
        RelationTablesErr: Label 'The record relation %1 must go from the table %2 to the table %3.', Comment = '%1 = relation code, %2 = parent table, %3 = table of the line';
        RelationWithoutLinesErr: Label 'The record relation %1 has no lines.', Comment = '%1 = relation code';
    begin
        if ICOutMappingLine."Record Relation" = '' then begin
            AddIssue(Issues, ICOutMappingLine, RelationRequiredErr);
            exit;
        end;

        if not ICTableRelationHeader.Get(ICOutMappingLine."Record Relation") then begin
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(RelationNotFoundErr, ICOutMappingLine."Record Relation"));
            exit;
        end;

        if (ICTableRelationHeader."Source Table No." <> ICOutMappingLine."Parent Table No.") or
           (ICTableRelationHeader."Target Table No." <> ICOutMappingLine."Table No.")
        then
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(RelationTablesErr, ICTableRelationHeader.Code, ICOutMappingLine."Parent Table No.", ICOutMappingLine."Table No."));

        ICTableRelationLine.SetRange(Code, ICTableRelationHeader.Code);
        if not ICTableRelationLine.FindSet() then begin
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(RelationWithoutLinesErr, ICTableRelationHeader.Code));
            exit;
        end;

        repeat
            CheckRelationField(ICOutMappingLine, ICTableRelationHeader."Source Table No.", ICTableRelationLine."Source Field No.", ICTableRelationHeader.Code, Issues);
            CheckRelationField(ICOutMappingLine, ICTableRelationHeader."Target Table No.", ICTableRelationLine."Target Field No.", ICTableRelationHeader.Code, Issues);
        until ICTableRelationLine.Next() = 0;
    end;

    local procedure CheckRelationField(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; TableNo: Integer; FieldNo: Integer; RelationCode: Code[20]; var Issues: List of [Text])
    var
        Field: Record Field;
        RelationFieldErr: Label 'The field %1 of the table %2 used by the record relation %3 does not exist.', Comment = '%1 = field no., %2 = table id, %3 = relation code';
    begin
        if not Field.Get(TableNo, FieldNo) then
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(RelationFieldErr, FieldNo, TableNo, RelationCode));
    end;

    local procedure ValidateAttributeLine(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentTableNo: Integer; var Issues: List of [Text])
    var
        AttributeTypeMissingErr: Label 'The attribute type is missing.';
        FunctionRequiredErr: Label 'The function is required.';
        JsonTagRequiredErr: Label 'The Json tag is required.';
    begin
        case ICOutMappingLine."Attribute Type" of
            ICOutMappingLine."Attribute Type"::" ":
                AddIssue(Issues, ICOutMappingLine, AttributeTypeMissingErr);
            ICOutMappingLine."Attribute Type"::Field:
                begin
                    ValidateFieldLine(ICOutMappingLine, ParentTableNo, Issues);
                    if ICOutMappingLine."Json Tag" = '' then
                        AddIssue(Issues, ICOutMappingLine, JsonTagRequiredErr);
                end;
            ICOutMappingLine."Attribute Type"::Constant:
                if ICOutMappingLine."Json Tag" = '' then
                    AddIssue(Issues, ICOutMappingLine, JsonTagRequiredErr);
            ICOutMappingLine."Attribute Type"::"Function":
                if ICOutMappingLine."Function" = '' then
                    AddIssue(Issues, ICOutMappingLine, FunctionRequiredErr);
        end;
    end;

    local procedure ValidateFieldLine(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentTableNo: Integer; var Issues: List of [Text])
    var
        Field: Record Field;
        FieldMissingErr: Label 'The field is missing.';
        FieldTableErr: Label 'The table %1 of the field must be the table %2 of the parent line.', Comment = '%1 = table of the line, %2 = table of the parent line';
        FieldNotFoundErr: Label 'The field %1 does not exist in the table %2.', Comment = '%1 = field no., %2 = table id';
        FieldNotSupportedErr: Label 'The field %1 of the table %2 cannot be exported because it is a filter field.', Comment = '%1 = field no., %2 = table id';
        Base64FieldErr: Label 'The field %1 of the table %2 cannot be encoded to Base64: only Text and Code fields are supported.', Comment = '%1 = field no., %2 = table id';
    begin
        if ICOutMappingLine."Field No." = 0 then begin
            AddIssue(Issues, ICOutMappingLine, FieldMissingErr);
            exit;
        end;

        if ICOutMappingLine."Table No." <> ParentTableNo then
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(FieldTableErr, ICOutMappingLine."Table No.", ParentTableNo));

        if not Field.Get(ParentTableNo, ICOutMappingLine."Field No.") then begin
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(FieldNotFoundErr, ICOutMappingLine."Field No.", ParentTableNo));
            exit;
        end;

        if Field.Class = Field.Class::FlowFilter then
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(FieldNotSupportedErr, ICOutMappingLine."Field No.", ParentTableNo));

        if ICOutMappingLine."Encode to Base64" and not (Field.Type in [Field.Type::Code, Field.Type::Text]) then
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(Base64FieldErr, ICOutMappingLine."Field No.", ParentTableNo));
    end;

    // Two lines cannot add the same tag to the same Json object: a record without tag adds its children to the object of its parent.
    local procedure CheckDuplicatedTag(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; var TagLines: Dictionary of [Text, Integer]; var Issues: List of [Text])
    var
        TagKey: Text;
        FirstLineNo: Integer;
        DuplicatedTagErr: Label 'The Json tag %1 is already used by the line %2 in the same Json object.', Comment = '%1 = Json tag, %2 = line no.';
    begin
        if ICOutMappingLine."Json Tag" = '' then
            exit;
        if (ICOutMappingLine."Line Type" = ICOutMappingLine."Line Type"::Attribute) and
           not (ICOutMappingLine."Attribute Type" in [ICOutMappingLine."Attribute Type"::Field, ICOutMappingLine."Attribute Type"::Constant])
        then
            exit;

        TagKey := StrSubstNo('%1|%2', GetContainerLineNo(ICOutMappingLine), ICOutMappingLine."Json Tag");
        if TagLines.Get(TagKey, FirstLineNo) then
            AddIssue(Issues, ICOutMappingLine, StrSubstNo(DuplicatedTagErr, ICOutMappingLine."Json Tag", FirstLineNo))
        else
            TagLines.Add(TagKey, ICOutMappingLine."Line No.");
    end;

    // The container is the closest ancestor that produces its own Json object (an array or a record with tag); 0 is the root object.
    local procedure GetContainerLineNo(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"): Integer
    var
        CurrentLine: Record "EOS IC Out. Mapping Lines";
        Steps: Integer;
    begin
        Steps := 0;
        CurrentLine := ICOutMappingLine;
        while (CurrentLine.Level > 1) and (Steps <= ICOutMappingLine.Level) do begin
            Steps += 1;
            if not TempMappingLine.Get(CurrentLine."Mapping Code", CurrentLine."Parent Line No.") then
                exit(0);
            CurrentLine := TempMappingLine;
            if CurrentLine."Is Array" or (CurrentLine."Json Tag" <> '') then
                exit(CurrentLine."Line No.");
        end;
        exit(0);
    end;

    [TryFunction]
    local procedure TrySetView(TableNo: Integer; ViewText: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecRef.SetView(ViewText);
    end;

    local procedure AddIssue(var Issues: List of [Text]; ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; IssueText: Text)
    begin
        Issues.Add(StrSubstNo(LineIssueLbl, ICOutMappingLine."Line No.", IssueText));
    end;
}
