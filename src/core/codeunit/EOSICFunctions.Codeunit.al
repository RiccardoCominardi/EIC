namespace EOS.Solutions.Intercompany;

using System.Reflection;
using System.Utilities;
codeunit 67001 "EOS IC Functions"
{
    #region CompanyInfo
    procedure GetCompanyInfos(var ICCompanies: Record "EOS IC Companies")
    var
        ICConnections: Record "EOS IC Connections";
        ICAuthentication: Interface "EOS IC Authentication";
        AccessToken: SecretText;
        EndpointUrl, ResponseText : Text;
        CompanyId, CompanyName : Text[100];
    begin
        ICCompanies.TestField("Connection Code");
        ICConnections.Get(ICCompanies."Connection Code");

        EndpointUrl := GetCompaniesEndpoint(ICConnections);

        ICAuthentication := ICConnections."Authentication Type";
        AccessToken := ICAuthentication.GetToken(ICConnections);

        ResponseText := ExecuteGetRequest(EndpointUrl, AccessToken);
        if not ResolveRemoteCompanyFromResponse(ResponseText, CompanyId, CompanyName) then
            exit;

        ICCompanies.Validate("Remote Company Id", CompanyId);
        ICCompanies.Validate("Remote Company Name", CompanyName);
        ICCompanies.Modify(true);
    end;

    local procedure GetCompaniesEndpoint(ICConnections: Record "EOS IC Connections"): Text
    var
        SaaSEndpointLbl: Label '%1/v2.0/%2/%3/api/v2.0/companies', Locked = true;
        OnPremEndpointLbl: Label '%1:%2/%3/api/v2.0/companies', Locked = true;
    begin
        ICConnections.TestField("API Base Url");
        case ICConnections."Environment Type" of
            ICConnections."Environment Type"::SaaS:
                begin
                    ICConnections.TestField("Tenant ID");
                    ICConnections.TestField("Environment Name");
                    exit(StrSubstNo(SaaSEndpointLbl, ICConnections."API Base Url", ICConnections."Tenant ID", ICConnections."Environment Name"));
                end;
            ICConnections."Environment Type"::OnPrem:
                begin
                    ICConnections.TestField("Server Port");
                    ICConnections.TestField("Instance Name");
                    exit(StrSubstNo(OnPremEndpointLbl,
                          NormalizeApiBaseUrl(ICConnections."API Base Url"),
                          ICConnections."Server Port",
                          ICConnections."Instance Name"));
                end;
        end;
    end;

    local procedure ResolveRemoteCompanyFromResponse(ResponseText: Text; var SelectedCompanyId: Text[100]; var SelectedCompanyName: Text[100]): Boolean
    var
        CompaniesArray: JsonArray;
    begin
        ReadValueArrayFromResponse(ResponseText, CompaniesArray);
        exit(SelectRemoteCompany(CompaniesArray, SelectedCompanyId, SelectedCompanyName));
    end;

    local procedure SelectRemoteCompany(CompaniesArray: JsonArray; var SelectedCompanyId: Text[100]; var SelectedCompanyName: Text[100]): Boolean
    var
        CompanyToken: JsonToken;
        CompanyObject: JsonObject;
        MenuOptions: Text;
        MenuSelection, I : Integer;
        NoCompaniesFoundErr: Label 'No remote companies were returned by the endpoint.';
        SelectCompanyPromptLbl: Label 'Select the remote company:';
    begin
        if CompaniesArray.Count() = 0 then
            Error(NoCompaniesFoundErr);

        if CompaniesArray.Count() = 1 then begin
            CompaniesArray.Get(0, CompanyToken);
            CompanyObject := CompanyToken.AsObject();
            ReadCompanyFields(CompanyObject, SelectedCompanyId, SelectedCompanyName);
            exit(true);
        end;

        for I := 0 to CompaniesArray.Count() - 1 do begin
            CompaniesArray.Get(I, CompanyToken);
            CompanyObject := CompanyToken.AsObject();

            if MenuOptions = '' then
                MenuOptions := GetDisplayNameForMenu(CompanyObject)
            else
                MenuOptions += ',' + GetDisplayNameForMenu(CompanyObject);
        end;

        MenuSelection := StrMenu(MenuOptions, 1, SelectCompanyPromptLbl);
        if MenuSelection = 0 then
            exit(false);

        CompaniesArray.Get(MenuSelection - 1, CompanyToken);
        CompanyObject := CompanyToken.AsObject();
        ReadCompanyFields(CompanyObject, SelectedCompanyId, SelectedCompanyName);
        exit(true);
    end;

    local procedure ReadCompanyFields(CompanyObject: JsonObject; var SelectedCompanyId: Text[100]; var SelectedCompanyName: Text[100])
    var
        CompanyIdText, CompanyName : Text;
        MissingCompanyIdErr: Label 'The company entry does not contain a valid "id" value.';
        MissingCompanyNameErr: Label 'The company entry does not contain a valid "name" value.', Comment = '%1 = Company id text';
    begin
        CompanyIdText := GetText(CompanyObject, 'id');
        if CompanyIdText = '' then
            Error(MissingCompanyIdErr);

        CompanyName := GetText(CompanyObject, 'name');
        if CompanyName = '' then
            Error(MissingCompanyNameErr);

        SelectedCompanyId := CopyStr(CompanyIdText, 1, MaxStrLen(SelectedCompanyId));
        SelectedCompanyName := CopyStr(CompanyName, 1, MaxStrLen(SelectedCompanyName));
    end;

    local procedure GetDisplayNameForMenu(CompanyObject: JsonObject): Text
    var
        DisplayName: Text;
        UnknownCompanyLbl: Label 'Unknown company';
    begin
        DisplayName := GetText(CompanyObject, 'displayName');
        if DisplayName = '' then
            DisplayName := GetText(CompanyObject, 'name');
        if DisplayName = '' then
            DisplayName := UnknownCompanyLbl;

        // StrMenu uses commas as separators, therefore commas in labels must be normalized.
        exit(ConvertStr(DisplayName, ',', ';'));
    end;

    #endregion CompanyInfo

    #region FlowPairing
    procedure PairFlow(var ICFlow: Record "EOS IC Flows")
    var
        ICCompanies: Record "EOS IC Companies";
        ICConnections: Record "EOS IC Connections";
        ICSetup: Record "EOS IC Setup";
        ICAuthentication: Interface "EOS IC Authentication";
        AccessToken: SecretText;
        DefaultCompanyCode: Code[20];
        FlowsEndpoint, ResponseText : Text;
        SelectedFlowId: Text[100];
        SelectedFlowCode: Code[20];
        SelectedFlowPairId: Text[100];
        NewPairId: Text[100];
        CurrentFlowAlreadyPairedErr: Label 'The current flow is already paired. Remove the existing pair before creating a new one.';
        RemoteFlowAlreadyPairedErr: Label 'The selected remote flow %1 is already paired. Remove the existing pair before creating a new one.', Comment = '%1 = remote flow code';
        PairingCompletedMsg: Label 'Flow %1 is now paired with flow %2.', Comment = '%1 = local flow code, %2 = selected remote flow code';
    begin
        ICFlow.TestField("Company Code");
        if ICFlow."Flow Pair Id" <> '' then
            Error(CurrentFlowAlreadyPairedErr);

        ICCompanies.Get(ICFlow."Company Code");
        ICCompanies.TestField("Connection Code");
        ICCompanies.TestField("Remote Company Id");
        ICConnections.Get(ICCompanies."Connection Code");

        ICSetup.Get();
        ICSetup.TestField("Company Code");
        DefaultCompanyCode := ICSetup."Company Code";

        ICAuthentication := ICConnections."Authentication Type";
        AccessToken := ICAuthentication.GetToken(ICConnections);

        FlowsEndpoint := GetFlowsEndpoint(ICConnections, ICCompanies."Remote Company Id");
        ResponseText := ExecuteGetRequest(GetFlowsListEndpoint(FlowsEndpoint, DefaultCompanyCode, GetOppositeDirection(ICFlow.Direction)), AccessToken);

        if not ResolveRemoteFlowFromResponse(ResponseText, DefaultCompanyCode, SelectedFlowId, SelectedFlowCode, SelectedFlowPairId) then
            exit;

        if SelectedFlowPairId <> '' then
            Error(RemoteFlowAlreadyPairedErr, SelectedFlowCode);

        NewPairId := CreatePairId();

        SetRemoteFlowPairId(FlowsEndpoint, AccessToken, SelectedFlowId, NewPairId);
        ICFlow.Validate("Flow Pair Id", NewPairId);
        ICFlow.Modify(true);

        Message(PairingCompletedMsg, ICFlow."Code", SelectedFlowCode);
    end;

    procedure UnpairFlow(var ICFlow: Record "EOS IC Flows")
    var
        ICCompanies: Record "EOS IC Companies";
        ICConnections: Record "EOS IC Connections";
        ICAuthentication: Interface "EOS IC Authentication";
        AccessToken: SecretText;
        FlowsEndpoint: Text;
        PairIdToRemove: Text[100];
        UnpairConfirmationQst: Label 'The current pair will be removed on both source and destination flows. Do you want to continue?';
        FlowNotPairedErr: Label 'The current flow is not paired.';
        UnpairCompletedMsg: Label 'Pair removed for flow %1.', Comment = '%1 = local flow code';
    begin
        PairIdToRemove := ICFlow."Flow Pair Id";
        if PairIdToRemove = '' then
            Error(FlowNotPairedErr);

        if not Confirm(UnpairConfirmationQst, false) then
            exit;

        ICFlow.TestField("Company Code");
        ICCompanies.Get(ICFlow."Company Code");
        ICCompanies.TestField("Connection Code");
        ICCompanies.TestField("Remote Company Id");
        ICConnections.Get(ICCompanies."Connection Code");

        ICAuthentication := ICConnections."Authentication Type";
        AccessToken := ICAuthentication.GetToken(ICConnections);
        FlowsEndpoint := GetFlowsEndpoint(ICConnections, ICCompanies."Remote Company Id");

        ClearLocalPairId(PairIdToRemove);
        ClearRemotePairId(FlowsEndpoint, AccessToken, PairIdToRemove);
        Message(UnpairCompletedMsg, ICFlow.Code);
    end;

    local procedure GetFlowsEndpoint(ICConnections: Record "EOS IC Connections"; RemoteCompanyId: Text[100]): Text
    begin
        exit(GetRemoteApiEndpoint(ICConnections, RemoteCompanyId, 'flows'));
    end;

    procedure GetRemoteApiEndpoint(ICConnections: Record "EOS IC Connections"; RemoteCompanyId: Text[100]; EntitySetName: Text): Text
    var
        RemoteCompanyGuid: Guid;
        SaaSEndpointLbl: Label '%1/v2.0/%2/%3/api/eos/eci/v1.0/companies(%4)/%5', Locked = true;
        OnPremEndpointLbl: Label '%1:%2/%3/api/eos/eci/v1.0/companies(%4)/%5', Locked = true;
        InvalidRemoteCompanyIdErr: Label 'The remote company id "%1" is not a valid GUID.', Comment = '%1 = remote company id';
    begin
        ICConnections.TestField("API Base Url");

        if not Evaluate(RemoteCompanyGuid, RemoteCompanyId) then
            Error(InvalidRemoteCompanyIdErr, RemoteCompanyId);

        case ICConnections."Environment Type" of
            ICConnections."Environment Type"::SaaS:
                begin
                    ICConnections.TestField("Tenant ID");
                    ICConnections.TestField("Environment Name");
                    exit(StrSubstNo(SaaSEndpointLbl,
                          NormalizeApiBaseUrl(ICConnections."API Base Url"),
                          ICConnections."Tenant ID",
                          ICConnections."Environment Name",
                          GetGuidText(RemoteCompanyGuid),
                          EntitySetName));
                end;
            ICConnections."Environment Type"::OnPrem:
                begin
                    ICConnections.TestField("Server Port");
                    ICConnections.TestField("Instance Name");
                    exit(StrSubstNo(OnPremEndpointLbl,
                          NormalizeApiBaseUrl(ICConnections."API Base Url"),
                          ICConnections."Server Port",
                          ICConnections."Instance Name",
                          GetGuidText(RemoteCompanyGuid),
                          EntitySetName));
                end;
        end;
    end;

    procedure UpdateSourceEntry(ICEntries: Record "EOS IC Entries")
    var
        ICCompanies: Record "EOS IC Companies";
        ICConnections: Record "EOS IC Connections";
        ICEntryTargetDocument: Record "EOS IC Created Updated Records";
        ICAuthentication: Interface "EOS IC Authentication";
        AccessToken: SecretText;
        EntryTargetDocumentsEndpoint: Text;
    begin
        ICEntries.TestField(Direction, ICEntries.Direction::Inbound);
        ICEntries.TestField("IC Transaction ID");

        ICEntryTargetDocument.SetRange("IC Entry No.", ICEntries."Entry No.");
        if ICEntryTargetDocument.IsEmpty() then
            exit;

        ICCompanies.Get(ICEntries."Source Company");
        ICCompanies.TestField("Connection Code");
        ICCompanies.TestField("Remote Company Id");
        ICConnections.Get(ICCompanies."Connection Code");

        ICAuthentication := ICConnections."Authentication Type";
        AccessToken := ICAuthentication.GetToken(ICConnections);

        EntryTargetDocumentsEndpoint := GetRemoteApiEndpoint(ICConnections, ICCompanies."Remote Company Id", 'entryCreatedDocuments');
        if ICEntryTargetDocument.FindSet() then
            repeat
                ICEntryTargetDocument.TestField("Document No.");
                ICEntryTargetDocument.TestField("Table Id");
                ICEntryTargetDocument.TestField("Doc. System Id");
                ExecutePostRequest(EntryTargetDocumentsEndpoint, AccessToken, BuildEntryTargetDocumentPayload(ICEntries, ICEntryTargetDocument));
            until ICEntryTargetDocument.Next() = 0;
    end;

    local procedure BuildEntryTargetDocumentPayload(ICEntries: Record "EOS IC Entries"; ICEntryTargetDocument: Record "EOS IC Created Updated Records") PayloadText: Text
    var
        PayloadObject: JsonObject;
    begin
        PayloadObject.Add('icTransactionId', GetGuidText(ICEntries."IC Transaction ID"));
        PayloadObject.Add('targetDocumentNo', ICEntryTargetDocument."Document No.");
        PayloadObject.Add('targetTableId', ICEntryTargetDocument."Table Id");
        PayloadObject.Add('targetSystemId', GetGuidText(ICEntryTargetDocument."Doc. System Id"));
        PayloadObject.WriteTo(PayloadText);
    end;

    local procedure GetFlowsListEndpoint(FlowsEndpoint: Text; CompanyCode: Code[20]; RemoteDirection: Enum "EOS IC Direction"): Text
    begin
        exit(FlowsEndpoint + '?$filter=companyCode%20eq%20''' + CompanyCode + '''%20and%20flowPairId%20eq%20''''%20and%20direction%20eq%20''' + GetDirectionName(RemoteDirection) + '''&$orderby=code');
    end;

    local procedure GetDirectionName(FlowDirection: Enum "EOS IC Direction"): Text
    begin
        exit(FlowDirection.Names().Get(FlowDirection.Ordinals().IndexOf(FlowDirection.AsInteger())));
    end;

    local procedure GetFlowsByPairIdEndpoint(FlowsEndpoint: Text; PairId: Text[100]): Text
    begin
        exit(FlowsEndpoint + '?$filter=flowPairId%20eq%20''' + PairId + '''');
    end;

    local procedure GetSingleFlowEndpoint(FlowsEndpoint: Text; FlowId: Text[100]): Text
    var
        FlowEndpointLbl: Label '%1(%2)', Locked = true;
    begin
        exit(StrSubstNo(FlowEndpointLbl, FlowsEndpoint, FlowId));
    end;

    local procedure ResolveRemoteFlowFromResponse(ResponseText: Text; DefaultCompanyCode: Code[20]; var SelectedFlowId: Text[100]; var SelectedFlowCode: Code[20]; var SelectedFlowPairId: Text[100]): Boolean
    var
        TempRemoteFlows: Record "EOS IC Flows" temporary;
        FlowsArray: JsonArray;
    begin
        ReadValueArrayFromResponse(ResponseText, FlowsArray);
        PopulateRemoteFlowsTemporary(FlowsArray, DefaultCompanyCode, TempRemoteFlows);
        exit(SelectRemoteFlowFromTemporaryList(TempRemoteFlows, SelectedFlowId, SelectedFlowCode, SelectedFlowPairId));
    end;

    local procedure PopulateRemoteFlowsTemporary(FlowsArray: JsonArray; DefaultCompanyCode: Code[20]; var TempRemoteFlows: Record "EOS IC Flows" temporary)
    var
        FlowToken: JsonToken;
        FlowObject: JsonObject;
        I: Integer;
    begin
        TempRemoteFlows.Reset();
        TempRemoteFlows.DeleteAll();

        for I := 0 to FlowsArray.Count() - 1 do begin
            FlowsArray.Get(I, FlowToken);
            FlowObject := FlowToken.AsObject();
            AddRemoteFlowToTemporary(FlowObject, DefaultCompanyCode, TempRemoteFlows);
        end;
    end;

    local procedure AddRemoteFlowToTemporary(FlowObject: JsonObject; DefaultCompanyCode: Code[20]; var TempRemoteFlows: Record "EOS IC Flows" temporary)
    var
        FlowIdText: Text[100];
        FlowCode: Code[20];
        FlowPairId: Text[100];
        FlowCompanyCode: Code[20];
        FlowGuid: Guid;
    begin
        ReadFlowFields(FlowObject, FlowIdText, FlowCode, FlowPairId);

        if not Evaluate(FlowGuid, FlowIdText) then
            exit;

        FlowCompanyCode := CopyStr(GetText(FlowObject, 'companyCode'), 1, MaxStrLen(FlowCompanyCode));
        if FlowCompanyCode = '' then
            FlowCompanyCode := DefaultCompanyCode;

        if FlowCompanyCode <> DefaultCompanyCode then
            exit;

        if TempRemoteFlows.Get(FlowCompanyCode, FlowCode) then
            exit;

        TempRemoteFlows.Init();
        TempRemoteFlows.SystemId := FlowGuid;
        TempRemoteFlows."Company Code" := FlowCompanyCode;
        TempRemoteFlows.Code := FlowCode;
        TempRemoteFlows.Description := CopyStr(GetText(FlowObject, 'description'), 1, MaxStrLen(TempRemoteFlows.Description));
        TempRemoteFlows."Flow Pair Id" := FlowPairId;
        TempRemoteFlows.Direction := GetDirectionFromJson(FlowObject, TempRemoteFlows.Direction);
        TempRemoteFlows."Relation Table Id" := GetJsonIntegerOrDefault(FlowObject, 'relationTableId', 0);
        TempRemoteFlows."Relation Option Type" := GetJsonIntegerOrDefault(FlowObject, 'relationOptionType', 0);
        TempRemoteFlows."Relation Table Name" := CopyStr(GetText(FlowObject, 'relationTableName'), 1, MaxStrLen(TempRemoteFlows."Relation Table Name"));
        TempRemoteFlows."Auto Send" := GetJsonBooleanOrDefault(FlowObject, 'autoSend', false);
        TempRemoteFlows."Auto Process" := GetJsonBooleanOrDefault(FlowObject, 'autoProcess', false);
        TempRemoteFlows."Auto Create Documents" := GetJsonBooleanOrDefault(FlowObject, 'autoCreateDocuments', false);
        TempRemoteFlows.Enabled := GetJsonBooleanOrDefault(FlowObject, 'enabled', false);
        TempRemoteFlows.Insert(false, true);
    end;

    local procedure SelectRemoteFlowFromTemporaryList(var TempRemoteFlows: Record "EOS IC Flows" temporary; var SelectedFlowId: Text[100]; var SelectedFlowCode: Code[20]; var SelectedFlowPairId: Text[100]): Boolean
    var
        RemoteFlowsLookupPage: Page "EOS IC Remote Flows Lookup";
        SelectedFlowGuid: Guid;
        NoFlowsFoundErr: Label 'No remote flows were returned by the endpoint.';
    begin
        if TempRemoteFlows.IsEmpty() then
            Error(NoFlowsFoundErr);

        RemoteFlowsLookupPage.LoadRemoteFlows(TempRemoteFlows);
        RemoteFlowsLookupPage.LookupMode(true);
        if RemoteFlowsLookupPage.RunModal() <> Action::LookupOK then
            exit(false);

        RemoteFlowsLookupPage.GetRecord(TempRemoteFlows);
        SelectedFlowGuid := TempRemoteFlows.SystemId;

        SelectedFlowId := CopyStr(GetGuidText(SelectedFlowGuid), 1, MaxStrLen(SelectedFlowId));
        SelectedFlowCode := TempRemoteFlows.Code;
        SelectedFlowPairId := TempRemoteFlows."Flow Pair Id";
        exit(true);
    end;

    local procedure GetOppositeDirection(FlowDirection: Enum "EOS IC Direction"): Enum "EOS IC Direction"
    var
        UnsupportedDirectionErr: Label 'Direction %1 is not supported for pairing.', Comment = '%1 = flow direction';
    begin
        if FlowDirection = FlowDirection::Inbound then
            exit(FlowDirection::Outbound);

        if FlowDirection = FlowDirection::Outbound then
            exit(FlowDirection::Inbound);

        Error(UnsupportedDirectionErr, Format(FlowDirection));
    end;

    local procedure ReadFlowFields(FlowObject: JsonObject; var SelectedFlowId: Text[100]; var SelectedFlowCode: Code[20]; var SelectedFlowPairId: Text[100])
    var
        FlowIdText, FlowCodeText : Text;
        RemoteFlowGuid: Guid;
        MissingFlowIdErr: Label 'The flow entry does not contain a valid "id" value.';
        InvalidFlowIdErr: Label 'The flow entry contains an invalid id value: %1.', Comment = '%1 = invalid flow id';
        MissingFlowCodeErr: Label 'The flow entry does not contain a valid "code" value.';
    begin
        FlowIdText := GetText(FlowObject, 'id');
        if FlowIdText = '' then
            Error(MissingFlowIdErr);

        if not Evaluate(RemoteFlowGuid, FlowIdText) then
            Error(InvalidFlowIdErr, FlowIdText);

        FlowCodeText := GetText(FlowObject, 'code');
        if FlowCodeText = '' then
            Error(MissingFlowCodeErr);

        SelectedFlowId := CopyStr(GetGuidText(RemoteFlowGuid), 1, MaxStrLen(SelectedFlowId));
        SelectedFlowCode := CopyStr(FlowCodeText, 1, MaxStrLen(SelectedFlowCode));
        SelectedFlowPairId := CopyStr(GetText(FlowObject, 'flowPairId'), 1, MaxStrLen(SelectedFlowPairId));
    end;

    local procedure GetDirectionFromJson(FlowObject: JsonObject; DefaultDirection: Enum "EOS IC Direction"): Enum "EOS IC Direction"
    var
        FlowDirection: Enum "EOS IC Direction";
    begin
        if TryParseDirectionByOrdinal(FlowObject, 'directionOrdinal', FlowDirection) then
            exit(FlowDirection);

        if TryParseDirectionByOrdinal(FlowObject, 'direction', FlowDirection) then
            exit(FlowDirection);

        exit(DefaultDirection);
    end;

    local procedure TryParseDirectionByOrdinal(FlowObject: JsonObject; PropertyName: Text; var FlowDirection: Enum "EOS IC Direction"): Boolean
    var
        DirectionOrdinal: Integer;
    begin
        if not TryGetJsonInteger(FlowObject, PropertyName, DirectionOrdinal) then
            exit(false);

        exit(Evaluate(FlowDirection, Format(DirectionOrdinal)));
    end;

    local procedure TryGetJsonInteger(SourceObject: JsonObject; PropertyName: Text; var Value: Integer): Boolean
    var
        JsonNumberText: Text;
    begin
        JsonNumberText := DelChr(DelChr(GetText(SourceObject, PropertyName), '<', ' '), '>', ' ');
        if JsonNumberText = '' then
            exit(false);

        exit(Evaluate(Value, JsonNumberText));
    end;

    local procedure GetJsonIntegerOrDefault(SourceObject: JsonObject; PropertyName: Text; DefaultValue: Integer): Integer
    var
        JsonIntegerValue: Integer;
    begin
        if TryGetJsonInteger(SourceObject, PropertyName, JsonIntegerValue) then
            exit(JsonIntegerValue);

        exit(DefaultValue);
    end;

    local procedure GetJsonBooleanOrDefault(SourceObject: JsonObject; PropertyName: Text; DefaultValue: Boolean): Boolean
    var
        JsonBooleanText: Text;
        JsonBooleanValue: Boolean;
    begin
        JsonBooleanText := LowerCase(GetText(SourceObject, PropertyName));
        if JsonBooleanText = '' then
            exit(DefaultValue);

        if JsonBooleanText = 'true' then
            exit(true);

        if JsonBooleanText = 'false' then
            exit(false);

        if Evaluate(JsonBooleanValue, JsonBooleanText) then
            exit(JsonBooleanValue);

        exit(DefaultValue);
    end;

    local procedure CreatePairId(): Text[100]
    begin
        exit(CopyStr(GetGuidText(CreateGuid()), 1, 100));
    end;

    local procedure SetRemoteFlowPairId(FlowsEndpoint: Text; AccessToken: SecretText; FlowId: Text[100]; PairId: Text[100])
    var
        PayloadText: Text;
    begin
        PayloadText := BuildFlowPairIdPayload(PairId);
        ExecutePatchRequest(GetSingleFlowEndpoint(FlowsEndpoint, FlowId), AccessToken, PayloadText);
    end;

    local procedure BuildFlowPairIdPayload(PairId: Text[100]) PayloadText: Text
    var
        PayloadObject: JsonObject;
    begin
        PayloadObject.Add('flowPairId', PairId);
        PayloadObject.WriteTo(PayloadText);
    end;

    local procedure ClearLocalPairId(PairId: Text[100])
    var
        ICFlows: Record "EOS IC Flows";
    begin
        if PairId = '' then
            exit;

        ICFlows.Reset();
        ICFlows.SetRange("Flow Pair Id", PairId);
        if ICFlows.FindSet(true) then
            repeat
                ICFlows.Validate("Flow Pair Id", '');
                ICFlows.Modify(true);
            until ICFlows.Next() = 0;
    end;

    local procedure ClearRemotePairId(FlowsEndpoint: Text; AccessToken: SecretText; PairId: Text[100])
    var
        ResponseText: Text;
        FlowsArray: JsonArray;
        FlowToken: JsonToken;
        FlowObject: JsonObject;
        FlowId: Text[100];
        I: Integer;
    begin
        if PairId = '' then
            exit;

        ResponseText := ExecuteGetRequest(GetFlowsByPairIdEndpoint(FlowsEndpoint, PairId), AccessToken);
        ReadValueArrayFromResponse(ResponseText, FlowsArray);

        for I := 0 to FlowsArray.Count() - 1 do begin
            FlowsArray.Get(I, FlowToken);
            FlowObject := FlowToken.AsObject();
            FlowId := CopyStr(GetText(FlowObject, 'id'), 1, MaxStrLen(FlowId));

            if FlowId <> '' then
                SetRemoteFlowPairId(FlowsEndpoint, AccessToken, FlowId, '');
        end;
    end;

    #endregion FlowPairing

    local procedure ReadValueArrayFromResponse(ResponseText: Text; var ValueArray: JsonArray)
    var
        ResponseObject: JsonObject;
        ValueToken: JsonToken;
        InvalidJsonErr: Label 'The endpoint response is not a valid Json payload.';
        MissingValueNodeErr: Label 'The endpoint response is missing the ''value'' node.';
        MissingValueArrayErr: Label 'The ''value'' node in the endpoint response is not an array.';
    begin
        if not ResponseObject.ReadFrom(ResponseText) then
            Error(InvalidJsonErr);

        if not ResponseObject.Get('value', ValueToken) then
            Error(MissingValueNodeErr);

        if not ValueToken.IsArray() then
            Error(MissingValueArrayErr);

        ValueArray := ValueToken.AsArray();
    end;

    local procedure NormalizeApiBaseUrl(BaseUrl: Text): Text
    begin
        BaseUrl := DelChr(DelChr(BaseUrl, '<', ' '), '>', ' ');

        if (StrLen(BaseUrl) > 0) and (BaseUrl[StrLen(BaseUrl)] = '/') then
            BaseUrl := CopyStr(BaseUrl, 1, StrLen(BaseUrl) - 1);

        exit(BaseUrl);
    end;

    local procedure GetGuidText(GuidValue: Guid): Text
    begin
        exit(LowerCase(DelChr(Format(GuidValue), '=', '{}')));
    end;

    local procedure ExecuteGetRequest(EndpointUrl: Text; AccessToken: SecretText) ResponseText: Text
    var
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        BearerTokenLbl: Label 'Bearer %1', Locked = true;
        HttpStatusErr: Label 'Error %1: %2', Locked = true;
    begin
        RequestMessage.Method := 'GET';
        RequestMessage.SetRequestUri(EndpointUrl);
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Accept', 'application/Json');

        if not AccessToken.IsEmpty() then
            RequestHeaders.Add('Authorization', SecretStrSubstNo(BearerTokenLbl, AccessToken));

        if not HttpClient.Send(RequestMessage, ResponseMessage) then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase());

        ResponseMessage.Content.ReadAs(ResponseText);
        if not ResponseMessage.IsSuccessStatusCode() then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase());
    end;

    procedure ExecutePostRequest(EndpointUrl: Text; AccessToken: SecretText; PayloadText: Text) ResponseText: Text
    var
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        BearerTokenLbl: Label 'Bearer %1', Locked = true;
        HttpStatusErr: Label 'Error %1: %2. %3', Locked = true;
    begin
        RequestMessage.Method := 'POST';
        RequestMessage.SetRequestUri(EndpointUrl);
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Accept', 'application/Json');

        if not AccessToken.IsEmpty() then
            RequestHeaders.Add('Authorization', SecretStrSubstNo(BearerTokenLbl, AccessToken));

        RequestContent.WriteFrom(PayloadText);
        RequestContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/Json');
        RequestMessage.Content := RequestContent;

        if not HttpClient.Send(RequestMessage, ResponseMessage) then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase(), '');

        ResponseMessage.Content.ReadAs(ResponseText);
        if not ResponseMessage.IsSuccessStatusCode() then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase(), ResponseText);
    end;

    local procedure ExecutePatchRequest(EndpointUrl: Text; AccessToken: SecretText; PayloadText: Text)
    var
        HttpClient: HttpClient;
        RequestMessage: HttpRequestMessage;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ContentHeaders: HttpHeaders;
        ResponseText: Text;
        BearerTokenLbl: Label 'Bearer %1', Locked = true;
        HttpStatusErr: Label 'Error %1: %2. %3', Locked = true;
    begin
        RequestMessage.Method := 'PATCH';
        RequestMessage.SetRequestUri(EndpointUrl);
        RequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Accept', 'application/Json');
        RequestHeaders.Add('If-Match', '*');

        if not AccessToken.IsEmpty() then
            RequestHeaders.Add('Authorization', SecretStrSubstNo(BearerTokenLbl, AccessToken));

        RequestContent.WriteFrom(PayloadText);
        RequestContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/Json');
        RequestMessage.Content := RequestContent;

        if not HttpClient.Send(RequestMessage, ResponseMessage) then
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase(), '');

        if not ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content.ReadAs(ResponseText);
            Error(HttpStatusErr, ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase(), ResponseText);
        end;
    end;

    #region JsonHelpers
    procedure GetValue(SourceObject: JsonObject; PropertyName: Text; var JsonValue: JsonValue): Boolean
    var
        ValueToken: JsonToken;
    begin
        if not SourceObject.Get(PropertyName, ValueToken) then
            exit(false);

        if not ValueToken.IsValue() then
            exit(false);

        JsonValue := ValueToken.AsValue();
        exit(not JsonValue.IsNull());
    end;

    procedure GetText(SourceObject: JsonObject; PropertyName: Text): Text
    var
        JsonValue: JsonValue;
    begin
        if GetValue(SourceObject, PropertyName, JsonValue) then
            exit(JsonValue.AsText());
    end;
    #endregion JsonHelpers

    procedure LookupObjectID(var NewObjectID: Integer; ObjType: option ,,,"Report",,"Codeunit"; ObjectId: Integer): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
    begin
        if AllObjWithCaption.Get(ObjType, ObjectId) then;

        AllObjWithCaption.FilterGroup(2);
        AllObjWithCaption.SetRange("Object Type", ObjType);
        AllObjWithCaption.FilterGroup(0);
        Objects.SetRecord(AllObjWithCaption);
        Objects.SetTableView(AllObjWithCaption);
        Objects.LookupMode := true;
        if Objects.RunModal() = Action::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            NewObjectID := AllObjWithCaption."Object ID";
            exit(true);
        end;

        exit(false);
    end;

    procedure AssistTableOptionTypeList(var ICFlows: Record "EOS IC Flows")
    var
        IntegerTable: Record Integer;
        PageTableValueTypeList: Page "EOS IC Table Value Type List";
        RecRef: RecordRef;
        FiRef: FieldRef;
        TextOptionArray: array[20] of Text;
        VectorLenght: Integer;
        FieldNumber: Integer;
        lActAction: Action;
    begin
        RecRef.Open(ICFlows."Relation Table Id");
        FieldNumber := GetRecordPKOptionField(RecRef, false);
        if FieldNumber = 0 then
            exit;

        FiRef := RecRef.field(FieldNumber);

        VectorLenght := SplitOptionValues(FiRef.OptionCaption, TextOptionArray);
        if VectorLenght = 0 then
            exit;

        IntegerTable.SetRange(Number, 0, VectorLenght - 1);

        Clear(PageTableValueTypeList);
        PageTableValueTypeList.LookupMode(true);
        PageTableValueTypeList.SetValue(TextOptionArray);
        PageTableValueTypeList.SetTableView(IntegerTable);

        lActAction := PageTableValueTypeList.RunModal();

        if lActAction = Action::LookupOK then begin
            if ICFlows."Relation Option Type" <> PageTableValueTypeList.GetOptionType() then
                ICFlows.Validate("Relation Option Type", PageTableValueTypeList.GetOptionType())
        end else
            if lActAction = Action::Cancel then
                ICFlows.Validate("Relation Option Type", 0);
    end;

    procedure GetRecordPKOptionField(RecordVariant: Variant; ShowError: Boolean) OptionFieldNo: Integer
    var
        FieldTable: Record "Field";
        DataTypeManagement: Codeunit "Data Type Management";
        KeyFiRef: FieldRef;
        RecRef: RecordRef;
        KRef: KeyRef;
        i, OptionFieldCounter, TableId : integer;
        Text000Err: label 'Impossible to manage for Table %1 %2 because Primary Key contain more than one field with Type Option.';
    begin
        if RecordVariant.IsInteger() then begin
            TableId := RecordVariant;
            RecRef.Open(TableId);
        end else
            DataTypeManagement.GetRecordRef(RecordVariant, RecRef);

        KRef := RecRef.KeyIndex(1);
        for i := 1 to KRef.FieldCount() do begin
            KeyFiRef := KRef.FieldIndex(i);
            FieldTable.Get(RecRef.Number(), KeyFiRef.Number());
            if FieldTable.Type = FieldTable.Type::Option then begin
                OptionFieldNo := KeyFiRef.Number();
                OptionFieldCounter += 1;
            end;
        end;

        if (OptionFieldCounter > 1) and ShowError then
            Error(Text000Err, RecRef.Number(), RecRef.Caption());
    end;

    local procedure SplitOptionValues(TextOptionString: Text; var TextOptionArray: array[20] of Text) Vector: Integer
    var
        TextOptionValue: Text;
    begin
        Clear(TextOptionArray);
        if TextOptionString = '' then
            exit(0);

        while StrPos(TextOptionString, ',') <> 0 do begin
            TextOptionValue := CopyStr(TextOptionString, 1, StrPos(TextOptionString, ',') - 1);
            TextOptionString := CopyStr(TextOptionString, StrPos(TextOptionString, ',') + 1);
            Vector += 1;
            TextOptionArray[Vector] := TextOptionValue;
        end;
        Vector += 1;
        TextOptionArray[Vector] := TextOptionString;
    end;
}