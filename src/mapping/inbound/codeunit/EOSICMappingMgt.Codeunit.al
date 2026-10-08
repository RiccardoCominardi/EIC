namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;
using System.IO;

codeunit 67013 "EOS IC Mapping Mgt."
{
    var
        TempICMappingLine: Record "EOS IC Mapping Lines" temporary;
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
        ICMappingValidation: Codeunit "EOS IC Mapping Validation";
        ContextElements: Dictionary of [Text, JsonToken];
        TableContext: Dictionary of [Integer, Text];
        TablesOfContext: Dictionary of [Text, List of [Integer]];
        ChildContexts: Dictionary of [Text, List of [Text]];
        TableKeyFields: Dictionary of [Integer, List of [Integer]];
        InheritedKeyLines: Dictionary of [Integer, List of [Integer]];
        TableParents: Dictionary of [Integer, Integer];
        EntryContextTables: Dictionary of [Text, Integer];
        ContextEntryNos: Dictionary of [Text, Integer];
        CurrentMappingCode: Code[20];
        CurrentICEntryNo: Integer;

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
        TableOrder: List of [Integer];
        Issues: List of [Text];
    begin
        ICMappingValidation.CheckForExecution(MappingCode);

        ResetRunState(ICEntryNo, MappingCode);
        LoadActiveLines(MappingCode);
        ICMappingValidation.BuildTableContexts(TempICMappingLine, TableOrder, TableContext, Issues);
        BuildContextTree(TableOrder);
        BuildTableKeys(TableOrder);

        ContextElements.Set('', Payload);
        ProcessContext('');
    end;

    #region Preparation
    local procedure ResetRunState(ICEntryNo: Integer; MappingCode: Code[20])
    begin
        TempICMappingLine.Reset();
        TempICMappingLine.DeleteAll();
        Clear(ContextElements);
        Clear(TableContext);
        Clear(TablesOfContext);
        Clear(ChildContexts);
        Clear(TableKeyFields);
        Clear(InheritedKeyLines);
        Clear(TableParents);
        Clear(EntryContextTables);
        Clear(ContextEntryNos);
        CurrentMappingCode := MappingCode;
        CurrentICEntryNo := ICEntryNo;
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

    // A record is keyed by the entry number, the key fields of its ancestor tables (taken again from the key lines of the ancestors)
    // and the fields marked as key field in its own lines.
    local procedure BuildTableKeys(TableOrder: List of [Integer])
    var
        TableID: Integer;
    begin
        ICMappingValidation.BuildTableParents(TableOrder, TableContext, TableParents);
        foreach TableID in TableOrder do begin
            AddTableKeyFields(TableID);
            AddInheritedKeyLines(TableID);
            AddEntryContext(TableID);
        end;
    end;

    local procedure AddTableKeyFields(TableID: Integer)
    var
        KeyFieldNos: List of [Integer];
    begin
        ICMappingValidation.GetPrimaryKeyFields(TableID, KeyFieldNos);
        TableKeyFields.Set(TableID, KeyFieldNos);
    end;

    local procedure AddInheritedKeyLines(TableID: Integer)
    var
        LineNos: List of [Integer];
        CurrentID: Integer;
        ParentID: Integer;
    begin
        CurrentID := TableID;
        while TableParents.Get(CurrentID, ParentID) do begin
            AddKeyLineNos(ParentID, LineNos);
            CurrentID := ParentID;
        end;
        InheritedKeyLines.Set(TableID, LineNos);
    end;

    local procedure AddKeyLineNos(TableID: Integer; var LineNos: List of [Integer])
    begin
        TempICMappingLine.Reset();
        TempICMappingLine.SetRange("Target Table ID", TableID);
        TempICMappingLine.SetRange("Is Key Field", true);
        if TempICMappingLine.FindSet() then
            repeat
                LineNos.Add(TempICMappingLine."Line No.");
            until TempICMappingLine.Next() = 0;
        TempICMappingLine.Reset();
    end;

    // The first-level tables (without a parent table) share the entry number of their context; its sequence is the one of the first of them.
    local procedure AddEntryContext(TableID: Integer)
    var
        ContextPath: Text;
    begin
        if TableParents.ContainsKey(TableID) then
            exit;

        TableContext.Get(TableID, ContextPath);
        if not EntryContextTables.ContainsKey(ContextPath) then
            EntryContextTables.Add(ContextPath, TableID);
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
        AssignEntryNo(ContextPath);

        if TablesOfContext.Get(ContextPath, TableIDs) then
            foreach TableID in TableIDs do
                InsertRecord(TableID);

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
    local procedure InsertRecord(TableID: Integer)
    var
        RecRef: RecordRef;
        KeyFieldNos: List of [Integer];
    begin
        RecRef.Open(TableID);
        RecRef.Init();
        ApplyLines(TableID, RecRef);
        ApplyInheritedKeys(TableID, RecRef);
        CheckKeyValues(TableID, RecRef);

        // The entry number and the IC entry number are set after the mapping so that they cannot be overwritten by it.
        TableKeyFields.Get(TableID, KeyFieldNos);
        RecRef.Field(KeyFieldNos.Get(1)).Value := GetEntryNo(TableID);
        if not TableParents.ContainsKey(TableID) then
            RecRef.Field(ICMappingValidation.GetICEntryNoFieldNo(TableID)).Value := CurrentICEntryNo;
        RecRef.Insert(true);
        RecRef.Close();
    end;

    // Every element of the context of the first-level tables gets a new entry number.
    local procedure AssignEntryNo(ContextPath: Text)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        TableID: Integer;
        EntryNo: Integer;
    begin
        if not EntryContextTables.Get(ContextPath, TableID) then
            exit;

        EntryNo := SequenceNoMgt.GetNextSeqNo(TableID);
        ContextEntryNos.Set(ContextPath, EntryNo);
    end;

    // The entry number is the one of the nearest enclosing context of a first-level table, which is the context of the table itself for those.
    local procedure GetEntryNo(TableID: Integer): Integer
    var
        Chain: List of [Text];
        ContextPath: Text;
        EntryNo: Integer;
        Index: Integer;
    begin
        TableContext.Get(TableID, ContextPath);
        ICJsonPathMgt.GetContextChain(ContextPath, Chain);
        for Index := Chain.Count() downto 1 do
            if ContextEntryNos.Get(Chain.Get(Index), EntryNo) then
                exit(EntryNo);

        ContextEntryNos.Get('', EntryNo);
        exit(EntryNo);
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

    // The key fields of the ancestors are in the same position of the key of this table: the line of the ancestor is applied to that field.
    local procedure ApplyInheritedKeys(TableID: Integer; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        KeyFieldNos: List of [Integer];
        AncestorKeyFieldNos: List of [Integer];
        LineNos: List of [Integer];
        LineNo: Integer;
    begin
        if not InheritedKeyLines.Get(TableID, LineNos) then
            exit;

        TableKeyFields.Get(TableID, KeyFieldNos);
        TempICMappingLine.Reset();
        foreach LineNo in LineNos do begin
            TempICMappingLine.Get(CurrentMappingCode, LineNo);
            TableKeyFields.Get(TempICMappingLine."Target Table ID", AncestorKeyFieldNos);
            FieldRef := RecRef.Field(KeyFieldNos.Get(AncestorKeyFieldNos.IndexOf(TempICMappingLine."Target Field No.")));
            ApplyLine(TempICMappingLine, FieldRef);
        end;
    end;

    // The entry number (first key field) is assigned later: every other key field must have a value, otherwise the records would collide.
    local procedure CheckKeyValues(TableID: Integer; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        KeyFieldNos: List of [Integer];
        Index: Integer;
        ContextPath: Text;
        BlankKeyErr: Label 'The key field %1 of the table %2 has no value in the payload (array %3). Check the mapping.', Comment = '%1 = field caption, %2 = table caption, %3 = Json path of the array';
    begin
        TableKeyFields.Get(TableID, KeyFieldNos);
        TableContext.Get(TableID, ContextPath);
        for Index := 2 to KeyFieldNos.Count() do begin
            FieldRef := RecRef.Field(KeyFieldNos.Get(Index));
            if IsBlankValue(FieldRef) then
                Error(BlankKeyErr, FieldRef.Caption, RecRef.Caption, ContextPath);
        end;
    end;

    local procedure IsBlankValue(FieldRef: FieldRef): Boolean
    var
        GuidValue: Guid;
    begin
        case FieldRef.Type of
            FieldType::Integer, FieldType::BigInteger, FieldType::Decimal:
                exit(Format(FieldRef.Value, 0, 9) in ['', '0']);
            FieldType::Guid:
                begin
                    GuidValue := FieldRef.Value;
                    exit(IsNullGuid(GuidValue));
                end;
            else
                exit(Format(FieldRef.Value, 0, 9) = '');
        end;
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
    #endregion Records

    // ContextElement is the element of the payload the record is created from (the payload itself for records at the root).
    [IntegrationEvent(false, false)]
    procedure OnTransformValue(ICMappingLine: Record "EOS IC Mapping Lines"; ContextElement: JsonToken; CurrentValue: Text; var Result: Text; var Handled: Boolean)
    begin
    end;
}
