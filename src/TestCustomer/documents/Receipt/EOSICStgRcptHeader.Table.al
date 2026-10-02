namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;

table 67013 "EOS IC Stg. Rcpt. Header"
{
    DataClassification = CustomerContent;
    Caption = 'IC Staging Receipt Header (EIC)';

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
        field(5; "Buy-from Vendor No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Buy-from Vendor No.';
        }
        field(6; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
        }
        field(7; "Order No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Order No.';
        }
        field(8; "Vendor Shipment No."; Code[35])
        {
            DataClassification = CustomerContent;
            Caption = 'Vendor Shipment No.';
        }
        field(9; "Location Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Location Code';
        }
    }

    keys
    {
        key(Key1; "Entry No.") { Clustered = true; }
        key(Key2; "IC Entry No.") { }
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"EOS IC Stg. Rcpt. Header", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"EOS IC Stg. Rcpt. Header"));
    end;
}
