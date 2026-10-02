namespace EOS.Solutions.Intercompany;

using Microsoft.Sales.History;

tableextension 67004 "EOS IC Sales Shipment Header" extends "Sales Shipment Header"
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
