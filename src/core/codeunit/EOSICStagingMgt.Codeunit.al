namespace EOS.Solutions.Intercompany;

using System.Reflection;
using System.Utilities;

codeunit 67003 "EOS IC Staging Mgt."
{
    trigger OnRun()
    var
        ICEntries: Record "EOS IC Entries";
        RebuildEntryNotSetErr: Label 'The IC entry to rebuild has not been specified.';
    begin
        if RebuildEntryNo = 0 then
            Error(RebuildEntryNotSetErr);

        ICEntries.Get(RebuildEntryNo);
        if not ICEntries."Use Staging" then
            Error('Entry %1 is not configured for unified staging.', ICEntries."Entry No.");

        PopulateEntry(ICEntries);
    end;

    procedure PopulateFromPayload(ICEntries: Record "EOS IC Entries")
    begin
        if not ICEntries."Use Staging" then
            Error('Entry %1 is not configured for unified staging.', ICEntries."Entry No.");

        PopulateEntry(ICEntries);
    end;

    procedure RebuildFromOriginal(ICEntryNo: Integer)
    var
        RebuildRunner: Codeunit "EOS IC Staging Mgt.";
        RebuildFailedErr: Label 'The unified staging for entry %1 could not be rebuilt. %2', Comment = '%1 = entry no., %2 = error detail';
    begin
        Clear(RebuildRunner);
        RebuildRunner.SetRebuildEntryNo(ICEntryNo);
        if not RebuildRunner.Run() then
            Error(RebuildFailedErr, ICEntryNo, GetLastErrorText());
    end;

    procedure SetRebuildEntryNo(ICEntryNo: Integer)
    begin
        RebuildEntryNo := ICEntryNo;
    end;

    procedure UpdateManualValueStates(var Staging: Record "EOS IC Staging"; OldStaging: Record "EOS IC Staging")
    var
        ValueMetadata: Record "EOS IC Staging Value";
        StagingRecRef: RecordRef;
        OldStagingRecRef: RecordRef;
        StagingFieldRef: FieldRef;
        OldStagingFieldRef: FieldRef;
        FieldNo: Integer;
    begin
        StagingRecRef.GetTable(Staging);
        OldStagingRecRef.GetTable(OldStaging);
        for FieldNo := 20 to 199 do begin
            StagingFieldRef := StagingRecRef.Field(FieldNo);
            OldStagingFieldRef := OldStagingRecRef.Field(FieldNo);
            if Format(StagingFieldRef.Value, 0, 9) <> Format(OldStagingFieldRef.Value, 0, 9) then
                if ValueMetadata.Get(Staging."Staging Record ID", FieldNo) then begin
                    ValueMetadata."Value State" := ValueMetadata."Value State"::Value;
                    ValueMetadata.Modify(false);
                end;
        end;
        StagingRecRef.Close();
        OldStagingRecRef.Close();
    end;

    procedure ValidateMapping(MappingCode: Code[20]; ForExecution: Boolean; CheckSample: Boolean; var Issues: List of [Text]): Boolean
    var
        ICMapping: Record "EOS IC Mapping Headers";
        ICMappingLine: Record "EOS IC Mapping Lines";
        SampleNode: Record "EOS IC Mapping Json Node";
        Field: Record Field;
        SourceField: Record Field;
        SamplePaths: List of [Text];
        FieldCaptions: Dictionary of [Integer, Text];
        ContextTargets: Dictionary of [Text, Integer];
        ActiveLineCount: Integer;
        HasSample: Boolean;
        TargetKey: Text;
        PreviousLineNo: Integer;
        ExistingCaption: Text;
        ContextPath: Text;
        MissingMappingErr: Label 'The unified staging mapping %1 does not exist.', Comment = '%1 = mapping code';
        WrongDirectionErr: Label 'The unified staging mapping %1 must be inbound.', Comment = '%1 = mapping code';
        NoLinesErr: Label 'The unified staging mapping has no lines.';
        NoTargetsErr: Label 'The unified staging mapping has no configured staging fields.';
        MissingFieldErr: Label 'The unified staging field is missing.';
        FieldNotFoundErr: Label 'The staging field %1 does not exist.', Comment = '%1 = field no.';
        UnsupportedFieldErr: Label 'The staging field %1 cannot be used as a value field.', Comment = '%1 = field name';
        MissingCaptionErr: Label 'A caption is required for staging field %1.', Comment = '%1 = field name';
        DuplicateTargetErr: Label 'Staging field %1 is mapped more than once in the Json context %2.', Comment = '%1 = field name, %2 = Json context';
        InconsistentCaptionErr: Label 'Staging field %1 must use the same caption throughout the mapping.', Comment = '%1 = field name';
        LegacyTargetErr: Label 'Legacy target table and field must be blank in a unified staging mapping.';
        InvalidPathErr: Label 'The Json path %1 is invalid. %2', Comment = '%1 = path, %2 = error detail';
        MissingPathErr: Label 'A Json path is required for this mapping type.';
        MissingConstantErr: Label 'The constant text is required for a constant mapping.';
        SamplePathErr: Label 'The Json path %1 does not exist in the imported sample Json.', Comment = '%1 = path';
        InvalidEnumSourceErr: Label 'Enum or Option metadata must specify a valid source table and field.';
        EnumSourceTypeErr: Label 'The source field %1 must be an Enum or Option field.', Comment = '%1 = field name';
        EnumTargetTypeErr: Label 'Enum and Option values must be stored in an Integer staging field.';
        TransformTargetErr: Label 'String transformations can only be used with Text staging fields.';
        PathSteps: List of [Text];
        ErrorText: Text;
    begin
        Clear(Issues);
        Clear(FieldCaptions);
        Clear(ContextTargets);

        if not ICMapping.Get(MappingCode) then begin
            Issues.Add(StrSubstNo(MissingMappingErr, MappingCode));
            exit;
        end;
        if ICMapping.Direction <> ICMapping.Direction::Inbound then begin
            Issues.Add(StrSubstNo(WrongDirectionErr, MappingCode));
            exit;
        end;
        if not ICMapping."Unified Staging" then begin
            Issues.Add('The mapping is not configured for unified staging.');
            exit;
        end;

        ICMappingLine.SetRange("Mapping Code", MappingCode);
        if ICMappingLine.IsEmpty() then begin
            Issues.Add(NoLinesErr);
            exit;
        end;

        if CheckSample and not ForExecution then begin
            SampleNode.SetRange("Mapping Code", MappingCode);
            if SampleNode.FindSet() then begin
                HasSample := true;
                repeat
                    SamplePaths.Add(SampleNode.Path);
                until SampleNode.Next() = 0;
            end;
        end;

        if ICMappingLine.FindSet() then
            repeat
                if not (ICMappingLine."Is Structure" and (ICMappingLine."Staging Field No." = 0)) then
                    if not (ForExecution and (ICMappingLine."Staging Field No." = 0)) then
                        if ICMappingLine."Staging Field No." = 0 then
                            Issues.Add(MissingFieldErr)
                        else begin
                            ActiveLineCount += 1;
                            if ICMappingLine."Is Key Field" then
                                Issues.Add('Key fields are not used in unified staging mappings.');
                            if (ICMappingLine."Target Table ID" <> 0) or (ICMappingLine."Target Field No." <> 0) then
                                Issues.Add(LegacyTargetErr);

                            if not Field.Get(Database::"EOS IC Staging", ICMappingLine."Staging Field No.") then
                                Issues.Add(StrSubstNo(FieldNotFoundErr, ICMappingLine."Staging Field No."))
                            else begin
                                if (Field.Class <> Field.Class::Normal) or not IsSupportedFieldType(Field) then
                                    Issues.Add(StrSubstNo(UnsupportedFieldErr, Field.FieldName));

                                if ICMappingLine."Staging Caption" = '' then
                                    Issues.Add(StrSubstNo(MissingCaptionErr, Field.FieldName));

                                ContextPath := ICJsonPathMgt.GetArrayContext(ICMappingLine."Json Path");
                                TargetKey := ContextPath + '|' + Format(ICMappingLine."Staging Field No.", 0, 9);
                                if ContextTargets.Get(TargetKey, PreviousLineNo) then
                                    Issues.Add(StrSubstNo(DuplicateTargetErr, Field.FieldName, ContextPath))
                                else
                                    ContextTargets.Add(TargetKey, ICMappingLine."Line No.");

                                if FieldCaptions.Get(ICMappingLine."Staging Field No.", ExistingCaption) then begin
                                    if ExistingCaption <> ICMappingLine."Staging Caption" then
                                        Issues.Add(StrSubstNo(InconsistentCaptionErr, Field.FieldName));
                                end else
                                    FieldCaptions.Add(ICMappingLine."Staging Field No.", ICMappingLine."Staging Caption");

                                if ((ICMappingLine."Enum/Option Source Table No." = 0) and (ICMappingLine."Enum/Option Source Field No." <> 0)) or
                                    ((ICMappingLine."Enum/Option Source Table No." <> 0) and (ICMappingLine."Enum/Option Source Field No." = 0))
                                then
                                    Issues.Add(InvalidEnumSourceErr)
                                else
                                    if ICMappingLine."Enum/Option Source Field No." <> 0 then
                                        if not SourceField.Get(ICMappingLine."Enum/Option Source Table No.", ICMappingLine."Enum/Option Source Field No.") then
                                            Issues.Add(InvalidEnumSourceErr)
                                        else begin
                                            if SourceField.Type <> SourceField.Type::Option then
                                                Issues.Add(StrSubstNo(EnumSourceTypeErr, SourceField.FieldName));
                                            if Field.Type <> Field.Type::Integer then
                                                Issues.Add(EnumTargetTypeErr);
                                        end;

                                if ((ICMappingLine."Transliteration Code" <> '') or (ICMappingLine."String Replacement Code" <> '')) and
                                    (Field.Type <> Field.Type::Text)
                                then
                                    Issues.Add(TransformTargetErr);
                            end;

                            if ICMappingLine."Json Path" <> '' then
                                if not ICJsonPathMgt.ParsePath(ICMappingLine."Json Path", PathSteps, ErrorText) then
                                    Issues.Add(StrSubstNo(InvalidPathErr, ICMappingLine."Json Path", ErrorText))
                                else
                                    if HasSample and not SamplePaths.Contains(ICMappingLine."Json Path") then
                                        Issues.Add(StrSubstNo(SamplePathErr, ICMappingLine."Json Path"));

                            case ICMappingLine."Value Type" of
                                ICMappingLine."Value Type"::Unchanged:
                                    if ICMappingLine."Json Path" = '' then
                                        Issues.Add(MissingPathErr);
                                ICMappingLine."Value Type"::Constant:
                                    begin
                                        if ICMappingLine."Json Path" = '' then
                                            Issues.Add(MissingPathErr);
                                        if ICMappingLine."Constant Text" = '' then
                                            Issues.Add(MissingConstantErr);
                                    end;
                                ICMappingLine."Value Type"::Transformation:
                                    if ICMappingLine."Json Path" = '' then
                                        Issues.Add(MissingPathErr);
                            end;
                        end;
            until ICMappingLine.Next() = 0;

        if ForExecution then begin
            ICMappingLine.Reset();
            ICMappingLine.SetRange("Mapping Code", MappingCode);
            ICMappingLine.SetFilter("Staging Field No.", '<>0');
            ICMappingLine.SetRange("Is Structure", false);
            ActiveLineCount := ICMappingLine.Count();
        end;
        if ActiveLineCount = 0 then
            Issues.Add(NoTargetsErr);
        exit(Issues.Count() = 0);
    end;

    procedure GetMappingCodeForEntry(ICEntryNo: Integer): Code[20]
    var
        ICEntries: Record "EOS IC Entries";
        ICFlows: Record "EOS IC Flows";
    begin
        ICEntries.Get(ICEntryNo);
        ICFlows.Get(ICEntries."Source Company", ICEntries."IC Flow Code");
        exit(ICFlows."Mapping Code");
    end;

    procedure GetFieldCaption(MappingCode: Code[20]; FieldNo: Integer): Text
    var
        ICMappingLine: Record "EOS IC Mapping Lines";
        Field: Record Field;
    begin
        ICMappingLine.SetRange("Mapping Code", MappingCode);
        ICMappingLine.SetRange("Staging Field No.", FieldNo);
        if ICMappingLine.FindFirst() then
            exit(ICMappingLine."Staging Caption");

        if Field.Get(Database::"EOS IC Staging", FieldNo) then
            exit(Field."Field Caption");
    end;

    procedure GetEnumValueCaption(EnumSourceTableNo: Integer; EnumSourceFieldNo: Integer; EnumOrdinal: Integer): Text
    var
        SourceRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        EnumCaption: Text;
    begin
        if (EnumSourceTableNo = 0) or (EnumSourceFieldNo = 0) then
            exit('');

        SourceRecRef.Open(EnumSourceTableNo);
        SourceFieldRef := SourceRecRef.Field(EnumSourceFieldNo);
        EnumCaption := SourceFieldRef.GetEnumValueCaptionFromOrdinalValue(EnumOrdinal);
        if EnumCaption = '' then
            EnumCaption := SourceFieldRef.GetEnumValueNameFromOrdinalValue(EnumOrdinal);
        SourceRecRef.Close();
        exit(EnumCaption);
    end;

    #region ReadStaging
    // Values and child arrays are addressed by their Json name (postingDate, lines); parent names (shipTo.name) or the full path resolve an ambiguous name.

    procedure FindRootStagingRecord(ICEntryNo: Integer; var Staging: Record "EOS IC Staging"): Boolean
    begin
        Staging.Reset();
        Staging.SetCurrentKey("IC Entry No.", "Tree Order");
        Staging.SetRange("IC Entry No.", ICEntryNo);
        Staging.SetRange(Level, 0);
        exit(Staging.FindFirst());
    end;

    procedure GetRootStagingRecord(ICEntryNo: Integer; var Staging: Record "EOS IC Staging")
    var
        StagingNotFoundErr: Label 'No staging record was found for the entry %1.', Comment = '%1 = entry no.';
    begin
        if not FindRootStagingRecord(ICEntryNo, Staging) then
            Error(StagingNotFoundErr, ICEntryNo);
    end;

    // Filters the children of the parent that belong to the array with the given name (e.g. lines), in Json order.
    procedure SetChildStagingRecords(var ChildRecords: Record "EOS IC Staging"; ParentRecord: Record "EOS IC Staging"; ArrayName: Text)
    begin
        ChildRecords.Reset();
        ChildRecords.SetCurrentKey("IC Entry No.", "Parent Record ID", "Sequence No.");
        ChildRecords.SetRange("IC Entry No.", ParentRecord."IC Entry No.");
        ChildRecords.SetRange("Parent Record ID", ParentRecord."Staging Record ID");
        ChildRecords.SetRange("Node Identifier", ResolveChildContext(ParentRecord, ArrayName));
    end;

    // Missing: not mapped or not in the Json. Null: Json null. Value: a value was received.
    procedure GetStagingValueState(Staging: Record "EOS IC Staging"; JsonName: Text): Enum "EOS IC Staging Value State"
    var
        ValueMetadata: Record "EOS IC Staging Value";
    begin
        if FindValueMetadata(Staging, JsonName, ValueMetadata) then
            exit(ValueMetadata."Value State");
        exit(ValueMetadata."Value State"::Missing);
    end;

    // False when the Json value is missing, null or blank, so that optional fields can be skipped.
    procedure GetStagingValue(Staging: Record "EOS IC Staging"; JsonName: Text; var Value: Variant): Boolean
    var
        ValueMetadata: Record "EOS IC Staging Value";
        StagingRecRef: RecordRef;
        StagingFieldRef: FieldRef;
        HasValue: Boolean;
    begin
        Clear(Value);
        if not FindValueMetadata(Staging, JsonName, ValueMetadata) then
            exit(false);
        if ValueMetadata."Value State" <> ValueMetadata."Value State"::Value then
            exit(false);

        StagingRecRef.GetTable(Staging);
        StagingFieldRef := StagingRecRef.Field(ValueMetadata."Staging Field No.");
        HasValue := not IsBlankValue(StagingFieldRef);
        if HasValue then
            Value := StagingFieldRef.Value;
        StagingRecRef.Close();
        exit(HasValue);
    end;

    // Like GetStagingValue, but a missing, null or blank Json value is an error.
    procedure GetRequiredStagingValue(Staging: Record "EOS IC Staging"; JsonName: Text; var Value: Variant)
    var
        ValueRequiredErr: Label 'The Json field %1 must have a value in the staging of the entry %2.', Comment = '%1 = Json name, %2 = entry no.';
    begin
        if not GetStagingValue(Staging, JsonName, Value) then
            Error(ValueRequiredErr, JsonName, Staging."IC Entry No.");
    end;

    // Typed readers: default value when missing, null or blank; a value of another slot type is converted from its invariant text.
    procedure GetTextValue(Staging: Record "EOS IC Staging"; JsonName: Text): Text
    begin
        exit(GetValueText(Staging, JsonName));
    end;

    procedure GetDecimalValue(Staging: Record "EOS IC Staging"; JsonName: Text): Decimal
    var
        DecimalValue: Decimal;
        ValueText: Text;
    begin
        ValueText := GetValueText(Staging, JsonName);
        if ValueText <> '' then
            if not Evaluate(DecimalValue, ValueText, 9) then
                ErrorInvalidValue(JsonName, ValueText, 'Decimal');
        exit(DecimalValue);
    end;

    procedure GetIntegerValue(Staging: Record "EOS IC Staging"; JsonName: Text): Integer
    var
        IntegerValue: Integer;
        ValueText: Text;
    begin
        ValueText := GetValueText(Staging, JsonName);
        if ValueText <> '' then
            if not Evaluate(IntegerValue, ValueText, 9) then
                ErrorInvalidValue(JsonName, ValueText, 'Integer');
        exit(IntegerValue);
    end;

    procedure GetBigIntegerValue(Staging: Record "EOS IC Staging"; JsonName: Text): BigInteger
    var
        BigIntegerValue: BigInteger;
        ValueText: Text;
    begin
        ValueText := GetValueText(Staging, JsonName);
        if ValueText <> '' then
            if not Evaluate(BigIntegerValue, ValueText, 9) then
                ErrorInvalidValue(JsonName, ValueText, 'BigInteger');
        exit(BigIntegerValue);
    end;

    procedure GetBooleanValue(Staging: Record "EOS IC Staging"; JsonName: Text): Boolean
    var
        BooleanValue: Boolean;
        ValueText: Text;
    begin
        ValueText := GetValueText(Staging, JsonName);
        if ValueText <> '' then
            if not Evaluate(BooleanValue, ValueText, 9) then
                ErrorInvalidValue(JsonName, ValueText, 'Boolean');
        exit(BooleanValue);
    end;

    procedure GetDateValue(Staging: Record "EOS IC Staging"; JsonName: Text): Date
    var
        DateValue: Date;
        ValueText: Text;
    begin
        ValueText := GetValueText(Staging, JsonName);
        if ValueText <> '' then
            if not Evaluate(DateValue, ValueText, 9) then
                ErrorInvalidValue(JsonName, ValueText, 'Date');
        exit(DateValue);
    end;

    procedure GetDateTimeValue(Staging: Record "EOS IC Staging"; JsonName: Text): DateTime
    var
        DateTimeValue: DateTime;
        ValueText: Text;
    begin
        ValueText := GetValueText(Staging, JsonName);
        if ValueText <> '' then
            if not Evaluate(DateTimeValue, ValueText, 9) then
                ErrorInvalidValue(JsonName, ValueText, 'DateTime');
        exit(DateTimeValue);
    end;

    procedure GetTimeValue(Staging: Record "EOS IC Staging"; JsonName: Text): Time
    var
        TimeValue: Time;
        ValueText: Text;
    begin
        ValueText := GetValueText(Staging, JsonName);
        if ValueText <> '' then
            if not Evaluate(TimeValue, ValueText, 9) then
                ErrorInvalidValue(JsonName, ValueText, 'Time');
        exit(TimeValue);
    end;

    procedure GetGuidValue(Staging: Record "EOS IC Staging"; JsonName: Text): Guid
    var
        GuidValue: Guid;
        ValueText: Text;
    begin
        ValueText := GetValueText(Staging, JsonName);
        if ValueText <> '' then
            if not Evaluate(GuidValue, ValueText, 9) then
                ErrorInvalidValue(JsonName, ValueText, 'GUID');
        exit(GuidValue);
    end;

    // The whole Json path wins; otherwise the name must be the final part of exactly one path of the values of this staging record.
    local procedure FindValueMetadata(Staging: Record "EOS IC Staging"; JsonName: Text; var ValueMetadata: Record "EOS IC Staging Value"): Boolean
    var
        FirstMatch: Record "EOS IC Staging Value";
        NormalizedName: Text;
        MatchedPaths: Text;
        MatchCount: Integer;
        AmbiguousNameErr: Label 'The Json name %1 matches more than one value of the staging record: %2. Add the name of the parent object, e.g. shipTo.name.', Comment = '%1 = Json name, %2 = matching Json paths';
    begin
        // Constant mapping lines have no Json path, so a blank name must not match them.
        NormalizedName := ICJsonPathMgt.NormalizePath(JsonName);
        if NormalizedName = '' then
            exit(false);

        ValueMetadata.Reset();
        ValueMetadata.SetLoadFields("Staging Field No.", "Value State", "Json Path");
        ValueMetadata.SetRange("Staging Record ID", Staging."Staging Record ID");
        if not ValueMetadata.FindSet() then
            exit(false);

        repeat
            if ValueMetadata."Json Path" = NormalizedName then
                exit(true);
            if EndsWithName(ValueMetadata."Json Path", NormalizedName) then begin
                MatchCount += 1;
                if MatchCount = 1 then
                    FirstMatch := ValueMetadata;
                if MatchedPaths <> '' then
                    MatchedPaths += ', ';
                MatchedPaths += ValueMetadata."Json Path";
            end;
        until ValueMetadata.Next() = 0;

        if MatchCount > 1 then
            Error(AmbiguousNameErr, JsonName, MatchedPaths);
        if MatchCount = 0 then
            exit(false);

        ValueMetadata := FirstMatch;
        exit(true);
    end;

    // Same matching as the values, against the arrays under the parent; the name can be given with or without the array marker (lines or lines[]).
    local procedure ResolveChildContext(ParentRecord: Record "EOS IC Staging"; ArrayName: Text): Text
    var
        Children: Record "EOS IC Staging";
        VisitedContexts: List of [Text];
        NormalizedName: Text;
        ArrayContext: Text;
        FirstMatch: Text;
        MatchedContexts: Text;
        MatchCount: Integer;
        ArrayNameRequiredErr: Label 'The name of the child array is required.';
        AmbiguousArrayErr: Label 'The Json name %1 matches more than one array under the staging record: %2. Add the name of the parent object, e.g. shipTo.lines.', Comment = '%1 = Json name, %2 = matching arrays';
    begin
        NormalizedName := ICJsonPathMgt.NormalizePath(ArrayName);
        if NormalizedName = '' then
            Error(ArrayNameRequiredErr);

        ArrayContext := NormalizedName;
        if ICJsonPathMgt.GetArrayContext(NormalizedName) <> NormalizedName then
            ArrayContext := ICJsonPathMgt.AppendArray(NormalizedName);

        Children.SetLoadFields("Node Identifier");
        Children.SetCurrentKey("IC Entry No.", "Parent Record ID", "Sequence No.");
        Children.SetRange("IC Entry No.", ParentRecord."IC Entry No.");
        Children.SetRange("Parent Record ID", ParentRecord."Staging Record ID");
        if Children.FindSet() then
            repeat
                if not VisitedContexts.Contains(Children."Node Identifier") then begin
                    VisitedContexts.Add(Children."Node Identifier");
                    if Children."Node Identifier" = ArrayContext then
                        exit(Children."Node Identifier");
                    if EndsWithName(Children."Node Identifier", ArrayContext) then begin
                        MatchCount += 1;
                        if MatchCount = 1 then
                            FirstMatch := Children."Node Identifier";
                        if MatchedContexts <> '' then
                            MatchedContexts += ', ';
                        MatchedContexts += Children."Node Identifier";
                    end;
                end;
            until Children.Next() = 0;

        if MatchCount > 1 then
            Error(AmbiguousArrayErr, ArrayName, MatchedContexts);
        if MatchCount = 1 then
            exit(FirstMatch);
        exit(ArrayContext);
    end;

    // True when the name is the final part of the Json path, e.g. postingDate for header.postingDate.
    local procedure EndsWithName(JsonPath: Text; Name: Text): Boolean
    var
        NameStart: Integer;
    begin
        NameStart := StrLen(JsonPath) - StrLen(Name) + 1;
        if NameStart < 2 then
            exit(false);
        exit((CopyStr(JsonPath, NameStart - 1, 1) = '.') and (CopyStr(JsonPath, NameStart) = Name));
    end;

    local procedure GetValueText(Staging: Record "EOS IC Staging"; JsonName: Text): Text
    var
        Value: Variant;
    begin
        if GetStagingValue(Staging, JsonName, Value) then
            exit(Format(Value, 0, 9));
    end;

    // Only text and date/time slots can be blank: a numeric or boolean value is always a value.
    local procedure IsBlankValue(var StagingFieldRef: FieldRef): Boolean
    var
        GuidValue: Guid;
    begin
        case StagingFieldRef.Type of
            FieldType::Text, FieldType::Date, FieldType::DateTime, FieldType::Time:
                exit(Format(StagingFieldRef.Value, 0, 9) = '');
            FieldType::Guid:
                begin
                    GuidValue := StagingFieldRef.Value;
                    exit(IsNullGuid(GuidValue));
                end;
        end;
    end;

    local procedure ErrorInvalidValue(JsonName: Text; ValueText: Text; TypeName: Text)
    var
        InvalidValueErr: Label 'The staging value %1 of the Json field %2 is not a valid %3.', Comment = '%1 = value, %2 = Json name, %3 = data type';
    begin
        Error(InvalidValueErr, ValueText, JsonName, TypeName);
    end;
    #endregion ReadStaging

    procedure FindMappingLine(MappingCode: Code[20]; StagingFieldNo: Integer; JsonPath: Text; var ICMappingLine: Record "EOS IC Mapping Lines"): Boolean
    begin
        ICMappingLine.Reset();
        ICMappingLine.SetRange("Mapping Code", MappingCode);
        ICMappingLine.SetRange("Staging Field No.", StagingFieldNo);
        ICMappingLine.SetRange("Is Structure", false);
        ICMappingLine.SetRange("Json Path", JsonPath);
        if ICMappingLine.FindFirst() then
            exit(true);

        ICMappingLine.SetRange("Json Path");
        exit(ICMappingLine.FindFirst());
    end;

    // Rows loaded before "Mapping Line No." existed have no sort number: derive it from the mapping.
    procedure FillMissingMappingLineNos(ICEntryNo: Integer)
    var
        ValueMetadata: Record "EOS IC Staging Value";
        Staging: Record "EOS IC Staging";
        ICMappingLine: Record "EOS IC Mapping Lines";
    begin
        ValueMetadata.SetCurrentKey("IC Entry No.", "Staging Record ID", "Staging Field No.");
        ValueMetadata.SetRange("IC Entry No.", ICEntryNo);
        ValueMetadata.SetRange("Mapping Line No.", 0);
        if ValueMetadata.IsEmpty() then
            exit;

        ValueMetadata.SetRange("Mapping Line No.");
        if ValueMetadata.FindSet(true) then
            repeat
                if ValueMetadata."Mapping Line No." = 0 then
                    if Staging.Get(ValueMetadata."Staging Record ID") then
                        if FindMappingLine(Staging."Mapping Code", ValueMetadata."Staging Field No.", ValueMetadata."Json Path", ICMappingLine) then begin
                            ValueMetadata."Mapping Line No." := ICMappingLine."Line No.";
                            ValueMetadata.Modify(false);
                        end;
            until ValueMetadata.Next() = 0;
    end;

    procedure SuggestMapping(MappingCode: Code[20]; var UnassignedCount: Integer): Integer
    var
        ICMapping: Record "EOS IC Mapping Headers";
        ICMappingLine: Record "EOS IC Mapping Lines";
        JsonSample: JsonToken;
        JsonInStream: InStream;
        UsedSlotContexts: Dictionary of [Text, Boolean];
        SlotCaptions: Dictionary of [Integer, Text];
        ConflictingSlots: Dictionary of [Integer, Boolean];
        ExistingCaption: Text;
        SuggestedType: Text;
        SuggestedCaption: Text;
        ArrayContext: Text;
        SlotContextKey: Text;
        HasStructuralValue: Boolean;
        SuggestedFieldNo: Integer;
        SuggestedCount: Integer;
        MappingNotFoundErr: Label 'The mapping %1 does not exist.', Comment = '%1 = mapping code';
        InboundRequiredErr: Label 'Suggest Mapping is available only for inbound mappings.';
        UnifiedRequiredErr: Label 'Enable Unified Staging on the mapping before suggesting staging fields.';
        MappingMustBeDisabledErr: Label 'Disable the mapping before suggesting staging fields.';
        SampleJsonRequiredErr: Label 'Import a Json sample before suggesting staging fields.';
        InvalidSampleJsonErr: Label 'The stored Json sample is invalid.';
    begin
        UnassignedCount := 0;
        if not ICMapping.Get(MappingCode) then
            Error(MappingNotFoundErr, MappingCode);
        if ICMapping.Direction <> ICMapping.Direction::Inbound then
            Error(InboundRequiredErr);
        if not ICMapping."Unified Staging" then
            Error(UnifiedRequiredErr);
        if ICMapping.Enabled then
            Error(MappingMustBeDisabledErr);

        ICMapping.CalcFields("Json Content");
        if not ICMapping."Json Content".HasValue() then
            Error(SampleJsonRequiredErr);
        ICMapping."Json Content".CreateInStream(JsonInStream, TextEncoding::UTF8);
        if not JsonSample.ReadFrom(JsonInStream) then
            Error(InvalidSampleJsonErr);
        if not (JsonSample.IsObject() or JsonSample.IsArray()) then
            Error(InvalidSampleJsonErr);

        ICMappingLine.SetRange("Mapping Code", MappingCode);
        if ICMappingLine.FindSet() then
            repeat
                if ICMappingLine."Staging Field No." <> 0 then begin
                    ArrayContext := ICJsonPathMgt.GetArrayContext(ICMappingLine."Json Path");
                    SlotContextKey := GetSlotContextKey(ICMappingLine."Staging Field No.", ArrayContext);
                    UsedSlotContexts.Set(SlotContextKey, true);
                    if SlotCaptions.Get(ICMappingLine."Staging Field No.", ExistingCaption) then begin
                        if ExistingCaption <> ICMappingLine."Staging Caption" then
                            ConflictingSlots.Set(ICMappingLine."Staging Field No.", true);
                    end else
                        SlotCaptions.Add(ICMappingLine."Staging Field No.", ICMappingLine."Staging Caption");
                end;
            until ICMappingLine.Next() = 0;

        ICMappingLine.Reset();
        ICMappingLine.SetRange("Mapping Code", MappingCode);
        ICMappingLine.SetRange("Staging Field No.", 0);
        ICMappingLine.SetRange("Is Structure", false);
        if ICMappingLine.FindSet() then
            repeat
                if ICMappingLine."Json Path" = '' then
                    UnassignedCount += 1
                else begin
                    HasStructuralValue := false;
                    SuggestedType := InferJsonPathType(
                        JsonSample,
                        ICMappingLine."Json Path",
                        ICMappingLine."Enum/Option Source Field No." <> 0,
                        SuggestedType,
                        HasStructuralValue);
                    if (SuggestedType <> '') and not HasStructuralValue then begin
                        SuggestedCaption := GetSuggestedCaption(ICMappingLine."Json Path");
                        ArrayContext := ICJsonPathMgt.GetArrayContext(ICMappingLine."Json Path");
                        SuggestedFieldNo := FindSuggestedSlotNo(
                            SuggestedType,
                            ArrayContext,
                            SuggestedCaption,
                            UsedSlotContexts,
                            SlotCaptions,
                            ConflictingSlots);
                        if SuggestedFieldNo <> 0 then begin
                            ICMappingLine.Validate("Staging Field No.", SuggestedFieldNo);
                            ICMappingLine.Validate("Staging Caption", CopyStr(SuggestedCaption, 1, 100));
                            ICMappingLine.Modify(true);

                            SlotContextKey := GetSlotContextKey(SuggestedFieldNo, ArrayContext);
                            UsedSlotContexts.Set(SlotContextKey, true);
                            if not SlotCaptions.ContainsKey(SuggestedFieldNo) then
                                SlotCaptions.Add(SuggestedFieldNo, SuggestedCaption);
                            SuggestedCount += 1;
                        end else
                            UnassignedCount += 1;
                    end else
                        UnassignedCount += 1;
                end;
            until ICMappingLine.Next() = 0;

        exit(SuggestedCount);
    end;

    local procedure InferJsonPathType(JsonSample: JsonToken; JsonPath: Text; EnumSourceConfigured: Boolean; var InferredType: Text; var HasStructuralValue: Boolean): Text
    var
        Steps: List of [Text];
        PathError: Text;
        HasConflict: Boolean;
    begin
        InferredType := '';
        HasStructuralValue := false;
        if not ICJsonPathMgt.ParsePath(JsonPath, Steps, PathError) then
            exit('');

        CollectPathValues(JsonSample, Steps, 1, EnumSourceConfigured, InferredType, HasConflict, HasStructuralValue);
        if HasConflict or HasStructuralValue then
            exit('');
        exit(InferredType);
    end;

    local procedure CollectPathValues(CurrentToken: JsonToken; Steps: List of [Text]; StepIndex: Integer; EnumSourceConfigured: Boolean; var InferredType: Text; var HasConflict: Boolean; var HasStructuralValue: Boolean)
    var
        Step: Text;
        NextToken: JsonToken;
        ArrayElement: JsonToken;
        ObservedType: Text;
    begin
        if HasConflict or HasStructuralValue then
            exit;

        if StepIndex > Steps.Count() then begin
            if not CurrentToken.IsValue() then begin
                HasStructuralValue := true;
                exit;
            end;

            ObservedType := InferJsonValueType(CurrentToken, EnumSourceConfigured);
            MergeInferredType(InferredType, ObservedType, HasConflict);
            exit;
        end;

        Step := Steps.Get(StepIndex);
        if ICJsonPathMgt.IsArrayStep(Step) then begin
            if not CurrentToken.IsArray() then begin
                HasStructuralValue := true;
                exit;
            end;

            foreach ArrayElement in CurrentToken.AsArray() do
                CollectPathValues(ArrayElement, Steps, StepIndex + 1, EnumSourceConfigured, InferredType, HasConflict, HasStructuralValue);
            exit;
        end;

        if not CurrentToken.IsObject() then begin
            HasStructuralValue := true;
            exit;
        end;
        if CurrentToken.AsObject().Get(ICJsonPathMgt.GetPropertyName(Step), NextToken) then
            CollectPathValues(NextToken, Steps, StepIndex + 1, EnumSourceConfigured, InferredType, HasConflict, HasStructuralValue);
    end;

    local procedure InferJsonValueType(JsonValueToken: JsonToken; EnumSourceConfigured: Boolean): Text
    var
        JsonValue: JsonValue;
        RawJson: Text;
        StringValue: Text;
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        DecimalValue: Decimal;
    begin
        JsonValue := JsonValueToken.AsValue();
        if JsonValue.IsNull() then
            exit('');

        JsonValueToken.WriteTo(RawJson);
        if (RawJson = 'true') or (RawJson = 'false') then
            exit('Boolean');

        if CopyStr(RawJson, 1, 1) = '"' then begin
            StringValue := JsonValue.AsText();
            if DelChr(StringValue, '<>', ' ') = '' then
                exit('');
            if EnumSourceConfigured then
                exit('Integer');
            exit(InferStringType(StringValue));
        end;

        if EnumSourceConfigured then begin
            if (StrPos(RawJson, '.') > 0) or (StrPos(LowerCase(RawJson), 'e') > 0) then
                exit('');
            if TryEvaluateInteger(RawJson, IntegerValue) then
                exit('Integer');
            exit('');
        end;

        if (StrPos(RawJson, '.') > 0) or (StrPos(LowerCase(RawJson), 'e') > 0) then begin
            if TryEvaluateDecimal(RawJson, DecimalValue) then
                exit('Decimal');
            exit('');
        end;
        if TryEvaluateInteger(RawJson, IntegerValue) then
            exit('Integer');
        if TryEvaluateBigInteger(RawJson, BigIntegerValue) then
            exit('BigInteger');
        if TryEvaluateDecimal(RawJson, DecimalValue) then
            exit('Decimal');
        exit('');
    end;

    local procedure InferStringType(ValueText: Text): Text
    var
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
        GuidValue: Guid;
    begin
        if IsIsoDate(ValueText) then
            if TryEvaluateDate(ValueText, DateValue) then
                exit('Date');
        if IsIsoDateTime(ValueText) then
            if TryEvaluateDateTime(ValueText, DateTimeValue) then
                exit('DateTime');
        if IsIsoTime(ValueText) then
            if TryEvaluateTime(ValueText, TimeValue) then
                exit('Time');
        if IsCanonicalGuid(ValueText) then
            if TryEvaluateGuid(ValueText, GuidValue) then
                exit('Guid');
        exit('Text');
    end;

    local procedure IsIsoDate(ValueText: Text): Boolean
    begin
        exit((StrLen(ValueText) = 10) and (CopyStr(ValueText, 5, 1) = '-') and (CopyStr(ValueText, 8, 1) = '-'));
    end;

    local procedure IsIsoDateTime(ValueText: Text): Boolean
    begin
        exit((StrLen(ValueText) >= 19) and (CopyStr(ValueText, 5, 1) = '-') and (CopyStr(ValueText, 8, 1) = '-') and
            (CopyStr(ValueText, 11, 1) = 'T') and (CopyStr(ValueText, 14, 1) = ':') and (CopyStr(ValueText, 17, 1) = ':'));
    end;

    local procedure IsIsoTime(ValueText: Text): Boolean
    begin
        exit((StrLen(ValueText) = 8) and (CopyStr(ValueText, 3, 1) = ':') and (CopyStr(ValueText, 6, 1) = ':'));
    end;

    local procedure IsCanonicalGuid(ValueText: Text): Boolean
    begin
        exit((StrLen(ValueText) = 36) and (CopyStr(ValueText, 9, 1) = '-') and (CopyStr(ValueText, 14, 1) = '-') and
            (CopyStr(ValueText, 19, 1) = '-') and (CopyStr(ValueText, 24, 1) = '-'));
    end;

    local procedure MergeInferredType(var ExistingType: Text; NewType: Text; var HasConflict: Boolean)
    begin
        if (NewType = '') or HasConflict then
            exit;
        if ExistingType = '' then begin
            ExistingType := NewType;
            exit;
        end;
        if ExistingType = NewType then
            exit;

        if IsNumericInferredType(ExistingType) and IsNumericInferredType(NewType) then begin
            if (ExistingType = 'Decimal') or (NewType = 'Decimal') then
                ExistingType := 'Decimal'
            else
                ExistingType := 'BigInteger';
            exit;
        end;
        HasConflict := true;
    end;

    local procedure IsNumericInferredType(InferredType: Text): Boolean
    begin
        exit((InferredType = 'Integer') or (InferredType = 'BigInteger') or (InferredType = 'Decimal'));
    end;

    local procedure TryEvaluateInteger(ValueText: Text; var Value: Integer): Boolean
    begin
        exit(TryEvaluateIntegerValue(ValueText, Value));
    end;

    [TryFunction]
    local procedure TryEvaluateIntegerValue(ValueText: Text; var Value: Integer)
    begin
        if not Evaluate(Value, ValueText, 9) then
            Error('Invalid Integer');
    end;

    local procedure TryEvaluateBigInteger(ValueText: Text; var Value: BigInteger): Boolean
    begin
        exit(TryEvaluateBigIntegerValue(ValueText, Value));
    end;

    [TryFunction]
    local procedure TryEvaluateBigIntegerValue(ValueText: Text; var Value: BigInteger)
    begin
        if not Evaluate(Value, ValueText, 9) then
            Error('Invalid BigInteger');
    end;

    local procedure TryEvaluateDecimal(ValueText: Text; var Value: Decimal): Boolean
    begin
        exit(TryEvaluateDecimalValue(ValueText, Value));
    end;

    [TryFunction]
    local procedure TryEvaluateDecimalValue(ValueText: Text; var Value: Decimal)
    begin
        if not Evaluate(Value, ValueText, 9) then
            Error('Invalid Decimal');
    end;

    local procedure TryEvaluateDate(ValueText: Text; var Value: Date): Boolean
    begin
        exit(TryEvaluateDateValue(ValueText, Value));
    end;

    [TryFunction]
    local procedure TryEvaluateDateValue(ValueText: Text; var Value: Date)
    begin
        if not Evaluate(Value, ValueText, 9) then
            Error('Invalid Date');
    end;

    local procedure TryEvaluateDateTime(ValueText: Text; var Value: DateTime): Boolean
    begin
        exit(TryEvaluateDateTimeValue(ValueText, Value));
    end;

    [TryFunction]
    local procedure TryEvaluateDateTimeValue(ValueText: Text; var Value: DateTime)
    begin
        if not Evaluate(Value, ValueText, 9) then
            Error('Invalid DateTime');
    end;

    local procedure TryEvaluateTime(ValueText: Text; var Value: Time): Boolean
    begin
        exit(TryEvaluateTimeValue(ValueText, Value));
    end;

    [TryFunction]
    local procedure TryEvaluateTimeValue(ValueText: Text; var Value: Time)
    begin
        if not Evaluate(Value, ValueText, 9) then
            Error('Invalid Time');
    end;

    local procedure TryEvaluateGuid(ValueText: Text; var Value: Guid): Boolean
    begin
        exit(TryEvaluateGuidValue(ValueText, Value));
    end;

    [TryFunction]
    local procedure TryEvaluateGuidValue(ValueText: Text; var Value: Guid)
    begin
        if not Evaluate(Value, ValueText, 9) then
            Error('Invalid GUID');
    end;

    local procedure GetSuggestedCaption(JsonPath: Text): Text
    var
        NodeName: Text;
        ResultText: Text;
        CurrentCharacter: Text[1];
        PreviousCharacter: Text[1];
        Index: Integer;
    begin
        NodeName := ICJsonPathMgt.GetNodeName(JsonPath).Replace('_', ' ');
        for Index := 1 to StrLen(NodeName) do begin
            CurrentCharacter := CopyStr(NodeName, Index, 1);
            if Index = 1 then
                ResultText := UpperCase(CurrentCharacter)
            else begin
                PreviousCharacter := CopyStr(NodeName, Index - 1, 1);
                if (CurrentCharacter = UpperCase(CurrentCharacter)) and (CurrentCharacter <> LowerCase(CurrentCharacter)) and
                    (PreviousCharacter = LowerCase(PreviousCharacter)) and (PreviousCharacter <> UpperCase(PreviousCharacter)) and
                    (PreviousCharacter <> ' ')
                then
                    ResultText += ' ';
                ResultText += CurrentCharacter;
            end;
        end;
        exit(CopyStr(ResultText, 1, 100));
    end;

    local procedure GetSlotContextKey(FieldNo: Integer; ContextPath: Text): Text
    begin
        exit(Format(FieldNo, 0, 9) + '|' + ContextPath);
    end;

    local procedure FindSuggestedSlotNo(InferredType: Text; ContextPath: Text; CaptionText: Text; var UsedSlotContexts: Dictionary of [Text, Boolean]; var SlotCaptions: Dictionary of [Integer, Text]; var ConflictingSlots: Dictionary of [Integer, Boolean]): Integer
    var
        CandidateFieldNos: List of [Integer];
        CandidateFieldNo: Integer;
        ContextKey: Text;
        ExistingCaption: Text;
        CaptionExists: Boolean;
    begin
        GetCandidateSlotNos(InferredType, CandidateFieldNos);
        foreach CandidateFieldNo in CandidateFieldNos do begin
            ContextKey := GetSlotContextKey(CandidateFieldNo, ContextPath);
            CaptionExists := SlotCaptions.Get(CandidateFieldNo, ExistingCaption);
            if not UsedSlotContexts.ContainsKey(ContextKey) and not ConflictingSlots.ContainsKey(CandidateFieldNo) then
                if not CaptionExists or (ExistingCaption = CaptionText) then
                    exit(CandidateFieldNo);
        end;
    end;

    local procedure GetCandidateSlotNos(InferredType: Text; var FieldNos: List of [Integer])
    begin
        Clear(FieldNos);
        case InferredType of
            'Text':
                begin
                    AddSlotRange(FieldNos, 20);
                    AddSlotRange(FieldNos, 110);
                end;
            'Decimal':
                begin
                    AddSlotRange(FieldNos, 30);
                    AddSlotRange(FieldNos, 120);
                end;
            'Integer':
                begin
                    AddSlotRange(FieldNos, 40);
                    AddSlotRange(FieldNos, 130);
                end;
            'BigInteger':
                begin
                    AddSlotRange(FieldNos, 50);
                    AddSlotRange(FieldNos, 140);
                end;
            'Guid':
                begin
                    AddSlotRange(FieldNos, 60);
                    AddSlotRange(FieldNos, 150);
                end;
            'Boolean':
                begin
                    AddSlotRange(FieldNos, 70);
                    AddSlotRange(FieldNos, 160);
                end;
            'Date':
                begin
                    AddSlotRange(FieldNos, 80);
                    AddSlotRange(FieldNos, 170);
                end;
            'DateTime':
                begin
                    AddSlotRange(FieldNos, 90);
                    AddSlotRange(FieldNos, 180);
                end;
            'Time':
                begin
                    AddSlotRange(FieldNos, 100);
                    AddSlotRange(FieldNos, 190);
                end;
        end;
    end;

    local procedure AddSlotRange(var FieldNos: List of [Integer]; FirstFieldNo: Integer)
    var
        FieldNo: Integer;
    begin
        for FieldNo := FirstFieldNo to FirstFieldNo + 9 do
            FieldNos.Add(FieldNo);
    end;

    local procedure PopulateEntry(ICEntries: Record "EOS IC Entries")
    var
        ICFlows: Record "EOS IC Flows";
        ICMapping: Record "EOS IC Mapping Headers";
        TempStaging: Record "EOS IC Staging" temporary;
        TempValue: Record "EOS IC Staging Value" temporary;
        Payload: JsonToken;
        EmptyParentRecordID: Guid;
        Issues: List of [Text];
        InvalidPayloadErr: Label 'The received payload of entry %1 is not valid Json.', Comment = '%1 = entry no.';
        FlowNotFoundErr: Label 'The flow %1 of company %2 does not exist.', Comment = '%1 = flow code, %2 = company code';
        MappingNotAssignedErr: Label 'No mapping is assigned to flow %1 of company %2.', Comment = '%1 = flow code, %2 = company code';
        MappingNotEnabledErr: Label 'The mapping %1 assigned to flow %2 is not enabled.', Comment = '%1 = mapping code, %2 = flow code';
        MappingNotUnifiedErr: Label 'The mapping %1 is not configured for unified staging.', Comment = '%1 = mapping code';
        MappingInvalidErr: Label 'The mapping %1 is not valid:\%2', Comment = '%1 = mapping code, %2 = validation issues';
        InvalidRootErr: Label 'The root of the received Json must be an object or an array.';
    begin
        if not Payload.ReadFrom(ICEntries.GetBlobFields(ICEntries.FieldNo("Received Payload"))) then
            Error(InvalidPayloadErr, ICEntries."Entry No.");
        if not (Payload.IsObject() or Payload.IsArray()) then
            Error(InvalidRootErr);

        if not ICFlows.Get(ICEntries."Source Company", ICEntries."IC Flow Code") then
            Error(FlowNotFoundErr, ICEntries."IC Flow Code", ICEntries."Source Company");
        if ICFlows."Mapping Code" = '' then
            Error(MappingNotAssignedErr, ICFlows.Code, ICFlows."Company Code");

        ICMapping.Get(ICFlows."Mapping Code");
        if not ICMapping.Enabled then
            Error(MappingNotEnabledErr, ICMapping.Code, ICFlows.Code);
        if not ICMapping."Unified Staging" then
            Error(MappingNotUnifiedErr, ICMapping.Code);
        if not ValidateMapping(ICMapping.Code, true, false, Issues) then
            Error(MappingInvalidErr, ICMapping.Code, GetIssuesText(Issues));

        ResetRunState(ICEntries, ICMapping.Code);
        LoadActiveLines(ICMapping.Code);
        BuildContextTree();
        ContextElements.Set('', Payload);
        Clear(EmptyParentRecordID);
        ProcessContext('', EmptyParentRecordID, 1, TempStaging, TempValue);
        ReplaceEntryStaging(ICEntries."Entry No.", TempStaging, TempValue);
    end;

    local procedure ResetRunState(ICEntries: Record "EOS IC Entries"; MappingCode: Code[20])
    begin
        Clear(ContextElements);
        Clear(LinesByContext);
        Clear(ChildContexts);
        TempMappingLine.Reset();
        TempMappingLine.DeleteAll();
        CurrentICEntryNo := ICEntries."Entry No.";
        CurrentMappingCode := MappingCode;
        CurrentSourceCompany := ICEntries."Source Company";
        CurrentFlowCode := ICEntries."IC Flow Code";
        NextTreeOrder := 0;
    end;

    local procedure LoadActiveLines(MappingCode: Code[20])
    var
        ICMappingLine: Record "EOS IC Mapping Lines";
        ContextPath: Text;
        LineNos: List of [Integer];
    begin
        ICMappingLine.SetRange("Mapping Code", MappingCode);
        ICMappingLine.SetFilter("Staging Field No.", '<>0');
        ICMappingLine.SetRange("Is Structure", false);
        if not ICMappingLine.FindSet() then
            exit;

        repeat
            TempMappingLine := ICMappingLine;
            TempMappingLine.Insert(false);
            ContextPath := ICJsonPathMgt.GetArrayContext(ICMappingLine."Json Path");
            Clear(LineNos);
            if LinesByContext.Get(ContextPath, LineNos) then;
            LineNos.Add(ICMappingLine."Line No.");
            LinesByContext.Set(ContextPath, LineNos);
            AddContextChain(ContextPath);
        until ICMappingLine.Next() = 0;
    end;

    local procedure BuildContextTree()
    begin
        if LinesByContext.ContainsKey('') or ChildContexts.ContainsKey('') then
            exit;
        Error('The unified staging mapping has no active Json paths.');
    end;

    local procedure AddContextChain(ContextPath: Text)
    var
        ContextChain: List of [Text];
        ParentContext: Text;
        ChildContext: Text;
    begin
        ICJsonPathMgt.GetContextChain(ContextPath, ContextChain);
        ParentContext := '';
        foreach ChildContext in ContextChain do begin
            AddChildContext(ParentContext, ChildContext);
            ParentContext := ChildContext;
        end;
    end;

    local procedure AddChildContext(ParentContext: Text; ChildContext: Text)
    var
        Children: List of [Text];
    begin
        Clear(Children);
        if ChildContexts.Get(ParentContext, Children) then
            if Children.Contains(ChildContext) then
                exit;
        Children.Add(ChildContext);
        ChildContexts.Set(ParentContext, Children);
    end;

    local procedure ProcessContext(ContextPath: Text; ParentRecordID: Guid; SequenceNo: Integer; var TempStaging: Record "EOS IC Staging" temporary; var TempValue: Record "EOS IC Staging Value" temporary)
    var
        ContextElement: JsonToken;
        ChildPaths: List of [Text];
        ChildPath: Text;
        ChildParentRecordID: Guid;
        ChildSequenceNo: Integer;
        HasMappedLines: Boolean;
        HasMappedChildren: Boolean;
    begin
        if not ContextElements.Get(ContextPath, ContextElement) then
            exit;

        HasMappedLines := LinesByContext.ContainsKey(ContextPath);
        HasMappedChildren := ChildContexts.ContainsKey(ContextPath);
        ChildParentRecordID := ParentRecordID;
        if HasMappedLines or HasMappedChildren then begin
            InsertContextRecord(ContextPath, ContextElement, ParentRecordID, SequenceNo, TempStaging, TempValue, ChildParentRecordID);
            if ContextPath = '' then
                ChildParentRecordID := TempStaging."Staging Record ID";
        end;

        if not HasMappedChildren then
            exit;

        ChildContexts.Get(ContextPath, ChildPaths);
        foreach ChildPath in ChildPaths do begin
            ChildSequenceNo := 0;
            IterateContext(ContextPath, ChildPath, ChildParentRecordID, ChildSequenceNo, TempStaging, TempValue);
        end;
    end;

    local procedure IterateContext(ParentContext: Text; ChildContext: Text; ParentRecordID: Guid; var SequenceNo: Integer; var TempStaging: Record "EOS IC Staging" temporary; var TempValue: Record "EOS IC Staging Value" temporary)
    var
        ParentSteps: List of [Text];
        ChildSteps: List of [Text];
        ParentElement: JsonToken;
        Container: JsonToken;
        Element: JsonToken;
        ArrayExpectedErr: Label 'The Json node %1 is expected to be an array.', Comment = '%1 = Json path';
    begin
        if not ContextElements.Get(ParentContext, ParentElement) then
            exit;

        ICJsonPathMgt.ParseContext(ParentContext, ParentSteps);
        ICJsonPathMgt.ParseContext(ChildContext, ChildSteps);
        if not ICJsonPathMgt.NavigateProperties(ParentElement, ChildSteps, ParentSteps.Count() + 1, ChildSteps.Count() - 1, Container) then
            exit;

        if Container.IsValue() then
            if Container.AsValue().IsNull() then
                exit;
        if not Container.IsArray() then
            Error(ArrayExpectedErr, ChildContext);

        foreach Element in Container.AsArray() do begin
            SequenceNo += 1;
            ContextElements.Set(ChildContext, Element);
            ProcessContext(ChildContext, ParentRecordID, SequenceNo, TempStaging, TempValue);
            ContextElements.Remove(ChildContext);
        end;
    end;

    local procedure InsertContextRecord(ContextPath: Text; ContextElement: JsonToken; ParentRecordID: Guid; SequenceNo: Integer; var TempStaging: Record "EOS IC Staging" temporary; var TempValue: Record "EOS IC Staging Value" temporary; var NewRecordID: Guid)
    var
        StagingRecRef: RecordRef;
    begin
        TempStaging.Init();
        TempStaging."Staging Record ID" := CreateGuid();
        TempStaging."IC Entry No." := CurrentICEntryNo;
        TempStaging."Parent Record ID" := ParentRecordID;
        TempStaging.Level := ICJsonPathMgt.GetArrayDepth(ContextPath);
        TempStaging."Sequence No." := SequenceNo;
        NextTreeOrder += 1;
        TempStaging."Tree Order" := NextTreeOrder;
        TempStaging."Mapping Code" := CurrentMappingCode;
        TempStaging."Node Identifier" := CopyStr(ContextPath, 1, MaxStrLen(TempStaging."Node Identifier"));
        TempStaging."Source Company" := CurrentSourceCompany;
        TempStaging."IC Flow Code" := CurrentFlowCode;
        TempStaging."Node Type" := GetNodeType(ContextElement);

        StagingRecRef.GetTable(TempStaging);
        ApplyMappingLines(ContextPath, ContextElement, TempStaging."Staging Record ID", StagingRecRef, TempValue);
        StagingRecRef.SetTable(TempStaging);
        StagingRecRef.Close();

        TempStaging.Insert(false);
        NewRecordID := TempStaging."Staging Record ID";
    end;

    local procedure ApplyMappingLines(ContextPath: Text; ContextElement: JsonToken; StagingRecordID: Guid; var StagingRecRef: RecordRef; var TempValue: Record "EOS IC Staging Value" temporary)
    var
        FieldRef: FieldRef;
        LineNos: List of [Integer];
        LineNo: Integer;
        JsonTokenValue: JsonToken;
        JsonValue: JsonValue;
        ValueState: Enum "EOS IC Staging Value State";
        RawValue: Text;
        CurrentValue: Text;
        ResultValue: Text;
        Handled: Boolean;
    begin
        if not LinesByContext.Get(ContextPath, LineNos) then
            exit;

        foreach LineNo in LineNos do begin
            TempMappingLine.Get(CurrentMappingCode, LineNo);
            FieldRef := StagingRecRef.Field(TempMappingLine."Staging Field No.");
            ValueState := ValueState::Missing;
            RawValue := '';
            Clear(CurrentValue);
            Clear(ResultValue);
            Clear(Handled);

            case TempMappingLine."Value Type" of
                TempMappingLine."Value Type"::Unchanged:
                    if ResolveToken(TempMappingLine."Json Path", ContextPath, JsonTokenValue) then begin
                        if not JsonTokenValue.IsValue() then
                            Error('The Json path %1 must resolve to a primitive value.', TempMappingLine."Json Path");
                        JsonValue := JsonTokenValue.AsValue();
                        if JsonValue.IsNull() then
                            ValueState := ValueState::Null
                        else begin
                            ValueState := ValueState::Value;
                            RawValue := JsonValue.AsText();
                            SetFieldFromJsonValue(FieldRef, RawValue, TempMappingLine);
                        end;
                    end;
                TempMappingLine."Value Type"::Constant:
                    begin
                        ValueState := ValueState::Value;
                        SetFieldFromText(FieldRef, TempMappingLine."Constant Text", TempMappingLine, false);
                    end;
                TempMappingLine."Value Type"::"Transformation":
                    if ResolveToken(TempMappingLine."Json Path", ContextPath, JsonTokenValue) then
                        if JsonTokenValue.IsValue() then begin
                            JsonValue := JsonTokenValue.AsValue();
                            if not JsonValue.IsNull() then begin
                                CurrentValue := JsonValue.AsText();
                                RawValue := CurrentValue;
                                ValueState := ValueState::Value;
                                SetFieldFromText(FieldRef, CurrentValue, TempMappingLine, true);
                            end else
                                ValueState := ValueState::Null;
                        end else
                            Error('The Json path %1 must resolve to a primitive value.', TempMappingLine."Json Path");
                TempMappingLine."Value Type"::"External Management":
                    begin
                        if ResolveToken(TempMappingLine."Json Path", ContextPath, JsonTokenValue) then
                            if JsonTokenValue.IsValue() then begin
                                JsonValue := JsonTokenValue.AsValue();
                                if not JsonValue.IsNull() then begin
                                    CurrentValue := JsonValue.AsText();
                                    RawValue := CurrentValue;
                                    ValueState := ValueState::Value;
                                end else
                                    ValueState := ValueState::Null;
                            end else
                                Error('The Json path %1 must resolve to a primitive value.', TempMappingLine."Json Path");

                        OnTransformValue(TempMappingLine, ContextElement, CurrentValue, ResultValue, Handled);
                        if Handled then begin
                            RawValue := ResultValue;
                            ValueState := ValueState::Value;
                            SetFieldFromText(FieldRef, ResultValue, TempMappingLine, true);
                        end;
                    end;
            end;

            InsertValueMetadata(StagingRecordID, TempMappingLine, ValueState, RawValue, TempValue);
        end;
    end;

    local procedure ResolveToken(Path: Text; ContextPath: Text; var Result: JsonToken): Boolean
    var
        Steps: List of [Text];
        ErrorText: Text;
        LastArrayStep: Integer;
        PathContext: Text;
        ContextElement: JsonToken;
    begin
        if Path = '' then
            exit(false);
        if not ICJsonPathMgt.ParsePath(Path, Steps, ErrorText) then
            Error('The Json path %1 is invalid. %2', Path, ErrorText);

        LastArrayStep := ICJsonPathMgt.GetLastArrayStep(Steps);
        PathContext := ICJsonPathMgt.SerializeSteps(Steps, LastArrayStep);
        if PathContext <> ContextPath then
            exit(false);
        if not ContextElements.Get(ContextPath, ContextElement) then
            exit(false);
        exit(ICJsonPathMgt.NavigateProperties(ContextElement, Steps, LastArrayStep + 1, Steps.Count(), Result));
    end;

    local procedure SetFieldFromJsonValue(var FieldRef: FieldRef; ValueText: Text; ICMappingLine: Record "EOS IC Mapping Lines")
    begin
        SetFieldFromText(FieldRef, ValueText, ICMappingLine, false);
    end;

    local procedure SetFieldFromText(var FieldRef: FieldRef; ValueText: Text; ICMappingLine: Record "EOS IC Mapping Lines"; ApplyTransformations: Boolean)
    var
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        DecimalValue: Decimal;
        BooleanValue: Boolean;
        GuidValue: Guid;
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
        InvalidValueErr: Label 'The Json value for path %1 cannot be assigned to staging field %2. %3', Comment = '%1 = Json path, %2 = field name, %3 = error detail';
        TextTooLongErr: Label 'The Json value for path %1 exceeds the %2 characters supported by staging field %3.', Comment = '%1 = Json path, %2 = maximum length, %3 = field name';
    begin
        if FieldRef.Type = FieldType::Text then begin
            if ApplyTransformations then
                ValueText := StringTransformationMgt.ApplyTransformations(ICMappingLine."Transliteration Code", ICMappingLine."String Replacement Code", ICMappingLine."Transformation Order", ValueText);
            if StrLen(ValueText) > FieldRef.Length then
                Error(TextTooLongErr, ICMappingLine."Json Path", FieldRef.Length, FieldRef.Name);
            FieldRef.Value := ValueText;
            exit;
        end;

        if ICMappingLine."Enum/Option Source Field No." <> 0 then begin
            FieldRef.Value := GetEnumOrdinal(ICMappingLine, ValueText);
            exit;
        end;

        case FieldRef.Type of
            FieldType::Integer:
                begin
                    if not Evaluate(IntegerValue, ValueText, 9) then
                        Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The value is not a valid Integer.');
                    FieldRef.Value := IntegerValue;
                end;
            FieldType::BigInteger:
                begin
                    if not Evaluate(BigIntegerValue, ValueText, 9) then
                        Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The value is not a valid BigInteger.');
                    FieldRef.Value := BigIntegerValue;
                end;
            FieldType::Decimal:
                begin
                    if not Evaluate(DecimalValue, ValueText, 9) then
                        Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The value is not a valid Decimal.');
                    FieldRef.Value := DecimalValue;
                end;
            FieldType::Boolean:
                begin
                    if not Evaluate(BooleanValue, ValueText, 9) then
                        Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The value is not a valid Boolean.');
                    FieldRef.Value := BooleanValue;
                end;
            FieldType::Guid:
                begin
                    if not Evaluate(GuidValue, ValueText, 9) then
                        Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The value is not a valid GUID.');
                    FieldRef.Value := GuidValue;
                end;
            FieldType::Date:
                begin
                    if not Evaluate(DateValue, ValueText, 9) then
                        Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The value is not a valid Date.');
                    FieldRef.Value := DateValue;
                end;
            FieldType::DateTime:
                begin
                    if not Evaluate(DateTimeValue, ValueText, 9) then
                        Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The value is not a valid DateTime.');
                    FieldRef.Value := DateTimeValue;
                end;
            FieldType::Time:
                begin
                    if not Evaluate(TimeValue, ValueText, 9) then
                        Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The value is not a valid Time.');
                    FieldRef.Value := TimeValue;
                end;
            else
                Error(InvalidValueErr, ICMappingLine."Json Path", FieldRef.Name, 'The staging field type is not supported.');
        end;
    end;

    local procedure GetEnumOrdinal(ICMappingLine: Record "EOS IC Mapping Lines"; ValueText: Text): Integer
    var
        SourceRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        Ordinal: Integer;
        ValueIndex: Integer;
        Found: Boolean;
        InvalidEnumValueErr: Label 'The value %1 at Json path %2 is not a value of the configured Enum or Option.', Comment = '%1 = source value, %2 = Json path';
    begin
        SourceRecRef.Open(ICMappingLine."Enum/Option Source Table No.");
        SourceFieldRef := SourceRecRef.Field(ICMappingLine."Enum/Option Source Field No.");

        if Evaluate(Ordinal, ValueText, 9) then
            for ValueIndex := 1 to SourceFieldRef.EnumValueCount() do
                if SourceFieldRef.GetEnumValueOrdinal(ValueIndex) = Ordinal then begin
                    Found := true;
                    break;
                end;

        if not Found then
            for ValueIndex := 1 to SourceFieldRef.EnumValueCount() do
                if LowerCase(SourceFieldRef.GetEnumValueName(ValueIndex)) = LowerCase(ValueText) then begin
                    Ordinal := SourceFieldRef.GetEnumValueOrdinal(ValueIndex);
                    Found := true;
                    break;
                end;

        SourceRecRef.Close();
        if not Found then
            Error(InvalidEnumValueErr, ValueText, ICMappingLine."Json Path");
        exit(Ordinal);
    end;

    local procedure InsertValueMetadata(StagingRecordID: Guid; ICMappingLine: Record "EOS IC Mapping Lines"; ValueState: Enum "EOS IC Staging Value State"; RawValue: Text; var TempValue: Record "EOS IC Staging Value" temporary)
    var
        SourceField: Record Field;
        AllObjWithCaption: Record AllObjWithCaption;
        JsonValueTooLongErr: Label 'The Json value for path %1 exceeds the %2 characters supported for original value metadata.', Comment = '%1 = Json path, %2 = maximum length';
    begin
        if StrLen(RawValue) > MaxStrLen(TempValue."Original Json Value") then
            Error(JsonValueTooLongErr, ICMappingLine."Json Path", MaxStrLen(TempValue."Original Json Value"));

        TempValue.Init();
        TempValue."Staging Record ID" := StagingRecordID;
        TempValue."IC Entry No." := CurrentICEntryNo;
        TempValue."Staging Field No." := ICMappingLine."Staging Field No.";
        TempValue."Mapping Line No." := ICMappingLine."Line No.";
        TempValue."Value State" := ValueState;
        TempValue."Json Path" := ICMappingLine."Json Path";
        TempValue."Original Json Value" := CopyStr(RawValue, 1, MaxStrLen(TempValue."Original Json Value"));

        if ICMappingLine."Enum/Option Source Field No." <> 0 then begin
            TempValue."Enum/Option Source Table No." := ICMappingLine."Enum/Option Source Table No.";
            TempValue."Enum/Option Source Field No." := ICMappingLine."Enum/Option Source Field No.";
            if SourceField.Get(ICMappingLine."Enum/Option Source Table No.", ICMappingLine."Enum/Option Source Field No.") then begin
                TempValue."Enum Type Name" := CopyStr(SourceField."Type Name", 1, MaxStrLen(TempValue."Enum Type Name"));
                TempValue."Option Members" := CopyStr(SourceField.OptionString, 1, MaxStrLen(TempValue."Option Members"));
                TempValue."Is Option" := SourceField."Type Name" = '';
                if not TempValue."Is Option" then begin
                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Enum);
                    AllObjWithCaption.SetRange("Object Name", SourceField."Type Name");
                    if AllObjWithCaption.FindFirst() then begin
                        TempValue."Enum Type ID" := AllObjWithCaption."Object ID";
                        TempValue."Enum App ID" := AllObjWithCaption."App ID";
                        TempValue."Enum Namespace" := CopyStr(AllObjWithCaption."AL Namespace", 1, MaxStrLen(TempValue."Enum Namespace"));
                    end;
                end;
            end;
        end;

        TempValue.Insert(false);
    end;

    local procedure ReplaceEntryStaging(ICEntryNo: Integer; var TempStaging: Record "EOS IC Staging" temporary; var TempValue: Record "EOS IC Staging Value" temporary)
    var
        Staging: Record "EOS IC Staging";
        StagingValue: Record "EOS IC Staging Value";
    begin
        StagingValue.SetRange("IC Entry No.", ICEntryNo);
        StagingValue.DeleteAll(false);
        Staging.SetRange("IC Entry No.", ICEntryNo);
        Staging.DeleteAll(false);

        if TempStaging.FindSet() then
            repeat
                Staging := TempStaging;
                Staging.Insert(false);
            until TempStaging.Next() = 0;

        if TempValue.FindSet() then
            repeat
                StagingValue := TempValue;
                StagingValue.Insert(false);
            until TempValue.Next() = 0;
    end;

    local procedure GetNodeType(Node: JsonToken): Enum "EOS IC Json Node Type"
    var
        NodeType: Enum "EOS IC Json Node Type";
    begin
        if Node.IsObject() then
            exit(NodeType::"Object");
        if Node.IsArray() then
            exit(NodeType::"Array");
        exit(NodeType::Value);
    end;

    local procedure IsSupportedFieldType(Field: Record Field): Boolean
    begin
        exit(Field.Type in [Field.Type::Text, Field.Type::Decimal, Field.Type::Integer, Field.Type::BigInteger, Field.Type::Guid, Field.Type::Boolean, Field.Type::Date, Field.Type::DateTime, Field.Type::Time]);
    end;

    local procedure GetIssuesText(Issues: List of [Text]): Text
    var
        Issue: Text;
        Result: Text;
    begin
        foreach Issue in Issues do
            Result += Issue + '\';
        exit(Result);
    end;

    local procedure OnTransformValue(ICMappingLine: Record "EOS IC Mapping Lines"; ContextElement: JsonToken; CurrentValue: Text; var Result: Text; var Handled: Boolean)
    var
        ICMappingMgt: Codeunit "EOS IC Mapping Mgt.";
    begin
        ICMappingMgt.OnTransformValue(ICMappingLine, ContextElement, CurrentValue, Result, Handled);
    end;

    var
        TempMappingLine: Record "EOS IC Mapping Lines" temporary;
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
        StringTransformationMgt: Codeunit "EOS IC String Transform Mgt.";
        ContextElements: Dictionary of [Text, JsonToken];
        LinesByContext: Dictionary of [Text, List of [Integer]];
        ChildContexts: Dictionary of [Text, List of [Text]];
        CurrentMappingCode: Code[20];
        CurrentICEntryNo: Integer;
        CurrentSourceCompany: Code[20];
        CurrentFlowCode: Code[20];
        RebuildEntryNo: Integer;
        NextTreeOrder: Integer;
}