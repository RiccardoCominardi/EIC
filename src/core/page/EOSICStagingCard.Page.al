namespace EOS.Solutions.Intercompany;

page 67024 "EOS IC Staging Card"
{
    Caption = 'IC Staging Record (EIC)';
    PageType = Card;
    SourceTable = "EOS IC Staging";
    SourceTableView = sorting("IC Entry No.", "Tree Order");
    DataCaptionExpression = '';
    UsageCategory = None;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            part(FieldValues; "EOS IC Staging Fields")
            {
                ApplicationArea = All;
                Caption = 'Fields';
                SubPageLink = "Staging Record ID" = field("Staging Record ID");
            }
            group(Informations)
            {
                Caption = 'Informations';
                field("Manually Modified"; Rec."Manually Modified") { ApplicationArea = All; Editable = false; ToolTip = 'Indicates whether a value in this staging record was changed manually.'; }
                field("Manually Modified At"; Rec."Manually Modified At") { ApplicationArea = All; Editable = false; ToolTip = 'Specifies when a value in this staging record was last changed manually.'; }
                field("Manually Modified By"; Rec."Manually Modified By") { ApplicationArea = All; Editable = false; ToolTip = 'Specifies the user who last changed a value in this staging record.'; }
            }
        }
    }
}
