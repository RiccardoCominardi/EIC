namespace EOS.Solutions.Intercompany;

using Microsoft.Intercompany.Setup;
using System.Reflection;

table 67005 "EOS IC Functions"
{
    DataClassification = CustomerContent;
    Caption = 'IC Functions (EIC)';

    fields
    {
        field(1; "Company Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code';
            NotBlank = true;
        }
        field(2; "Direction"; Enum "EOS IC Direction")
        {
            DataClassification = CustomerContent;
            Caption = 'Direction';
        }
        field(3; "Send Create Sales Order"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Send Create Sales Order';
            TableRelation = "EOS IC Flows"."Code" where("Company Code" = field("Company Code"), Direction = field(Direction));
            trigger OnValidate()
            begin
                CheckDuplicatedFunction(Rec.FieldNo("Send Create Sales Order"));
            end;
        }
        field(4; "Send Create Purch. Order"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Send Create Purch. Order';
            TableRelation = "EOS IC Flows"."Code" where("Company Code" = field("Company Code"), Direction = field(Direction));
            trigger OnValidate()
            begin
                CheckDuplicatedFunction(Rec.FieldNo("Send Create Purch. Order"));
            end;
        }
        field(5; "Send Rec. Confirm Sales Order"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Send Received Confirm Sales Order';
            TableRelation = "EOS IC Flows"."Code" where("Company Code" = field("Company Code"), Direction = field(Direction));
            trigger OnValidate()
            begin
                CheckDuplicatedFunction(Rec.FieldNo("Send Rec. Confirm Sales Order"));
            end;
        }
        field(6; "Send Rec. Confirm Purch. Order"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Send Rec. Confirm Purch. Order';
            TableRelation = "EOS IC Flows"."Code" where("Company Code" = field("Company Code"), Direction = field(Direction));
            trigger OnValidate()
            begin
                CheckDuplicatedFunction(Rec.FieldNo("Send Rec. Confirm Purch. Order"));
            end;
        }
    }

    keys
    {
        key(Key1; "Company Code", Direction)
        {
            Clustered = true;
        }
    }

    procedure CheckDuplicatedFunction(ValidatedFieldNo: Integer)
    var
        Field: Record Field;
        RecRef: RecordRef;
        ValidatedFieldRef: FieldRef;
        OtherFieldRef: FieldRef;
        ValidatedValue: Text;
        FlowAlreadyUsedErr: Label 'The flow %1 is already assigned to the field %2 of the same company and direction.', Comment = '%1 = flow code, %2 = field caption';
    begin
        RecRef.GetTable(Rec);
        ValidatedFieldRef := RecRef.Field(ValidatedFieldNo);
        ValidatedValue := Format(ValidatedFieldRef.Value());
        if ValidatedValue = '' then
            exit;

        Field.SetRange(TableNo, Database::"EOS IC Functions");
        Field.SetRange(RelationTableNo, Database::"EOS IC Flows");
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(Enabled, true);
        Field.SetFilter("No.", '<>%1', ValidatedFieldNo);
        if Field.FindSet() then
            repeat
                OtherFieldRef := RecRef.Field(Field."No.");
                if Format(OtherFieldRef.Value()) = ValidatedValue then
                    Error(FlowAlreadyUsedErr, ValidatedValue, OtherFieldRef.Caption());
            until Field.Next() = 0;
    end;
}