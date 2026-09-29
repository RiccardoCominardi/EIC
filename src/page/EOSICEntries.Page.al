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
                }
                field("Processed At"; Rec."Processed At")
                {
                    ApplicationArea = All;
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }
                field("Call Stack"; Rec."Call Stack")
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
            action(ShowRequestPayload)
            {
                ApplicationArea = All;
                Caption = 'Show Request Payload';
                Image = ExportFile;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("Request Payload")));
                end;
            }
            action(ShowReceivedPayload)
            {
                ApplicationArea = All;
                Caption = 'Show Received Payload';
                Image = ExportFile;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("Received Payload")));
                end;
            }
            action(ShowFullError)
            {
                ApplicationArea = All;
                Caption = 'Show Full Error';
                Image = PrevErrorMessage;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("Error Message Blob")));
                end;
            }
            action(ShowCallStack)
            {
                ApplicationArea = All;
                Caption = 'Show Call Stack';
                Image = PrevErrorMessage;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("Call Stack Blob")));
                end;
            }
        }
        area(Promoted)
        {
            actionref(ShowFullError_Promoted; ShowFullError) { }
            actionref(ShowCallStack_Promoted; ShowCallStack) { }
            group(ShowPayload)
            {
                Caption = 'Show Payload';
                Image = ExportFile;
                actionref(ShowRequestPayload_Promoted; ShowRequestPayload) { }
                actionref(ShowReceivedPayload_Promoted; ShowReceivedPayload) { }
            }
        }
    }
}
