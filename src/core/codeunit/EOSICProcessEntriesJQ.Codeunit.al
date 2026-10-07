namespace EOS.Solutions.Intercompany;

using System.Threading;

codeunit 67010 "EOS IC Process Entries JQ"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ICEntries: Record "EOS IC Entries";
        ICEntriesManagement: Codeunit "EOS IC Entries Management";
        EntryNo: Integer;
    begin
        case Rec."Parameter String" of
            'PROCESS_ENTRY':
                begin
                    ICEntries.Reset();
                    ICEntries.SetRange(Direction, ICEntries.Direction::Inbound);
                    ICEntries.SetRange(Status, ICEntries.Status::Pending);
                    if ICEntries.FindSet() then
                        repeat
                            ICEntriesManagement.ProcessEntry(ICEntries);
                        until ICEntries.Next() = 0;
                end;
            'PROCESS_STAGING':
                begin
                    ICEntries.Reset();
                    ICEntries.SetRange(Direction, ICEntries.Direction::Inbound);
                    ICEntries.SetRange(Status, ICEntries.Status::Completed);
                    ICEntries.SetRange("Staging Status", ICEntries."Staging Status"::Pending);
                    if ICEntries.FindSet() then
                        repeat
                            ICEntriesManagement.ProcessStaging(ICEntries);
                        until ICEntries.Next() = 0;
                end;
            '':
                ;
            else begin
                Evaluate(EntryNo, Rec."Parameter String");
                ICEntries.Get(EntryNo);
                ICEntriesManagement.ProcessEntry(ICEntries);
            end;

        end;
    end;
}
