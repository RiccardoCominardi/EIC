namespace EOS.Solutions.Intercompany;

table 67004 "EOS IC Created Updated Records"
{
    DataClassification = CustomerContent;
    Caption = 'IC Created Updated Records';
    DrillDownPageId = "EOS IC Created Updated Records";
    LookupPageId = "EOS IC Created Updated Records";

    fields
    {
        field(1; "IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry No.';
            ToolTip = 'Specifies the intercompany entry associated with this document.';
            TableRelation = "EOS IC Entries"."Entry No.";
        }
        field(2; "Document Type"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of document created or updated by the intercompany entry.';
        }
        field(3; "Document No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the document created or updated by the intercompany entry.';
        }
        field(4; "Table Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Table Id';
            ToolTip = 'Specifies the ID of the table that contains the created or updated document.';
        }
        field(5; "Doc. System Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Doc. System Id';
            ToolTip = 'Specifies the system ID of the created or updated document.';
        }
    }

    keys
    {
        key(Key1; "IC Entry No.", "Table Id", "Doc. System Id") { Clustered = true; }
        key(Key2; "Table Id", "Doc. System Id", "IC Entry No.") { }
    }
}