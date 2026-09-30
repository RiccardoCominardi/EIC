namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;

table 67015 "EOS IC Stg. Item"
{
    DataClassification = CustomerContent;
    Caption = 'IC Staging Item (EIC)';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(100; "IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry No.';
            Editable = false;
        }
        field(101; Status; Enum "EOS IC Staging Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Status';
            trigger OnValidate()
            var
                ICEntriesManagement: Codeunit "EOS IC Entries Management";
            begin
                ICEntriesManagement.UpdateStagingStatus(Rec."IC Entry No.", Rec.Status);
            end;
        }
        field(2; "No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No.';
        }
        field(3; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(4; "Description 2"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Description 2';
        }
        field(5; Type; Text[30])
        {
            DataClassification = CustomerContent;
            Caption = 'Type';
        }
        field(6; "Base Unit of Measure"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Base Unit of Measure';
        }
        field(7; "Item Category Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Item Category Code';
        }
        field(8; "Gen. Prod. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Gen. Prod. Posting Group';
        }
        field(9; "Inventory Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Inventory Posting Group';
        }
        field(10; "VAT Prod. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'VAT Prod. Posting Group';
        }
        field(11; "Unit Price"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Unit Price';
            DecimalPlaces = 2 : 5;
        }
        field(12; "Unit Cost"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Unit Cost';
            DecimalPlaces = 2 : 5;
        }
        field(13; Blocked; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Blocked';
        }
        field(14; GTIN; Code[14])
        {
            DataClassification = CustomerContent;
            Caption = 'GTIN';
        }
    }

    keys
    {
        key(Key1; "Entry No.") { Clustered = true; }
        key(Key2; "IC Entry No.") { }
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"EOS IC Stg. Item", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"EOS IC Stg. Item"));
    end;
}
