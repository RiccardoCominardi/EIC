namespace EOS.Solutions.Intercompany;

table 67023 "EOS IC Transliteration Line"
{
    DataClassification = CustomerContent;
    Caption = 'IC Transliteration Line (EIC)';

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            TableRelation = "EOS IC Transliteration Header"."Code";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(3; Character; Text[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Character';
            NotBlank = true;
        }
        field(4; Transformation; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Transformation';
        }
    }

    keys
    {
        key(Key1; "Code", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        CheckDuplicateCharacter();
    end;

    trigger OnModify()
    begin
        CheckDuplicateCharacter();
    end;

    // Text equality and filters are case-insensitive in AL/SQL: the dictionary keys are compared case-sensitively.
    local procedure CheckDuplicateCharacter()
    var
        OtherLine: Record "EOS IC Transliteration Line";
        Characters: Dictionary of [Text, Integer];
        DuplicateErr: Label 'The character %1 is already defined in the line %2 of the transliteration %3.', Comment = '%1 = character, %2 = line no., %3 = transliteration code';
    begin
        OtherLine.SetRange(Code, Rec.Code);
        OtherLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        if OtherLine.FindSet() then
            repeat
                Characters.Set(OtherLine.Character, OtherLine."Line No.");
            until OtherLine.Next() = 0;

        if Characters.ContainsKey(Rec.Character) then
            Error(DuplicateErr, Rec.Character, Characters.Get(Rec.Character), Rec.Code);
    end;
}
