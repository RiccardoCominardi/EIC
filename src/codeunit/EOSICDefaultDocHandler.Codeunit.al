namespace EOS.Solutions.Intercompany;

codeunit 67011 "EOS IC Default Doc. Handler" implements "EOS IC Document Handler"
{
    procedure BuildPayload(SourceRecord: Variant; ICFlows: Record "EOS IC Flows"): JsonObject;
    begin
    end;

    procedure LoadStaging(ICEntries: Record "EOS IC Entries")
    begin
    end;

    procedure ProcessStaging(var ICEntries: Record "EOS IC Entries")
    begin
    end;

    procedure ShowStagingRecord(ICEntries: Record "EOS IC Entries")
    begin
    end;
}