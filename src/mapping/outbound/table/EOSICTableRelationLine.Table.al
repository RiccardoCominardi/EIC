namespace EOS.Solutions.Intercompany;

using System.Reflection;

table 67021 "EOS IC Table Relation Line"
{
    DataClassification = CustomerContent;
    Caption = 'IC Table Relation Line (EIC)';

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            ToolTip = 'Specifies the table relation that contains this field pair.';
            TableRelation = "EOS IC Table Relation Header"."Code";
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
            ToolTip = 'Specifies the sequence number of this table relation line.';
        }
        field(3; "Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
            ToolTip = 'Specifies the table that contains the source field.';
            FieldClass = FlowField;
            CalcFormula = lookup("EOS IC Table Relation Header"."Source Table No." where(Code = field(Code)));
            Editable = false;
        }
        field(4; "Source Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Field No.';
            ToolTip = 'Specifies the field number used to match source records.';
            BlankZero = true;

            trigger OnLookup()
            var
                NewFieldNo: Integer;
            begin
                Rec.CalcFields("Source Table No.");
                if LookupFieldNo(NewFieldNo, Rec."Source Table No.", Rec."Source Field No.") then
                    Rec.Validate("Source Field No.", NewFieldNo);
            end;

            trigger OnValidate()
            begin
                Rec.CalcFields("Source Table No.");
                CheckFieldExists(Rec."Source Table No.", Rec."Source Field No.");
            end;
        }
        field(5; "Target Table No."; Integer)
        {
            Caption = 'Target Table No.';
            ToolTip = 'Specifies the related table that contains the target field.';
            FieldClass = FlowField;
            CalcFormula = lookup("EOS IC Table Relation Header"."Target Table No." where(Code = field(Code)));
            Editable = false;
        }
        field(6; "Target Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Field No.';
            ToolTip = 'Specifies the field number matched against the source field.';
            BlankZero = true;

            trigger OnLookup()
            var
                NewFieldNo: Integer;
            begin
                Rec.CalcFields("Target Table No.");
                if LookupFieldNo(NewFieldNo, Rec."Target Table No.", Rec."Target Field No.") then
                    Rec.Validate("Target Field No.", NewFieldNo);
            end;

            trigger OnValidate()
            begin
                Rec.CalcFields("Target Table No.");
                CheckFieldExists(Rec."Target Table No.", Rec."Target Field No.");
            end;
        }
        field(7; "Source Field Name"; Text[80])
        {
            Caption = 'Source Field Name';
            ToolTip = 'Specifies the name of the selected source field.';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table No."), "No." = field("Source Field No.")));
            Editable = false;
        }
        field(8; "Target Field Name"; Text[80])
        {
            Caption = 'Target Field Name';
            ToolTip = 'Specifies the name of the selected target field.';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Target Table No."), "No." = field("Target Field No.")));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code", "Line No.") { Clustered = true; }
    }

    local procedure LookupFieldNo(var NewFieldNo: Integer; TableNo: Integer; CurrentFieldNo: Integer): Boolean
    var
        Field: Record Field;
        FieldsLookup: Page "Fields Lookup";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetRange(Class, Field.Class::Normal);
        if Field.Get(TableNo, CurrentFieldNo) then;

        FieldsLookup.SetRecord(Field);
        FieldsLookup.SetTableView(Field);
        FieldsLookup.LookupMode(true);
        if FieldsLookup.RunModal() <> Action::LookupOK then
            exit(false);

        FieldsLookup.GetRecord(Field);
        NewFieldNo := Field."No.";
        exit(true);
    end;

    local procedure CheckFieldExists(TableNo: Integer; FieldNo: Integer)
    var
        Field: Record Field;
        FieldNotFoundErr: Label 'The field %1 does not exist in the table %2.', Comment = '%1 = field no., %2 = table id';
    begin
        if FieldNo = 0 then
            exit;

        if not Field.Get(TableNo, FieldNo) then
            Error(FieldNotFoundErr, FieldNo, TableNo);
    end;
}
