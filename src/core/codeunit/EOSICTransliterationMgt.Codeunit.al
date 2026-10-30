namespace EOS.Solutions.Intercompany;

codeunit 67021 "EOS IC Transliteration Mgt."
{
    var
        Replacements: Dictionary of [Text, Dictionary of [Text, Text]];
        MaxCharacterLengths: Dictionary of [Text, Integer];

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
        ICTransliterationLine: Record "EOS IC Transliteration Line";
        CodeReplacements: Dictionary of [Text, Text];
        MaxLength: Integer;
    begin
        MaxLength := 0;
        ICTransliterationLine.SetRange(Code, TransliterationCode);
        if ICTransliterationLine.FindSet() then
            repeat
                CodeReplacements.Set(ICTransliterationLine.Character, ICTransliterationLine.Transformation);
                if StrLen(ICTransliterationLine.Character) > MaxLength then
                    MaxLength := StrLen(ICTransliterationLine.Character);
            until ICTransliterationLine.Next() = 0;

        Replacements.Set(TransliterationCode, CodeReplacements);
        MaxCharacterLengths.Set(TransliterationCode, MaxLength);
    end;
}
