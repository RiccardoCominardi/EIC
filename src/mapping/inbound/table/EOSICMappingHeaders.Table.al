namespace EOS.Solutions.Intercompany;

table 67016 "EOS IC Mapping Headers"
{
    DataClassification = CustomerContent;
    Caption = 'IC Mapping Headers (EIC)';
    LookupPageId = "EOS IC Mapping List";
    DrillDownPageId = "EOS IC Mapping List";

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
        field(3; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
            trigger OnValidate()
            var
                ICMappingValidation: Codeunit "EOS IC Mapping Validation";
            begin
                if Rec.Enabled then
                    ICMappingValidation.CheckForActivation(Rec.Code);
            end;
        }
        field(4; "Json File Name"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Json File Name';
            Editable = false;
        }
        field(5; "Json Imported At"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Json Imported At';
            Editable = false;
        }
        field(6; "Json Content"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Json Content';
        }
        field(10; "No. of Lines"; Integer)
        {
            Caption = 'No. of Lines';
            FieldClass = FlowField;
            CalcFormula = count("EOS IC Mapping Lines" where("Mapping Code" = field(Code)));
            Editable = false;
        }
        field(11; "No. of Flows"; Integer)
        {
            Caption = 'No. of Flows';
            FieldClass = FlowField;
            CalcFormula = count("EOS IC Flows" where("Mapping Code" = field(Code)));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ICMappingLines: Record "EOS IC Mapping Lines";
        ICMappingJsonNode: Record "EOS IC Mapping Json Node";
    begin
        CheckNotUsedByFlows();

        ICMappingLines.SetRange("Mapping Code", Code);
        ICMappingLines.DeleteAll(true);

        ICMappingJsonNode.SetRange("Mapping Code", Code);
        ICMappingJsonNode.DeleteAll();
    end;

    trigger OnRename()
    var
        RenameNotAllowedErr: Label 'A mapping cannot be renamed. Export it and import it again with a new code.';
    begin
        Error(RenameNotAllowedErr);
    end;

    procedure CheckNotUsedByFlows()
    var
        ICFlows: Record "EOS IC Flows";
        FlowList: Text;
        FlowCount: Integer;
        FlowItemLbl: Label '%1 / %2', Locked = true, Comment = '%1 = company code, %2 = flow code';
        InUseErr: Label 'The mapping %1 cannot be deleted because it is used by the following flows (company / flow): %2.', Comment = '%1 = mapping code, %2 = list of flows';
    begin
        ICFlows.SetRange("Mapping Code", Code);
        if not ICFlows.FindSet() then
            exit;

        repeat
            FlowCount += 1;
            if FlowCount <= 10 then begin
                if FlowList <> '' then
                    FlowList += ', ';
                FlowList += StrSubstNo(FlowItemLbl, ICFlows."Company Code", ICFlows.Code);
            end;
        until ICFlows.Next() = 0;

        if FlowCount > 10 then
            FlowList += ', ...';
        Error(InUseErr, Code, FlowList);
    end;
}
