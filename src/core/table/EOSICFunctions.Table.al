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
        field(2; "Direction"; Enum "IC Direction Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Direction';
        }
        field(3; "Sales Order Creation Flow"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Sales Order Creation Flow';
            TableRelation = "EOS IC Flows"."Code";

            trigger OnValidate()
            begin
                CheckDuplicatedFunction(Rec.FieldNo("Sales Order Creation Flow"));
            end;
        }
        field(4; "Purchase Order Creation Flow"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Purchase Order Creation Flow';
            TableRelation = "EOS IC Flows"."Code";

            trigger OnValidate()
            begin
                CheckDuplicatedFunction(Rec.FieldNo("Purchase Order Creation Flow"));
            end;
        }
        field(5; "Confirm Sales Order Flow"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Confirm Sales Order Flow';
            TableRelation = "EOS IC Flows"."Code";

            trigger OnValidate()
            begin
                CheckDuplicatedFunction(Rec.FieldNo("Confirm Sales Order Flow"));
            end;
        }
        field(6; "Confirm Purchase Order Flow"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Confirm Purchase Order Flow';
            TableRelation = "EOS IC Flows"."Code";

            trigger OnValidate()
            begin
                CheckDuplicatedFunction(Rec.FieldNo("Confirm Purchase Order Flow"));
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