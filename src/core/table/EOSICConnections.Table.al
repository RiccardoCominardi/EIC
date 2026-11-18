namespace EOS.Solutions.Intercompany;
table 67001 "EOS IC Connections"
{
    DataClassification = CustomerContent;
    Caption = 'IC Connections (EIC)';
    DrillDownPageId = "EOS IC Connections List";
    LookupPageId = "EOS IC Connections List";

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            ToolTip = 'Specifies the unique code of the connection.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
            ToolTip = 'Specifies a description of the connection.';
        }
        field(3; "Environment Type"; Enum "EOS IC Environment Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Environment Type';
            ToolTip = 'Specifies whether the remote Business Central environment is online or on-premises.';
        }
        field(4; "Environment Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Environment Name';
            ToolTip = 'Specifies the name of the remote Business Central environment.';
        }
        field(5; "API Base Url"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'API Base Url';
            ToolTip = 'Specifies the base URL used for API requests to the remote Business Central environment.';
        }
        field(6; "Authentication Type"; Enum "EOS IC Authentication Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Authentication Type';
            ToolTip = 'Specifies the authentication method used to connect to the remote environment.';
        }
        field(7; "Tenant ID"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Tenant ID';
            ToolTip = 'Specifies the Microsoft Entra tenant that contains the remote Business Central environment.';
        }
        field(8; "Client Id"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Client Id';
            ToolTip = 'Specifies the application client ID used for authentication.';
        }
        field(9; "Secret Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Secret Id';
            ToolTip = 'Specifies the identifier of the credential stored securely for this connection.';
        }
        field(10; "Token Url"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Token Url';
            ToolTip = 'Specifies the OAuth 2.0 endpoint used to request access tokens.';
        }
        field(11; "Redirect Url"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Redirect Url';
            ToolTip = 'Specifies the URL to which the OAuth 2.0 authentication flow returns.';
        }
        field(12; Scope; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Scope';
            ToolTip = 'Specifies the permission scope requested for the access token.';
        }
        field(13; "Server Port"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Port';
            ToolTip = 'Specifies the port used to access the on-premises Business Central server.';
        }
        field(14; "Instance Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Instance';
            ToolTip = 'Specifies the name of the on-premises Business Central server instance.';
        }
    }

    keys
    {
        key(Key1; "Code") { Clustered = true; }
    }

    [NonDebuggable]
    procedure SetToken(var TokenKey: Guid; TokenValue: SecretText)
    begin
        if IsNullGuid(TokenKey) then
            TokenKey := CreateGuid();

        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(TokenKey, TokenValue, DataScope::Module)
        else
            IsolatedStorage.Set(TokenKey, TokenValue, DataScope::Module);
    end;

    [NonDebuggable]
    internal procedure SetTokenForceNoEncryption(var TokenKey: Guid; TokenValue: SecretText) NewToken: Boolean
    begin
        if IsNullGuid(TokenKey) then
            NewToken := true;
        if NewToken then
            TokenKey := CreateGuid();

        IsolatedStorage.Set(TokenKey, TokenValue, DataScope::Module);
    end;

    [NonDebuggable]
    procedure GetTokenAsSecretText(TokenKey: Guid) TokenValue: SecretText
    begin
        if not HasToken(TokenKey) then
            exit(TokenValue);

        IsolatedStorage.Get(TokenKey, DataScope::Module, TokenValue);
    end;

    [NonDebuggable]
    procedure DeleteToken(TokenKey: Guid)
    begin
        if not HasToken(TokenKey) then
            exit;

        IsolatedStorage.Delete(TokenKey, DataScope::Module);
    end;

    [NonDebuggable]
    procedure HasToken(TokenKey: Guid): Boolean
    begin
        exit(not IsNullGuid(TokenKey) and IsolatedStorage.Contains(TokenKey, DataScope::Module));
    end;
}