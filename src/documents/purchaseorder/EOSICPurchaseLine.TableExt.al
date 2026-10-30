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
        }
        field(67001; "EOS IC Source Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Line No. (EIC)';
        }
    }
}
