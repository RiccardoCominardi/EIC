namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;
using System.IO;

codeunit 67013 "EOS IC Mapping Mgt."
{
    var
        TempICMappingLine: Record "EOS IC Mapping Lines" temporary;
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
        ContextElements: Dictionary of [Text, JsonToken];
        TableContext: Dictionary of [Integer, Text];
        TablesOfContext: Dictionary of [Text, List of [Integer]];
        ChildContexts: Dictionary of [Text, List of [Text]];
        LineCounters: Dictionary of [Integer, Integer];
        CurrentICEntryNo: Integer;
        StagingEntryNo: Integer;

    procedure PopulateFromPayload(ICEntries: Record "EOS IC Entries")
    var
        Payload: JsonToken;
        InvalidPayloadErr: Label 'The received payload of the entry %1 is not a valid Json.', Comment = '%1 = entry no.';
    begin
        if not Payload.ReadFrom(ICEntries.GetBlobFields(ICEntries.FieldNo("Received Payload"))) then
            Error(InvalidPayloadErr, ICEntries."Entry No.");
        PopulateFromToken(ICEntries, Payload);
    end;

    procedure PopulateFromToken(ICEntries: Record "EOS IC Entries"; Payload: JsonToken)
    var
        ICFlows: Record "EOS IC Flows";
        ICMapping: Record "EOS IC Mapping Headers";
        FlowNotFoundErr: Label 'The flow %1 of the company %2 does not exist.', Comment = '%1 = flow code, %2 = company code';
        MappingNotAssignedErr: Label 'No mapping has been assigned to the flow %1 of the company %2.', Comment = '%1 = flow code, %2 = company code';
        MappingNotEnabledErr: Label 'The mapping %1 assigned to the flow %2 of the company %3 is not enabled.', Comment = '%1 = mapping code, %2 = flow code, %3 = company code';
    begin
        if not ICFlows.Get(ICEntries."Source Company", ICEntries."IC Flow Code") then
            Error(FlowNotFoundErr, ICEntries."IC Flow Code", ICEntries."Source Company");
        if ICFlows."Mapping Code" = '' then
            Error(MappingNotAssignedErr, ICFlows.Code, ICFlows."Company Code");

        ICMapping.Get(ICFlows."Mapping Code");
        if not ICMapping.Enabled then
            Error(MappingNotEnabledErr, ICMapping.Code, ICFlows.Code, ICFlows."Company Code");

        PopulateFromMapping(ICEntries."Entry No.", ICMapping.Code, Payload);
    end;

    // Creates the target records described by the mapping for the given payload. The payload can have any structure:
    // each target table gets one record for every element of the innermost array crossed by its paths.
    procedure PopulateFromMapping(ICEntryNo: Integer; MappingCode: Code[20]; Payload: JsonToken)
    var
        ICMappingValidation: Codeunit "EOS IC Mapping Validation";
        TableOrder: List of [Integer];
        Issues: List of [Text];
    begin
        ICMappingValidation.CheckForExecution(MappingCode);

        ResetRunState(ICEntryNo);
        LoadActiveLines(MappingCode);
        ICMappingValidation.BuildTableContexts(TempICMappingLine, TableOrder, TableContext, Issues);
        BuildContextTree(TableOrder);
        StagingEntryNo := GetStagingEntryNo(ICEntryNo, TableOrder);

        ContextElements.Set('', Payload);
        ProcessContext('');
    end;

    #region Preparation
    local procedure ResetRunState(ICEntryNo: Integer)
    begin
        TempICMappingLine.Reset();
        TempICMappingLine.DeleteAll();
        Clear(ContextElements);
        Clear(TableContext);
        Clear(TablesOfContext);
        Clear(ChildContexts);
        Clear(LineCounters);
        CurrentICEntryNo := ICEntryNo;
        StagingEntryNo := 0;
    end;

    // Lines without a target table or field are ignored, as in the previous versions.
    local procedure LoadActiveLines(MappingCode: Code[20])
    var
        ICMappingLine: Record "EOS IC Mapping Lines";
    begin
        ICMappingLine.SetRange("Mapping Code", MappingCode);
        ICMappingLine.SetFilter("Target Table ID", '<>0');
        ICMappingLine.SetFilter("Target Field No.", '<>0');
        if ICMappingLine.FindSet() then
            repeat
                TempICMappingLine := ICMappingLine;
                TempICMappingLine.Insert();
            until ICMappingLine.Next() = 0;
    end;

    // Builds the tree of the array contexts to be iterated: every context is a child of the enclosing array context.
    local procedure BuildContextTree(TableOrder: List of [Integer])
    var
        TableIDs: List of [Integer];
        Chain: List of [Text];
        TableID: Integer;
        ContextPath: Text;
        ChainContext: Text;
        ParentContext: Text;
    begin
        foreach TableID in TableOrder do begin
            TableContext.Get(TableID, ContextPath);

            Clear(TableIDs);
            if TablesOfContext.Get(ContextPath, TableIDs) then;
            TableIDs.Add(TableID);
            TablesOfContext.Set(ContextPath, TableIDs);

            ICJsonPathMgt.GetContextChain(ContextPath, Chain);
            ParentContext := '';
            foreach ChainContext in Chain do begin
                AddChildContext(ParentContext, ChainContext);
                ParentContext := ChainContext;
            end;
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

    // Records are linked through the number of the first record created at the root of the payload; without it the IC entry number is used.
    local procedure GetStagingEntryNo(ICEntryNo: Integer; TableOrder: List of [Integer]): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        TableID: Integer;
        ContextPath: Text;
    begin
        foreach TableID in TableOrder do begin
            TableContext.Get(TableID, ContextPath);
            if ContextPath = '' then
                exit(SequenceNoMgt.GetNextSeqNo(TableID));
        end;
        exit(ICEntryNo);
    end;
    #endregion Preparation

    #region Navigation
    // ContextElements holds the current element of every array level being processed, so a path always
    // resolves against the right element of each enclosing array.
    local procedure ProcessContext(ContextPath: Text)
    var
        TableIDs: List of [Integer];
        ChildPaths: List of [Text];
        TableID: Integer;
        ChildPath: Text;
    begin
        if TablesOfContext.Get(ContextPath, TableIDs) then
            foreach TableID in TableIDs do
                InsertRecord(TableID, ContextPath = '');

        if ChildContexts.Get(ContextPath, ChildPaths) then
            foreach ChildPath in ChildPaths do
                IterateContext(ContextPath, ChildPath);
    end;

    local procedure IterateContext(ParentContext: Text; ChildContext: Text)
    var
        ParentSteps: List of [Text];
        ChildSteps: List of [Text];
        ParentElement: JsonToken;
        Container: JsonToken;
        Element: JsonToken;
        ArrayExpectedErr: Label 'The node %1 of the payload is expected to be an array.', Comment = '%1 = Json path of the array';
    begin
        if not ContextElements.Get(ParentContext, ParentElement) then
            exit;

        ICJsonPathMgt.ParseContext(ParentContext, ParentSteps);
        ICJsonPathMgt.ParseContext(ChildContext, ChildSteps);

        // Between the enclosing array level and the last array marker of the child there are only properties.
        if not ICJsonPathMgt.NavigateProperties(ParentElement, ChildSteps, ParentSteps.Count() + 1, ChildSteps.Count() - 1, Container) then
            exit;

        if Container.IsValue() then
            if Container.AsValue().IsNull() then
                exit;
        if not Container.IsArray() then
            Error(ArrayExpectedErr, ChildContext);

        foreach Element in Container.AsArray() do begin
            ContextElements.Set(ChildContext, Element);
            ProcessContext(ChildContext);
        end;
        ContextElements.Remove(ChildContext);
    end;

    local procedure ResolveToken(Path: Text; var Result: JsonToken): Boolean
    var
        Steps: List of [Text];
        ErrorText: Text;
        ContextPath: Text;
        LastArrayStep: Integer;
        ContextElement: JsonToken;
    begin
        if not ICJsonPathMgt.ParsePath(Path, Steps, ErrorText) then
            exit(false);

        LastArrayStep := ICJsonPathMgt.GetLastArrayStep(Steps);
        ContextPath := ICJsonPathMgt.SerializeSteps(Steps, LastArrayStep);
        if not ContextElements.Get(ContextPath, ContextElement) then
            exit(false);
        exit(ICJsonPathMgt.NavigateProperties(ContextElement, Steps, LastArrayStep + 1, Steps.Count(), Result));
    end;

    local procedure ResolveValue(Path: Text; var Result: JsonValue): Boolean
    var
        ResultToken: JsonToken;
    begin
        if not ResolveToken(Path, ResultToken) then
            exit(false);
        if not ResultToken.IsValue() then
            exit(false);

        Result := ResultToken.AsValue();
        exit(not Result.IsNull());
    end;

    local procedure GetTableElement(TableID: Integer; var Element: JsonToken)
    var
        ContextPath: Text;
    begin
        TableContext.Get(TableID, ContextPath);
        ContextElements.Get(ContextPath, Element);
    end;
    #endregion Navigation

    #region Records
    local procedure InsertRecord(TableID: Integer; IsRootRecord: Boolean)
    var
        RecRef: RecordRef;
        SecondFieldRef: FieldRef;
        LineNo: Integer;
    begin
        RecRef.Open(TableID);
        RecRef.Init();
        ApplyLines(TableID, RecRef);

        // Key fields are set after the mapping so that they cannot be overwritten by it.
        RecRef.Field(EntryNoFieldNo()).Value := StagingEntryNo;
        SecondFieldRef := RecRef.Field(SecondFieldNo());
        if IsRootRecord then
            SecondFieldRef.Value := CurrentICEntryNo
        else begin
            // The line number comes from the mapping when available, otherwise it is generated.
            LineNo := SecondFieldRef.Value;
            if LineNo = 0 then
                SecondFieldRef.Value := GetNextLineNo(TableID);
        end;
        RecRef.Insert(true);
        RecRef.Close();
    end;

    local procedure ApplyLines(TableID: Integer; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        TempICMappingLine.Reset();
        TempICMappingLine.SetRange("Target Table ID", TableID);
        if not TempICMappingLine.FindSet() then
            exit;

        repeat
            FieldRef := RecRef.Field(TempICMappingLine."Target Field No.");
            ApplyLine(TempICMappingLine, FieldRef);
        until TempICMappingLine.Next() = 0;
    end;

    local procedure ApplyLine(ICMappingLine: Record "EOS IC Mapping Lines"; var FieldRef: FieldRef)
    var
        JsonValue: JsonValue;
        ContextElement: JsonToken;
        CurrentValue: Text;
        Result: Text;
        Handled: Boolean;
    begin
        case ICMappingLine."Mapping Type" of
            ICMappingLine."Mapping Type"::Value:
                if ICMappingLine."Json Path" <> '' then
                    if ResolveValue(ICMappingLine."Json Path", JsonValue) then
                        if (ICMappingLine."Source Value" <> '') and (JsonValue.AsText() = ICMappingLine."Source Value") then
                            SetFieldText(FieldRef, ICMappingLine."Target Value")
                        else
                            SetFieldValue(FieldRef, JsonValue);
            ICMappingLine."Mapping Type"::Constant:
                SetFieldText(FieldRef, ICMappingLine."Target Value");
            ICMappingLine."Mapping Type"::Transformation:
                begin
                    if ICMappingLine."Json Path" <> '' then
                        if ResolveValue(ICMappingLine."Json Path", JsonValue) then
                            CurrentValue := JsonValue.AsText();
                    GetTableElement(ICMappingLine."Target Table ID", ContextElement);
                    OnTransformValue(ICMappingLine, ContextElement, CurrentValue, Result, Handled);
                    if Handled then
                        SetFieldText(FieldRef, Result);
                end;
        end;
    end;

    local procedure SetFieldValue(var FieldRef: FieldRef; JsonValue: JsonValue)
    begin
        case FieldRef.Type of
            FieldType::Integer:
                FieldRef.Value := JsonValue.AsInteger();
            FieldType::BigInteger:
                FieldRef.Value := JsonValue.AsBigInteger();
            FieldType::Decimal:
                FieldRef.Value := JsonValue.AsDecimal();
            FieldType::Boolean:
                FieldRef.Value := JsonValue.AsBoolean();
            else
                SetFieldText(FieldRef, JsonValue.AsText());
        end;
    end;

    // Blank text leaves the field untouched; text longer than the field is truncated.
    local procedure SetFieldText(var FieldRef: FieldRef; ValueText: Text)
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ErrorText: Text;
        InvalidValueErr: Label 'The value cannot be mapped to the field %1 of the table %2. %3', Comment = '%1 = field caption, %2 = table caption, %3 = error detail';
    begin
        if ValueText = '' then
            exit;

        if FieldRef.Type in [FieldType::Text, FieldType::Code] then
            ValueText := CopyStr(ValueText, 1, FieldRef.Length);

        ErrorText := ConfigValidateMgt.EvaluateValue(FieldRef, ValueText, false);
        if ErrorText <> '' then
            Error(InvalidValueErr, FieldRef.Caption, FieldRef.Record().Caption, ErrorText);
    end;

    local procedure GetNextLineNo(TableID: Integer): Integer
    var
        LastLineNo: Integer;
    begin
        if LineCounters.Get(TableID, LastLineNo) then;
        LastLineNo += 10000;
        LineCounters.Set(TableID, LastLineNo);
        exit(LastLineNo);
    end;

    // Target tables share the key layout: field 1 is the entry number; field 2 is the IC entry number (root record) or the line number.
    local procedure EntryNoFieldNo(): Integer
    begin
        exit(1);
    end;

    local procedure SecondFieldNo(): Integer
    begin
        exit(2);
    end;
    #endregion Records

    // ContextElement is the element of the payload the record is created from (the payload itself for records at the root).
    [IntegrationEvent(false, false)]
    procedure OnTransformValue(ICMappingLine: Record "EOS IC Mapping Lines"; ContextElement: JsonToken; CurrentValue: Text; var Result: Text; var Handled: Boolean)
    begin
    end;
}
