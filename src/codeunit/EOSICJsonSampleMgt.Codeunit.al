namespace EOS.Solutions.Intercompany;

using System.Utilities;

codeunit 67016 "EOS IC Json Sample Mgt."
{
    var
        TempJsonNode: Record "EOS IC Mapping Json Node" temporary;
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
        NodeIndex: Dictionary of [Text, Integer];
        CurrentMappingCode: Code[20];
        NextEntryNo: Integer;

    procedure ImportSample(var ICMapping: Record "EOS IC Mapping Headers")
    var
        ICMappingLines: Record "EOS IC Mapping Lines";
        SampleJsonBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        Root: JsonToken;
        FileName: Text;
        NodeCount: Integer;
        DialogTitleLbl: Label 'Import Json';
        FileFilterLbl: Label 'Json files (*.Json)|*.Json|All files (*.*)|*.*', Locked = true;
        RecreateQst: Label 'All the lines of the mapping %1 will be deleted and created again from the Json, so the configuration of the existing lines will be lost. Do you want to continue?', Comment = '%1 = mapping code';
        ImportedMsg: Label 'The Json structure has been imported (%1 nodes). %2 lines have been created in the mapping %3: select the target table and field of each line to complete the configuration.', Comment = '%1 = number of nodes, %2 = number of lines created, %3 = mapping code';
    begin
        ICMapping.TestField(Code);
        if not UploadIntoStream(DialogTitleLbl, '', FileFilterLbl, FileName, InStr) then
            exit;
        SampleJsonBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        SampleJsonBlob.CreateInStream(InStr);
        ReadJsonStream(InStr, Root);

        ICMappingLines.SetRange("Mapping Code", ICMapping.Code);
        if not ICMappingLines.IsEmpty() then
            if not Confirm(RecreateQst, false, ICMapping.Code) then
                exit;

        NodeCount := ImportSampleFromTokenAndBlob(ICMapping, Root, FileName, SampleJsonBlob);
        Message(ImportedMsg, NodeCount, ICMappingLines.Count(), ICMapping.Code);
    end;

    procedure ExportSampleJson(ICMapping: Record "EOS IC Mapping Headers")
    var
        InStr: InStream;
        FileName: Text;
        DialogTitleLbl: Label 'Export Json';
        MissingJsonErr: Label 'The original Json content is not available for mapping %1. Import the Json again to enable export.', Comment = '%1 = mapping code';
        ExtensionLbl: Label '%1.Json', Locked = true;
    begin
        ICMapping.TestField(Code);
        ICMapping.CalcFields("Json Content");
        if not ICMapping."Json Content".HasValue() then
            Error(MissingJsonErr, ICMapping.Code);

        ICMapping."Json Content".CreateInStream(InStr);
        FileName := ICMapping."Json File Name";
        if FileName = '' then
            FileName := StrSubstNo(ExtensionLbl, ICMapping.Code);
        DownloadFromStream(InStr, DialogTitleLbl, '', '', FileName);
    end;

    procedure ImportSampleFromText(var ICMapping: Record "EOS IC Mapping Headers"; JsonText: Text; FileName: Text): Integer
    var
        SampleJsonBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Root: JsonToken;
        InvalidJsonErr: Label 'The Json file is not valid. %1', Comment = '%1 = error detail with the position of the error';
    begin
        if not TryReadJsonText(JsonText, Root) then
            Error(InvalidJsonErr, GetLastErrorText());
        SampleJsonBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(JsonText);
        exit(ImportSampleFromTokenAndBlob(ICMapping, Root, FileName, SampleJsonBlob));
    end;

    local procedure ImportSampleFromTokenAndBlob(var ICMapping: Record "EOS IC Mapping Headers"; Root: JsonToken; FileName: Text; var SampleJsonBlob: Codeunit "Temp Blob"): Integer
    var
        ICMappingLines: Record "EOS IC Mapping Lines";
    begin
        ICMapping.TestField(Code);
        AnalyzeRoot(Root, ICMapping.Code);

        ICMappingLines.SetRange("Mapping Code", ICMapping.Code);
        ICMappingLines.DeleteAll();
        exit(StoreSample(ICMapping, FileName, SampleJsonBlob));
    end;

    procedure LookupPath(MappingCode: Code[20]; CurrentPath: Text; var SelectedPath: Text): Boolean
    var
        ICMappingJsonNode: Record "EOS IC Mapping Json Node";
        CurrentNode: Record "EOS IC Mapping Json Node";
        ICMappingJsonNodes: Page "EOS IC Mapping Json Nodes";
        NoSampleMsg: Label 'No Json has been imported for the mapping %1. Use the action "Import Json" to import it.', Comment = '%1 = mapping code';
    begin
        ICMappingJsonNode.SetRange("Mapping Code", MappingCode);
        if ICMappingJsonNode.IsEmpty() then begin
            Message(NoSampleMsg, MappingCode);
            exit(false);
        end;

        ICMappingJsonNodes.SetTableView(ICMappingJsonNode);
        if CurrentPath <> '' then begin
            CurrentNode.SetRange("Mapping Code", MappingCode);
            CurrentNode.SetRange(Path, CurrentPath);
            if CurrentNode.FindFirst() then
                ICMappingJsonNodes.SetRecord(CurrentNode);
        end;

        ICMappingJsonNodes.LookupMode(true);
        if ICMappingJsonNodes.RunModal() <> Action::LookupOK then
            exit(false);

        ICMappingJsonNodes.GetRecord(ICMappingJsonNode);
        SelectedPath := ICMappingJsonNode.Path;
        exit(true);
    end;

    #region Analysis
    local procedure AnalyzeRoot(Root: JsonToken; MappingCode: Code[20])
    var
        NodeNo: Integer;
        RootArrayPath: Text;
        UnsupportedRootErr: Label 'The root of the Json must be an object or an array.';
        EmptyStructureErr: Label 'The Json does not contain any property to be mapped.';
    begin
        TempJsonNode.Reset();
        TempJsonNode.DeleteAll();
        Clear(NodeIndex);
        NextEntryNo := 0;
        CurrentMappingCode := MappingCode;

        case true of
            Root.IsObject():
                AnalyzeObject(Root.AsObject(), '', 0);
            Root.IsArray():
                begin
                    RootArrayPath := ICJsonPathMgt.AppendArray('');
                    NodeNo := EnsureNode(RootArrayPath, RootArrayPath, 0, TempJsonNode."Node Type"::"Array", '');
                    AnalyzeArray(Root.AsArray(), RootArrayPath, NodeNo);
                end;
            else
                Error(UnsupportedRootErr);
        end;

        if TempJsonNode.IsEmpty() then
            Error(EmptyStructureErr);
    end;

    local procedure AnalyzeObject(SourceObject: JsonObject; ParentPath: Text; ParentNodeNo: Integer)
    var
        PropertyName: Text;
        PropertyToken: JsonToken;
    begin
        foreach PropertyName in SourceObject.Keys() do
            // A property without a name cannot be expressed as a path.
            if PropertyName <> '' then begin
                SourceObject.Get(PropertyName, PropertyToken);
                AnalyzeProperty(PropertyToken, PropertyName, ParentPath, ParentNodeNo);
            end;
    end;

    local procedure AnalyzeProperty(PropertyToken: JsonToken; PropertyName: Text; ParentPath: Text; ParentNodeNo: Integer)
    var
        PropertyPath: Text;
        ArrayPath: Text;
        NodeNo: Integer;
    begin
        PropertyPath := ICJsonPathMgt.AppendProperty(ParentPath, PropertyName);
        case true of
            PropertyToken.IsObject():
                begin
                    NodeNo := EnsureNode(PropertyPath, PropertyName, ParentNodeNo, TempJsonNode."Node Type"::"Object", '');
                    AnalyzeObject(PropertyToken.AsObject(), PropertyPath, NodeNo);
                end;
            PropertyToken.IsArray():
                begin
                    ArrayPath := ICJsonPathMgt.AppendArray(PropertyPath);
                    NodeNo := EnsureNode(ArrayPath, PropertyName + '[]', ParentNodeNo, TempJsonNode."Node Type"::"Array", '');
                    AnalyzeArray(PropertyToken.AsArray(), ArrayPath, NodeNo);
                end;
            else
                EnsureNode(PropertyPath, PropertyName, ParentNodeNo, TempJsonNode."Node Type"::Value, GetSampleValue(PropertyToken));
        end;
    end;

    // The elements of an array are merged: the node of an array contains the properties found in any of its elements.
    local procedure AnalyzeArray(SourceArray: JsonArray; ArrayPath: Text; ArrayNodeNo: Integer)
    var
        ItemToken: JsonToken;
        ItemPath: Text;
        NodeNo: Integer;
    begin
        foreach ItemToken in SourceArray do
            case true of
                ItemToken.IsObject():
                    AnalyzeObject(ItemToken.AsObject(), ArrayPath, ArrayNodeNo);
                ItemToken.IsArray():
                    begin
                        ItemPath := ICJsonPathMgt.AppendArray(ArrayPath);
                        NodeNo := EnsureNode(ItemPath, '[]', ArrayNodeNo, TempJsonNode."Node Type"::"Array", '');
                        AnalyzeArray(ItemToken.AsArray(), ItemPath, NodeNo);
                    end;
                else
                    MarkArrayAsValue(ArrayNodeNo, GetSampleValue(ItemToken));
            end;
    end;

    local procedure EnsureNode(NodePath: Text; NodeName: Text; ParentNodeNo: Integer; NodeType: Enum "EOS IC Json Node Type"; SampleValue: Text): Integer
    var
        EntryNo: Integer;
        PathTooLongErr: Label 'The path %1 is longer than the %2 characters supported.', Comment = '%1 = path, %2 = maximum length';
    begin
        if NodeIndex.Get(NodePath, EntryNo) then begin
            TempJsonNode.Get(CurrentMappingCode, EntryNo);
            if (TempJsonNode."Node Type" = TempJsonNode."Node Type"::Value) and (NodeType <> NodeType::Value) then begin
                // A property that is null in some elements and structured in others is treated as structured.
                TempJsonNode."Node Type" := NodeType;
                TempJsonNode."Has Value" := false;
                TempJsonNode."Sample Value" := '';
                TempJsonNode.Modify();
            end else
                if (TempJsonNode."Node Type" = NodeType) and (SampleValue <> '') and (TempJsonNode."Sample Value" = '') then begin
                    TempJsonNode."Sample Value" := CopyStr(SampleValue, 1, MaxStrLen(TempJsonNode."Sample Value"));
                    TempJsonNode.Modify();
                end;
            exit(EntryNo);
        end;

        if StrLen(NodePath) > MaxStrLen(TempJsonNode.Path) then
            Error(PathTooLongErr, NodePath, MaxStrLen(TempJsonNode.Path));

        NextEntryNo += 1;
        TempJsonNode.Init();
        TempJsonNode."Mapping Code" := CurrentMappingCode;
        TempJsonNode."Entry No." := NextEntryNo;
        TempJsonNode."Parent Entry No." := ParentNodeNo;
        TempJsonNode.Name := CopyStr(NodeName, 1, MaxStrLen(TempJsonNode.Name));
        TempJsonNode.Path := CopyStr(NodePath, 1, MaxStrLen(TempJsonNode.Path));
        TempJsonNode."Node Type" := NodeType;
        TempJsonNode."Has Value" := NodeType = NodeType::Value;
        TempJsonNode."Sample Value" := CopyStr(SampleValue, 1, MaxStrLen(TempJsonNode."Sample Value"));
        TempJsonNode."Array Depth" := ICJsonPathMgt.GetArrayDepth(NodePath);
        TempJsonNode.Insert();
        NodeIndex.Add(NodePath, NextEntryNo);
        exit(NextEntryNo);
    end;

    // An array of scalar values can be mapped through the path of the array itself.
    local procedure MarkArrayAsValue(ArrayNodeNo: Integer; SampleValue: Text)
    begin
        TempJsonNode.Get(CurrentMappingCode, ArrayNodeNo);
        TempJsonNode."Has Value" := true;
        if (TempJsonNode."Sample Value" = '') and (SampleValue <> '') then
            TempJsonNode."Sample Value" := CopyStr(SampleValue, 1, MaxStrLen(TempJsonNode."Sample Value"));
        TempJsonNode.Modify();
    end;

    local procedure GetSampleValue(SourceToken: JsonToken): Text
    var
        SourceValue: JsonValue;
    begin
        if not SourceToken.IsValue() then
            exit('');

        SourceValue := SourceToken.AsValue();
        if SourceValue.IsNull() then
            exit('');
        exit(SourceValue.AsText());
    end;
    #endregion Analysis

    #region Storage
    local procedure StoreSample(var ICMapping: Record "EOS IC Mapping Headers"; FileName: Text; var SampleJsonBlob: Codeunit "Temp Blob"): Integer
    var
        SampleInStr: InStream;
        SampleOutStr: OutStream;
        NodeCount: Integer;
    begin
        NodeCount := ReplaceNodes(ICMapping.Code);
        AddMappingLines(ICMapping.Code);
        EnsureStructureLines(ICMapping.Code);

        ICMapping."Json File Name" := CopyStr(GetFileNameOnly(FileName), 1, MaxStrLen(ICMapping."Json File Name"));
        ICMapping."Json Imported At" := CurrentDateTime();
        SampleJsonBlob.CreateInStream(SampleInStr);
        ICMapping."Json Content".CreateOutStream(SampleOutStr);
        CopyStream(SampleOutStr, SampleInStr);
        ICMapping.Modify();
        exit(NodeCount);
    end;

    local procedure ReplaceNodes(MappingCode: Code[20]): Integer
    var
        ICMappingJsonNode: Record "EOS IC Mapping Json Node";
        NewEntryNo: Integer;
    begin
        ICMappingJsonNode.SetRange("Mapping Code", MappingCode);
        ICMappingJsonNode.DeleteAll();
        InsertChildNodes(MappingCode, 0, 0, 0, NewEntryNo);
        exit(NewEntryNo);
    end;

    // Every node holding a value becomes a line of the mapping, so that only the target is left to choose.
    // Paths that already have a line are skipped, so the existing configuration is never changed.
    local procedure AddMappingLines(MappingCode: Code[20])
    var
        ICMappingJsonNode: Record "EOS IC Mapping Json Node";
        ICMappingLine: Record "EOS IC Mapping Lines";
        NewICMappingLine: Record "EOS IC Mapping Lines";
        MappedPaths: List of [Text];
        LastLineNo: Integer;
    begin
        ICMappingLine.SetRange("Mapping Code", MappingCode);
        if ICMappingLine.FindSet() then
            repeat
                MappedPaths.Add(GetCanonicalPath(ICMappingLine."Json Path"));
                LastLineNo := ICMappingLine."Line No.";
            until ICMappingLine.Next() = 0;

        ICMappingJsonNode.SetRange("Mapping Code", MappingCode);
        ICMappingJsonNode.SetRange("Has Value", true);
        if ICMappingJsonNode.FindSet() then
            repeat
                if not MappedPaths.Contains(ICMappingJsonNode.Path) then begin
                    LastLineNo += 10000;
                    NewICMappingLine.Init();
                    NewICMappingLine."Mapping Code" := MappingCode;
                    NewICMappingLine."Line No." := LastLineNo;
                    NewICMappingLine.Validate("Json Path", ICMappingJsonNode.Path);
                    NewICMappingLine.Insert();
                end;
            until ICMappingJsonNode.Next() = 0;
    end;

    local procedure EnsureStructureLines(MappingCode: Code[20])
    var
        ICMappingJsonNode: Record "EOS IC Mapping Json Node";
        ICMappingLine: Record "EOS IC Mapping Lines";
        GroupPaths: List of [Text];
        GroupPath: Text;
        Index: Integer;
    begin
        ICMappingJsonNode.SetRange("Mapping Code", MappingCode);
        if ICMappingJsonNode.FindSet() then
            repeat
                if (ICMappingJsonNode."Node Type" = ICMappingJsonNode."Node Type"::"Object") or
                    (ICMappingJsonNode."Node Type" = ICMappingJsonNode."Node Type"::"Array")
                then
                    AddUniquePath(GroupPaths, ICMappingJsonNode.Path);
            until ICMappingJsonNode.Next() = 0;

        ICMappingLine.SetRange("Mapping Code", MappingCode);
        ICMappingLine.SetRange("Is Structure", false);
        ICMappingLine.SetFilter("Json Path", '<>%1', '');
        if ICMappingLine.FindSet() then
            repeat
                AddAncestorPaths(ICMappingLine."Json Path", GroupPaths);
            until ICMappingLine.Next() = 0;

        ICMappingLine.Reset();
        ICMappingLine.SetRange("Mapping Code", MappingCode);
        ICMappingLine.SetRange("Is Structure", true);
        if ICMappingLine.FindSet() then
            repeat
                if not GroupPaths.Contains(ICMappingLine."Json Path") then
                    if (ICMappingLine."Target Table ID" = 0) and (ICMappingLine."Target Field No." = 0) then
                        ICMappingLine.Delete()
                    else begin
                        ICMappingLine."Is Structure" := false;
                        ICMappingLine.Modify();
                    end;
            until ICMappingLine.Next() = 0;

        for Index := GroupPaths.Count() downto 1 do begin
            GroupPath := GroupPaths.Get(Index);
            ICMappingLine.Reset();
            ICMappingLine.SetRange("Mapping Code", MappingCode);
            ICMappingLine.SetRange("Json Path", GroupPath);
            if not ICMappingLine.FindFirst() then
                InsertStructureLine(MappingCode, GroupPath);
        end;
    end;

    local procedure AddAncestorPaths(Path: Text; var GroupPaths: List of [Text])
    var
        Steps: List of [Text];
        ErrorText: Text;
        Step: Text;
        NextStep: Text;
        Index: Integer;
    begin
        if not ICJsonPathMgt.ParsePath(Path, Steps, ErrorText) then
            exit;

        for Index := 1 to Steps.Count() do begin
            Step := Steps.Get(Index);
            if ICJsonPathMgt.IsArrayStep(Step) then
                AddUniquePath(GroupPaths, ICJsonPathMgt.SerializeSteps(Steps, Index))
            else
                if Index < Steps.Count() then begin
                    NextStep := Steps.Get(Index + 1);
                    if not ICJsonPathMgt.IsArrayStep(NextStep) then
                        AddUniquePath(GroupPaths, ICJsonPathMgt.SerializeSteps(Steps, Index));
                end;
        end;
    end;

    local procedure AddUniquePath(var Paths: List of [Text]; Path: Text)
    begin
        if (Path <> '') and not Paths.Contains(Path) then
            Paths.Add(Path);
    end;

    local procedure InsertStructureLine(MappingCode: Code[20]; GroupPath: Text)
    var
        ICMappingLine: Record "EOS IC Mapping Lines";
    begin
        ICMappingLine.Init();
        ICMappingLine."Mapping Code" := MappingCode;
        ICMappingLine."Line No." := GetStructureLineNo(MappingCode, GroupPath);
        ICMappingLine.Validate("Json Path", CopyStr(GroupPath, 1, MaxStrLen(ICMappingLine."Json Path")));
        ICMappingLine."Is Structure" := true;
        ICMappingLine.Insert();
    end;

    local procedure GetStructureLineNo(MappingCode: Code[20]; GroupPath: Text): Integer
    var
        ICMappingLine: Record "EOS IC Mapping Lines";
        FirstChildLineNo: Integer;
        CandidateLineNo: Integer;
    begin
        FirstChildLineNo := 0;
        ICMappingLine.SetRange("Mapping Code", MappingCode);
        if ICMappingLine.FindSet() then
            repeat
                if IsDescendantPath(ICMappingLine."Json Path", GroupPath) then
                    if (FirstChildLineNo = 0) or (ICMappingLine."Line No." < FirstChildLineNo) then
                        FirstChildLineNo := ICMappingLine."Line No.";
            until ICMappingLine.Next() = 0;

        if FirstChildLineNo = 0 then begin
            ICMappingLine.Reset();
            ICMappingLine.SetRange("Mapping Code", MappingCode);
            if ICMappingLine.FindLast() then
                exit(ICMappingLine."Line No." + 10000);
            exit(10000);
        end;

        CandidateLineNo := FirstChildLineNo - 1;
        while ICMappingLine.Get(MappingCode, CandidateLineNo) do
            CandidateLineNo -= 1;
        exit(CandidateLineNo);
    end;

    local procedure IsDescendantPath(Path: Text; ParentPath: Text): Boolean
    var
        NextCharacter: Text[1];
    begin
        if StrLen(Path) <= StrLen(ParentPath) then
            exit(false);
        if CopyStr(Path, 1, StrLen(ParentPath)) <> ParentPath then
            exit(false);

        NextCharacter := CopyStr(Path, StrLen(ParentPath) + 1, 1);
        exit(NextCharacter in ['.', '[']);
    end;

    local procedure GetCanonicalPath(Path: Text): Text
    var
        Steps: List of [Text];
        ErrorText: Text;
    begin
        if not ICJsonPathMgt.ParsePath(Path, Steps, ErrorText) then
            exit(Path);
        exit(ICJsonPathMgt.SerializeSteps(Steps, Steps.Count()));
    end;

    // Nodes are stored depth first so that the entry number order is the order of the tree.
    local procedure InsertChildNodes(MappingCode: Code[20]; TempParentNo: Integer; NewParentNo: Integer; NodeIndentation: Integer; var NewEntryNo: Integer)
    var
        ICMappingJsonNode: Record "EOS IC Mapping Json Node";
        ChildNos: List of [Integer];
        ChildNo: Integer;
    begin
        TempJsonNode.Reset();
        TempJsonNode.SetCurrentKey("Mapping Code", "Parent Entry No.", "Entry No.");
        TempJsonNode.SetRange("Mapping Code", MappingCode);
        TempJsonNode.SetRange("Parent Entry No.", TempParentNo);
        if TempJsonNode.FindSet() then
            repeat
                ChildNos.Add(TempJsonNode."Entry No.");
            until TempJsonNode.Next() = 0;
        TempJsonNode.Reset();

        foreach ChildNo in ChildNos do begin
            TempJsonNode.Get(MappingCode, ChildNo);
            NewEntryNo += 1;
            ICMappingJsonNode := TempJsonNode;
            ICMappingJsonNode."Entry No." := NewEntryNo;
            ICMappingJsonNode."Parent Entry No." := NewParentNo;
            ICMappingJsonNode.Indentation := NodeIndentation;
            ICMappingJsonNode.Insert();
            InsertChildNodes(MappingCode, ChildNo, NewEntryNo, NodeIndentation + 1, NewEntryNo);
        end;
    end;
    #endregion Storage

    local procedure ReadJsonStream(var InStr: InStream; var Root: JsonToken)
    var
        InvalidJsonErr: Label 'The Json file is not valid. %1', Comment = '%1 = error detail with the position of the error';
    begin
        if not TryReadJson(InStr, Root) then
            Error(InvalidJsonErr, GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryReadJson(var InStr: InStream; var Root: JsonToken)
    begin
        Root.ReadFrom(InStr);
    end;

    [TryFunction]
    local procedure TryReadJsonText(JsonText: Text; var Root: JsonToken)
    begin
        Root.ReadFrom(JsonText);
    end;

    local procedure GetFileNameOnly(FileName: Text): Text
    var
        Index: Integer;
    begin
        for Index := StrLen(FileName) downto 1 do
            if CopyStr(FileName, Index, 1) in ['\', '/'] then
                exit(CopyStr(FileName, Index + 1));
        exit(FileName);
    end;
}
