namespace EOS.Solutions.Intercompany;

using Microsoft.Sales.Customer;

pageextension 67000 "EOS IC Customer Card" extends "Customer Card"
{
    layout
    {
        addlast(General)
        {
            field("EOS IC Company"; Rec."EOS IC Company")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the intercompany company associated with this customer.';
            }
        }
    }
}
