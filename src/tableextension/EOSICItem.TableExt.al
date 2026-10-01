tableextension 67006 "EOS IC Item" extends Item
{
    fields
    {
        field(67000; "EOS IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry No.';
            TableRelation = "EOS IC Entries"."Entry No.";
        }
    }
}