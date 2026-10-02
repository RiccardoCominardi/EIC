namespace EOS.Solutions.Intercompany;

using System.Reflection;

table 67016 "EOS IC Document Types"
{
    DataClassification = CustomerContent;
    Caption = 'IC Document Types (EIC)';

    fields
    {
        field(3; "Document Type"; Enum "EOS IC Document Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Document Type';
            trigger OnValidate()
            begin
                UpdateTableId();
            end;
        }
        field(2; "Description"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(4; "Table Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Table Id';
        }
        field(5; "Company Code Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code Field No.';
            TableRelation = Field."No." where(TableNo = field("Table Id"), Class = const(Normal), Type = filter(Code | Text));
        }
        field(6; "IC Entry Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry Field No.';
            TableRelation = Field."No." where(TableNo = field("Table Id"), Class = const(Normal), Type = const(Integer));
        }
    }

    keys
    {
        key(Key1; "Document Type")
        {
            Clustered = true;
        }
    }

    local procedure UpdateTableId()
    begin
        case Rec."Document Type" of
            Rec."Document Type"::" ":
                ;
            else
                OnUpdateTableId(Rec);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTableId(var Rec: Record "EOS IC Document Types")
    begin
    end;
}