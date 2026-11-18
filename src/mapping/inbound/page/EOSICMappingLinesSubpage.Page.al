namespace EOS.Solutions.Intercompany;

using System.Reflection;

page 67011 "EOS IC Mapping Lines Subpage"
{
    Caption = 'IC Mapping Lines (EIC)';
    AutoSplitKey = true;
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "EOS IC Mapping Lines";
    UsageCategory = None;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = NodeNames;
                ShowAsTree = true;
                TreeInitialState = ExpandAll;

                field(NodeNames; NodeName)
                {
                    ApplicationArea = All;
                    Caption = 'Node Name';
                    ToolTip = 'Specifies the name of the JSON node represented by this mapping line.';
                    StyleExpr = NodeStyle;
                    Editable = false;
                }
                field("Staging Field No."; Rec."Staging Field No.")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies the typed staging field that receives the mapped value.';
                }
                field("Staging Field Name"; StagingFieldName)
                {
                    Caption = 'Staging Field Name';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the name of the selected staging field.';
                }
                field("Enum/Option Source Table No."; Rec."Enum/Option Source Table No.")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies the table that defines the enum or option values for the staging field.';
                }
                field("Enum/Option Source Field No."; Rec."Enum/Option Source Field No.")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies the field that defines the enum or option values for the staging field.';
                }
                field("Staging Caption"; Rec."Staging Caption")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    ToolTip = 'Specifies the caption displayed for this value in the staging record.';
                }
                field("Show in Staging List"; Rec."Show in Staging List")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies that this mapped value is included in the unified staging tree summary.';
                }
                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies whether the staging value comes from the JSON payload, a constant, or a transformation.';
                }
                field("Constant Text"; Rec."Constant Text")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies the fixed text value assigned to this mapping line.';
                }
                field("Transformation Order"; Rec."Transformation Order")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies whether transliteration or string replacement is applied first.';
                }
                field("Transliteration Code"; Rec."Transliteration Code")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies the transliteration applied to the text read from the Json before it is written in the target field (Text and Code fields only).';
                }
                field("String Replacement Code"; Rec."String Replacement Code")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    ToolTip = 'Specifies the complete string replacement applied before the value is written in the target field (Text and Code fields only).';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MoveUp)
            {
                ApplicationArea = All;
                Caption = 'Move Up Line';
                Image = MoveUp;
                Enabled = CanMoveLine;
                ToolTip = 'Moves the selected field up within the same Json object or array.';

                trigger OnAction()
                begin
                    ICMappingMgt.MoveUp(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(MoveDown)
            {
                ApplicationArea = All;
                Caption = 'Move Down Line';
                Image = MoveDown;
                Enabled = CanMoveLine;
                ToolTip = 'Moves the selected field down within the same Json object or array.';

                trigger OnAction()
                begin
                    ICMappingMgt.MoveDown(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(SuggestMapping)
            {
                ApplicationArea = All;
                Caption = 'Suggest Mapping';
                Image = SuggestField;
                Enabled = CanSuggestMapping;
                ToolTip = 'Suggests typed unified staging fields for unassigned mapping lines using the imported Json sample.';

                trigger OnAction()
                var
                    StagingMgt: Codeunit "EOS IC Staging Mgt.";
                    SuggestedCount: Integer;
                    UnassignedCount: Integer;
                    SuggestionResultMsg: Label '%1 mapping line(s) were assigned staging fields. %2 line(s) remain unassigned because their Json value is empty, ambiguous, structural, or no compatible slot is available.', Comment = '%1 = assigned line count, %2 = unassigned line count';
                begin
                    SuggestedCount := StagingMgt.SuggestMapping(Rec."Mapping Code", UnassignedCount);
                    CurrPage.Update(false);
                    Message(SuggestionResultMsg, SuggestedCount, UnassignedCount);
                end;
            }
        }
    }

    var
        ICMappingHeader: Record "EOS IC Mapping Headers";
        Field: Record Field;
        ICMappingMgt: Codeunit "EOS IC Mapping Mgt.";
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
        NodeName, NodeStyle : Text;
        StagingFieldName: Text[80];
        NodeEditable, CanSuggestMapping, CanMoveLine : Boolean;

    trigger OnAfterGetRecord()
    begin
        CanSuggestMapping := false;
        if ICMappingHeader.Get(Rec."Mapping Code") then
            CanSuggestMapping := (ICMappingHeader.Direction = ICMappingHeader.Direction::Inbound) and not ICMappingHeader.Enabled;

        StagingFieldName := '';
        if Rec."Staging Field No." <> 0 then
            if Field.Get(Database::"EOS IC Staging", Rec."Staging Field No.") then
                StagingFieldName := Field.FieldName;

        NodeEditable := true;
        NodeName := ICJsonPathMgt.GetNodeName(Rec."Json Path");
        if Rec."Is Structure" then begin
            NodeName := NodeName.Replace('[]', '');
            if NodeName = '' then
                NodeName := '[]';
            NodeStyle := Format(PageStyle::Strong);
            NodeEditable := false;
        end else
            NodeStyle := Format(PageStyle::Standard);
        CanMoveLine := ICMappingMgt.CanMoveLine(Rec);
    end;

}
