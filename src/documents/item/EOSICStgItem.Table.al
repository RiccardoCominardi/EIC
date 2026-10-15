namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;
using System.Security.User;

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
        field(2; "IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry No.';
            Editable = false;
        }
        field(4; "No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No.';
        }
        field(5; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(6; "Description 2"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Description 2';
        }
        field(7; Type; Text[30])
        {
            DataClassification = CustomerContent;
            Caption = 'Type';
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Base Unit of Measure';
        }
        field(9; "Item Category Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Item Category Code';
        }
        field(10; "Gen. Prod. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Gen. Prod. Posting Group';
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Inventory Posting Group';
        }
        field(12; "VAT Prod. Posting Group"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'VAT Prod. Posting Group';
        }
        field(13; "Unit Price"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Unit Price';
            DecimalPlaces = 2 : 5;
        }
        field(14; "Unit Cost"; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Unit Cost';
            DecimalPlaces = 2 : 5;
        }
        field(15; Blocked; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Blocked';
        }
        field(16; GTIN; Code[14])
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

    trigger OnModify()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(UserId());
        UserSetup.TestField("EOS IC Admin");
    end;
}
