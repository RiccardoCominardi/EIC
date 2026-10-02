namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.History;

tableextension 67005 "EOS IC Purch. Rcpt. Header" extends "Purch. Rcpt. Header"
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
