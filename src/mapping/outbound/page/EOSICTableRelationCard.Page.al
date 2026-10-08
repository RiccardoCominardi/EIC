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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
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
                    }
                    field("Source Table Name"; Rec."Source Table Name")
                    {
                        ApplicationArea = All;
                    }
                }
                group(Target)
                {
                    Caption = 'Target';
                    field("Target Table No."; Rec."Target Table No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Target Table Name"; Rec."Target Table Name")
                    {
                        ApplicationArea = All;
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
