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
            trigger OnValidate()
            begin
                Rec.TestField(Direction, Rec.Direction::Inbound);
            end;
        }
        field(12; "Mapping Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Code';
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
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = filter(Table), "Object ID" = field("Relation Table Id")));
            Editable = false;
        }
        field(15; "Relation Option Type"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Relation Option Type';
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