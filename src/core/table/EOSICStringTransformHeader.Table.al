namespace EOS.Solutions.Intercompany;

table 67022 "EOS IC String Transform Header"
{
    DataClassification = CustomerContent;
    Caption = 'IC String Transformation Header (EIC)';
    LookupPageId = "EOS IC String Transformations";
    DrillDownPageId = "EOS IC String Transformations";

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(3; "Transformation Type"; Enum "EOS IC String Transform Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Transformation Type';
        }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ICStringTransformationLine: Record "EOS IC String Transform Line";
        ICMappingLine: Record "EOS IC Mapping Lines";
        ICOutMappingLine: Record "EOS IC Out. Mapping Lines";
    begin
        ICStringTransformationLine.SetRange(Code, Rec.Code);
        ICStringTransformationLine.DeleteAll(true);

        // RunTrigger false: the out. mapping lines OnModify refuses enabled mappings.
        ICMappingLine.SetRange("Transliteration Code", Rec.Code);
        ICMappingLine.ModifyAll("Transliteration Code", '', false);
        ICMappingLine.Reset();
        ICMappingLine.SetRange("String Replacement Code", Rec.Code);
        ICMappingLine.ModifyAll("String Replacement Code", '', false);

        ICOutMappingLine.SetRange("Transliteration Code", Rec.Code);
        ICOutMappingLine.ModifyAll("Transliteration Code", '', false);
        ICOutMappingLine.Reset();
        ICOutMappingLine.SetRange("String Replacement Code", Rec.Code);
        ICOutMappingLine.ModifyAll("String Replacement Code", '', false);
    end;

    trigger OnModify()
    begin
        if Rec."Transformation Type" <> xRec."Transformation Type" then
            CheckTransformationTypeChange();
    end;

    local procedure CheckTransformationTypeChange()
    var
        ICMappingLine: Record "EOS IC Mapping Lines";
        ICOutMappingLine: Record "EOS IC Out. Mapping Lines";
        ICStringTransformationLine: Record "EOS IC String Transform Line";
        CannotChangeTypeErr: Label 'The transformation type cannot be changed while the code is assigned to mapping lines using the other transformation mode.';
        CharacterSourceTooLongErr: Label 'The source string cannot exceed two characters in Character Transliteration mode.';
    begin
        if Rec."Transformation Type" = Rec."Transformation Type"::"Character Transliteration" then begin
            ICStringTransformationLine.SetRange(Code, Rec.Code);
            if ICStringTransformationLine.FindSet() then
                repeat
                    if StrLen(ICStringTransformationLine.Character) > 2 then
                        Error(CharacterSourceTooLongErr);
                until ICStringTransformationLine.Next() = 0;
        end;

        case Rec."Transformation Type" of
            Rec."Transformation Type"::"Character Transliteration":
                begin
                    ICMappingLine.SetRange("String Replacement Code", Rec.Code);
                    if not ICMappingLine.IsEmpty() then
                        Error(CannotChangeTypeErr);

                    ICOutMappingLine.SetRange("String Replacement Code", Rec.Code);
                    if not ICOutMappingLine.IsEmpty() then
                        Error(CannotChangeTypeErr);
                end;
            Rec."Transformation Type"::"Complete String Replacement":
                begin
                    ICMappingLine.SetRange("Transliteration Code", Rec.Code);
                    if not ICMappingLine.IsEmpty() then
                        Error(CannotChangeTypeErr);

                    ICOutMappingLine.SetRange("Transliteration Code", Rec.Code);
                    if not ICOutMappingLine.IsEmpty() then
                        Error(CannotChangeTypeErr);
                end;
        end;
    end;
}
