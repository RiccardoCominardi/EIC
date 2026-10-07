namespace EOS.Solutions.Intercompany;
interface "EOS IC Authentication"
{
    procedure TestConnection(ICConnections: Record "EOS IC Connections");
    procedure GetToken(ICConnections: Record "EOS IC Connections") AccessToken: SecretText;
}