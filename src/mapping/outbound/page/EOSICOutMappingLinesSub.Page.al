namespace EOS.Solutions.Intercompany;

using System.Reflection;

page 67030 "EOS IC Out. Mapping Lines Sub"
{
    Caption = 'IC Outbound Mapping Lines (EIC)';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "EOS IC Out. Mapping Lines";
    SourceTableView = sorting("Mapping Code", "Sort No.");
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                IndentationColumn = Rec.Level;
                IndentationControls = "Line Type";
                ShowAsTree = true;
                TreeInitialState = ExpandAll;

                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = All;
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                }
                field("Sort No."; Rec."Sort No.")
                {
                    ApplicationArea = All;
                }
                field("Parent Line No."; Rec."Parent Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Parent Table No."; Rec."Parent Table No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Attribute Type"; Rec."Attribute Type")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" <> Rec."Line Type"::Record;
                }
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::Record;
                    Style = Strong;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                    Editable = Rec."Attribute Type" = Rec."Attribute Type"::Field;
                    Style = Strong;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Blank as null"; Rec."Blank as null")
                {
                    ApplicationArea = All;
                }
                field("Json Tag"; Rec."Json Tag")
                {
                    ApplicationArea = All;
                    Caption = 'Tag Name';
                }
                field(Constant; Rec.Constant)
                {
                    ApplicationArea = All;
                    Enabled = Rec."Attribute Type" = Rec."Attribute Type"::Constant;
                }
                field("Constant Type"; Rec."Constant Type")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Attribute Type" = Rec."Attribute Type"::Constant;
                }
                field("Function"; Rec."Function")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Attribute Type" = Rec."Attribute Type"::"Function";

                    trigger OnAssistEdit()
                    begin
                        ICOutMappingLinesMgt.LookupFunction(Rec);
                    end;
                }
                field("Function Parameters"; Rec."Function Parameters")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Attribute Type" = Rec."Attribute Type"::"Function";
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
                field("Is Array"; Rec."Is Array")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Line Type" = Rec."Line Type"::Record;
                }
                field("Field Type"; Rec."Field Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                    ApplicationArea = All;
                }
                field("Encode to Base64"; Rec."Encode to Base64")
                {
                    ApplicationArea = All;
                }
                field("Record Relation"; Rec."Record Relation")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::Record;
                }
                field(HasFilterFld; HasTableFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Has Filter';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        OpenFilterPageBuilder();
                    end;
                }
                field(TableFilterFld; TableFilterText)
                {
                    ApplicationArea = All;
                    Caption = 'Table Filter';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        OpenFilterPageBuilder();
                    end;
                }
                field("Line No."; Rec."Line No.")
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
            group(LineAction)
            {
                Caption = 'Lines';

                action(AddNewLine)
                {
                    ApplicationArea = All;
                    Caption = 'Add New Line';
                    Image = New;
                    ToolTip = 'Adds a line at the same level of the current line.';

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.AddNewLine(Rec);
                    end;
                }
                action(AttachNewLine)
                {
                    ApplicationArea = All;
                    Caption = 'Attach New Line';
                    Image = Link;
                    ToolTip = 'Adds a line under the current line.';

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.AttachNewLine(Rec);
                    end;
                }
                action(DeleteLine)
                {
                    ApplicationArea = All;
                    Caption = 'Delete Line';
                    Image = Delete;
                    ToolTip = 'Deletes the selected lines.';

                    trigger OnAction()
                    var
                        ICOutMappingLines: Record "EOS IC Out. Mapping Lines";
                    begin
                        CurrPage.SetSelectionFilter(ICOutMappingLines);
                        ICOutMappingLinesMgt.DeleteLine(ICOutMappingLines);
                        CurrPage.Update(false);
                    end;
                }
                action(MoveUp)
                {
                    ApplicationArea = All;
                    Caption = 'Move Up Line';
                    Image = MoveUp;

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.MoveUp(Rec);
                    end;
                }
                action(MoveDown)
                {
                    ApplicationArea = All;
                    Caption = 'Move Down Line';
                    Image = MoveDown;

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.MoveDown(Rec);
                    end;
                }
                action(SortLines)
                {
                    ApplicationArea = All;
                    Caption = 'Sort Lines';
                    Image = SortAscending;

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.SortLines(Rec."Mapping Code");
                    end;
                }
                action(ClearTableFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Clear Filters';
                    Image = ClearFilter;

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.ClearTableFilter(Rec);
                        TableFilterText := '';
                        HasTableFilter := false;
                    end;
                }
                action(SuggestTableFields)
                {
                    ApplicationArea = All;
                    Caption = 'Suggest Table Fields';
                    Image = GetLines;
                    ToolTip = 'Adds a line for each selected field of the table of the current line.';

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.SuggestTableFields(Rec);
                    end;
                }
            }
        }
    }

    var
        ICOutMappingLinesMgt: Codeunit "EOS IC Out. Mapping Lines Mgt.";
        TableFilterText: Text;
        HasTableFilter: Boolean;

    trigger OnAfterGetRecord()
    begin
        TableFilterText := '';
        if Rec."Line Type" = Rec."Line Type"::Record then
            TableFilterText := Rec.GetTableFilter();
        HasTableFilter := TableFilterText <> '';
    end;

    local procedure OpenFilterPageBuilder()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        FilterPageBuilderPage: FilterPageBuilder;
        FilterName: Text;
    begin
        Rec.TestField("Line Type", Rec."Line Type"::Record);
        Rec.TestField("Table No.");
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Rec."Table No.");
        FilterName := AllObjWithCaption."Object Caption";

        FilterPageBuilderPage.AddTable(FilterName, Rec."Table No.");
        if TableFilterText <> '' then
            FilterPageBuilderPage.SetView(FilterName, TableFilterText);
        if FilterPageBuilderPage.RunModal() then begin
            TableFilterText := FilterPageBuilderPage.GetView(FilterName, false);
            Rec.SetTableFilter(TableFilterText);
            Rec.Modify(true);
            HasTableFilter := TableFilterText <> '';
        end;
    end;
}
