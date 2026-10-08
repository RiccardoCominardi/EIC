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

        exit(NewMappingLine);
    end;

    procedure MoveUp(MappingLine: Record "EOS IC Out. Mapping Lines")
    var
        PrevMappingLine: Record "EOS IC Out. Mapping Lines";
        SortNo: Integer;
    begin
        PrevMappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        PrevMappingLine.SetAscending("Sort No.", false);
        PrevMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        PrevMappingLine.SetRange(Level, MappingLine.Level);
        PrevMappingLine.SetFilter("Sort No.", '<%1', MappingLine."Sort No.");
        if PrevMappingLine.FindFirst() then begin
            SortNo := MappingLine."Sort No.";
            MappingLine."Sort No." := PrevMappingLine."Sort No.";
            PrevMappingLine."Sort No." := SortNo;
            MappingLine.Modify(true);
            PrevMappingLine.Modify(true);
        end;
        SortLines(MappingLine."Mapping Code");
    end;

    procedure MoveDown(MappingLine: Record "EOS IC Out. Mapping Lines")
    var
        NextMappingLine: Record "EOS IC Out. Mapping Lines";
        SortNo: Integer;
    begin
        NextMappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        NextMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        NextMappingLine.SetRange(Level, MappingLine.Level);
        NextMappingLine.SetFilter("Sort No.", '>%1', MappingLine."Sort No.");
        if NextMappingLine.FindFirst() then begin
            SortNo := MappingLine."Sort No.";
            MappingLine."Sort No." := NextMappingLine."Sort No.";
            NextMappingLine."Sort No." := SortNo;
            MappingLine.Modify(true);
            NextMappingLine.Modify(true);
        end;
        SortLines(MappingLine."Mapping Code");
    end;

    procedure SortLines(MappingCode: Code[20])
    var
        MappingLine: Record "EOS IC Out. Mapping Lines";
        SortNo: Integer;
    begin
        SortNo := 10000;
        MappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        MappingLine.SetRange("Mapping Code", MappingCode);
        MappingLine.SetRange(Level, 1);
        if MappingLine.FindSet() then
            repeat
                MappingLine."Sort No." := SortNo;
                MappingLine.Modify(true);
                SortNo += 10000;
                SortChildLines(MappingLine, SortNo);
            until MappingLine.Next() = 0;
    end;

    procedure SortChildLines(MappingLine: Record "EOS IC Out. Mapping Lines"; var SortNo: Integer)
    var
        ChildMappingLine: Record "EOS IC Out. Mapping Lines";
        InvalidLevelErr: Label 'Invalid level %1 for line %2', Comment = '%1 = level, %2 = line no.';
    begin
        ChildMappingLine.SetCurrentKey("Mapping Code", "Sort No.");
        ChildMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        ChildMappingLine.SetRange("Parent Line No.", MappingLine."Line No.");
        if ChildMappingLine.FindSet() then
            repeat
                if ChildMappingLine.Level <> MappingLine.Level + 1 then
                    // A child at the same level as its parent is repositioned under the parent of the latter.
                    if ChildMappingLine.Level = MappingLine.Level then
                        ChildMappingLine."Parent Line No." := MappingLine."Parent Line No."
                    else
                        Error(InvalidLevelErr, ChildMappingLine.Level, ChildMappingLine."Line No.");

                ChildMappingLine."Sort No." := SortNo;
                ChildMappingLine.Modify(true);
                SortNo += 10000;
                SortChildLines(ChildMappingLine, SortNo);
            until ChildMappingLine.Next() = 0;
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

    // Json tags cannot contain spaces, dots, accented letters and brackets.
    procedure GetName(FieldName: Text): Text
    begin
        exit(ConvertStr(FieldName, ' .àèéìòù()"''', '__aeeiou____'));
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
