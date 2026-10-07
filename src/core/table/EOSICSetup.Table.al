namespace EOS.Solutions.Intercompany;
table 67000 "EOS IC Setup"
{
    DataClassification = CustomerContent;
    Caption = 'IC Setup (ECI)';
    DrillDownPageId = "EOS IC Setup";
    LookupPageId = "EOS IC Setup";
    fields
    {
        field(1; "Code"; Code[1])
        {
            DataClassification = CustomerContent;
            Caption = 'Code', Locked = true;
        }
        field(2; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
        }
        field(3; "Company Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code';
        }
        field(4; "Interface Company"; Enum "EOS IC Companies")
        {
            DataClassification = CustomerContent;
            Caption = 'Interface Company';
        }
        field(5; "Company Code Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code Field No.';
            BlankZero = true;
        }
        field(6; "IC Entry Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry Field No.';
            BlankZero = true;
        }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}