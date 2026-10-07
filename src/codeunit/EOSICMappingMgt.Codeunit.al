namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;
using System.IO;

codeunit 67013 "EOS IC Mapping Mgt."
{
    var
        ICFunctions: Codeunit "EOS IC Functions";

    procedure PopulateFromPayload(ICEntries: Record "EOS IC Entries"; HeaderObject: JsonObject; LinesArray: JsonArray)
    var
        ICMappingHeaders: Record "EOS IC Mapping Headers";
        MappingNotFoundErr: Label 'No enabled mapping was found for the flow %1 of the company %2.', Comment = '%1 = flow code, %2 = company code';
    begin
        ICMappingHeaders.SetRange("Company Code", ICEntries."Source Company");
        ICMappingHeaders.SetRange("Flow Code", ICEntries."IC Flow Code");
        ICMappingHeaders.SetRange(Enabled, true);
        if not ICMappingHeaders.FindSet() then
            Error(MappingNotFoundErr, ICEntries."IC Flow Code", ICEntries."Source Company");

        repeat
            PopulateFromMapping(ICEntries."Entry No.", ICMappingHeaders, HeaderObject, LinesArray);
        until ICMappingHeaders.Next() = 0;
    end;

    local procedure PopulateFromMapping(ICEntryNo: Integer; ICMappingHeaders: Record "EOS IC Mapping Headers"; HeaderObject: JsonObject; LinesArray: JsonArray)
    var
        LineToken: JsonToken;
        StagingEntryNo: Integer;
        NextLineNo: Integer;
    begin
        ICMappingHeaders.TestField("Header Table ID");

        StagingEntryNo := InsertHeader(ICEntryNo, ICMappingHeaders, HeaderObject);

        if ICMappingHeaders."Lines Table ID" = 0 then
            exit;

        foreach LineToken in LinesArray do begin
            NextLineNo += 10000;
            InsertLine(ICMappingHeaders, LineToken.AsObject(), StagingEntryNo, NextLineNo);
        end;
    end;

    local procedure InsertHeader(ICEntryNo: Integer; ICMappingHeaders: Record "EOS IC Mapping Headers"; HeaderObject: JsonObject): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        HeaderRecRef: RecordRef;
        MappingSection: Enum "EOS IC Mapping Section";
        StagingEntryNo: Integer;
    begin
        HeaderRecRef.Open(ICMappingHeaders."Header Table ID");
        HeaderRecRef.Init();
        ApplyMapping(ICMappingHeaders, MappingSection::Header, HeaderObject, HeaderRecRef);

        // Key fields are set after the mapping so that they cannot be overwritten by it.
        StagingEntryNo := SequenceNoMgt.GetNextSeqNo(ICMappingHeaders."Header Table ID");
        HeaderRecRef.Field(EntryNoFieldNo()).Value := StagingEntryNo;
        HeaderRecRef.Field(ICEntryNoFieldNo()).Value := ICEntryNo;
        HeaderRecRef.Insert(true);
        exit(StagingEntryNo);
    end;

    local procedure InsertLine(ICMappingHeaders: Record "EOS IC Mapping Headers"; LineObject: JsonObject; StagingEntryNo: Integer; DefaultLineNo: Integer)
    var
        LineRecRef: RecordRef;
        LineNoFieldRef: FieldRef;
        MappingSection: Enum "EOS IC Mapping Section";
        LineNo: Integer;
    begin
        LineRecRef.Open(ICMappingHeaders."Lines Table ID");
        LineRecRef.Init();
        ApplyMapping(ICMappingHeaders, MappingSection::Lines, LineObject, LineRecRef);
        LineRecRef.Field(EntryNoFieldNo()).Value := StagingEntryNo;

        // The line number comes from the mapping when available, otherwise it is generated.
        LineNoFieldRef := LineRecRef.Field(LineNoFieldNo());
        LineNo := LineNoFieldRef.Value;
        if LineNo = 0 then
            LineNoFieldRef.Value := DefaultLineNo;
        LineRecRef.Insert(true);
    end;

    local procedure ApplyMapping(ICMappingHeaders: Record "EOS IC Mapping Headers"; MappingSection: Enum "EOS IC Mapping Section"; SourceObject: JsonObject; var RecRef: RecordRef)
    var
        ICMappingLines: Record "EOS IC Mapping Lines";
        FieldRef: FieldRef;
    begin
        ICMappingLines.SetRange("Company Code", ICMappingHeaders."Company Code");
        ICMappingLines.SetRange("Flow Code", ICMappingHeaders."Flow Code");
        ICMappingLines.SetRange("Mapping Code", ICMappingHeaders.Code);
        ICMappingLines.SetRange(Section, MappingSection);
        ICMappingLines.SetFilter("Target Field No.", '<>0');
        if not ICMappingLines.FindSet() then
            exit;

        repeat
            FieldRef := RecRef.Field(ICMappingLines."Target Field No.");
            ApplyMappingLine(ICMappingLines, SourceObject, FieldRef);
        until ICMappingLines.Next() = 0;
    end;

    local procedure ApplyMappingLine(ICMappingLines: Record "EOS IC Mapping Lines"; SourceObject: JsonObject; var FieldRef: FieldRef)
    var
        JsonValue: JsonValue;
        CurrentValue: Text;
        Result: Text;
        Handled: Boolean;
    begin
        case ICMappingLines."Mapping Type" of
            ICMappingLines."Mapping Type"::Value:
                if ICMappingLines."JSON Tag" <> '' then
                    if ICFunctions.GetValue(SourceObject, ICMappingLines."JSON Tag", JsonValue) then
                        if (ICMappingLines."Source Value" <> '') and (JsonValue.AsText() = ICMappingLines."Source Value") then
                            SetFieldText(FieldRef, ICMappingLines."Target Value")
                        else
                            SetFieldValue(FieldRef, JsonValue);
            ICMappingLines."Mapping Type"::Constant:
                SetFieldText(FieldRef, ICMappingLines."Target Value");
            ICMappingLines."Mapping Type"::Transformation:
                begin
                    if ICMappingLines."JSON Tag" <> '' then
                        CurrentValue := ICFunctions.GetText(SourceObject, ICMappingLines."JSON Tag");
                    OnTransformValue(ICMappingLines, SourceObject, CurrentValue, Result, Handled);
                    if Handled then
                        SetFieldText(FieldRef, Result);
                end;
        end;
    end;

    local procedure SetFieldValue(var FieldRef: FieldRef; JsonValue: JsonValue)
    begin
        case FieldRef.Type of
            FieldType::Integer:
                FieldRef.Value := JsonValue.AsInteger();
            FieldType::BigInteger:
                FieldRef.Value := JsonValue.AsBigInteger();
            FieldType::Decimal:
                FieldRef.Value := JsonValue.AsDecimal();
            FieldType::Boolean:
                FieldRef.Value := JsonValue.AsBoolean();
            else
                SetFieldText(FieldRef, JsonValue.AsText());
        end;
    end;

    // Blank text leaves the field untouched; text longer than the field is truncated.
    local procedure SetFieldText(var FieldRef: FieldRef; ValueText: Text)
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ErrorText: Text;
        InvalidValueErr: Label 'The value cannot be mapped to the field %1 of the table %2. %3', Comment = '%1 = field caption, %2 = table caption, %3 = error detail';
    begin
        if ValueText = '' then
            exit;

        if FieldRef.Type in [FieldType::Text, FieldType::Code] then
            ValueText := CopyStr(ValueText, 1, FieldRef.Length);

        ErrorText := ConfigValidateMgt.EvaluateValue(FieldRef, ValueText, false);
        if ErrorText <> '' then
            Error(InvalidValueErr, FieldRef.Caption, FieldRef.Record().Caption, ErrorText);
    end;

    // Staging tables share the key layout: header (Entry No., IC Entry No.) and lines (Entry No., Line No.).
    local procedure EntryNoFieldNo(): Integer
    begin
        exit(1);
    end;

    local procedure ICEntryNoFieldNo(): Integer
    begin
        exit(2);
    end;

    local procedure LineNoFieldNo(): Integer
    begin
        exit(2);
    end;

    [IntegrationEvent(false, false)]
    procedure OnTransformValue(ICMappingLines: Record "EOS IC Mapping Lines"; SourceObject: JsonObject; CurrentValue: Text; var Result: Text; var Handled: Boolean)
    begin
    end;
}
