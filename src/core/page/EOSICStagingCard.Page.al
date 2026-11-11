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
                field("Manually Modified"; Rec."Manually Modified") { ApplicationArea = All; Editable = false; }
                field("Manually Modified At"; Rec."Manually Modified At") { ApplicationArea = All; Editable = false; }
                field("Manually Modified By"; Rec."Manually Modified By") { ApplicationArea = All; Editable = false; }
            }
        }
    }
}
