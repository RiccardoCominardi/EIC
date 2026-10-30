namespace EOS.Solutions.Intercompany;

page 67028 "EOS IC Entry Target Doc API"
{
    PageType = API;
    APIPublisher = 'eos';
    APIGroup = 'eci';
    APIVersion = 'v1.0';
    EntityName = 'entryTargetDocument';
    EntitySetName = 'entryTargetDocuments';
    SourceTable = "EOS IC Entry Target Document";
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
                    Editable = false;
                }
                field(icTransactionId; ICTransactionId)
                {
                    Caption = 'IC Transaction ID';
                }
                field(targetDocumentTypeOrdinal; TargetDocumentTypeOrdinal)
                {
                    Caption = 'Target Document Type Ordinal';
                }
                field(targetDocumentNo; Rec."Target Document No.")
                {
                    Caption = 'Target Document No.';
                }
                field(targetTableId; Rec."Target Table Id")
                {
                    Caption = 'Target Table Id';
                }
                field(targetSystemId; Rec."Target System Id")
                {
                    Caption = 'Target System Id';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ICEntries: Record "EOS IC Entries";
        ExistingTargetDocument: Record "EOS IC Entry Target Document";
        EntryNotFoundErr: Label 'No outbound entry was found for IC transaction ID %1.', Comment = '%1 = IC transaction ID';
    begin
        ICEntries.SetRange("IC Transaction ID", ICTransactionId);
        ICEntries.SetRange(Direction, ICEntries.Direction::Outbound);
        if not ICEntries.FindFirst() then
            Error(EntryNotFoundErr, Format(ICTransactionId, 0, 4));

        Rec."IC Entry No." := ICEntries."Entry No.";
        Rec."Target Flow Type" := Enum::"EOS IC Flow Types".FromInteger(TargetDocumentTypeOrdinal);
        Rec.TestField("Target Document No.");
        Rec.TestField("Target Table Id");
        Rec.TestField("Target System Id");

        if ExistingTargetDocument.Get(Rec."IC Entry No.", Rec."Target Table Id", Rec."Target System Id") then begin
            Rec := ExistingTargetDocument;
            exit(false);
        end;

        Rec.Insert(true);
        exit(false);
    end;

    var
        ICTransactionId: Guid;
        TargetDocumentTypeOrdinal: Integer;
}