namespace EOS.Solutions.Intercompany;
table 67003 "EOS IC Flows"
{
    DataClassification = CustomerContent;
    Caption = 'IC Flows (EIC)';

    fields
    {
        field(1; "Company Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code';
            TableRelation = "EOS IC Companies".Code;
            NotBlank = true;
        }
        field(2; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(4; "Flow Pair Id"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Flow Pair Id';
        }
        field(5; Direction; Enum "EOS IC Direction")
        {
            DataClassification = CustomerContent;
            Caption = 'Direction';
        }
        field(6; "Local Document Type"; Enum "EOS IC Flow Document Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Local Document Type';
        }
        field(7; "External Document Type"; Enum "EOS IC Flow Document Types")
        {
            DataClassification = CustomerContent;
            Caption = 'External Document Type';
        }
        field(8; "Auto Send"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Auto Send';
            trigger OnValidate()
            begin
                Rec.TestField(Direction, Rec.Direction::Outbound);
            end;
        }
        field(9; "Auto Process"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Auto Process';
            trigger OnValidate()
            begin
                Rec.TestField(Direction, Rec.Direction::Inbound);
            end;
        }
        field(10; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
        }
        field(11; "Auto Create Documents"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Auto Create Documents';
            trigger OnValidate()
            begin
                Rec.TestField(Direction, Rec.Direction::Inbound);
            end;
        }
    }

    keys
    {
        key(Key1; "Company Code", "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ICMappingHeaders: Record "EOS IC Mapping Headers";
    begin
        ICMappingHeaders.Reset();
        ICMappingHeaders.SetRange("Company Code", "Company Code");
        ICMappingHeaders.SetRange("Flow Code", "Code");
        ICMappingHeaders.DeleteAll(true);
    end;
}