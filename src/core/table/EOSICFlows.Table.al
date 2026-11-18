namespace EOS.Solutions.Intercompany;

using System.Reflection;
using System.Utilities;
table 67003 "EOS IC Flows"
{
    DataClassification = CustomerContent;
    Caption = 'IC Flows (EIC)';
    DrillDownPageId = "EOS IC Flows";
    LookupPageId = "EOS IC Flows";

    fields
    {
        field(1; "Company Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Company Code';
            ToolTip = 'Specifies the intercompany company that owns this flow.';
            TableRelation = "EOS IC Companies".Code;
            NotBlank = true;
        }
        field(2; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            ToolTip = 'Specifies the unique code of the flow within the company.';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
            ToolTip = 'Specifies a description of the flow.';
        }
        field(4; "Flow Pair Id"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Flow Pair Id';
            ToolTip = 'Specifies the identifier used to pair this flow with a flow in the remote company.';
        }
        field(5; Direction; Enum "EOS IC Direction")
        {
            DataClassification = CustomerContent;
            Caption = 'Direction';
            ToolTip = 'Specifies whether the flow sends data to or receives data from another company.';
        }
        field(8; "Auto Send"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Auto Send';
            ToolTip = 'Specifies whether outbound entries using this flow are sent automatically.';
            trigger OnValidate()
            begin
                Rec.TestField(Direction, Rec.Direction::Outbound);
            end;
        }
        field(9; "Auto Process"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Auto Process';
            ToolTip = 'Specifies whether inbound entries using this flow are processed automatically.';
            trigger OnValidate()
            begin
                Rec.TestField(Direction, Rec.Direction::Inbound);
            end;
        }
        field(10; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
            ToolTip = 'Specifies whether the flow is available for processing.';
            trigger OnValidate()
            var
                FlowNotPairedErr: Label 'The flow %1 is not paired and cannot be enabled. Pair it first.', Comment = '%1 = flow code';
            begin
                //if Rec.Enabled and (Rec."Flow Pair Id" = '') then
                //    Error(FlowNotPairedErr, Rec.Code);
            end;
        }
        field(11; "Auto Create Documents"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Auto Create Documents';
            ToolTip = 'Specifies whether documents are created automatically from inbound staging data.';
            trigger OnValidate()
            begin
                Rec.TestField(Direction, Rec.Direction::Inbound);
            end;
        }
        field(12; "Mapping Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Code';
            ToolTip = 'Specifies the mapping used to translate data for this flow.';
            TableRelation = "EOS IC Mapping Headers"."Code" where(Direction = field(Direction));

            trigger OnValidate()
            var
                ICMappingHeaders: Record "EOS IC Mapping Headers";
            begin
                if Rec."Mapping Code" = '' then
                    exit;

                ICMappingHeaders.Get(Rec."Mapping Code");
                ICMappingHeaders.TestField(Direction, Rec.Direction);
            end;
        }
        field(13; "Relation Table Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Relation Table Id';
            ToolTip = 'Specifies the ID of the table containing the source documents for this flow.';
            BlankZero = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnLookup()
            var
                ICFunctions: Codeunit "EOS IC Functions";
                NewObjectID: Integer;
                ObjType: Option "TableData","Table",,"Report",,"Codeunit";
            begin
                if ICFunctions.LookupObjectID(NewObjectID, ObjType::Table, Rec."Relation Table Id") then
                    Rec.Validate("Relation Table Id", NewObjectID);
            end;

            trigger OnValidate()
            var
                AllObj: Record AllObj;
                ObjType: option "TableData","Table",,"Report",,"Codeunit";
                ObjNotFoundErr: Label 'There is no Table with ID %1';
            begin
                Rec.TestField(Enabled, false);

                if Rec."Relation Table Id" = 0 then
                    exit;

                if not AllObj.Get(ObjType::Table, Rec."Relation Table Id") then
                    Error(ObjNotFoundErr, Rec."Relation Table Id");
            end;
        }
        field(14; "Relation Table Name"; Text[249])
        {
            Caption = 'Relation Table Name';
            ToolTip = 'Specifies the name of the table containing the source documents for this flow.';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = filter(Table), "Object ID" = field("Relation Table Id")));
            Editable = false;
        }
        field(15; "Relation Option Type"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Relation Option Type';
            ToolTip = 'Specifies the option value used to identify the source document type for this flow.';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19";
            trigger OnValidate()
            begin
                Rec.TestField(Enabled, false);
            end;
        }
    }
    keys
    {
        key(Key1; "Company Code", "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        FlowPairedErr: Label 'The flow %1 is paired and cannot be deleted. Remove the pair first.', Comment = '%1 = flow code';
    begin
        if Rec."Flow Pair Id" <> '' then
            Error(FlowPairedErr, Rec.Code);
    end;
}