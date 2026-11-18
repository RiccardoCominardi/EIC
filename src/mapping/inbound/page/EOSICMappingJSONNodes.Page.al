namespace EOS.Solutions.Intercompany;

page 67029 "EOS IC Mapping Json Nodes"
{
    Caption = 'IC Mapping Json Structure (EIC)';
    PageType = List;
    SourceTable = "EOS IC Mapping Json Node";
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = Name;
                ShowAsTree = true;
                TreeInitialState = ExpandAll;

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the JSON property or array node.';
                    StyleExpr = NameStyle;
                }
                field("Node Type"; Rec."Node Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the JSON node is an object, array, or value.';
                }
                field("Sample Value"; Rec."Sample Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value found for this node in the imported JSON sample.';
                }
                field("Array Depth"; Rec."Array Depth")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of nested arrays containing this node.';
                }
                field(Path; Rec.Path)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the full JSON path to this node in the imported sample.';
                }
            }
        }
    }

    var
        NameStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec."Has Value" then
            NameStyle := 'Standard'
        else
            NameStyle := 'Strong';
    end;
}
