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
                    ToolTip = 'Specifies the unique system ID of the intercompany entry.';
                    Editable = false;
                }
                field(icTransactionId; Rec."IC Transaction ID")
                {
                    Caption = 'IC Transaction ID';
                    ToolTip = 'Specifies the transaction identifier shared by the connected companies.';
                }
                field(flowPairId; FlowPairId)
                {
                    Caption = 'Flow Pair Id';
                    ToolTip = 'Specifies the identifier of the inbound flow used to route the entry.';
                }
                field(requestPayload; RequestPayload)
                {
                    Caption = 'Request Payload';
                    ToolTip = 'Specifies the Base64-encoded JSON payload of the inbound entry.';
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
        Rec."Relation Table Id" := ICFlows."Relation Table Id";
        Rec."Relation Option Type" := ICFlows."Relation Option Type";
        Rec.Status := Rec.Status::Pending;
        Rec.SetBlobFields(Rec.FieldNo("Received Payload"), Base64Convert.FromBase64(RequestPayload), false);
        Rec.Insert(true);

        if ICFlows."Auto Process" then
            ICEntriesManagement.ScheduleEntryProcessing(Rec, 'PROCESS_ENTRY');

        exit(false);
    end;

    var
        FlowPairId: Text[100];
        RequestPayload: Text;
}
