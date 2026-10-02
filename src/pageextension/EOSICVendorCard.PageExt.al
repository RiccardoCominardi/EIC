namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Vendor;

pageextension 67001 "EOS IC Vendor Card" extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("EOS IC Company"; Rec."EOS IC Company")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the intercompany company associated with this vendor.';
            }
        }
    }
}
