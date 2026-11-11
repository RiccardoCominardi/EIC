namespace EOS.Solutions.Intercompany;

page 67023 "EOS IC Staging Tree"
{
    Caption = 'IC Staging (EIC)';
    PageType = List;
    SourceTable = "EOS IC Staging";
    SourceTableView = sorting("IC Entry No.", "Tree Order");
    CardPageId = "EOS IC Staging Card";
    UsageCategory = None;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                IndentationColumn = Rec.Level;
                ShowAsTree = true;
                TreeInitialState = ExpandAll;

                field(Node; NodeName)
                {
                    ApplicationArea = All;
                    Caption = 'Node';
                    StyleExpr = NodeStyle;
                }
                field(ListSummaryColumn; ListSummary)
                {
                    ApplicationArea = All;
                    Caption = 'Main values';
                }
                field("Manually Modified"; Rec."Manually Modified")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RebuildFromOriginal)
            {
                ApplicationArea = All;
                Caption = 'Rebuild from Original Json';
                Image = Refresh;
                ToolTip = 'Recreates the unified staging records from the original received Json.';

                trigger OnAction()
                var
                    StagingMgt: Codeunit "EOS IC Staging Mgt.";
                    RebuildQst: Label 'The unified staging for entry %1 will be replaced with values from the original Json. Continue?', Comment = '%1 = entry no.';
                begin
                    if not Confirm(RebuildQst, false, ICEntryNo) then
                        exit;

                    StagingMgt.RebuildFromOriginal(ICEntryNo);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RebuildFromOriginal_Promoted; RebuildFromOriginal) { }
        }
    }

    trigger OnOpenPage()
    var
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        RootNodeLbl: Label 'Root';
    begin
        if ICEntryNo = 0 then
            Error('An IC entry must be specified.');

        StagingMgt.FillMissingMappingLineNos(ICEntryNo);
        Rec.SetRange("IC Entry No.", ICEntryNo);
        RootNodeName := RootNodeLbl;
        if Rec.FindFirst() then begin
            RootNodeName := GetRootNodeName(Rec."Mapping Code");
            if RootNodeName = '' then
                RootNodeName := RootNodeLbl;
            Rec.FindFirst();
        end;
    end;

    trigger OnAfterGetRecord()
    var
        RootNodeLbl: Label 'Root';
    begin
        if Rec.Level = 0 then
            NodeName := RootNodeName
        else
            NodeName := ICJsonPathMgt.GetNodeName(Rec."Node Identifier").Replace('[]', '');
        if NodeName = '' then
            NodeName := RootNodeLbl;

        ListSummary := BuildListSummary();

        NodeStyle := Format(PageStyle::Standard);
        if Rec.Level = 0 then
            NodeStyle := Format(PageStyle::Strong);
    end;

    local procedure BuildListSummary(): Text
    var
        ICMappingLine: Record "EOS IC Mapping Lines";
        ValueMetadata: Record "EOS IC Staging Value";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        StagingRecRef: RecordRef;
        SlotFieldRef: FieldRef;
        ValueState: Enum "EOS IC Staging Value State";
        EnumOrdinal: Integer;
        EnumCaption: Text;
        ValueText: Text;
        SummaryText: Text;
        SummaryItem: Text;
    begin
        StagingRecRef.GetTable(Rec);
        ICMappingLine.SetRange("Mapping Code", Rec."Mapping Code");
        ICMappingLine.SetRange("Array Context", Rec."Node Identifier");
        ICMappingLine.SetRange("Show in Staging List", true);
        ICMappingLine.SetFilter("Staging Field No.", '<>0');
        if ICMappingLine.FindSet() then
            repeat
                if ValueMetadata.Get(Rec."Staging Record ID", ICMappingLine."Staging Field No.") then
                    if ValueMetadata."Value State" = ValueState::Value then begin
                        SlotFieldRef := StagingRecRef.Field(ICMappingLine."Staging Field No.");
                        ValueText := Format(SlotFieldRef.Value, 0, 9);
                        if (ValueMetadata."Enum/Option Source Table No." <> 0) and (ValueMetadata."Enum/Option Source Field No." <> 0) then begin
                            EnumOrdinal := SlotFieldRef.Value;
                            EnumCaption := StagingMgt.GetEnumValueCaption(
                                ValueMetadata."Enum/Option Source Table No.", ValueMetadata."Enum/Option Source Field No.", EnumOrdinal);
                            if EnumCaption <> '' then
                                ValueText := EnumCaption;
                        end;
                        if ValueText <> '' then begin
                            SummaryItem := StrSubstNo('%1: %2', ICMappingLine."Staging Caption", ValueText);
                            if SummaryText <> '' then
                                SummaryText += ' · ';
                            SummaryText += SummaryItem;
                        end;
                    end;
            until ICMappingLine.Next() = 0;
        StagingRecRef.Close();
        exit(CopyStr(SummaryText, 1, 2048));
    end;

    local procedure GetRootNodeName(MappingCode: Code[20]): Text
    var
        ICMapping: Record "EOS IC Mapping Headers";
        JsonInStream: InStream;
        JsonSample: JsonToken;
        RootObject: JsonObject;
        RootProperties: List of [Text];
        RootValue: JsonToken;
        PropertyName: Text;
    begin
        if not ICMapping.Get(MappingCode) then
            exit('');

        ICMapping.CalcFields("Json Content");
        if not ICMapping."Json Content".HasValue() then
            exit('');
        ICMapping."Json Content".CreateInStream(JsonInStream, TextEncoding::UTF8);
        if not JsonSample.ReadFrom(JsonInStream) or not JsonSample.IsObject() then
            exit('');

        RootObject := JsonSample.AsObject();
        RootProperties := RootObject.Keys();
        if RootProperties.Count() <> 1 then
            exit('');

        PropertyName := RootProperties.Get(1);
        if not RootObject.Get(PropertyName, RootValue) or not RootValue.IsObject() then
            exit('');
        exit(UpperCase(CopyStr(PropertyName, 1, 1)) + CopyStr(PropertyName, 2));
    end;

    procedure SetICEntryNo(NewICEntryNo: Integer)
    begin
        ICEntryNo := NewICEntryNo;
    end;

    var
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
        ICEntryNo: Integer;
        NodeName: Text;
        RootNodeName: Text;
        NodeStyle: Text;
        ListSummary: Text;
}