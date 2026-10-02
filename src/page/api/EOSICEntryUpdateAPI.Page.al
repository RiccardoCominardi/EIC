namespace EOS.Solutions.Intercompany;

page 67028 "EOS IC Entry Update API"
{
    PageType = API;
    APIPublisher = 'eos';
    APIGroup = 'eci';
    APIVersion = 'v1.0';
    EntityName = 'entryUpdate';
    EntitySetName = 'entryUpdates';
    SourceTable = "EOS IC Entries";
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = true;
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
                field(icTransactionId; Rec."IC Transaction ID")
                {
                    Caption = 'IC Transaction ID';
                    Editable = false;
                }
                field(targetDocumentTypeOrdinal; TargetDocumentTypeOrdinal)
                {
                    Caption = 'Target Document Type Ordinal';
                }
                field(targetDocumentNo; Rec."Target Document No.")
                {
                    Caption = 'Target Document No.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        TargetDocumentTypeOrdinal := Rec."Target Document Type".AsInteger();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec."Target Document Type" := Enum::"EOS IC Document Types".FromInteger(TargetDocumentTypeOrdinal);
        exit(true);
    end;

    var
        TargetDocumentTypeOrdinal: Integer;
}