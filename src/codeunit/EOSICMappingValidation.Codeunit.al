namespace EOS.Solutions.Intercompany;

using System.Reflection;

codeunit 67015 "EOS IC Mapping Validation"
{
    var
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";

    // Checks the configuration of a mapping. When ForExecution is true only the problems that would break the execution are reported
    // and lines without a target are ignored (as the engine does); otherwise incomplete lines are reported too.
    // CheckSample verifies that the paths exist in the imported sample Json, when there is one.
    procedure ValidateMapping(MappingCode: Code[20]; ForExecution: Boolean; CheckSample: Boolean; var Issues: List of [Text]): Boolean
    var
        ICMapping: Record "EOS IC Mapping Headers";
        ICMappingLine: Record "EOS IC Mapping Lines";
        TempICMappingLine: Record "EOS IC Mapping Lines" temporary;
        SamplePaths: List of [Text];
        PathLines: Dictionary of [Text, Integer];
        CheckedTables: List of [Integer];
        TableOrder: List of [Integer];
        TableContext: Dictionary of [Integer, Text];
        PathIssues: Dictionary of [Text, Text];
        PathIssueOrder: List of [Text];
        HasSample: Boolean;
        MappingNotFoundErr: Label 'The mapping %1 does not exist.', Comment = '%1 = mapping code';
        NoLinesErr: Label 'The mapping has no lines.';
        NoActiveLinesErr: Label 'The mapping has no line with a target table and a target field.';
    begin
        Clear(Issues);
        Clear(PathIssues);
        Clear(PathIssueOrder);

        if not ICMapping.Get(MappingCode) then begin
            Issues.Add(StrSubstNo(MappingNotFoundErr, MappingCode));
            exit(false);
        end;

        ICMappingLine.SetRange("Mapping Code", MappingCode);
        if not ICMappingLine.FindSet() then begin
            Issues.Add(NoLinesErr);
            exit(false);
        end;

        if CheckSample and not ForExecution then
            HasSample := LoadSamplePaths(MappingCode, SamplePaths);

        repeat
            ValidateLine(ICMappingLine, ForExecution, HasSample, SamplePaths, CheckedTables, TempICMappingLine, PathIssues, PathIssueOrder);
            if not ForExecution then
                CheckDuplicatedPath(ICMappingLine, PathLines, PathIssues, PathIssueOrder);
        until ICMappingLine.Next() = 0;

        if TempICMappingLine.IsEmpty() then
            Issues.Add(NoActiveLinesErr)
        else begin
            BuildTableContextsInternal(TempICMappingLine, TableOrder, TableContext, PathIssues, PathIssueOrder);
            ValidateReservedFields(TempICMappingLine, TableContext, PathIssues, PathIssueOrder);
        end;

        AppendPathIssues(Issues, PathIssues, PathIssueOrder);
        exit(Issues.Count() = 0);
    end;

    procedure CheckForExecution(MappingCode: Code[20])
    var
        Issues: List of [Text];
        NotValidErr: Label 'The mapping %1 is not valid:\%2', Comment = '%1 = mapping code, %2 = list of problems';
    begin
        if not ValidateMapping(MappingCode, true, false, Issues) then
            Error(NotValidErr, MappingCode, GetIssuesText(Issues));
    end;

    procedure CheckForActivation(MappingCode: Code[20])
    var
        Issues: List of [Text];
        NotValidErr: Label 'The mapping %1 cannot be enabled because it is not valid:\%2', Comment = '%1 = mapping code, %2 = list of problems';
    begin
        if not ValidateMapping(MappingCode, false, true, Issues) then
            Error(NotValidErr, MappingCode, GetIssuesText(Issues));
    end;

    procedure ValidateAndShowResult(MappingCode: Code[20])
    var
        Issues: List of [Text];
        ValidMsg: Label 'The mapping %1 is valid.', Comment = '%1 = mapping code';
        NotValidMsg: Label 'The mapping %1 is not valid:\%2', Comment = '%1 = mapping code, %2 = list of problems';
    begin
        if ValidateMapping(MappingCode, false, true, Issues) then
            Message(ValidMsg, MappingCode)
        else
            Message(NotValidMsg, MappingCode, GetIssuesText(Issues));
    end;

    procedure GetIssuesText(Issues: List of [Text]): Text
    var
        Result: TextBuilder;
        Issue: Text;
    begin
        foreach Issue in Issues do
            Result.AppendLine(Issue);
        exit(Result.ToText());
    end;

    // Determines the array context of each target table: the innermost array crossed by its paths. All the paths of a table
    // must lie on the same branch of the Json, otherwise elements of different branches would be mixed in the same record.
    procedure BuildTableContexts(var ICMappingLine: Record "EOS IC Mapping Lines"; var TableOrder: List of [Integer]; var TableContext: Dictionary of [Integer, Text]; var Issues: List of [Text])
    var
        PathIssues: Dictionary of [Text, Text];
        PathIssueOrder: List of [Text];
    begin
        Clear(PathIssues);
        Clear(PathIssueOrder);
        BuildTableContextsInternal(ICMappingLine, TableOrder, TableContext, PathIssues, PathIssueOrder);
        AppendPathIssues(Issues, PathIssues, PathIssueOrder);
    end;

    local procedure BuildTableContextsInternal(var ICMappingLine: Record "EOS IC Mapping Lines"; var TableOrder: List of [Integer]; var TableContext: Dictionary of [Integer, Text]; var PathIssues: Dictionary of [Text, Text]; var PathIssueOrder: List of [Text])
    var
        LineContext: Text;
        CurrentContext: Text;
        LineChain: List of [Text];
        CurrentChain: List of [Text];
        BranchConflictErr: Label 'The path %1 belongs to a different array branch than the other paths of the table %2 (%3).', Comment = '%1 = path, %2 = table, %3 = array context of the table';
    begin
        Clear(TableOrder);
        Clear(TableContext);

        ICMappingLine.Reset();
        ICMappingLine.SetCurrentKey("Mapping Code", "Line No.");
        if not ICMappingLine.FindSet() then
            exit;

        repeat
            if not TableContext.ContainsKey(ICMappingLine."Target Table ID") then begin
                TableOrder.Add(ICMappingLine."Target Table ID");
                TableContext.Add(ICMappingLine."Target Table ID", '');
            end;

            LineContext := ICJsonPathMgt.GetArrayContext(ICMappingLine."Json Path");
            if LineContext <> '' then begin
                TableContext.Get(ICMappingLine."Target Table ID", CurrentContext);
                ICJsonPathMgt.GetContextChain(LineContext, LineChain);
                ICJsonPathMgt.GetContextChain(CurrentContext, CurrentChain);
                if (CurrentContext = '') or LineChain.Contains(CurrentContext) then
                    TableContext.Set(ICMappingLine."Target Table ID", LineContext)
                else
                    if not CurrentChain.Contains(LineContext) then
                        AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path",
                            StrSubstNo(BranchConflictErr, ICMappingLine."Json Path", GetTableText(ICMappingLine."Target Table ID"), CurrentContext));
            end;
        until ICMappingLine.Next() = 0;
    end;

    // Each Json path can be used by one line only; at execution the engine does not need this rule.
    local procedure CheckDuplicatedPath(ICMappingLine: Record "EOS IC Mapping Lines"; var PathLines: Dictionary of [Text, Integer]; var PathIssues: Dictionary of [Text, Text]; var PathIssueOrder: List of [Text])
    var
        FirstLineNo: Integer;
        PathKey: Text;
        DuplicatedPathErr: Label 'The Json path %1 is already used by the line %2.', Comment = '%1 = Json path, %2 = line no.';
    begin
        if (ICMappingLine."Json Path" = '') or
            (ICMappingLine."Is Structure" and (ICMappingLine."Target Table ID" = 0) and (ICMappingLine."Target Field No." = 0))
        then
            exit;

        PathKey := LowerCase(ICMappingLine."Json Path");
        if PathLines.Get(PathKey, FirstLineNo) then
            AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", StrSubstNo(DuplicatedPathErr, ICMappingLine."Json Path", FirstLineNo))
        else
            PathLines.Add(PathKey, ICMappingLine."Line No.");
    end;

    local procedure ValidateLine(ICMappingLine: Record "EOS IC Mapping Lines"; ForExecution: Boolean; HasSample: Boolean; SamplePaths: List of [Text]; var CheckedTables: List of [Integer]; var TempICMappingLine: Record "EOS IC Mapping Lines" temporary; var PathIssues: Dictionary of [Text, Text]; var PathIssueOrder: List of [Text])
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Field: Record Field;
        Steps: List of [Text];
        ErrorText: Text;
        PathIsValid: Boolean;
        TableExists: Boolean;
        MissingTableErr: Label 'The target table is missing.';
        TableNotFoundErr: Label 'The target table %1 does not exist.', Comment = '%1 = table id';
        MissingFieldErr: Label 'The target field is missing.';
        FieldNotFoundErr: Label 'The field %1 does not exist in the table %2.', Comment = '%1 = field no., %2 = table';
        FieldNotSupportedErr: Label 'The field %1 of the table %2 cannot be mapped because it is not a normal field.', Comment = '%1 = field no., %2 = table';
        InvalidPathErr: Label 'The Json path %1 is not valid. %2', Comment = '%1 = path, %2 = error detail';
        NodeNotFoundErr: Label 'The Json path %1 does not exist in the sample Json.', Comment = '%1 = path';
        PathRequiredErr: Label 'The Json path is required for the mapping type Value.';
        ConstantRequiredErr: Label 'The target value is required for the mapping type Constant.';
    begin
        if ICMappingLine."Is Structure" and (ICMappingLine."Target Table ID" = 0) and (ICMappingLine."Target Field No." = 0) then
            exit;

        if ForExecution and ((ICMappingLine."Target Table ID" = 0) or (ICMappingLine."Target Field No." = 0)) then
            exit;

        if ICMappingLine."Target Table ID" = 0 then
            AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", MissingTableErr)
        else
            if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, ICMappingLine."Target Table ID") then
                AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", StrSubstNo(TableNotFoundErr, ICMappingLine."Target Table ID"))
            else begin
                TableExists := true;
                CheckTableStructure(ICMappingLine, CheckedTables, PathIssues, PathIssueOrder);
                if ICMappingLine."Target Field No." <> 0 then
                    if not Field.Get(ICMappingLine."Target Table ID", ICMappingLine."Target Field No.") then
                        AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", StrSubstNo(FieldNotFoundErr, ICMappingLine."Target Field No.", GetTableText(ICMappingLine."Target Table ID")))
                    else
                        if Field.Class <> Field.Class::Normal then
                            AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", StrSubstNo(FieldNotSupportedErr, ICMappingLine."Target Field No.", GetTableText(ICMappingLine."Target Table ID")));
            end;

        if ICMappingLine."Target Field No." = 0 then
            AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", MissingFieldErr);

        if ICMappingLine."Json Path" <> '' then
            if not ICJsonPathMgt.ParsePath(ICMappingLine."Json Path", Steps, ErrorText) then
                AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", StrSubstNo(InvalidPathErr, ICMappingLine."Json Path", ErrorText))
            else begin
                PathIsValid := true;
                if HasSample then
                    if not SamplePaths.Contains(ICJsonPathMgt.SerializeSteps(Steps, Steps.Count())) then
                        AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", StrSubstNo(NodeNotFoundErr, ICMappingLine."Json Path"));
            end;

        if not ForExecution then
            case ICMappingLine."Mapping Type" of
                ICMappingLine."Mapping Type"::Value:
                    if ICMappingLine."Json Path" = '' then
                        AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", PathRequiredErr);
                ICMappingLine."Mapping Type"::Constant:
                    if ICMappingLine."Target Value" = '' then
                        AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", ConstantRequiredErr);
            end;

        if TableExists and ((ICMappingLine."Json Path" = '') or PathIsValid) then begin
            TempICMappingLine := ICMappingLine;
            TempICMappingLine.Insert();
        end;
    end;

    // Staging tables share the key layout: field 1 is the entry number and field 2 the IC entry number (root) or the line number.
    local procedure CheckTableStructure(ICMappingLine: Record "EOS IC Mapping Lines"; var CheckedTables: List of [Integer]; var PathIssues: Dictionary of [Text, Text]; var PathIssueOrder: List of [Text])
    var
        Field: Record Field;
        StructureErr: Label 'The table %1 cannot be used as a target: the fields 1 and 2 must be Integer fields (entry number and IC entry number / line number).', Comment = '%1 = table';
    begin
        if CheckedTables.Contains(ICMappingLine."Target Table ID") then
            exit;
        CheckedTables.Add(ICMappingLine."Target Table ID");

        if not Field.Get(ICMappingLine."Target Table ID", 1) or (Field.Type <> Field.Type::Integer) or
           not Field.Get(ICMappingLine."Target Table ID", 2) or (Field.Type <> Field.Type::Integer)
        then
            AddPathIssue(PathIssues, PathIssueOrder, ICMappingLine."Json Path", StrSubstNo(StructureErr, GetTableText(ICMappingLine."Target Table ID")));
    end;

    local procedure ValidateReservedFields(var TempICMappingLine: Record "EOS IC Mapping Lines" temporary; TableContext: Dictionary of [Integer, Text]; var PathIssues: Dictionary of [Text, Text]; var PathIssueOrder: List of [Text])
    var
        ReservedFieldErr: Label 'The field %1 of the table %2 is filled in automatically and cannot be mapped.', Comment = '%1 = field no., %2 = table';
        TableContextText: Text;
    begin
        TempICMappingLine.Reset();
        if not TempICMappingLine.FindSet() then
            exit;

        repeat
            TableContext.Get(TempICMappingLine."Target Table ID", TableContextText);
            if (TempICMappingLine."Target Field No." = 1) or ((TempICMappingLine."Target Field No." = 2) and (TableContextText = '')) then
                AddPathIssue(PathIssues, PathIssueOrder, TempICMappingLine."Json Path", StrSubstNo(ReservedFieldErr, TempICMappingLine."Target Field No.", GetTableText(TempICMappingLine."Target Table ID")));
        until TempICMappingLine.Next() = 0;
    end;

    local procedure LoadSamplePaths(MappingCode: Code[20]; var SamplePaths: List of [Text]): Boolean
    var
        ICMappingJsonNode: Record "EOS IC Mapping Json Node";
    begin
        ICMappingJsonNode.SetRange("Mapping Code", MappingCode);
        if ICMappingJsonNode.FindSet() then
            repeat
                SamplePaths.Add(ICMappingJsonNode.Path);
            until ICMappingJsonNode.Next() = 0;
        exit(SamplePaths.Count() > 0);
    end;

    local procedure GetTableText(TableID: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TableTextLbl: Label '%1 %2', Locked = true, Comment = '%1 = table id, %2 = table name';
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableID) then
            exit(StrSubstNo(TableTextLbl, TableID, AllObjWithCaption."Object Name"));
        exit(Format(TableID));
    end;

    local procedure AddPathIssue(var PathIssues: Dictionary of [Text, Text]; var PathIssueOrder: List of [Text]; JsonPath: Text; ErrorText: Text)
    var
        CombinedErrors: Text;
    begin
        if PathIssues.Get(JsonPath, CombinedErrors) then
            PathIssues.Set(JsonPath, CombinedErrors + ' ' + ErrorText)
        else begin
            PathIssues.Add(JsonPath, ErrorText);
            PathIssueOrder.Add(JsonPath);
        end;
    end;

    local procedure AppendPathIssues(var Issues: List of [Text]; PathIssues: Dictionary of [Text, Text]; PathIssueOrder: List of [Text])
    var
        JsonPath: Text;
        CombinedErrors: Text;
    begin
        foreach JsonPath in PathIssueOrder do begin
            PathIssues.Get(JsonPath, CombinedErrors);
            Issues.Add(PathIssue(JsonPath, CombinedErrors));
        end;
    end;

    local procedure PathIssue(JsonPath: Text; ErrorText: Text): Text
    var
        PathIssueLbl: Label 'Path: %1: %2', Comment = '%1 = Json path, %2 = problem';
        MissingPathIssueLbl: Label 'Path: (not specified): %1', Comment = '%1 = problem';
    begin
        if JsonPath = '' then
            exit(StrSubstNo(MissingPathIssueLbl, ErrorText));
        exit(StrSubstNo(PathIssueLbl, JsonPath, ErrorText));
    end;
}
