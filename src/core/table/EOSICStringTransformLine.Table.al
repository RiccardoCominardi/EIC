namespace EOS.Solutions.Intercompany;

table 67023 "EOS IC String Transform Line"
{
    DataClassification = CustomerContent;
    Caption = 'IC String Transformation Line (EIC)';

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            TableRelation = "EOS IC String Transform Header"."Code";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(3; Character; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Source String';
            NotBlank = true;

            trigger OnValidate()
            begin
                CheckCharacterSourceLength();
            end;
        }
        field(4; Transformation; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Replacement';
        }
    }

    keys
    {
        key(Key1; "Code", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        CheckCharacterSourceLength();
        CheckDuplicateSourceString();
    end;

    trigger OnModify()
    begin
        if (Rec.Character <> xRec.Character) or (Rec.Code <> xRec.Code) then
            CheckCharacterSourceLength();
        CheckDuplicateSourceString();
    end;

    local procedure CheckCharacterSourceLength()
    var
        ICStringTransformationHeader: Record "EOS IC String Transform Header";
        CharacterSourceTooLongErr: Label 'The source string cannot exceed two characters in Character Transliteration mode.';
    begin
        if not ICStringTransformationHeader.Get(Rec.Code) then
            exit;

        if ICStringTransformationHeader."Transformation Type" <> ICStringTransformationHeader."Transformation Type"::"Character Transliteration" then
            exit;

        if StrLen(Rec.Character) > 2 then
            Error(CharacterSourceTooLongErr);
    end;

    // Text equality and filters are case-insensitive in AL/SQL: the dictionary keys are compared case-sensitively.
    local procedure CheckDuplicateSourceString()
    var
        OtherLine: Record "EOS IC String Transform Line";
        SourceStrings: Dictionary of [Text, Integer];
        DuplicateErr: Label 'The source string %1 is already defined in the line %2 of the transformation %3.', Comment = '%1 = source string, %2 = line no., %3 = transformation code';
    begin
        OtherLine.SetRange(Code, Rec.Code);
        OtherLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        if OtherLine.FindSet() then
            repeat
                SourceStrings.Set(OtherLine.Character, OtherLine."Line No.");
            until OtherLine.Next() = 0;

        if SourceStrings.ContainsKey(Rec.Character) then
            Error(DuplicateErr, Rec.Character, SourceStrings.Get(Rec.Character), Rec.Code);
    end;
}
