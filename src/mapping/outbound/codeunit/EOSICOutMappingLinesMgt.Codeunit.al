namespace EOS.Solutions.Intercompany;

using Microsoft.Utilities;
using System.Reflection;

codeunit 67018 "EOS IC Out. Mapping Lines Mgt."
{
    procedure AddNewLine(MappingLine: Record "EOS IC Out. Mapping Lines")
    var
        NewMappingLine: Record "EOS IC Out. Mapping Lines";
        LineNo: Integer;
        SortNo: Integer;
    begin
        LineNo := 10000;
        SortNo := MappingLine."Sort No.";
        NewMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        if NewMappingLine.FindLast() then
            LineNo += NewMappingLine."Line No.";

        NewMappingLine.Reset();
        NewMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        NewMappingLine.SetRange(Level, MappingLine.Level);
        NewMappingLine.SetRange("Parent Line No.", MappingLine."Parent Line No.");
        if NewMappingLine.FindLast() then
            SortNo := NewMappingLine."Sort No.";

        NewMappingLine.Init();
        NewMappingLine.Validate("Mapping Code", MappingLine."Mapping Code");
        NewMappingLine.Validate("Line No.", LineNo);
        NewMappingLine.Validate("Sort No.", SortNo);
        NewMappingLine.Validate(Level, MappingLine.Level);
        NewMappingLine.Validate("Parent Table No.", MappingLine."Parent Table No.");
        NewMappingLine.Validate("Parent Line No.", MappingLine."Parent Line No.");
        NewMappingLine.Insert(true);

        SortLines(NewMappingLine."Mapping Code");
    end;

    procedure AttachNewLine(MappingLine: Record "EOS IC Out. Mapping Lines"): Record "EOS IC Out. Mapping Lines"
    var
        NewMappingLine: Record "EOS IC Out. Mapping Lines";
        LineNo: Integer;
        SortNo: Integer;
    begin
        LineNo := 10000;
        SortNo := MappingLine."Sort No.";
        NewMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        if NewMappingLine.FindLast() then
            LineNo += NewMappingLine."Line No.";

        NewMappingLine.Reset();
        NewMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        NewMappingLine.SetRange(Level, MappingLine.Level + 1);
        NewMappingLine.SetRange("Parent Line No.", MappingLine."Line No.");
        if NewMappingLine.FindLast() then
            SortNo := NewMappingLine."Sort No.";

        NewMappingLine.Init();
        NewMappingLine.Validate("Mapping Code", MappingLine."Mapping Code");
        NewMappingLine.Validate("Line No.", LineNo);
        NewMappingLine.Validate("Sort No.", SortNo);
        NewMappingLine.Validate(Level, MappingLine.Level + 1);
        NewMappingLine.Validate("Parent Line No.", MappingLine."Line No.");
        NewMappingLine.Validate("Parent Table No.", MappingLine."Table No.");
        NewMappingLine.Insert(true);

        SortLines(NewMappingLine."Mapping Code");

        // SortLines changes the Sort No. in the database: the caller must not save an outdated copy of the line.
        NewMappingLine.Get(NewMappingLine."Mapping Code", NewMappingLine."Line No.");
        exit(NewMappingLine);
    end;

    procedure MoveUp(MappingLine: Record "EOS IC Out. Mapping Lines")
    begin
        MoveLine(MappingLine, -1);
    end;

    procedure MoveDown(MappingLine: Record "EOS IC Out. Mapping Lines")
    begin
        MoveLine(MappingLine, 1);
    end;

    // The line and its child lines swap place with the previous (Direction = -1) or the next (Direction = 1) line of the same parent.
    local procedure MoveLine(MappingLine: Record "EOS IC Out. Mapping Lines"; Direction: Integer)
    var
        AdjacentMappingLine: Record "EOS IC Out. Mapping Lines";
        SortNo: Integer;
    begin
        // Lines can share the same Sort No.: sorting them first makes the adjacent line unambiguous.
        SortLines(MappingLine."Mapping Code");
        if not MappingLine.Get(MappingLine."Mapping Code", MappingLine."Line No.") then
            exit;

        AdjacentMappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        AdjacentMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        AdjacentMappingLine.SetRange(Level, MappingLine.Level);
        // All the lines of the first level are siblings, whatever their parent line.
        if MappingLine.Level > 1 then
            AdjacentMappingLine.SetRange("Parent Line No.", MappingLine."Parent Line No.");

        if Direction < 0 then begin
            AdjacentMappingLine.SetFilter("Sort No.", '<%1', MappingLine."Sort No.");
            if not AdjacentMappingLine.FindLast() then
                exit;
        end else begin
            AdjacentMappingLine.SetFilter("Sort No.", '>%1', MappingLine."Sort No.");
            if not AdjacentMappingLine.FindFirst() then
                exit;
        end;

        SortNo := MappingLine."Sort No.";
        MappingLine."Sort No." := AdjacentMappingLine."Sort No.";
        AdjacentMappingLine."Sort No." := SortNo;
        MappingLine.Modify(true);
        AdjacentMappingLine.Modify(true);

        SortLines(MappingLine."Mapping Code");
    end;

    procedure SortLines(MappingCode: Code[20])
    var
        MappingLine: Record "EOS IC Out. Mapping Lines";
        RootLineNos: List of [Integer];
        RootLineNo: Integer;
        SortNo: Integer;
    begin
        SortNo := 10000;
        MappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        MappingLine.SetRange("Mapping Code", MappingCode);
        MappingLine.SetRange(Level, 1);
        if MappingLine.FindSet() then
            repeat
                RootLineNos.Add(MappingLine."Line No.");
            until MappingLine.Next() = 0;

        // Sort No. is part of the key used to read the lines: modifying it inside the loop would skip or repeat lines.
        MappingLine.Reset();
        foreach RootLineNo in RootLineNos do begin
            MappingLine.Get(MappingCode, RootLineNo);
            if MappingLine."Sort No." <> SortNo then begin
                MappingLine."Sort No." := SortNo;
                MappingLine.Modify(true);
            end;
            SortNo += 10000;
            SortChildLines(MappingLine, SortNo);
        end;
    end;

    procedure SortChildLines(MappingLine: Record "EOS IC Out. Mapping Lines"; var SortNo: Integer)
    var
        ChildMappingLine: Record "EOS IC Out. Mapping Lines";
        ChildLineNos: List of [Integer];
        ChildLineNo: Integer;
        ParentLineNo: Integer;
        InvalidLevelErr: Label 'Invalid level %1 for line %2', Comment = '%1 = level, %2 = line no.';
    begin
        ChildMappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        ChildMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        ChildMappingLine.SetRange("Parent Line No.", MappingLine."Line No.");
        if ChildMappingLine.FindSet() then
            repeat
                ChildLineNos.Add(ChildMappingLine."Line No.");
            until ChildMappingLine.Next() = 0;

        ChildMappingLine.Reset();
        foreach ChildLineNo in ChildLineNos do begin
            ChildMappingLine.Get(MappingLine."Mapping Code", ChildLineNo);
            ParentLineNo := ChildMappingLine."Parent Line No.";
            if ChildMappingLine.Level <> MappingLine.Level + 1 then
                // A child at the same level as its parent is repositioned under the parent of the latter.
                if ChildMappingLine.Level = MappingLine.Level then
                    ParentLineNo := MappingLine."Parent Line No."
                else
                    Error(InvalidLevelErr, ChildMappingLine.Level, ChildMappingLine."Line No.");

            if (ChildMappingLine."Sort No." <> SortNo) or (ChildMappingLine."Parent Line No." <> ParentLineNo) then begin
                ChildMappingLine."Sort No." := SortNo;
                ChildMappingLine."Parent Line No." := ParentLineNo;
                ChildMappingLine.Modify(true);
            end;
            SortNo += 10000;
            SortChildLines(ChildMappingLine, SortNo);
        end;
    end;

    procedure DeleteRecurr(MappingLine: Record "EOS IC Out. Mapping Lines"; var FirstLoop: Boolean)
    var
        ChildMappingLine: Record "EOS IC Out. Mapping Lines";
        DeleteChildrenQst: Label 'There are attached lines for Line No. %1. Do you want to delete them?', Comment = '%1 = line no.';
    begin
        ChildMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        ChildMappingLine.SetRange("Parent Line No.", MappingLine."Line No.");
        ChildMappingLine.SetRange(Level, MappingLine.Level + 1);
        if ChildMappingLine.FindSet() then begin
            if GuiAllowed() and FirstLoop then
                if not Confirm(DeleteChildrenQst, false, MappingLine."Line No.") then
                    Error('');

            FirstLoop := false;
            repeat
                DeleteRecurr(ChildMappingLine, FirstLoop);
                ChildMappingLine.Delete(true);
            until ChildMappingLine.Next() = 0;
        end;
    end;

    procedure CheckIfChildRecordExists(MappingLine: Record "EOS IC Out. Mapping Lines")
    var
        ChildMappingLine: Record "EOS IC Out. Mapping Lines";
        ChildLinesExistErr: Label 'There are child lines.';
    begin
        ChildMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        ChildMappingLine.SetRange("Parent Line No.", MappingLine."Line No.");
        if not ChildMappingLine.IsEmpty() then
            Error(ChildLinesExistErr);
    end;

    procedure ClearTableFilter(var MappingLine: Record "EOS IC Out. Mapping Lines")
    begin
        MappingLine.SetTableFilter('');
        MappingLine.Modify(true);
    end;

    procedure DeleteLine(var MappingLine: Record "EOS IC Out. Mapping Lines")
    var
        DeleteLinesQst: Label 'Do you want to delete selected lines (%1)?', Comment = '%1 = number of lines';
    begin
        if not MappingLine.FindLast() then
            exit;

        if not Confirm(DeleteLinesQst, false, MappingLine.Count()) then
            exit;

        repeat
            MappingLine.Delete(true);
        until MappingLine.Next(-1) = 0;
    end;

    procedure SuggestTableFields(MappingLine: Record "EOS IC Out. Mapping Lines")
    var
        NewMappingLine: Record "EOS IC Out. Mapping Lines";
        Field: Record Field;
        FieldsLookup: Page "Fields Lookup";
        AppendFieldsQst: Label 'Do you want to append selected fields (%1)?', Comment = '%1 = number of fields';
    begin
        MappingLine.TestField("Line Type", MappingLine."Line Type"::Record);
        MappingLine.TestField("Table No.");

        Field.SetRange(TableNo, MappingLine."Table No.");
        Field.SetFilter(Class, '<>%1', Field.Class::FlowFilter);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        Field.SetRange(Enabled, true);
        FieldsLookup.SetTableView(Field);
        FieldsLookup.LookupMode := true;
        if FieldsLookup.RunModal() <> Action::LookupOK then
            exit;

        FieldsLookup.SetSelectionFilter(Field);
        if not Field.FindSet() then
            exit;

        if not Confirm(AppendFieldsQst, false, Field.Count()) then
            exit;

        repeat
            NewMappingLine := AttachNewLine(MappingLine);
            NewMappingLine.Validate("Line Type", NewMappingLine."Line Type"::Attribute);
            NewMappingLine.Validate("Attribute Type", NewMappingLine."Attribute Type"::Field);
            NewMappingLine.Validate("Field No.", Field."No.");
            NewMappingLine.Validate("Json Tag", CopyStr(GetName(Field.FieldName), 1, 50));
            NewMappingLine.Modify(true);
        until Field.Next() = 0;
    end;

    // Json tag in camelCase without spaces and special characters, e.g. "Ship-to Name 2" becomes "shipToName2".
    procedure GetName(FieldName: Text): Text
    var
        Word: Text;
        Result: Text;
        Index: Integer;
    begin
        // The trailing space closes the last word.
        FieldName := ConvertStr(FieldName, 'àèéìòùÀÈÉÌÒÙ', 'aeeiouAEEIOU') + ' ';
        for Index := 1 to StrLen(FieldName) do
            if IsAlphanumeric(FieldName[Index]) then
                Word += CopyStr(FieldName, Index, 1)
            else
                if Word <> '' then begin
                    Result += GetCamelCaseWord(Word, Result = '');
                    Word := '';
                end;

        exit(Result);
    end;

    local procedure GetCamelCaseWord(Word: Text; IsFirstWord: Boolean): Text
    var
        HasLowercase: Boolean;
        Index: Integer;
    begin
        for Index := 1 to StrLen(Word) do
            if IsLowercaseLetter(Word[Index]) then
                HasLowercase := true;

        // Words made only of capitals, like VAT, are normalized; the other words keep their inner capitals.
        if not HasLowercase then
            Word := LowerCase(Word);

        if IsFirstWord then
            exit(LowerCase(CopyStr(Word, 1, 1)) + CopyStr(Word, 2));

        exit(UpperCase(CopyStr(Word, 1, 1)) + CopyStr(Word, 2));
    end;

    local procedure IsLowercaseLetter(Character: Char): Boolean
    begin
        // Character codes: 97-122 = a-z.
        exit((Character >= 97) and (Character <= 122));
    end;

    local procedure IsAlphanumeric(Character: Char): Boolean
    begin
        // Character codes: 48-57 = 0-9, 65-90 = A-Z.
        exit(((Character >= 48) and (Character <= 57)) or ((Character >= 65) and (Character <= 90)) or IsLowercaseLetter(Character));
    end;

    procedure LookupFunction(var MappingLine: Record "EOS IC Out. Mapping Lines")
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        ICOutMappingMgt: Codeunit "EOS IC Out. Mapping Mgt.";
        NameValueLookup: Page "Name/Value Lookup";
    begin
        ICOutMappingMgt.PopulateFunctions(TempNameValueBuffer);

        TempNameValueBuffer.Reset();
        if TempNameValueBuffer.FindSet() then
            repeat
                NameValueLookup.AddItem(TempNameValueBuffer.Name, TempNameValueBuffer.Value);
            until TempNameValueBuffer.Next() = 0;

        TempNameValueBuffer.SetFilter(Name, '@' + MappingLine."Function");
        if TempNameValueBuffer.IsEmpty() then
            TempNameValueBuffer.SetFilter(Name, '@' + MappingLine."Function" + '*');
        if TempNameValueBuffer.FindFirst() then;
        TempNameValueBuffer.Reset();

        NameValueLookup.SetRecord(TempNameValueBuffer);
        NameValueLookup.LookupMode(true);
        NameValueLookup.Editable(false);
        if NameValueLookup.RunModal() in [Action::LookupOK, Action::OK] then begin
            NameValueLookup.GetRecord(TempNameValueBuffer);
            MappingLine."Function" := CopyStr(TempNameValueBuffer.Name, 1, MaxStrLen(MappingLine."Function"));
            MappingLine.Modify(true);
        end;
    end;
}
