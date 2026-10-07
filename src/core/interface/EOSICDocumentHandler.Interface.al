namespace EOS.Solutions.Intercompany;
interface "EOS IC Document Handler"
{
    procedure BuildPayload(SourceRecord: Variant; ICFlows: Record "EOS IC Flows"): JsonObject;
    procedure ProcessStaging(var ICEntries: Record "EOS IC Entries");
    procedure ShowStagingRecord(ICEntries: Record "EOS IC Entries");
}