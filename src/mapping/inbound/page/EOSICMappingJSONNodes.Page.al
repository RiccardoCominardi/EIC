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
                    StyleExpr = NameStyle;
                }
                field("Node Type"; Rec."Node Type")
                {
                    ApplicationArea = All;
                }
                field("Sample Value"; Rec."Sample Value")
                {
                    ApplicationArea = All;
                }
                field("Array Depth"; Rec."Array Depth")
                {
                    ApplicationArea = All;
                }
                field(Path; Rec.Path)
                {
                    ApplicationArea = All;
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
