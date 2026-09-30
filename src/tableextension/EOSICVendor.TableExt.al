namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Vendor;

tableextension 67001 "EOS IC Vendor" extends Vendor
{
    fields
    {
        field(67000; "EOS IC Company"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'IC Company';
            TableRelation = "EOS IC Companies".Code;
        }
    }
}
