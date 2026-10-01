namespace EOS.Solutions.Intercompany;

using System.Text;

codeunit 67002 "EOS IC Try Functions"
{
    trigger OnRun()
    begin
        case FunctionCode of
            'SEND_ENTRY':
                TrySendEntry();
            'PROCESS_ENTRY':
                TryProcessEntry();
            'PROCESS_STAGING':
                TryProcessStaging();
        end;

        OnAfterRun(FunctionCode);
    end;

    local procedure TrySendEntry()
    var
        ICEntries: Record "EOS IC Entries";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DocVariant);
        if not DocVariant.IsRecord then
            Error(Text000Err);

        RecRef.SetTable(ICEntries);
        SendEntry(ICEntries);
    end;

    local procedure TryProcessEntry()
    var
        ICEntries: Record "EOS IC Entries";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DocVariant);
        if not DocVariant.IsRecord then
            Error(Text000Err);

        RecRef.SetTable(ICEntries);
        ProcessEntry(ICEntries);
    end;

    local procedure ProcessEntry(ICEntries: Record "EOS IC Entries")
    var
        ICSetup: Record "EOS IC Setup";
        ICDocumentHandler: Interface "EOS IC Document Handler";
    begin
        ICSetup.Get();
        ICSetup.TestField(Enabled, true);

        ICDocumentHandler := ICSetup."Interface Company";
        ICDocumentHandler.LoadStaging(ICEntries);
    end;

    local procedure TryProcessStaging()
    var
        ICEntries: Record "EOS IC Entries";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DocVariant);
        if not DocVariant.IsRecord then
            Error(Text000Err);

        RecRef.SetTable(ICEntries);
        ProcessStaging(ICEntries);
        DocVariant := ICEntries;
    end;

    local procedure ProcessStaging(var ICEntries: Record "EOS IC Entries")
    var
        ICSetup: Record "EOS IC Setup";
        ICDocumentHandler: Interface "EOS IC Document Handler";
    begin
        ICSetup.Get();
        ICSetup.TestField(Enabled, true);

        ICDocumentHandler := ICSetup."Interface Company";
        ICDocumentHandler.ProcessStaging(ICEntries);
    end;

    local procedure SendEntry(ICEntries: Record "EOS IC Entries")
    var
        ICCompanies: Record "EOS IC Companies";
        ICConnections: Record "EOS IC Connections";
        ICFlows: Record "EOS IC Flows";
        ICFunctions: Codeunit "EOS IC Functions";
        ICAuthentication: Interface "EOS IC Authentication";
        AccessToken: SecretText;
        EndpointUrl: Text;
    begin
        ICCompanies.Get(ICEntries."Target Company");
        ICCompanies.TestField("Connection Code");
        ICCompanies.TestField("Remote Company Id");
        ICConnections.Get(ICCompanies."Connection Code");

        ICFlows.Get(ICEntries."Target Company", ICEntries."IC Flow Code");
        ICFlows.TestField("Flow Pair Id");

        ICAuthentication := ICConnections."Authentication Type";
        AccessToken := ICAuthentication.GetToken(ICConnections);

        EndpointUrl := ICFunctions.GetRemoteApiEndpoint(ICConnections, ICCompanies."Remote Company Id", 'entries');
        ICFunctions.ExecutePostRequest(EndpointUrl, AccessToken, BuildSendPayload(ICEntries, ICFlows));
    end;

    local procedure BuildSendPayload(ICEntries: Record "EOS IC Entries"; ICFlows: Record "EOS IC Flows") PayloadText: Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        PayloadObject: JsonObject;
    begin
        PayloadObject.Add('icTransactionId', Format(ICEntries."IC Transaction ID", 0, 4));
        PayloadObject.Add('flowPairId', ICFlows."Flow Pair Id");
        PayloadObject.Add('sourceDocumentTypeOrdinal', ICEntries."Source Document Type".AsInteger());
        PayloadObject.Add('sourceDocumentNo', ICEntries."Source Document No.");
        PayloadObject.Add('sourceTableId', ICEntries."Source Table Id");
        PayloadObject.Add('sourceSystemId', Format(ICEntries."Source System Id", 0, 4));
        PayloadObject.Add('targetDocumentTypeOrdinal', ICEntries."Target Document Type".AsInteger());
        PayloadObject.Add('requestPayload', Base64Convert.ToBase64(ICEntries.GetBlobFields(ICEntries.FieldNo("Request Payload"))));
        PayloadObject.WriteTo(PayloadText);
    end;

    procedure SetFunctionCode(NewFunctionCode: Code[50])
    begin
        FunctionCode := NewFunctionCode;
    end;

    procedure SetDocVariant(NewDocVariant: Variant)
    begin
        DocVariant := NewDocVariant;
    end;

    procedure GetDocVariant(): Variant
    begin
        exit(DocVariant);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(FunctionCode: Code[50])
    begin
    end;

    var
        DocVariant: Variant;
        FunctionCode: Code[50];
        Text000Err: label 'The provided variant is not a record.';
}