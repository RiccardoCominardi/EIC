namespace EOS.Solutions.Intercompany;

table 67004 "EOS IC Entry Target Document"
{
    DataClassification = CustomerContent;
    Caption = 'IC Entry Target Document';
    DrillDownPageId = "EOS IC Entry Target Docs";
    LookupPageId = "EOS IC Entry Target Docs";

    fields
    {
        field(1; "IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry No.';
            TableRelation = "EOS IC Entries"."Entry No.";
        }
        field(2; "Target Flow Type"; Enum "EOS IC Flow Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Target Flow Type';
        }
        field(3; "Target Document No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Target Document No.';
        }
        field(4; "Target Table Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Table Id';
        }
        field(5; "Target System Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Target System Id';
        }
    }

    keys
    {
        key(Key1; "IC Entry No.", "Target Table Id", "Target System Id") { Clustered = true; }
        key(Key2; "Target Table Id", "Target System Id", "IC Entry No.") { }
    }
}