namespace EOS.Solutions.Intercompany;

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
                }
                field("Target Table Name"; Rec."Target Table Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    HideValue = not NodeEditable;
                }
                field("Target Field No."; Rec."Target Field No.")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                }
                field("Target Field Name"; Rec."Target Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    HideValue = not NodeEditable;
                }
                field("Mapping Type"; Rec."Mapping Type")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                }
                field("Source Value"; Rec."Source Value")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                }
                field("Target Value"; Rec."Target Value")
                {
                    ApplicationArea = All;
                    Editable = NodeEditable;
                    HideValue = not NodeEditable;
                }
            }
        }
    }

    var
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";
        NodeName, NodeStyle : Text;
        SourceValueEditable, NodeEditable : Boolean;

    trigger OnAfterGetRecord()
    begin
        SourceValueEditable := true;
        NodeEditable := true;
        NodeName := ICJsonPathMgt.GetNodeName(Rec."Json Path");
        if Rec."Is Structure" then begin
            NodeName := NodeName.Replace('[]', '');
            if NodeName = '' then
                NodeName := '[]';
            NodeStyle := Format(PageStyle::Strong);
            NodeEditable := false;
            SourceValueEditable := false;
        end else begin
            NodeStyle := Format(PageStyle::Standard);
            if Rec."Mapping Type" in [Rec."Mapping Type"::Constant] then
                SourceValueEditable := false;
        end;
    end;

}
