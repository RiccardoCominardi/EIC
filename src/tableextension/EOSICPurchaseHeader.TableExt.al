namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Document;

tableextension 67003 "EOS IC Purchase Header" extends "Purchase Header"
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
