namespace EOS.Solutions.Intercompany;
table 67002 "EOS IC Companies"
{
    DataClassification = CustomerContent;
    Caption = 'IC Companies (EIC)';

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(3; "Connection Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Connection Code';
            TableRelation = "EOS IC Connections"."Code";
        }
        field(4; "Remote Company Id"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Remote Company Id';
        }
        field(5; "Remote Company Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Remote Company Name';
        }
        field(6; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
        }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ICFlows: Record "EOS IC Flows";
    begin
        ICFlows.Reset();
        ICFlows.SetRange("Company Code", "Code");
        ICFlows.DeleteAll(true);
    end;
}