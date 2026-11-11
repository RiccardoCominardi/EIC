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
                    StyleExpr = NodeStyle;
                    Editable = false;
                }
                field("Target Table ID"; Rec."Target Table ID")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    Visible = ShowLegacyTargets;
                }
                field("Target Table Name"; Rec."Target Table Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    HideValue = not NodeEditable;
                    Visible = ShowLegacyTargets;
                }
                field("Target Field No."; Rec."Target Field No.")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    Visible = ShowLegacyTargets;
                }
                field("Target Field Name"; Rec."Target Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    HideValue = not NodeEditable;
                    Visible = ShowLegacyTargets;
                }
                field("Staging Field No."; Rec."Staging Field No.")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    Visible = ShowUnifiedTargets;
                }
                field("Staging Field Name"; StagingFieldName)
                {
                    Caption = 'Staging Field Name';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = ShowUnifiedTargets;
                }
                field("Enum/Option Source Table No."; Rec."Enum/Option Source Table No.")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    Visible = ShowUnifiedTargets;
                }
                field("Enum/Option Source Field No."; Rec."Enum/Option Source Field No.")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    Visible = ShowUnifiedTargets;
                }
                field("Staging Caption"; Rec."Staging Caption")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    Visible = ShowUnifiedTargets;
                }
                field("Show in Staging List"; Rec."Show in Staging List")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    Visible = ShowUnifiedTargets;
                    ToolTip = 'Specifies that this mapped value is included in the unified staging tree summary.';
                }
                field("Is Key Field"; Rec."Is Key Field")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                    Visible = ShowLegacyTargets;
                    ToolTip = 'Specifies that the target field is part of the primary key of the target table, after the entry number and the key fields of the parent table. Its value identifies each record created from the elements of the array.';
                }
                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                }
                field("Constant Text"; Rec."Constant Text")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                }
                field("Transformation Order"; Rec."Transformation Order")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
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
            action(SuggestMapping)
            {
                ApplicationArea = All;
                Caption = 'Suggest Mapping';
                Image = SuggestField;
                Visible = ShowUnifiedTargets;
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
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
        NodeName, NodeStyle : Text;
        StagingFieldName: Text[80];
        NodeEditable, ShowLegacyTargets, ShowUnifiedTargets, CanSuggestMapping : Boolean;

    trigger OnAfterGetRecord()
    begin
        ShowUnifiedTargets := false;
        CanSuggestMapping := false;
        if ICMappingHeader.Get(Rec."Mapping Code") then begin
            ShowUnifiedTargets := ICMappingHeader."Unified Staging";
            CanSuggestMapping := ShowUnifiedTargets and not ICMappingHeader.Enabled;
        end;
        ShowLegacyTargets := not ShowUnifiedTargets;

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
    end;

}
