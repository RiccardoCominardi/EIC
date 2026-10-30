namespace EOS.Solutions.Intercompany;

using Microsoft.Sales.Document;

tableextension 67008 "EOS IC Sales Line" extends "Sales Line"
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
