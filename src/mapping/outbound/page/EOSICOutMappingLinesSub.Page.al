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
                    ToolTip = 'Specifies whether the line creates a JSON record or an attribute.';
                }
                field(Level; Rec.Level)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the nesting level of this line in the JSON structure.';
                }
                field("Sort No."; Rec."Sort No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the order in which this line is written to the JSON output.';
                }
                field("Parent Line No."; Rec."Parent Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the line number of the parent record in the mapping tree.';
                }
                field("Parent Table No."; Rec."Parent Table No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the table that contains the parent record.';
                }
                field("Attribute Type"; Rec."Attribute Type")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" <> Rec."Line Type"::Record;
                    ToolTip = 'Specifies whether the attribute value comes from a field, a constant, or a function.';
                }
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::Record;
                    ToolTip = 'Specifies the table used to create the record for this mapping line.';
                    Style = Strong;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the table used by this record line.';
                    Style = Strong;
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                    Editable = Rec."Attribute Type" = Rec."Attribute Type"::Field;
                    ToolTip = 'Specifies the source field used to create this JSON attribute.';
                    Style = Strong;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the source field selected for this attribute.';
                    Style = Strong;
                }
                field("Blank as null"; Rec."Blank as null")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether a blank value is written as JSON null.';
                }
                field("Json Tag"; Rec."Json Tag")
                {
                    ApplicationArea = All;
                    Caption = 'Tag Name';
                    ToolTip = 'Specifies the JSON property name written for this attribute or record.';
                }
                field(Constant; Rec.Constant)
                {
                    ApplicationArea = All;
                    Enabled = Rec."Attribute Type" = Rec."Attribute Type"::Constant;
                    ToolTip = 'Specifies the fixed value written when the attribute type is Constant.';
                }
                field("Constant Type"; Rec."Constant Type")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Attribute Type" = Rec."Attribute Type"::Constant;
                    ToolTip = 'Specifies the data type of the constant value.';
                }
                field("Function"; Rec."Function")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Attribute Type" = Rec."Attribute Type"::"Function";
                    ToolTip = 'Specifies the function used to calculate the attribute value.';

                    trigger OnAssistEdit()
                    begin
                        ICOutMappingLinesMgt.LookupFunction(Rec);
                    end;
                }
                field("Function Parameters"; Rec."Function Parameters")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Attribute Type" = Rec."Attribute Type"::"Function";
                    ToolTip = 'Specifies the parameters passed to the selected function.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum length of the value written to JSON.';
                    Style = Strong;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of this mapping line.';
                    Style = Strong;
                }
                field("Is Array"; Rec."Is Array")
                {
                    ApplicationArea = All;
                    Enabled = Rec."Line Type" = Rec."Line Type"::Record;
                    ToolTip = 'Specifies whether the records created by this line are written as a JSON array.';
                }
                field("Field Type"; Rec."Field Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the data type of the selected source field.';
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the standard transformation rule applied to the source value.';
                }
                field("Transformation Order"; Rec."Transformation Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether transliteration or string replacement is applied first.';
                }
                field("Transliteration Code"; Rec."Transliteration Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transliteration applied to the value after the transformation rule and before the length limit and the Base64 encoding (Text and Code fields only).';
                }
                field("String Replacement Code"; Rec."String Replacement Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the complete string replacement applied to text output from a field or function.';
                }
                field("Encode to Base64"; Rec."Encode to Base64")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the text or code value is encoded as Base64.';
                }
                field("Record Relation"; Rec."Record Relation")
                {
                    ApplicationArea = All;
                    Editable = Rec."Line Type" = Rec."Line Type"::Record;
                    ToolTip = 'Specifies the table relation used to find records related to the parent record.';
                }
                field(HasFilterFld; HasTableFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Has Filter';
                    Editable = false;
                    ToolTip = 'Indicates whether a table filter is applied to this record line.';

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
                    ToolTip = 'Specifies the filter applied to records included in this JSON array.';

                    trigger OnAssistEdit()
                    begin
                        OpenFilterPageBuilder();
                    end;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique number of this mapping line.';
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
                    ToolTip = 'Moves the selected line up in the mapping order.';
                    Image = MoveUp;

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.MoveUp(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(MoveDown)
                {
                    ApplicationArea = All;
                    Caption = 'Move Down Line';
                    ToolTip = 'Moves the selected line down in the mapping order.';
                    Image = MoveDown;

                    trigger OnAction()
                    begin
                        ICOutMappingLinesMgt.MoveDown(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(SortLines)
                {
                    ApplicationArea = All;
                    Caption = 'Sort Lines';
                    ToolTip = 'Sorts the lines of the outbound mapping.';
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
                    ToolTip = 'Removes the table filter from the selected record line.';
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
