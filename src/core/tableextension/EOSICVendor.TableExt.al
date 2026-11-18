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
            ToolTip = 'Specifies the intercompany company associated with this vendor.';
            TableRelation = "EOS IC Companies".Code;
        }
    }
}
