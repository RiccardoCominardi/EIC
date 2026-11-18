namespace EOS.Solutions.Intercompany;

page 67028 "EOS IC Entry Target Doc API"
{
    PageType = API;
    APIPublisher = 'eos';
    APIGroup = 'eci';
    APIVersion = 'v1.0';
    EntityName = 'entryCreatedDocument';
    EntitySetName = 'entryCreatedDocuments';
    SourceTable = "EOS IC Created Updated Records";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    ToolTip = 'Specifies the unique system ID of the target document link.';
                    Editable = false;
                }
                field(icTransactionId; ICTransactionId)
                {
                    Caption = 'IC Transaction ID';
                    ToolTip = 'Specifies the transaction ID of the outbound entry linked to this document.';
                }
                field(targetDocumentType; Rec."Document Type")
                {
                    Caption = 'Target Document Type';
                    ToolTip = 'Specifies the type of the document created or updated in the target company.';
                }
                field(targetDocumentNo; Rec."Document No.")
                {
                    Caption = 'Target Document No.';
                    ToolTip = 'Specifies the number of the document created or updated in the target company.';
                }
                field(targetTableId; Rec."Table Id")
                {
                    Caption = 'Target Table Id';
                    ToolTip = 'Specifies the ID of the table that contains the target document.';
                }
                field(targetSystemId; Rec."Doc. System Id")
                {
                    Caption = 'Target System Id';
                    ToolTip = 'Specifies the system ID of the target document.';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ICEntries: Record "EOS IC Entries";
        ExistingTargetDocument: Record "EOS IC Created Updated Records";
        EntryNotFoundErr: Label 'No outbound entry was found for IC transaction ID %1.', Comment = '%1 = IC transaction ID';
    begin
        ICEntries.SetRange("IC Transaction ID", ICTransactionId);
        ICEntries.SetRange(Direction, ICEntries.Direction::Outbound);
        if not ICEntries.FindFirst() then
            Error(EntryNotFoundErr, Format(ICTransactionId, 0, 4));

        Rec."IC Entry No." := ICEntries."Entry No.";
        Rec.TestField("Document No.");
        Rec.TestField("Table Id");
        Rec.TestField("Doc. System Id");

        if ExistingTargetDocument.Get(Rec."IC Entry No.", Rec."Table Id", Rec."Doc. System Id") then begin
            Rec := ExistingTargetDocument;
            exit(false);
        end;

        Rec.Insert(true);
        exit(false);
    end;

    var
        ICTransactionId: Guid;
}