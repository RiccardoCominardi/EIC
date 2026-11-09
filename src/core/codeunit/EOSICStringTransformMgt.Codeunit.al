namespace EOS.Solutions.Intercompany;

codeunit 67021 "EOS IC String Transform Mgt."
{
    var
        Replacements: Dictionary of [Text, Dictionary of [Text, Text]];
        MaxCharacterLengths: Dictionary of [Text, Integer];

    procedure ApplyTransformations(TransliterationCode: Code[20]; StringReplacementCode: Code[20]; TransformationOrder: Enum "EOS IC Transformation Order"; InputText: Text): Text
    begin
        if (TransliterationCode <> '') and (StringReplacementCode <> '') then
            case TransformationOrder of
                TransformationOrder::"Transliteration First":
                    begin
                        InputText := ApplyConfiguredTransformation(TransliterationCode, InputText);
                        exit(ApplyConfiguredTransformation(StringReplacementCode, InputText));
                    end;
                TransformationOrder::"String Replacement First":
                    begin
                        InputText := ApplyConfiguredTransformation(StringReplacementCode, InputText);
                        exit(ApplyConfiguredTransformation(TransliterationCode, InputText));
                    end;
            end;

        if TransliterationCode <> '' then
            exit(ApplyConfiguredTransformation(TransliterationCode, InputText));

        if StringReplacementCode <> '' then
            exit(ApplyConfiguredTransformation(StringReplacementCode, InputText));

        exit(InputText);
    end;

    local procedure ApplyConfiguredTransformation(TransformationCode: Code[20]; InputText: Text): Text
    var
        ICStringTransformationHeader: Record "EOS IC String Transform Header";
    begin
        if (TransformationCode = '') or (InputText = '') then
            exit(InputText);

        if not ICStringTransformationHeader.Get(TransformationCode) then
            exit(InputText);

        case ICStringTransformationHeader."Transformation Type" of
            ICStringTransformationHeader."Transformation Type"::"Character Transliteration":
                exit(Transliterate(TransformationCode, InputText));
            ICStringTransformationHeader."Transformation Type"::"Complete String Replacement":
                exit(ReplaceCompleteString(TransformationCode, InputText));
        end;

        exit(InputText);
    end;

    local procedure ReplaceCompleteString(TransformationCode: Code[20]; InputText: Text): Text
    var
        CodeReplacements: Dictionary of [Text, Text];
        Replacement: Text;
    begin
        if not MaxCharacterLengths.ContainsKey(TransformationCode) then
            LoadReplacements(TransformationCode);

        CodeReplacements := Replacements.Get(TransformationCode);
        if CodeReplacements.Get(InputText, Replacement) then
            exit(Replacement);

        exit(InputText);
    end;

    // Single pass, case-sensitive, longest Character first: the output of a replacement is never replaced again.
    // The rules are cached per instance: keep the codeunit in a global variable of the caller.
    procedure Transliterate(TransliterationCode: Code[20]; InputText: Text): Text
    var
        CodeReplacements: Dictionary of [Text, Text];
        Result: TextBuilder;
        Candidate: Text;
        Replacement: Text;
        MaxLength: Integer;
        TextLength: Integer;
        Position: Integer;
        MatchLength: Integer;
        Replaced: Boolean;
    begin
        if (TransliterationCode = '') or (InputText = '') then
            exit(InputText);

        if not MaxCharacterLengths.ContainsKey(TransliterationCode) then
            LoadReplacements(TransliterationCode);

        MaxLength := MaxCharacterLengths.Get(TransliterationCode);
        if MaxLength = 0 then
            exit(InputText);

        CodeReplacements := Replacements.Get(TransliterationCode);
        TextLength := StrLen(InputText);
        Position := 1;
        while Position <= TextLength do begin
            Replaced := false;
            MatchLength := MaxLength;
            if MatchLength > TextLength - Position + 1 then
                MatchLength := TextLength - Position + 1;

            while (MatchLength > 0) and not Replaced do begin
                Candidate := CopyStr(InputText, Position, MatchLength);
                if CodeReplacements.Get(Candidate, Replacement) then begin
                    Result.Append(Replacement);
                    Position += MatchLength;
                    Replaced := true;
                end;
                MatchLength -= 1;
            end;

            if not Replaced then begin
                Result.Append(CopyStr(InputText, Position, 1));
                Position += 1;
            end;
        end;

        exit(Result.ToText());
    end;

    local procedure LoadReplacements(TransliterationCode: Code[20])
    var
        ICStringTransformationLine: Record "EOS IC String Transform Line";
        CodeReplacements: Dictionary of [Text, Text];
        MaxLength: Integer;
    begin
        MaxLength := 0;
        ICStringTransformationLine.SetRange(Code, TransliterationCode);
        if ICStringTransformationLine.FindSet() then
            repeat
                CodeReplacements.Set(ICStringTransformationLine.Character, ICStringTransformationLine.Transformation);
                if StrLen(ICStringTransformationLine.Character) > MaxLength then
                    MaxLength := StrLen(ICStringTransformationLine.Character);
            until ICStringTransformationLine.Next() = 0;

        Replacements.Set(TransliterationCode, CodeReplacements);
        MaxCharacterLengths.Set(TransliterationCode, MaxLength);
    end;
}
