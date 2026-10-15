namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;
using System.Security.User;

table 67009 "EOS IC Stg. Purch. Header"
{
    DataClassification = CustomerContent;
    Caption = 'IC Staging Purchase Header (EIC)';

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
        field(6; "Order Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Order Date';
        }
        field(7; "Posting Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Posting Date';
        }
        field(8; "Document Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Document Date';
        }
        field(9; "Requested Receipt Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Requested Receipt Date';
        }
        field(10; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Currency Code';
        }
        field(11; "Vendor Order No."; Code[35])
        {
            DataClassification = CustomerContent;
            Caption = 'Vendor Order No.';
        }
        field(12; "Your Reference"; Text[35])
        {
            DataClassification = CustomerContent;
            Caption = 'Your Reference';
        }
        field(13; "Payment Terms Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Payment Terms Code';
        }
        field(14; "Shipment Method Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Shipment Method Code';
        }
        field(15; "Location Code"; Code[10])
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

    [InherentPermissions(PermissionObjectType::TableData, Database::"EOS IC Stg. Purch. Header", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"EOS IC Stg. Purch. Header"));
    end;

    trigger OnModify()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(UserId());
        UserSetup.TestField("EOS IC Admin");
    end;
}
