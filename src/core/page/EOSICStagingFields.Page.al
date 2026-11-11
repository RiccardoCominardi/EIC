namespace EOS.Solutions.Intercompany;

using Microsoft.Utilities;

page 67025 "EOS IC Staging Fields"
{
    Caption = 'IC Staging Fields (EIC)';
    PageType = ListPart;
    SourceTable = "EOS IC Staging Value";
    SourceTableView = sorting("Staging Record ID", "Mapping Line No.");
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;

                field(FieldCaptionText; FieldCaptionText)
                {
                    ApplicationArea = All;
                    Caption = 'Field';
                    Editable = false;
                }
                field(DisplayValueText; DisplayValueText)
                {
                    ApplicationArea = All;
                    Caption = 'Value';

                    trigger OnValidate()
                    var
                        NewValueText: Text;
                    begin
                        // Restore the stored value first so a rejected entry does not stay in the cell.
                        NewValueText := DisplayValueText;
                        LoadRow();
                        ModifyStagingValue(NewValueText, 0, false);
                        CurrPage.Update(false);
                    end;

                    trigger OnAssistEdit()
                    begin
                        LookupEnumValue();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadRow();
    end;

    local procedure LoadRow()
    var
        Staging: Record "EOS IC Staging";
        ICMappingLine: Record "EOS IC Mapping Lines";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        StagingRecRef: RecordRef;
        StagingFieldRef: FieldRef;
    begin
        FieldCaptionText := '';
        DisplayValueText := '';
        if Rec."Staging Field No." = 0 then
            exit;
        if not Staging.Get(Rec."Staging Record ID") then
            exit;

        StagingRecRef.GetTable(Staging);
        StagingFieldRef := StagingRecRef.Field(Rec."Staging Field No.");
        if StagingMgt.FindMappingLine(Staging."Mapping Code", Rec."Staging Field No.", Rec."Json Path", ICMappingLine) then
            FieldCaptionText := ICMappingLine."Staging Caption"
        else
            FieldCaptionText := CopyStr(StagingFieldRef.Caption, 1, MaxStrLen(FieldCaptionText));
        DisplayValueText := CopyStr(GetDisplayValue(StagingFieldRef), 1, MaxStrLen(DisplayValueText));
        StagingRecRef.Close();
    end;

    local procedure IsEnumRow(): Boolean
    begin
        exit((Rec."Enum/Option Source Table No." <> 0) and (Rec."Enum/Option Source Field No." <> 0));
    end;

    local procedure GetDisplayValue(var StagingFieldRef: FieldRef): Text
    var
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        EnumOrdinal: Integer;
        EnumCaption: Text;
    begin
        if not IsEnumRow() then
            exit(Format(StagingFieldRef.Value));

        EnumOrdinal := StagingFieldRef.Value;
        EnumCaption := StagingMgt.GetEnumValueCaption(Rec."Enum/Option Source Table No.", Rec."Enum/Option Source Field No.", EnumOrdinal);
        if EnumCaption = '' then
            EnumCaption := Format(EnumOrdinal, 0, 9);
        exit(EnumCaption);
    end;

    local procedure ModifyStagingValue(NewValueText: Text; EnumOrdinal: Integer; IsEnumOrdinal: Boolean)
    var
        Staging: Record "EOS IC Staging";
        StagingRecRef: RecordRef;
        StagingFieldRef: FieldRef;
    begin
        Staging.Get(Rec."Staging Record ID");
        StagingRecRef.GetTable(Staging);
        StagingFieldRef := StagingRecRef.Field(Rec."Staging Field No.");
        if IsEnumOrdinal then
            StagingFieldRef.Value := EnumOrdinal
        else
            if IsEnumRow() then
                StagingFieldRef.Value := FindEnumOrdinal(NewValueText)
            else
                AssignValue(StagingFieldRef, NewValueText);
        StagingRecRef.SetTable(Staging);
        StagingRecRef.Close();
        Staging.Modify(true);

        LoadRow();
    end;

    local procedure AssignValue(var StagingFieldRef: FieldRef; ValueText: Text)
    var
        DecimalValue: Decimal;
        IntegerValue: Integer;
        BigIntegerValue: BigInteger;
        BooleanValue: Boolean;
        GuidValue: Guid;
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
    begin
        if StagingFieldRef.Type <> FieldType::Text then
            ValueText := DelChr(ValueText, '<>', ' ');

        // A blank entry resets the field to its default value.
        case StagingFieldRef.Type of
            FieldType::Text:
                StagingFieldRef.Value := ValueText;
            FieldType::Decimal:
                begin
                    if ValueText <> '' then
                        if not Evaluate(DecimalValue, ValueText) then
                            ErrorInvalidValue(ValueText);
                    StagingFieldRef.Value := DecimalValue;
                end;
            FieldType::Integer:
                begin
                    if ValueText <> '' then
                        if not Evaluate(IntegerValue, ValueText) then
                            ErrorInvalidValue(ValueText);
                    StagingFieldRef.Value := IntegerValue;
                end;
            FieldType::BigInteger:
                begin
                    if ValueText <> '' then
                        if not Evaluate(BigIntegerValue, ValueText) then
                            ErrorInvalidValue(ValueText);
                    StagingFieldRef.Value := BigIntegerValue;
                end;
            FieldType::Boolean:
                begin
                    if ValueText <> '' then
                        if not Evaluate(BooleanValue, ValueText) then
                            ErrorInvalidValue(ValueText);
                    StagingFieldRef.Value := BooleanValue;
                end;
            FieldType::Guid:
                begin
                    if ValueText <> '' then
                        if not Evaluate(GuidValue, ValueText) then
                            ErrorInvalidValue(ValueText);
                    StagingFieldRef.Value := GuidValue;
                end;
            FieldType::Date:
                begin
                    if ValueText <> '' then
                        if not Evaluate(DateValue, ValueText) then
                            ErrorInvalidValue(ValueText);
                    StagingFieldRef.Value := DateValue;
                end;
            FieldType::DateTime:
                begin
                    if ValueText <> '' then
                        if not Evaluate(DateTimeValue, ValueText) then
                            ErrorInvalidValue(ValueText);
                    StagingFieldRef.Value := DateTimeValue;
                end;
            FieldType::Time:
                begin
                    if ValueText <> '' then
                        if not Evaluate(TimeValue, ValueText) then
                            ErrorInvalidValue(ValueText);
                    StagingFieldRef.Value := TimeValue;
                end;
        end;
    end;

    local procedure FindEnumOrdinal(EnteredText: Text): Integer
    var
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        SourceRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        ValueIndex: Integer;
        EnumOrdinal: Integer;
    begin
        SourceRecRef.Open(Rec."Enum/Option Source Table No.");
        SourceFieldRef := SourceRecRef.Field(Rec."Enum/Option Source Field No.");
        for ValueIndex := 1 to SourceFieldRef.EnumValueCount() do begin
            EnumOrdinal := SourceFieldRef.GetEnumValueOrdinal(ValueIndex);
            if (LowerCase(StagingMgt.GetEnumValueCaption(Rec."Enum/Option Source Table No.", Rec."Enum/Option Source Field No.", EnumOrdinal)) = LowerCase(EnteredText)) or
               (LowerCase(SourceFieldRef.GetEnumValueName(ValueIndex)) = LowerCase(EnteredText))
            then begin
                SourceRecRef.Close();
                exit(EnumOrdinal);
            end;
        end;
        SourceRecRef.Close();
        ErrorInvalidValue(EnteredText);
    end;

    local procedure ErrorInvalidValue(EnteredText: Text)
    var
        InvalidValueErr: Label 'The value %1 is not valid for the field %2.', Comment = '%1 = entered value, %2 = field caption';
    begin
        Error(InvalidValueErr, EnteredText, FieldCaptionText);
    end;

    local procedure LookupEnumValue()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        NameValueLookup: Page "Name/Value Lookup";
        SourceRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        ValueIndex: Integer;
        EnumOrdinal: Integer;
        NewOrdinal: Integer;
        EnumCaption: Text;
    begin
        if not IsEnumRow() then
            exit;

        SourceRecRef.Open(Rec."Enum/Option Source Table No.");
        SourceFieldRef := SourceRecRef.Field(Rec."Enum/Option Source Field No.");
        for ValueIndex := 1 to SourceFieldRef.EnumValueCount() do begin
            EnumOrdinal := SourceFieldRef.GetEnumValueOrdinal(ValueIndex);
            EnumCaption := StagingMgt.GetEnumValueCaption(Rec."Enum/Option Source Table No.", Rec."Enum/Option Source Field No.", EnumOrdinal);
            if EnumCaption = '' then
                EnumCaption := SourceFieldRef.GetEnumValueName(ValueIndex);
            NameValueLookup.AddItem(CopyStr(EnumCaption, 1, MaxStrLen(TempNameValueBuffer.Name)), Format(EnumOrdinal, 0, 9));
        end;
        SourceRecRef.Close();

        NameValueLookup.LookupMode(true);
        NameValueLookup.Editable(false);
        if not (NameValueLookup.RunModal() in [Action::LookupOK, Action::OK]) then
            exit;
        NameValueLookup.GetRecord(TempNameValueBuffer);
        if not Evaluate(NewOrdinal, TempNameValueBuffer.Value, 9) then
            exit;

        ModifyStagingValue('', NewOrdinal, true);
        CurrPage.Update(false);
    end;

    var
        FieldCaptionText: Text[100];
        DisplayValueText: Text[2048];
}
