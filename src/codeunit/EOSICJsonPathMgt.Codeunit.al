namespace EOS.Solutions.Intercompany;

// A Json path is a dot separated list of property names where '[]' marks an array level, e.g. document.customers[].orders[].number.
// The characters '\', '.', '[' and ']' inside a property name are escaped with a backslash.
// Parsed paths are lists of steps: '.name' for a property and '[]' for an array level.
codeunit 67014 "EOS IC Json Path Mgt."
{
    procedure ParsePath(Path: Text; var Steps: List of [Text]; var ErrorText: Text): Boolean
    var
        Buffer: Text;
        Ch: Text[1];
        Position: Integer;
        InName: Boolean;
        AfterArray: Boolean;
        ExpectName: Boolean;
        EmptyPathErr: Label 'The path is empty.';
        DanglingEscapeErr: Label 'Unexpected end of the path after the escape character at position %1.', Comment = '%1 = position';
        MissingSeparatorErr: Label 'A "." separator is expected before the character at position %1.', Comment = '%1 = position';
        UnexpectedSeparatorErr: Label 'Unexpected "." at position %1.', Comment = '%1 = position';
        InvalidArrayMarkerErr: Label 'The character "[" at position %1 must be followed by "]".', Comment = '%1 = position';
        ArrayAfterSeparatorErr: Label 'The array marker at position %1 must follow a property name.', Comment = '%1 = position';
        UnexpectedBracketErr: Label 'Unexpected "]" at position %1.', Comment = '%1 = position';
        TrailingSeparatorErr: Label 'The path cannot end with a "." separator.';
    begin
        Clear(Steps);
        ErrorText := '';

        if Path = '' then begin
            ErrorText := EmptyPathErr;
            exit(false);
        end;

        Position := 1;
        while Position <= StrLen(Path) do begin
            Ch := CopyStr(Path, Position, 1);
            case Ch of
                '\':
                    begin
                        if Position = StrLen(Path) then begin
                            ErrorText := StrSubstNo(DanglingEscapeErr, Position);
                            exit(false);
                        end;
                        if AfterArray then begin
                            ErrorText := StrSubstNo(MissingSeparatorErr, Position);
                            exit(false);
                        end;
                        Position += 1;
                        Buffer += CopyStr(Path, Position, 1);
                        InName := true;
                        ExpectName := false;
                    end;
                '.':
                    begin
                        if InName then begin
                            Steps.Add('.' + Buffer);
                            Buffer := '';
                            InName := false;
                        end else
                            if not AfterArray then begin
                                ErrorText := StrSubstNo(UnexpectedSeparatorErr, Position);
                                exit(false);
                            end;
                        AfterArray := false;
                        ExpectName := true;
                    end;
                '[':
                    begin
                        if CopyStr(Path, Position + 1, 1) <> ']' then begin
                            ErrorText := StrSubstNo(InvalidArrayMarkerErr, Position);
                            exit(false);
                        end;
                        if InName then begin
                            Steps.Add('.' + Buffer);
                            Buffer := '';
                            InName := false;
                        end else
                            if ExpectName then begin
                                ErrorText := StrSubstNo(ArrayAfterSeparatorErr, Position);
                                exit(false);
                            end;
                        Steps.Add(ArrayStep());
                        AfterArray := true;
                        ExpectName := false;
                        Position += 1;
                    end;
                ']':
                    begin
                        ErrorText := StrSubstNo(UnexpectedBracketErr, Position);
                        exit(false);
                    end;
                else begin
                    if AfterArray then begin
                        ErrorText := StrSubstNo(MissingSeparatorErr, Position);
                        exit(false);
                    end;
                    Buffer += Ch;
                    InName := true;
                    ExpectName := false;
                end;
            end;
            Position += 1;
        end;

        if InName then
            Steps.Add('.' + Buffer)
        else
            if ExpectName then begin
                ErrorText := TrailingSeparatorErr;
                exit(false);
            end;
        exit(true);
    end;

    // The empty context is the root of the document and is always valid.
    procedure ParseContext(ContextPath: Text; var Steps: List of [Text]): Boolean
    var
        ErrorText: Text;
    begin
        Clear(Steps);
        if ContextPath = '' then
            exit(true);
        exit(ParsePath(ContextPath, Steps, ErrorText));
    end;

    procedure NormalizePath(Path: Text): Text
    var
        Steps: List of [Text];
        ErrorText: Text;
        InvalidPathErr: Label 'The Json path "%1" is not valid. %2', Comment = '%1 = path, %2 = error detail';
    begin
        Path := DelChr(Path, '<>', ' ');
        if Path = '' then
            exit('');

        if not ParsePath(Path, Steps, ErrorText) then
            Error(InvalidPathErr, Path, ErrorText);
        exit(SerializeSteps(Steps, Steps.Count()));
    end;

    procedure EscapeName(Name: Text): Text
    begin
        Name := Name.Replace('\', '\\');
        Name := Name.Replace('.', '\.');
        Name := Name.Replace('[', '\[');
        Name := Name.Replace(']', '\]');
        exit(Name);
    end;

    procedure AppendProperty(ParentPath: Text; PropertyName: Text): Text
    begin
        if ParentPath = '' then
            exit(EscapeName(PropertyName));
        exit(ParentPath + '.' + EscapeName(PropertyName));
    end;

    procedure AppendArray(ParentPath: Text): Text
    begin
        exit(ParentPath + ArrayStep());
    end;

    procedure SerializeSteps(Steps: List of [Text]; StepCount: Integer): Text
    var
        Step: Text;
        Result: Text;
        Index: Integer;
    begin
        for Index := 1 to StepCount do begin
            Step := Steps.Get(Index);
            if Step = ArrayStep() then
                Result += Step
            else begin
                if Result <> '' then
                    Result += '.';
                Result += EscapeName(CopyStr(Step, 2));
            end;
        end;
        exit(Result);
    end;

    procedure IsArrayStep(Step: Text): Boolean
    begin
        exit(Step = ArrayStep());
    end;

    procedure GetPropertyName(Step: Text): Text
    begin
        exit(CopyStr(Step, 2));
    end;

    // Position of the innermost array level of the steps, 0 when the path does not cross any array.
    procedure GetLastArrayStep(Steps: List of [Text]): Integer
    var
        Index: Integer;
    begin
        for Index := Steps.Count() downto 1 do
            if Steps.Get(Index) = ArrayStep() then
                exit(Index);
        exit(0);
    end;

    // The array context of a path is the path up to its innermost array level; blank when no array is crossed.
    procedure GetArrayContext(Path: Text): Text
    var
        Steps: List of [Text];
        ErrorText: Text;
    begin
        if not ParsePath(Path, Steps, ErrorText) then
            exit('');
        exit(SerializeSteps(Steps, GetLastArrayStep(Steps)));
    end;

    // The chain lists every array context from the outermost one up to the given context, e.g. a[], a[].b[], a[].b[].c[].
    procedure GetContextChain(ContextPath: Text; var Chain: List of [Text])
    var
        Steps: List of [Text];
        Index: Integer;
    begin
        Clear(Chain);
        if not ParseContext(ContextPath, Steps) then
            exit;

        for Index := 1 to Steps.Count() do
            if Steps.Get(Index) = ArrayStep() then
                Chain.Add(SerializeSteps(Steps, Index));
    end;

    procedure GetArrayDepth(Path: Text): Integer
    var
        Chain: List of [Text];
    begin
        GetContextChain(GetArrayContext(Path), Chain);
        exit(Chain.Count());
    end;

    // Name of the node a path points to: the last property followed by its array markers, e.g. quantity or lines[].
    procedure GetNodeName(Path: Text): Text
    var
        Steps: List of [Text];
        ErrorText: Text;
        Markers: Text;
        Index: Integer;
    begin
        if not ParsePath(Path, Steps, ErrorText) then
            exit(Path);

        Index := Steps.Count();
        while Index >= 1 do begin
            if not IsArrayStep(Steps.Get(Index)) then
                exit(GetPropertyName(Steps.Get(Index)) + Markers);
            Markers += ArrayStep();
            Index -= 1;
        end;
        exit(Markers);
    end;

    // Indentation is the number of object or array ancestors of the node.
    procedure GetNodeLevel(Path: Text): Integer
    var
        Steps: List of [Text];
        ErrorText: Text;
        Step: Text;
        NextStep: Text;
        Index: Integer;
        NodeLevel: Integer;
    begin
        if not ParsePath(Path, Steps, ErrorText) then
            exit(0);

        for Index := 1 to Steps.Count() - 1 do begin
            Step := Steps.Get(Index);
            if IsArrayStep(Step) then
                NodeLevel += 1
            else begin
                NextStep := Steps.Get(Index + 1);
                if not IsArrayStep(NextStep) then
                    NodeLevel += 1;
            end;
        end;
        exit(NodeLevel);
    end;

    // Follows the property steps from FromIndex to ToIndex starting from the given token.
    procedure NavigateProperties(Start: JsonToken; Steps: List of [Text]; FromIndex: Integer; ToIndex: Integer; var Result: JsonToken): Boolean
    var
        Current: JsonToken;
        Next: JsonToken;
        Index: Integer;
    begin
        Current := Start;
        for Index := FromIndex to ToIndex do begin
            if IsArrayStep(Steps.Get(Index)) then
                exit(false);
            if not Current.IsObject() then
                exit(false);
            if not Current.AsObject().Get(GetPropertyName(Steps.Get(Index)), Next) then
                exit(false);
            Current := Next;
        end;
        Result := Current;
        exit(true);
    end;

    local procedure ArrayStep(): Text
    begin
        exit('[]');
    end;
}
