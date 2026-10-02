namespace EOS.Solutions.Intercompany;
page 67030 "EOS IC Document Type"
{
    Caption = 'IC Document Type Card (EIC)';
    PageType = Document;
    UsageCategory = None;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Document Types";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
            group(Fields)
            {
                Caption = 'Fields';
                group(FieldsToGet)
                {
                    Caption = 'To get';
                    field("Company Code Field No."; Rec."Company Code Field No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Company Code';
                    }
                }
                group(FieldsToUpdate)
                {
                    Caption = 'To update';
                    field("IC Entry Field No."; Rec."IC Entry Field No.")
                    {
                        ApplicationArea = All;
                        Caption = 'IC Entry No.';
                    }
                }
            }
        }
    }
}
