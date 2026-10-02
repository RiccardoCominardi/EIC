namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;

table 67007 "EOS IC Stg. Sales Header"
{
    DataClassification = CustomerContent;
    Caption = 'IC Staging Sales Header (EIC)';

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
        field(3; "No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'No.';
        }
        field(4; "Sell-to Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Sell-to Customer No.';
        }
        field(5; "Order Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Order Date';
        }
        field(6; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
        }
        field(7; "Document Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Document Date';
        }
        field(8; "Requested Delivery Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Requested Delivery Date';
        }
        field(9; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Currency Code';
        }
        field(10; "External Document No."; Code[35])
        {
            DataClassification = CustomerContent;
            Caption = 'External Document No.';
        }
        field(11; "Your Reference"; Text[35])
        {
            DataClassification = CustomerContent;
            Caption = 'Your Reference';
        }
        field(12; "Payment Terms Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Payment Terms Code';
        }
        field(13; "Shipment Method Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Shipment Method Code';
        }
        field(14; "Location Code"; Code[10])
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

    [InherentPermissions(PermissionObjectType::TableData, Database::"EOS IC Stg. Sales Header", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"EOS IC Stg. Sales Header"));
    end;
}
