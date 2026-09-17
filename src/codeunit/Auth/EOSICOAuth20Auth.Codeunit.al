namespace EOS.Solutions.Intercompany;
using System.Security.Authentication;

codeunit 67000 "EOS IC OAuth 2.0 Auth." implements "EOS IC Authentication"
{
    var
        AccessTokenEmptyErr: Label 'Unable to get an access token.';

    [NonDebuggable]
    procedure TestConnection(ICConnections: Record "EOS IC Connections");
    var
        AccessToken: SecretText;
        ConnectionSuccessfulMsg: Label 'Connection successful';
    begin
        AccessToken := GetToken(ICConnections);
        if AccessToken.IsEmpty() then
            Error(AccessTokenEmptyErr);

        Message(ConnectionSuccessfulMsg);
    end;

    [NonDebuggable]
    procedure GetToken(ICConnections: Record "EOS IC Connections") AccessToken: SecretText;
    var
        OAuth2: Codeunit OAuth2;
        TokenUrl, ScopeText, RedirectUrl : Text;
        MissingClientSecretErr: Label 'Client secret is missing for connection %1.', Comment = '%1 = Connection code';
        TokenRequestFailedErr: Label 'Unable to get an access token for connection %1. Details: %2', Comment = '%1 = connection code, %2 = error details';
    begin
        ICConnections.TestField("Client Id");
        ICConnections.TestField("Token Url");
        ICConnections.TestField(Scope);

        if not ICConnections.HasToken(ICConnections."Secret Id") then
            Error(MissingClientSecretErr, ICConnections.Code);

        TokenUrl := NormalizeText(ICConnections."Token Url");
        ScopeText := NormalizeText(ICConnections.Scope);
        RedirectUrl := NormalizeText(ICConnections."Redirect Url");

        if not OAuth2.AcquireTokenWithClientCredentials(ICConnections."Client Id", ICConnections.GetTokenAsSecretText(ICConnections."Secret Id"), TokenUrl, RedirectUrl, ScopeText, AccessToken) then
            Error(TokenRequestFailedErr, ICConnections.Code, GetLastErrorText());

        if AccessToken.IsEmpty() then
            Error(AccessTokenEmptyErr);

        exit(AccessToken);
    end;

    local procedure NormalizeText(InputText: Text): Text
    begin
        exit(DelChr(DelChr(InputText, '<', ' '), '>', ' '));
    end;
}