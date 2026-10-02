namespace EOS.Solutions.Intercompany;

using Microsoft.Sales.Customer;

tableextension 67000 "EOS IC Customer" extends Customer
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
