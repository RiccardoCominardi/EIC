namespace EOS.Solutions.Intercompany;

page 67032 "EOS IC Table Relation Card"
{
    Caption = 'IC Table Relation Card (EIC)';
    PageType = Card;
    SourceTable = "EOS IC Table Relation Header";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code of the table relation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the table relation.';
                }
            }
            group(Tables)
            {
                Caption = 'Tables';
                group(Source)
                {
                    Caption = 'Source';
                    field("Source Table No."; Rec."Source Table No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the table that contains the source records.';
                    }
                    field("Source Table Name"; Rec."Source Table Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the name of the source table.';
                    }
                }
                group(Target)
                {
                    Caption = 'Target';
                    field("Target Table No."; Rec."Target Table No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the related table whose records are selected.';
                    }
                    field("Target Table Name"; Rec."Target Table Name")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the name of the related target table.';
                    }
                }
            }
            part(Lines; "EOS IC Table Relation Lines")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = Code = field(Code);
                UpdatePropagation = Both;
            }
        }
    }
}
