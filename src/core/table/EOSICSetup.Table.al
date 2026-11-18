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
            ToolTip = 'Identifies the intercompany setup record.';
        }
        field(2; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
            ToolTip = 'Specifies whether the intercompany functionality is enabled.';
        }
        field(3; "Company Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code';
            ToolTip = 'Specifies the code that identifies this company to intercompany partners.';
        }
        field(5; "Company Code Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code Field No.';
            ToolTip = 'Specifies the field number that stores the intercompany company code on documents.';
            BlankZero = true;
        }
        field(6; "IC Entry Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry Field No.';
            ToolTip = 'Specifies the field number that stores the linked intercompany entry count on documents.';
            BlankZero = true;
        }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }
}