namespace EOS.Solutions.Intercompany;

table 67022 "EOS IC Transliteration Header"
{
    DataClassification = CustomerContent;
    Caption = 'IC Transliteration Header (EIC)';
    LookupPageId = "EOS IC Transliterations";
    DrillDownPageId = "EOS IC Transliterations";

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
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ICTransliterationLine: Record "EOS IC Transliteration Line";
        ICMappingLine: Record "EOS IC Mapping Lines";
        ICOutMappingLine: Record "EOS IC Out. Mapping Lines";
    begin
        ICTransliterationLine.SetRange(Code, Rec.Code);
        ICTransliterationLine.DeleteAll(true);

        // RunTrigger false: the out. mapping lines OnModify refuses enabled mappings.
        ICMappingLine.SetRange("Transliteration Code", Rec.Code);
        ICMappingLine.ModifyAll("Transliteration Code", '', false);

        ICOutMappingLine.SetRange("Transliteration Code", Rec.Code);
        ICOutMappingLine.ModifyAll("Transliteration Code", '', false);
    end;
}
