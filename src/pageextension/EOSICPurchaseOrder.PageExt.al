namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Document;

pageextension 67003 "EOS IC Purchase Order" extends "Purchase Order"
{
    layout
    {
        addlast(General)
        {
            field("EOS IC Company"; Rec."EOS IC Company")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the intercompany company associated with this document.';
            }
        }
    }
}
