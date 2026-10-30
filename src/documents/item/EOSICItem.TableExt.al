namespace EOS.Solutions.Intercompany;

using Microsoft.Inventory.Item;

tableextension 67006 "EOS IC Item" extends Item
{
    fields
    {
        field(67000; "EOS IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entries';
        }
        field(67001; "EOS IC Source Document No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Document No. (EIC)';
        }
    }
}