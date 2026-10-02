namespace EOS_Solutions.EOS_Intercompany;

using System.Security.User;

tableextension 67007 "EOS IC User Setup" extends "User Setup"
{
    fields
    {
        field(67000; "EOS IC Admin"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Admin (EIC)';
        }
    }
}