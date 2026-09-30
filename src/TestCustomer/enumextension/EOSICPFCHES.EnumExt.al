namespace EOS_Solutions.EOS_Intercompany;

using EOS.Solutions.Intercompany;

enumextension 67000 "EOS IC PFCH ES" extends "EOS IC Companies"
{
    value(67000; "EOS IC PFCH ES")
    {
        Caption = 'PFCH ES';
        Implementation = "EOS IC Document Handler" = "EOS IC PFCH ES Doc. Handler";
    }
}