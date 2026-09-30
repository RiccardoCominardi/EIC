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
        field(3; "Buy-from Vendor No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Buy-from Vendor No.';
        }
        field(4; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
        }
        field(5; "Order No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Order No.';
        }
        field(6; "Vendor Shipment No."; Code[35])
        {
            DataClassification = CustomerContent;
            Caption = 'Vendor Shipment No.';
        }
        field(7; "Location Code"; Code[10])
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
