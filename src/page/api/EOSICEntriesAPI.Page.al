namespace EOS.Solutions.Intercompany;

using System.Text;

page 67013 "EOS IC Entries API"
{
    PageType = API;
    APIPublisher = 'eos';
    APIGroup = 'eci';
    APIVersion = 'v1.0';
    EntityName = 'entry';
    EntitySetName = 'entries';
    SourceTable = "EOS IC Entries";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

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
                }
                field(flowPairId; FlowPairId)
                {
                    Caption = 'Flow Pair Id';
                }
                field(sourceDocumentTypeOrdinal; SourceDocumentTypeOrdinal)
                {
                    Caption = 'Source Document Type Ordinal';
                }
                field(sourceDocumentNo; Rec."Source Document No.")
                {
                    Caption = 'Source Document No.';
                }
                field(sourceTableId; Rec."Source Table Id")
                {
                    Caption = 'Source Table Id';
                }
                field(sourceSystemId; Rec."Source System Id")
                {
                    Caption = 'Source System Id';
                }
                field(targetDocumentTypeOrdinal; TargetDocumentTypeOrdinal)
                {
                    Caption = 'Target Document Type Ordinal';
                }
                field(requestPayload; RequestPayload)
                {
                    Caption = 'Request Payload';
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ICFlows: Record "EOS IC Flows";
        ICSetup: Record "EOS IC Setup";
        Base64Convert: Codeunit "Base64 Convert";
        ICEntriesManagement: Codeunit "EOS IC Entries Management";
        FlowPairIdMissingErr: Label 'The flow pair id is required.';
        FlowNotFoundErr: Label 'No enabled inbound flow was found for the flow pair id %1.', Comment = '%1 = flow pair id';
    begin
        if FlowPairId = '' then
            Error(FlowPairIdMissingErr);

        ICFlows.SetRange("Flow Pair Id", FlowPairId);
        ICFlows.SetRange(Direction, ICFlows.Direction::Inbound);
        ICFlows.SetRange(Enabled, true);
        if not ICFlows.FindFirst() then
            Error(FlowNotFoundErr, FlowPairId);

        ICSetup.Get();
        ICSetup.TestField("Company Code");

        Rec."Entry No." := Rec.GetNextEntryNo();
        Rec."IC Flow Code" := ICFlows.Code;
        Rec.Direction := Rec.Direction::Inbound;
        Rec."Source Company" := ICFlows."Company Code";
        Rec."Target Company" := ICSetup."Company Code";
        Rec."Source Document Type" := Enum::"EOS IC Flow Document Types".FromInteger(SourceDocumentTypeOrdinal);
        Rec."Target Document Type" := Enum::"EOS IC Flow Document Types".FromInteger(TargetDocumentTypeOrdinal);
        Rec.Status := Rec.Status::Pending;
        Rec.SetBlobFields(Rec.FieldNo("Received Payload"), Base64Convert.FromBase64(RequestPayload), false);
        Rec.Insert(true);

        if ICFlows."Auto Process" then
            ICEntriesManagement.ScheduleEntryProcessing(Rec);

        exit(false);
    end;

    var
        FlowPairId: Text[100];
        RequestPayload: Text;
        SourceDocumentTypeOrdinal, TargetDocumentTypeOrdinal : Integer;
}
