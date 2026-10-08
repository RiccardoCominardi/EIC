namespace EOS.Solutions.Intercompany;

using Microsoft.Utilities;
using System.IO;
using System.Text;
using System.Utilities;

codeunit 67017 "EOS IC Out. Mapping Mgt."
{
    var
        TempMappingLine: Record "EOS IC Out. Mapping Lines" temporary;
        TempRelationLine: Record "EOS IC Table Relation Line" temporary;
        ICFlowsContext: Record "EOS IC Flows";
        LineFilters: Dictionary of [Integer, Text];
        ChildLineNos: Dictionary of [Integer, List of [Integer]];
        RelationTargets: Dictionary of [Text, Integer];
        RootLineNos: List of [Integer];
        CurrentMappingCode: Code[20];
        SampleMode: Boolean;

    #region PublicProcedures
    // Builds the payload of the source record with the outbound mapping assigned to the flow.
    procedure BuildPayload(SourceRecord: Variant; ICFlows: Record "EOS IC Flows") MasterJson: JsonObject
    var
        ICMapping: Record "EOS IC Mapping Headers";
        RecRef: RecordRef;
        RecRefView: Text;
        InvalidSourceErr: Label 'The source must be a record.';
        SourceTableMismatchErr: Label 'The mapping %1 is defined for the table %2 but the flow %3 is sending a record of the table %4.', Comment = '%1 = mapping code, %2 = mapping source table, %3 = flow code, %4 = table of the record';
    begin
        SampleMode := false;
        ICFlows.TestField("Mapping Code");
        GetOutboundMapping(ICFlows."Mapping Code", ICMapping);

        if not SourceRecord.IsRecord() then
            Error(InvalidSourceErr);

        RecRef.GetTable(SourceRecord);
        if RecRef.Number <> ICMapping."Source Table No." then
            Error(SourceTableMismatchErr, ICMapping.Code, ICMapping."Source Table No.", ICFlows.Code, RecRef.Number);

        // Only the record being sent is exported, whatever filters the caller had on it.
        RecRef.Reset();
        RecRef.SetRecFilter();
        RecRefView := RecRef.GetView(false);

        OnBeforeCreateJson(ICMapping, ICFlows, RecRefView);

        MasterJson := CreateJson(ICMapping.Code, RecRefView, ICFlows);
    end;

    // RecFilter is the view of the source table to be exported; when it is blank the table filter of the mapping is used.
    procedure CreateJson(MappingCode: Code[20]; RecFilter: Text; ICFlows: Record "EOS IC Flows") MasterJson: JsonObject
    var
        ICMapping: Record "EOS IC Mapping Headers";
        MappingLine: Record "EOS IC Out. Mapping Lines";
        SourceRecRef: RecordRef;
        TableFilterText: Text;
        LineNo: Integer;
    begin
        GetOutboundMapping(MappingCode, ICMapping);
        ICMapping.TestField("Source Table No.");

        SourceRecRef.Open(ICMapping."Source Table No.");
        if RecFilter <> '' then
            SourceRecRef.SetView(RecFilter)
        else begin
            TableFilterText := ICMapping.GetTableFilter();
            if TableFilterText <> '' then
                SourceRecRef.SetView(TableFilterText);
        end;

        ICFlowsContext := ICFlows;
        LoadMapping(MappingCode);

        // The first level is always 1.
        foreach LineNo in RootLineNos do begin
            GetLine(LineNo, MappingLine);
            AddJsonLine(SourceRecRef, MappingLine, MasterJson);
        end;

        OnAfterCreateJson(MappingCode, SourceRecRef, MasterJson);
    end;

    // Downloads the Json produced for the first records of the source table that match the table filter of the mapping.
    procedure DownloadExampleFile(ICMapping: Record "EOS IC Mapping Headers")
    var
        ICFlows: Record "EOS IC Flows";
        TempBlob: Codeunit "Temp Blob";
        FileOutStr: OutStream;
        FileInStr: InStream;
        JsonFile: JsonObject;
        FileText: Text;
        FileName: Text;
        DialogTitleLbl: Label 'Download Json Example';
        FileNameLbl: Label '%1.json', Locked = true, Comment = '%1 = mapping code';
    begin
        ICMapping.TestField(Direction, ICMapping.Direction::Outbound);

        SampleMode := true;
        JsonFile := CreateJson(ICMapping.Code, ICMapping.GetTableFilter(), ICFlows);
        SampleMode := false;
        JsonFile.WriteTo(FileText);

        TempBlob.CreateOutStream(FileOutStr, TextEncoding::UTF8);
        FileOutStr.WriteText(FileText);
        TempBlob.CreateInStream(FileInStr, TextEncoding::UTF8);
        FileName := StrSubstNo(FileNameLbl, ICMapping.Code);
        DownloadFromStream(FileInStr, DialogTitleLbl, '', '', FileName);
    end;

    procedure PopulateFunctions(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
        OnJsonFunctionPopulate(TempNameValueBuffer);
    end;
    #endregion PublicProcedures

    #region Preparation
    local procedure GetOutboundMapping(MappingCode: Code[20]; var ICMapping: Record "EOS IC Mapping Headers")
    begin
        ICMapping.Get(MappingCode);
        ICMapping.TestField(Direction, ICMapping.Direction::Outbound);
        ICMapping.TestField(Enabled, true);
    end;

    // The lines and the relations of the mapping are read once; the tree is then navigated in memory.
    local procedure LoadMapping(MappingCode: Code[20])
    var
        ICOutMappingLine: Record "EOS IC Out. Mapping Lines";
        LineNos: List of [Integer];
        TableFilterText: Text;
    begin
        TempMappingLine.Reset();
        TempMappingLine.DeleteAll();
        TempRelationLine.Reset();
        TempRelationLine.DeleteAll();
        Clear(LineFilters);
        Clear(ChildLineNos);
        Clear(RelationTargets);
        Clear(RootLineNos);
        CurrentMappingCode := MappingCode;

        ICOutMappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        ICOutMappingLine.SetRange("Mapping Code", MappingCode);
        if ICOutMappingLine.FindSet() then
            repeat
                TempMappingLine := ICOutMappingLine;
                TempMappingLine.Insert(false);

                TableFilterText := ICOutMappingLine.GetTableFilter();
                if TableFilterText <> '' then
                    LineFilters.Add(ICOutMappingLine."Line No.", TableFilterText);

                if ICOutMappingLine.Level = 1 then
                    RootLineNos.Add(ICOutMappingLine."Line No.");

                Clear(LineNos);
                if ChildLineNos.Get(ICOutMappingLine."Parent Line No.", LineNos) then;
                LineNos.Add(ICOutMappingLine."Line No.");
                ChildLineNos.Set(ICOutMappingLine."Parent Line No.", LineNos);

                if ICOutMappingLine."Record Relation" <> '' then
                    LoadRelation(ICOutMappingLine."Record Relation");
            until ICOutMappingLine.Next() = 0;
    end;

    local procedure LoadRelation(RelationCode: Code[20])
    var
        ICTableRelationHeader: Record "EOS IC Table Relation Header";
        ICTableRelationLine: Record "EOS IC Table Relation Line";
    begin
        if RelationTargets.ContainsKey(RelationCode) then
            exit;

        ICTableRelationHeader.Get(RelationCode);
        RelationTargets.Add(RelationCode, ICTableRelationHeader."Target Table No.");

        ICTableRelationLine.SetRange(Code, RelationCode);
        if ICTableRelationLine.FindSet() then
            repeat
                TempRelationLine := ICTableRelationLine;
                TempRelationLine.Insert(false);
            until ICTableRelationLine.Next() = 0;
    end;

    local procedure GetLine(LineNo: Integer; var MappingLine: Record "EOS IC Out. Mapping Lines")
    begin
        TempMappingLine.Get(CurrentMappingCode, LineNo);
        MappingLine := TempMappingLine;
    end;

    local procedure GetChildLineNos(ParentLine: Record "EOS IC Out. Mapping Lines"; var ChildNos: List of [Integer])
    var
        CandidateNos: List of [Integer];
        CandidateNo: Integer;
    begin
        Clear(ChildNos);
        if not ChildLineNos.Get(ParentLine."Line No.", CandidateNos) then
            exit;

        foreach CandidateNo in CandidateNos do begin
            TempMappingLine.Get(CurrentMappingCode, CandidateNo);
            if TempMappingLine.Level = ParentLine.Level + 1 then
                ChildNos.Add(CandidateNo);
        end;
    end;

    local procedure GetLineFilter(LineNo: Integer): Text
    var
        TableFilterText: Text;
    begin
        if LineFilters.Get(LineNo, TableFilterText) then;
        exit(TableFilterText);
    end;
    #endregion Preparation

    #region Json
    local procedure AddJsonLine(SourceRecRef: RecordRef; MappingLine: Record "EOS IC Out. Mapping Lines"; var MasterJson: JsonObject)
    begin
        case MappingLine."Line Type" of
            MappingLine."Line Type"::Record:
                ManageJsonRecord(SourceRecRef, MappingLine, MasterJson);
            MappingLine."Line Type"::Attribute:
                case MappingLine."Attribute Type" of
                    MappingLine."Attribute Type"::Constant:
                        ManageJsonConstant(MappingLine, MasterJson);
                    MappingLine."Attribute Type"::"Function":
                        ManageJsonFunction(SourceRecRef, MappingLine, MasterJson);
                    MappingLine."Attribute Type"::Field:
                        ManageJsonField(SourceRecRef, MappingLine, MasterJson);
                end;
        end;
    end;

    local procedure ManageJsonRecord(SourceRecRef: RecordRef; MappingLine: Record "EOS IC Out. Mapping Lines"; var MasterJson: JsonObject)
    var
        ChildLine: Record "EOS IC Out. Mapping Lines";
        RecRef: RecordRef;
        ChildNos: List of [Integer];
        ChildNo: Integer;
        JsonArr: JsonArray;
        JsonRecord: JsonObject;
    begin
        OpenRecordSet(SourceRecRef, MappingLine, RecRef);

        OnManageJsonRecordOnBeforeFindRec(RecRef, MappingLine, SourceRecRef, MasterJson);

        GetChildLineNos(MappingLine, ChildNos);

        if MappingLine."Is Array" then begin
            if RecRef.FindSet() then
                repeat
                    Clear(JsonRecord);
                    if AddChildLines(RecRef, ChildNos, JsonRecord) then
                        JsonArr.Add(JsonRecord);
                until RecRef.Next() = 0;

            MasterJson.Add(MappingLine."Json Tag", JsonArr);
            exit;
        end;

        if RecRef.FindFirst() then begin
            // Without a tag the children are added directly to the parent object.
            if MappingLine."Json Tag" = '' then
                AddChildLines(RecRef, ChildNos, MasterJson)
            else begin
                Clear(JsonRecord);
                AddChildLines(RecRef, ChildNos, JsonRecord);
                MasterJson.Add(MappingLine."Json Tag", JsonRecord);
            end;
            exit;
        end;

        // No record found: the tags of the children are added with an empty value.
        foreach ChildNo in ChildNos do begin
            GetLine(ChildNo, ChildLine);
            if ChildLine."Json Tag" <> '' then
                MasterJson.Add(ChildLine."Json Tag", '');
        end;
    end;

    local procedure AddChildLines(ParentRecRef: RecordRef; ChildNos: List of [Integer]; var JsonRecord: JsonObject) ChildFound: Boolean
    var
        ChildLine: Record "EOS IC Out. Mapping Lines";
        ChildNo: Integer;
    begin
        foreach ChildNo in ChildNos do begin
            GetLine(ChildNo, ChildLine);
            AddJsonLine(ParentRecRef, ChildLine, JsonRecord);
            ChildFound := true;
        end;
    end;

    // The records of a line are those related to the parent record through the table relation, or the parent record itself when the table is the same.
    local procedure OpenRecordSet(SourceRecRef: RecordRef; MappingLine: Record "EOS IC Out. Mapping Lines"; var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        SourceFldRef: FieldRef;
        TargetTableNo: Integer;
        RelationMissingErr: Label 'The line %1 of the mapping %2 requires a table relation.', Comment = '%1 = line no., %2 = mapping code';
    begin
        if (MappingLine."Parent Table No." <> 0) and (MappingLine."Parent Table No." <> MappingLine."Table No.") then begin
            if not RelationTargets.Get(MappingLine."Record Relation", TargetTableNo) then
                Error(RelationMissingErr, MappingLine."Line No.", MappingLine."Mapping Code");

            RecRef.Open(TargetTableNo);
            RecRef.SetView(GetLineFilter(MappingLine."Line No."));

            TempRelationLine.SetRange(Code, MappingLine."Record Relation");
            if TempRelationLine.FindSet() then
                repeat
                    SourceFldRef := SourceRecRef.Field(TempRelationLine."Source Field No.");
                    FldRef := RecRef.Field(TempRelationLine."Target Field No.");
                    FldRef.SetRange(SourceFldRef.Value);
                until TempRelationLine.Next() = 0;
        end else begin
            RecRef.Open(SourceRecRef.Number);
            RecRef.Copy(SourceRecRef);
            if Format(SourceRecRef.GetFilters()) = '' then
                RecRef.SetView(GetLineFilter(MappingLine."Line No."));
        end;
    end;

    local procedure ManageJsonConstant(MappingLine: Record "EOS IC Out. Mapping Lines"; var MasterJson: JsonObject)
    var
        IsHandled: Boolean;
        BooleanValue: Boolean;
        IntegerValue: Integer;
        DecimalValue: Decimal;
        DateTimeValue: DateTime;
        DateValue: Date;
        TimeValue: Time;
        OptionValue: Option;
    begin
        MappingLine.TestField("Json Tag");

        OnBeforeAddConstantValue(MappingLine, MasterJson, IsHandled);
        if IsHandled then
            exit;

        case MappingLine."Constant Type" of
            MappingLine."Constant Type"::Boolean:
                if Evaluate(BooleanValue, MappingLine.Constant) then
                    MasterJson.Add(MappingLine."Json Tag", BooleanValue);
            MappingLine."Constant Type"::Integer:
                if Evaluate(IntegerValue, MappingLine.Constant) then
                    MasterJson.Add(MappingLine."Json Tag", IntegerValue);
            MappingLine."Constant Type"::Decimal:
                if Evaluate(DecimalValue, MappingLine.Constant) then
                    MasterJson.Add(MappingLine."Json Tag", DecimalValue);
            MappingLine."Constant Type"::DateTime:
                if Evaluate(DateTimeValue, MappingLine.Constant) then
                    MasterJson.Add(MappingLine."Json Tag", DateTimeValue);
            MappingLine."Constant Type"::Date:
                if Evaluate(DateValue, MappingLine.Constant) then
                    MasterJson.Add(MappingLine."Json Tag", DateValue);
            MappingLine."Constant Type"::Time:
                if Evaluate(TimeValue, MappingLine.Constant) then
                    MasterJson.Add(MappingLine."Json Tag", TimeValue);
            MappingLine."Constant Type"::Option:
                if Evaluate(OptionValue, MappingLine.Constant) then
                    MasterJson.Add(MappingLine."Json Tag", OptionValue);
            else
                MasterJson.Add(MappingLine."Json Tag", MappingLine.Constant);
        end;
    end;

    // The value of the function is added to the Json by the subscribers of OnExecuteJsonFunction.
    local procedure ManageJsonFunction(SourceRecRef: RecordRef; MappingLine: Record "EOS IC Out. Mapping Lines"; var MasterJson: JsonObject)
    var
        IsHandled: Boolean;
        FunctionNotHandledErr: Label 'The function %1 of the line %2 of the mapping %3 is not handled. Subscribe to the event OnExecuteJsonFunction to implement it.', Comment = '%1 = function code, %2 = line no., %3 = mapping code';
    begin
        MappingLine.TestField("Function");

        OnExecuteJsonFunction(ICFlowsContext, MappingLine, SourceRecRef, MasterJson, IsHandled);

        // The example file is produced without flow, so the functions without a sample implementation are skipped.
        if not IsHandled and not SampleMode then
            Error(FunctionNotHandledErr, MappingLine."Function", MappingLine."Line No.", MappingLine."Mapping Code");
    end;

    local procedure ManageJsonField(ParentRecRef: RecordRef; MappingLine: Record "EOS IC Out. Mapping Lines"; var MasterJson: JsonObject)
    var
        FldRef: FieldRef;
    begin
        MappingLine.TestField("Table No.", ParentRecRef.Number);
        MappingLine.TestField("Field No.");
        MappingLine.TestField("Json Tag");

        FldRef := ParentRecRef.Field(MappingLine."Field No.");
        if FldRef.Class = FldRef.Class::FlowField then
            FldRef.CalcField();

        case FldRef.Type of
            FieldType::Code,
            FieldType::Text:
                AddTextField(MappingLine, ParentRecRef, FldRef, MasterJson);
            FieldType::Integer:
                AddIntegerField(MappingLine, ParentRecRef, FldRef, MasterJson);
            FieldType::Decimal:
                AddDecimalField(MappingLine, ParentRecRef, FldRef, MasterJson);
            FieldType::Option:
                AddOptionField(MappingLine, ParentRecRef, FldRef, MasterJson);
            FieldType::Boolean:
                AddBooleanField(MappingLine, ParentRecRef, FldRef, MasterJson);
            FieldType::Date:
                AddDateField(MappingLine, ParentRecRef, FldRef, MasterJson);
            FieldType::DateTime:
                AddDateTimeField(MappingLine, ParentRecRef, FldRef, MasterJson);
            FieldType::Time:
                AddTimeField(MappingLine, ParentRecRef, FldRef, MasterJson);
            else
                AddGenericField(MappingLine, ParentRecRef, FldRef, MasterJson);
        end;
    end;

    local procedure AddTextField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TextValue: Text;
        IsHandled: Boolean;
    begin
        TextValue := FldRef.Value;
        OnBeforeAddTextCode(MappingLine, ParentRecRef, FldRef, TextValue, MasterJson, IsHandled);
        if IsHandled then
            exit;

        if MappingLine."Blank as null" and (TextValue = '') then begin
            AddNull(MasterJson, MappingLine."Json Tag");
            exit;
        end;

        if MappingLine."Transformation Rule" <> '' then
            TextValue := TransformValue(MappingLine, TextValue);

        if MappingLine.Length <> 0 then
            TextValue := CopyStr(TextValue, 1, MappingLine.Length);

        if MappingLine."Encode to Base64" then
            TextValue := Base64Convert.ToBase64(TextValue, TextEncoding::UTF8);

        MasterJson.Add(MappingLine."Json Tag", TextValue);
    end;

    local procedure AddIntegerField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        IntegerValue: Integer;
        IsHandled: Boolean;
    begin
        IntegerValue := FldRef.Value;
        OnBeforeAddIntegerValue(MappingLine, ParentRecRef, FldRef, IntegerValue, MasterJson, IsHandled);
        if IsHandled then
            exit;

        if MappingLine."Blank as null" and (IntegerValue = 0) then begin
            AddNull(MasterJson, MappingLine."Json Tag");
            exit;
        end;

        if MappingLine."Transformation Rule" <> '' then
            Evaluate(IntegerValue, TransformValue(MappingLine, Format(IntegerValue, 0, 9)));

        MasterJson.Add(MappingLine."Json Tag", IntegerValue);
    end;

    local procedure AddDecimalField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        DecimalValue: Decimal;
        IsHandled: Boolean;
    begin
        DecimalValue := FldRef.Value;
        OnBeforeAddDecimalValue(MappingLine, ParentRecRef, FldRef, DecimalValue, MasterJson, IsHandled);
        if IsHandled then
            exit;

        if MappingLine."Blank as null" and (DecimalValue = 0) then begin
            AddNull(MasterJson, MappingLine."Json Tag");
            exit;
        end;

        if MappingLine."Transformation Rule" <> '' then
            Evaluate(DecimalValue, TransformValue(MappingLine, Format(DecimalValue, 0, 9)));

        MasterJson.Add(MappingLine."Json Tag", DecimalValue);
    end;

    local procedure AddOptionField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        OptionValue: Option;
        IsHandled: Boolean;
    begin
        OptionValue := FldRef.Value;
        OnBeforeAddOptionValue(MappingLine, ParentRecRef, FldRef, OptionValue, MasterJson, IsHandled);
        if IsHandled then
            exit;

        if MappingLine."Blank as null" and (OptionValue = 0) then begin
            AddNull(MasterJson, MappingLine."Json Tag");
            exit;
        end;

        if MappingLine."Transformation Rule" <> '' then
            Evaluate(OptionValue, TransformValue(MappingLine, Format(OptionValue, 0, 9)));

        MasterJson.Add(MappingLine."Json Tag", OptionValue);
    end;

    local procedure AddBooleanField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        BooleanValue: Boolean;
        IsHandled: Boolean;
    begin
        BooleanValue := FldRef.Value;
        OnBeforeAddBooleanValue(MappingLine, ParentRecRef, FldRef, BooleanValue, MasterJson, IsHandled);
        if IsHandled then
            exit;

        MasterJson.Add(MappingLine."Json Tag", BooleanValue);
    end;

    local procedure AddDateField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        DateValue: Date;
        TextValue: Text;
        IsHandled: Boolean;
    begin
        DateValue := FldRef.Value;
        OnBeforeAddDateValue(MappingLine, ParentRecRef, FldRef, DateValue, MasterJson, IsHandled);
        if IsHandled then
            exit;

        if MappingLine."Blank as null" and (DateValue = 0D) then begin
            AddNull(MasterJson, MappingLine."Json Tag");
            exit;
        end;

        if MappingLine."Transformation Rule" = '' then begin
            MasterJson.Add(MappingLine."Json Tag", DateValue);
            exit;
        end;

        TextValue := TransformValue(MappingLine, Format(DateValue, 0, 9));
        AddTextOrNull(MasterJson, MappingLine."Json Tag", TextValue);
    end;

    local procedure AddDateTimeField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        DateTimeValue: DateTime;
        TextValue: Text;
        IsHandled: Boolean;
    begin
        DateTimeValue := FldRef.Value;
        OnBeforeAddDateTimeValue(MappingLine, ParentRecRef, FldRef, DateTimeValue, MasterJson, IsHandled);
        if IsHandled then
            exit;

        if MappingLine."Blank as null" and (DateTimeValue = 0DT) then begin
            AddNull(MasterJson, MappingLine."Json Tag");
            exit;
        end;

        if MappingLine."Transformation Rule" = '' then begin
            MasterJson.Add(MappingLine."Json Tag", DateTimeValue);
            exit;
        end;

        TextValue := TransformValue(MappingLine, Format(DateTimeValue, 0, 9));
        AddTextOrNull(MasterJson, MappingLine."Json Tag", TextValue);
    end;

    local procedure AddTimeField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        TimeValue: Time;
        TextValue: Text;
        IsHandled: Boolean;
    begin
        TimeValue := FldRef.Value;
        OnBeforeAddTimeValue(MappingLine, ParentRecRef, FldRef, TimeValue, MasterJson, IsHandled);
        if IsHandled then
            exit;

        if MappingLine."Blank as null" and (TimeValue = 0T) then begin
            AddNull(MasterJson, MappingLine."Json Tag");
            exit;
        end;

        if MappingLine."Transformation Rule" = '' then begin
            MasterJson.Add(MappingLine."Json Tag", TimeValue);
            exit;
        end;

        TextValue := TransformValue(MappingLine, Format(TimeValue, 0, 9));
        AddTextOrNull(MasterJson, MappingLine."Json Tag", TextValue);
    end;

    local procedure AddGenericField(MappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject)
    var
        IsHandled: Boolean;
    begin
        OnBeforeAddGenericValue(MappingLine, ParentRecRef, FldRef, MasterJson, IsHandled);
        if IsHandled then
            exit;

        MasterJson.Add(MappingLine."Json Tag", Format(FldRef.Value, 0, 9));
    end;

    local procedure TransformValue(MappingLine: Record "EOS IC Out. Mapping Lines"; ValueText: Text): Text
    var
        TransformationRule: Record "Transformation Rule";
    begin
        TransformationRule.Get(MappingLine."Transformation Rule");
        exit(TransformationRule.TransformText(ValueText));
    end;

    local procedure AddNull(var MasterJson: JsonObject; JsonTag: Text)
    var
        NullValue: JsonValue;
    begin
        NullValue.SetValueToNull();
        MasterJson.Add(JsonTag, NullValue);
    end;

    local procedure AddTextOrNull(var MasterJson: JsonObject; JsonTag: Text; TextValue: Text)
    begin
        if TextValue = '' then
            AddNull(MasterJson, JsonTag)
        else
            MasterJson.Add(JsonTag, TextValue);
    end;
    #endregion Json

    #region Events
    [IntegrationEvent(false, false)]
    procedure OnBeforeCreateJson(ICMapping: Record "EOS IC Mapping Headers"; ICFlows: Record "EOS IC Flows"; var RecRefView: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCreateJson(MappingCode: Code[20]; SourceRecRef: RecordRef; var MasterJson: JsonObject)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnManageJsonRecordOnBeforeFindRec(var RecRef: RecordRef; ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; SourceRecRef: RecordRef; var MasterJson: JsonObject)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnJsonFunctionPopulate(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    begin
    end;

    // Subscribers add to MasterJson the value computed for ICOutMappingLine."Function" (using the parameters and the Json tag of the line) and set IsHandled.
    // ICFlows is empty when the example file is generated.
    [IntegrationEvent(false, false)]
    procedure OnExecuteJsonFunction(ICFlows: Record "EOS IC Flows"; ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; SourceRecRef: RecordRef; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddConstantValue(var ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddTextCode(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; TextValue: Text; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddIntegerValue(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; IntegerValue: Integer; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddDecimalValue(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; DecimalValue: Decimal; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddOptionValue(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; OptionValue: Option; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddBooleanValue(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; BooleanValue: Boolean; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddDateValue(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; DateValue: Date; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddDateTimeValue(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; DateTimeValue: DateTime; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddTimeValue(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; TimeValue: Time; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeAddGenericValue(ICOutMappingLine: Record "EOS IC Out. Mapping Lines"; ParentRecRef: RecordRef; FldRef: FieldRef; var MasterJson: JsonObject; var IsHandled: Boolean)
    begin
    end;
    #endregion Events
}
