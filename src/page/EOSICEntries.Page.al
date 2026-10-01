namespace EOS.Solutions.Intercompany;

using Microsoft.Utilities;
page 67012 "EOS IC Entries"
{
    Caption = 'IC Entries (EIC)';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    PageType = List;
    SourceTable = "EOS IC Entries";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("IC Transaction ID"; Rec."IC Transaction ID")
                {
                    ApplicationArea = All;
                }
                field("IC Flow Code"; Rec."IC Flow Code")
                {
                    ApplicationArea = All;
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                }
                field("Source Company"; Rec."Source Company")
                {
                    ApplicationArea = All;
                }
                field("Target Company"; Rec."Target Company")
                {
                    ApplicationArea = All;
                }
                field("Source Document Type"; Rec."Source Document Type")
                {
                    ApplicationArea = All;
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                    ApplicationArea = All;
                }
                field("Target Document Type"; Rec."Target Document Type")
                {
                    ApplicationArea = All;
                }
                field("Target Document No."; Rec."Target Document No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = FieldColor;
                }
                field("Staging Status"; Rec."Staging Status")
                {
                    ApplicationArea = All;
                    StyleExpr = StagingColor;

                    trigger OnDrillDown()
                    var
                        ICEntriesManagement: Codeunit "EOS IC Entries Management";
                    begin
                        ICEntriesManagement.ShowStagingRecord(Rec);
                    end;
                }
                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ShowDocument)
            {
                ApplicationArea = All;
                Caption = 'Show Document';
                Image = View;
                trigger OnAction()
                var
                    PageManagement: Codeunit "Page Management";
                    RecRef: RecordRef;
                    DocVariant: Variant;
                begin
                    case Rec.Direction of
                        Rec.Direction::Outbound:
                            begin
                                RecRef.Open(Rec."Source Table Id");
                                RecRef.GetBySystemId(Rec."Source System Id");
                            end;
                        Rec.Direction::Inbound:
                            begin
                                RecRef.Open(Rec."Target Table Id");
                                RecRef.GetBySystemId(Rec."Target System Id");
                            end;
                    end;
                    DocVariant := RecRef;
                    PageManagement.PageRun(DocVariant);
                end;
            }
        }
        area(Processing)
        {
            action(ProcessEntries)
            {
                ApplicationArea = All;
                Caption = 'Process';
                Image = NextRecord;
                ToolTip = 'Sends the selected outbound entries and populates the staging tables for the selected inbound entries.';

                trigger OnAction()
                var
                    ICEntries: Record "EOS IC Entries";
                    ICEntriesManagement: Codeunit "EOS IC Entries Management";
                begin
                    CurrPage.SetSelectionFilter(ICEntries);
                    ICEntries.SetFilter(Status, '<>%1', ICEntries.Status::Completed);
                    if ICEntries.FindSet() then
                        repeat
                            case ICEntries.Direction of
                                ICEntries.Direction::Outbound:
                                    ICEntriesManagement.SendEntry(ICEntries);
                                ICEntries.Direction::Inbound:
                                    ICEntriesManagement.ProcessEntry(ICEntries);
                            end;
                        until ICEntries.Next() = 0;
                end;
            }
            action(ProcessStaging)
            {
                ApplicationArea = All;
                Caption = 'Process Staging';
                Image = NextSet;
                ToolTip = 'Creates the documents from the staging records of the selected inbound entries. Entries in error are retried.';
                trigger OnAction()
                var
                    ICEntries: Record "EOS IC Entries";
                    ICEntriesManagement: Codeunit "EOS IC Entries Management";
                begin
                    CurrPage.SetSelectionFilter(ICEntries);
                    ICEntries.SetRange(Direction, ICEntries.Direction::Inbound);
                    ICEntries.SetRange(Status, ICEntries.Status::Completed);
                    ICEntries.SetFilter("Staging Status", '<>%1', ICEntries."Staging Status"::Completed);
                    if ICEntries.FindSet() then
                        repeat
                            ICEntriesManagement.ProcessStaging(ICEntries);
                        until ICEntries.Next() = 0;
                end;
            }
            action(ShowRequestPayload)
            {
                ApplicationArea = All;
                Caption = 'Show Request';
                Image = ShowList;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("Request Payload")));
                end;
            }
            action(ExportRequestPayload)
            {
                ApplicationArea = All;
                Caption = 'Export Request';
                Image = ExportFile;

                trigger OnAction()
                begin
                    Rec.ExportBlobToJson(Rec.FieldNo("Request Payload"));
                end;
            }
            action(ShowReceivedPayload)
            {
                ApplicationArea = All;
                Caption = 'Show Received';
                Image = ShowList;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("Received Payload")));
                end;
            }
            action(ExportReceivedPayload)
            {
                ApplicationArea = All;
                Caption = 'Export Received';
                Image = ExportFile;

                trigger OnAction()
                begin
                    Rec.ExportBlobToJson(Rec.FieldNo("Received Payload"));
                end;
            }
            action(FullError)
            {
                ApplicationArea = All;
                Caption = 'Full Error';
                Image = PrevErrorMessage;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("Error Message Blob")));
                end;
            }
            action(CallStack)
            {
                ApplicationArea = All;
                Caption = 'Call Stack';
                Image = PrevErrorMessage;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("Call Stack Blob")));
                end;
            }
        }
        area(Promoted)
        {
            actionref(ProcessEntries_Promoted; ProcessEntries) { }
            actionref(ProcessStaging_Promoted; ProcessStaging) { }
            actionref(ShowDocument_Promoted; ShowDocument) { }
            group(RequestPayload)
            {
                Caption = 'Request Payload';
                Image = Database;
                actionref(ShowRequestPayload_Promoted; ShowRequestPayload) { }
                actionref(ExportRequestPayload_Promoted; ExportRequestPayload) { }
            }
            group(ReceivedPayload)
            {
                Caption = 'Received Payload';
                Image = Database;
                actionref(ShowReceivedPayload_Promoted; ShowReceivedPayload) { }
                actionref(ExportReceivedPayload_Promoted; ExportReceivedPayload) { }
            }
            group(Error)
            {
                Caption = 'Error';
                Image = ErrorLog;
                actionref(FullError_Promoted; FullError) { }
                actionref(CallStack_Promoted; CallStack) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetLineColors();
    end;

    local procedure SetLineColors()
    begin
        FieldColor := Format(PageStyle::Standard);
        StagingColor := Format(PageStyle::Standard);

        case Rec."Status" of
            Rec."Status"::Pending:
                FieldColor := Format(PageStyle::Ambiguous);
            Rec."Status"::Processing:
                FieldColor := Format(PageStyle::StrongAccent);
            Rec."Status"::Error:
                FieldColor := Format(PageStyle::Unfavorable);
            Rec."Status"::Completed:
                FieldColor := Format(PageStyle::Favorable);
        end;

        case Rec."Staging Status" of
            Rec."Staging Status"::Pending:
                StagingColor := Format(PageStyle::Ambiguous);
            Rec."Staging Status"::Processing:
                StagingColor := Format(PageStyle::StrongAccent);
            Rec."Staging Status"::Error:
                StagingColor := Format(PageStyle::Unfavorable);
            Rec."Staging Status"::Completed:
                StagingColor := Format(PageStyle::Favorable);
        end;
    end;

    var
        FieldColor, StagingColor : Text;
}
