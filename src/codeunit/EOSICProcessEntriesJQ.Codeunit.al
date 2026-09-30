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
        if Rec."Parameter String" <> '' then begin
            Evaluate(EntryNo, Rec."Parameter String");
            ICEntries.Get(EntryNo);
            ICEntriesManagement.ProcessEntry(ICEntries);
            exit;
        end;

        ICEntries.SetRange(Direction, ICEntries.Direction::Inbound);
        ICEntries.SetRange(Status, ICEntries.Status::Pending);
        if ICEntries.FindSet() then
            repeat
                ICEntriesManagement.ProcessEntry(ICEntries);
            until ICEntries.Next() = 0;
    end;
}
