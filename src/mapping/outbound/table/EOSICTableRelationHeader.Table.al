namespace EOS.Solutions.Intercompany;

using System.Reflection;

table 67020 "EOS IC Table Relation Header"
{
    DataClassification = CustomerContent;
    Caption = 'IC Table Relation Header (EIC)';
    LookupPageId = "EOS IC Table Relation List";
    DrillDownPageId = "EOS IC Table Relation List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            ToolTip = 'Specifies the unique code of the table relation.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
            ToolTip = 'Specifies a description of the table relation.';
        }
        field(3; "Source Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Table No.';
            ToolTip = 'Specifies the table that contains the source records.';
            BlankZero = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(4; "Target Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Target Table No.';
            ToolTip = 'Specifies the related table whose records are selected.';
            BlankZero = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(5; "Source Table Name"; Text[249])
        {
            Caption = 'Source Table Name';
            ToolTip = 'Specifies the name of the source table.';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Source Table No.")));
            Editable = false;
        }
        field(6; "Target Table Name"; Text[249])
        {
            Caption = 'Target Table Name';
            ToolTip = 'Specifies the name of the related target table.';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Target Table No.")));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ICTableRelationLine: Record "EOS IC Table Relation Line";
    begin
        CheckNotUsedByMappings();

        ICTableRelationLine.SetRange(Code, Rec.Code);
        ICTableRelationLine.DeleteAll(true);
    end;

    local procedure CheckNotUsedByMappings()
    var
        ICOutMappingLine: Record "EOS IC Out. Mapping Lines";
        InUseErr: Label 'The table relation %1 cannot be deleted because it is used by the line %2 of the mapping %3.', Comment = '%1 = relation code, %2 = line no., %3 = mapping code';
    begin
        ICOutMappingLine.SetRange("Record Relation", Rec.Code);
        if ICOutMappingLine.FindFirst() then
            Error(InUseErr, Rec.Code, ICOutMappingLine."Line No.", ICOutMappingLine."Mapping Code");
    end;
}
