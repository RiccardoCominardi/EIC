namespace EOS.Solutions.Intercompany;

using System.Security.User;

pageextension 67005 "EOS IC User Setup" extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("EOS IC Admin"; Rec."EOS IC Admin")
            {
                ApplicationArea = All;
            }
        }
    }
}