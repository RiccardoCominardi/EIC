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
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(3; "Environment Type"; Enum "EOS IC Environment Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Environment Type';
        }
        field(4; "Environment Name"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Environment Name';
        }
        field(5; "API Base Url"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'API Base Url';
        }
        field(6; "Authentication Type"; Enum "EOS IC Authentication Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Authentication Type';
        }
        field(7; "Tenant ID"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Tenant ID';
        }
        field(8; "Client Id"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Client Id';
        }
        field(9; "Secret Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Secret Id';
        }
        field(10; "Token Url"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Token Url';
        }
        field(11; "Redirect Url"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Redirect Url';
        }
        field(12; Scope; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Scope';
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