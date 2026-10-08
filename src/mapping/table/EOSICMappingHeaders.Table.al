namespace EOS.Solutions.Intercompany;

using System.Reflection;

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
        field(7; Direction; Enum "EOS IC Direction")
        {
            DataClassification = CustomerContent;
            Caption = 'Direction';

            trigger OnValidate()
            begin
                if Rec.Direction <> xRec.Direction then
                    CheckDirectionCanChange();
            end;
        }
        field(8; "Source Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Table No.';
            BlankZero = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                Rec.TestField(Direction, Rec.Direction::Outbound);
                Rec.TestField(Enabled, false);
                CreateRootLine();
            end;
        }
        field(9; "Source Table Name"; Text[249])
        {
            Caption = 'Source Table Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Source Table No.")));
            Editable = false;
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
        field(12; "No. of Outbound Lines"; Integer)
        {
            Caption = 'No. of Outbound Lines';
            FieldClass = FlowField;
            CalcFormula = count("EOS IC Out. Mapping Lines" where("Mapping Code" = field(Code)));
            Editable = false;
        }
        field(13; "Table Filter"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Table Filter';
        }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        ICMappingLines: Record "EOS IC Mapping Lines";
        ICOutMappingLines: Record "EOS IC Out. Mapping Lines";
        ICMappingJsonNode: Record "EOS IC Mapping Json Node";
    begin
        CheckNotUsedByFlows();

        ICMappingLines.SetRange("Mapping Code", Code);
        ICMappingLines.DeleteAll(true);

        // The whole tree is deleted, so the confirmation to delete the child lines is not needed.
        ICOutMappingLines.SetRange("Mapping Code", Code);
        ICOutMappingLines.DeleteAll();

        ICMappingJsonNode.SetRange("Mapping Code", Code);
        ICMappingJsonNode.DeleteAll();
    end;

    trigger OnRename()
    var
        RenameNotAllowedErr: Label 'A mapping cannot be renamed. Export it and import it again with a new code.';
    begin
        Error(RenameNotAllowedErr);
    end;

    // Stored as language-independent view (field numbers) so that it does not depend on the user language.
    procedure SetTableFilter(TableFilterText: Text)
    var
        RecRef: RecordRef;
        OutStr: OutStream;
    begin
        Clear(Rec."Table Filter");
        if TableFilterText = '' then
            exit;

        RecRef.Open(Rec."Source Table No.");
        RecRef.SetView(TableFilterText);
        Rec."Table Filter".CreateOutStream(OutStr);
        OutStr.WriteText(RecRef.GetView(false));
    end;

    procedure GetTableFilter() TableFilterText: Text
    var
        InStr: InStream;
        LineText: Text;
    begin
        Rec.CalcFields("Table Filter");
        if not Rec."Table Filter".HasValue() then
            exit;

        Rec."Table Filter".CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(LineText);
            TableFilterText += LineText;
        end;
    end;

    procedure GetNoOfLines(): Integer
    begin
        if Rec.Direction = Rec.Direction::Outbound then begin
            Rec.CalcFields("No. of Outbound Lines");
            exit(Rec."No. of Outbound Lines");
        end;

        Rec.CalcFields("No. of Lines");
        exit(Rec."No. of Lines");
    end;

    // The first line of an outbound mapping is the record of the source table.
    local procedure CreateRootLine()
    var
        ICOutMappingLine: Record "EOS IC Out. Mapping Lines";
    begin
        if Rec."Source Table No." = 0 then
            exit;

        Rec.TestField(Code);
        ICOutMappingLine.SetRange("Mapping Code", Rec.Code);
        if not ICOutMappingLine.IsEmpty() then
            exit;

        ICOutMappingLine.Init();
        ICOutMappingLine."Mapping Code" := Rec.Code;
        ICOutMappingLine."Line No." := 10000;
        ICOutMappingLine."Sort No." := 10000;
        ICOutMappingLine.Level := 1;
        ICOutMappingLine.Validate("Line Type", ICOutMappingLine."Line Type"::Record);
        ICOutMappingLine.Validate("Table No.", Rec."Source Table No.");
        ICOutMappingLine.Insert(true);
    end;

    local procedure CheckDirectionCanChange()
    var
        DirectionInUseErr: Label 'The direction of the mapping %1 cannot be changed because it already has lines or it is used by flows.', Comment = '%1 = mapping code';
    begin
        Rec.CalcFields("No. of Lines", "No. of Outbound Lines", "No. of Flows");
        if (Rec."No. of Lines" <> 0) or (Rec."No. of Outbound Lines" <> 0) or (Rec."No. of Flows" <> 0) then
            Error(DirectionInUseErr, Rec.Code);
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
