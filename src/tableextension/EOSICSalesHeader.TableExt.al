namespace EOS.Solutions.Intercompany;

using Microsoft.Sales.Document;

tableextension 67002 "EOS IC Sales Header" extends "Sales Header"
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
