namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Document;

tableextension 67009 "EOS IC Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(67000; "EOS IC Source Document No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Document No. (EIC)';
            ToolTip = 'Specifies the source document number for this intercompany purchase line.';
        }
        field(67001; "EOS IC Source Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Line No. (EIC)';
            ToolTip = 'Specifies the source line number for this intercompany purchase line.';
        }
    }
}
