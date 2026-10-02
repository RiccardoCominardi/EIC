namespace EOS.Solutions.Intercompany;

using System.Reflection;

table 67004 "EOS IC Mapping Headers"
{
    DataClassification = CustomerContent;
    Caption = 'IC Mapping Headers (EIC)';
    LookupPageId = "EOS IC Mapping List";
    DrillDownPageId = "EOS IC Mapping List";

    fields
    {
        field(1; "Company Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code';
            TableRelation = "EOS IC Companies".Code;
            NotBlank = true;
        }
        field(2; "Flow Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Flow Code';
            TableRelation = "EOS IC Flows"."Code" where("Company Code" = field("Company Code"));
            NotBlank = true;
        }
        field(3; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            NotBlank = true;
        }
        field(4; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(5; "Source Table ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            BlankZero = true;
            trigger OnValidate()
            begin
                if Rec."Source Table ID" <> xRec."Source Table ID" then
                    CheckNoLines();
            end;
        }
        field(6; "Target Table ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            BlankZero = true;
            trigger OnValidate()
            begin
                if Rec."Target Table ID" <> xRec."Target Table ID" then
                    CheckNoLines();
            end;
        }
        field(7; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
        }
    }

    keys
    {
        key(Key1; "Company Code", "Flow Code", "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ICMappingLines: Record "EOS IC Mapping Lines";
    begin
        ICMappingLines.Reset();
        ICMappingLines.SetRange("Company Code", "Company Code");
        ICMappingLines.SetRange("Flow Code", "Flow Code");
        ICMappingLines.SetRange("Mapping Code", "Code");
        ICMappingLines.DeleteAll(true);
    end;

    local procedure CheckNoLines()
    var
        ICMappingLines: Record "EOS IC Mapping Lines";
        LinesExistErr: Label 'You cannot change the table IDs while mapping lines exist.';
    begin
        ICMappingLines.SetRange("Company Code", "Company Code");
        ICMappingLines.SetRange("Flow Code", "Flow Code");
        ICMappingLines.SetRange("Mapping Code", "Code");
        if not ICMappingLines.IsEmpty() then
            Error(LinesExistErr);
    end;
}
