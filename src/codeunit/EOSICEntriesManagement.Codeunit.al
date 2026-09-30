namespace EOS.Solutions.Intercompany;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Text;
using System.Threading;
using Microsoft.Intercompany.Setup;

codeunit 67007 "EOS IC Entries Management"
{
    #region CreateEntry
    procedure CreateEntry(SourceRecord: Variant; CompanyCode: Code[20]): Integer
    var
        ICCompanies: Record "EOS IC Companies";
        ICFlows: Record "EOS IC Flows";
        ICSetup: Record "EOS IC Setup";
        ICEntries: Record "EOS IC Entries";
        RecRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        ICDocumentHandler: Interface "EOS IC Document Handler";
        SourceDocumentType: Enum "EOS IC Flow Document Types";
        SourceDocumentNo: Code[50];
        SourceSystemId: Guid;
        PayloadJson: JsonObject;
        PayloadText: Text;
        EmptyPayloadErr: Label 'The flow %1 did not produce a payload for the document %2.', Comment = '%1 = flow code, %2 = document no.';
    begin
        ICCompanies.Get(CompanyCode);
        ICCompanies.TestField(Enabled);

        RecRef := GetSourceRecordRef(SourceRecord);
        GetSourceInfo(RecRef, SourceDocumentType, SourceDocumentNo);

        ICFlows.Get(CompanyCode, GetFlowCode(SourceRecord, CompanyCode));

        SystemIdFieldRef := RecRef.Field(RecRef.SystemIdNo());
        SourceSystemId := SystemIdFieldRef.Value;
        if not ConfirmResend(RecRef.Number, SourceSystemId, CompanyCode) then
            exit(0);

        ICSetup.Get();
        ICSetup.TestField("Company Code");

        ICDocumentHandler := ICCompanies."Interface Company";
        PayloadJson := ICDocumentHandler.BuildPayload(SourceRecord, ICFlows);
        if PayloadJson.Keys().Count() = 0 then
            Error(EmptyPayloadErr, ICFlows.Code, SourceDocumentNo);
        PayloadJson.WriteTo(PayloadText);

        ICEntries.Init();
        ICEntries."Entry No." := ICEntries.GetNextEntryNo();
        ICEntries."IC Transaction ID" := CreateGuid();
        ICEntries."IC Flow Code" := ICFlows.Code;
        ICEntries.Direction := ICFlows.Direction;
        ICEntries."Source Company" := ICSetup."Company Code";
        ICEntries."Target Company" := CompanyCode;
        ICEntries."Source Document Type" := SourceDocumentType;
        ICEntries."Source Document No." := SourceDocumentNo;
        ICEntries."Source Table Id" := RecRef.Number;
        ICEntries."Source System Id" := SourceSystemId;
        ICEntries."Target Document Type" := ICFlows."External Document Type";
        ICEntries.Status := ICEntries.Status::Pending;
        ICEntries.SetBlobFields(ICEntries.FieldNo("Request Payload"), PayloadText, false);
        ICEntries.Insert(true);

        if ICFlows."Auto Send" then
            SendEntry(ICEntries);

        if GuiAllowed() then
            ShowCreateResult(ICEntries);

        exit(ICEntries."Entry No.");
    end;

    local procedure ShowCreateResult(ICEntries: Record "EOS IC Entries")
    var
        EntrySentMsg: Label 'The document %1 %2 has been sent to company %3.\Entry No.: %4', Comment = '%1 = document type, %2 = document no., %3 = target company, %4 = entry no.';
        EntryCreatedMsg: Label 'The entry %1 has been created for the document %2 %3 and is waiting to be sent to company %4.', Comment = '%1 = entry no., %2 = document type, %3 = document no., %4 = target company';
        EntryErrorMsg: Label 'The entry %1 has been created but the sending to company %2 failed.\%3', Comment = '%1 = entry no., %2 = target company, %3 = error message';
    begin
        case ICEntries.Status of
            ICEntries.Status::Completed:
                Message(EntrySentMsg, ICEntries."Source Document Type", ICEntries."Source Document No.", ICEntries."Target Company", ICEntries."Entry No.");
            ICEntries.Status::Error:
                Message(EntryErrorMsg, ICEntries."Entry No.", ICEntries."Target Company", ICEntries."Error Message");
            else
                Message(EntryCreatedMsg, ICEntries."Entry No.", ICEntries."Source Document Type", ICEntries."Source Document No.", ICEntries."Target Company");
        end;
    end;

    procedure ShowStagingRecord(ICEntries: Record "EOS IC Entries")
    var
        StgSalesHeader: Record "EOS IC Stg. Sales Header";
        StgPurchHeader: Record "EOS IC Stg. Purch. Header";
        StgShptHeader: Record "EOS IC Stg. Shpt. Header";
        StgRcptHeader: Record "EOS IC Stg. Rcpt. Header";
        StgItem: Record "EOS IC Stg. Item";
        StagingNotFoundErr: Label 'No staging record was found for the entry %1.', Comment = '%1 = entry no.';
    begin
        if ICEntries."Staging Status" = ICEntries."Staging Status"::None then
            exit;

        case ICEntries."Target Document Type" of
            ICEntries."Target Document Type"::"Sales Order":
                begin
                    StgSalesHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgSalesHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Sales Order", StgSalesHeader);
                end;
            ICEntries."Target Document Type"::"Purchase Order":
                begin
                    StgPurchHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgPurchHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Purch. Order", StgPurchHeader);
                end;
            ICEntries."Target Document Type"::Shipment:
                begin
                    StgShptHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgShptHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Shipment", StgShptHeader);
                end;
            ICEntries."Target Document Type"::Receipt:
                begin
                    StgRcptHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgRcptHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Receipt", StgRcptHeader);
                end;
            ICEntries."Target Document Type"::Item:
                begin
                    StgItem.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgItem.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Item Card", StgItem);
                end;
        end;
    end;

    procedure GetFlowCode(SourceRecord: Variant; CompanyCode: Code[20]): Code[20]
    var
        ICFlows: Record "EOS IC Flows";
        RecRef: RecordRef;
        SourceDocumentType: Enum "EOS IC Flow Document Types";
        SourceDocumentNo: Code[50];
        MissingCompanyCodeErr: Label 'The IC company code is required to determine the flow.';
        NoFlowFoundErr: Label 'No enabled outbound flow was found for company %1 and document type %2.', Comment = '%1 = company code, %2 = document type';
        MultipleFlowsFoundErr: Label 'More than one enabled outbound flow was found for company %1 and document type %2.', Comment = '%1 = company code, %2 = document type';
    begin
        if CompanyCode = '' then
            Error(MissingCompanyCodeErr);

        RecRef := GetSourceRecordRef(SourceRecord);
        GetSourceInfo(RecRef, SourceDocumentType, SourceDocumentNo);

        ICFlows.SetRange("Company Code", CompanyCode);
        ICFlows.SetRange(Direction, ICFlows.Direction::Outbound);
        ICFlows.SetRange("Local Document Type", SourceDocumentType);
        ICFlows.SetRange(Enabled, true);

        case ICFlows.Count() of
            0:
                Error(NoFlowFoundErr, CompanyCode, SourceDocumentType);
            1:
                ICFlows.FindFirst();
            else
                Error(MultipleFlowsFoundErr, CompanyCode, SourceDocumentType);
        end;

        exit(ICFlows.Code);
    end;

    local procedure ConfirmResend(SourceTableId: Integer; SourceSystemId: Guid; CompanyCode: Code[20]): Boolean
    var
        ICEntries: Record "EOS IC Entries";
        AlreadySentQst: Label 'The document has already been sent to company %1 with the entry %2. Do you want to send it again?', Comment = '%1 = company code, %2 = entry no.';
    begin
        ICEntries.SetRange(Direction, ICEntries.Direction::Outbound);
        ICEntries.SetRange("Target Company", CompanyCode);
        ICEntries.SetRange("Source Table Id", SourceTableId);
        ICEntries.SetRange("Source System Id", SourceSystemId);
        ICEntries.SetRange(Status, ICEntries.Status::Completed);
        if not ICEntries.FindLast() then
            exit(true);

        if not GuiAllowed() then
            exit(true);

        exit(Confirm(AlreadySentQst, false, CompanyCode, ICEntries."Entry No."));
    end;

    local procedure GetSourceRecordRef(SourceRecord: Variant) RecRef: RecordRef
    var
        InvalidSourceErr: Label 'The source must be a record.';
    begin
        if not SourceRecord.IsRecord() then
            Error(InvalidSourceErr);

        RecRef.GetTable(SourceRecord);
    end;

    local procedure GetSourceInfo(RecRef: RecordRef; var DocumentType: Enum "EOS IC Flow Document Types"; var DocumentNo: Code[50])
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        Item: Record Item;
        UnsupportedTableErr: Label 'The table %1 is not supported as an intercompany source.', Comment = '%1 = table name';
    begin
        case RecRef.Number of
            Database::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    DocumentType := DocumentType::"Sales Order";
                    DocumentNo := SalesHeader."No.";
                end;
            Database::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    DocumentType := DocumentType::"Purchase Order";
                    DocumentNo := PurchaseHeader."No.";
                end;
            Database::"Sales Shipment Header":
                begin
                    RecRef.SetTable(SalesShipmentHeader);
                    DocumentType := DocumentType::Shipment;
                    DocumentNo := SalesShipmentHeader."No.";
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    RecRef.SetTable(PurchRcptHeader);
                    DocumentType := DocumentType::Receipt;
                    DocumentNo := PurchRcptHeader."No.";
                end;
            Database::Item:
                begin
                    RecRef.SetTable(Item);
                    DocumentType := DocumentType::Item;
                    DocumentNo := Item."No.";
                end;
            else
                Error(UnsupportedTableErr, RecRef.Name);
        end;
    end;
    #endregion CreateEntry

    #region SendEntry
    procedure SendEntry(var ICEntries: Record "EOS IC Entries")
    var
        ICTryFunctions: Codeunit "EOS IC Try Functions";
        AlreadyCompletedErr: Label 'The entry %1 has already been sent.', Comment = '%1 = entry no.';
    begin
        ICEntries.TestField(Direction, ICEntries.Direction::Outbound);
        if ICEntries.Status = ICEntries.Status::Completed then
            Error(AlreadyCompletedErr, ICEntries."Entry No.");

        // Http calls are not allowed with an open write transaction.
        ICEntries.Status := ICEntries.Status::Processing;
        ICEntries.Modify(true);
        Commit();

        Clear(ICTryFunctions);
        ICTryFunctions.SetFunctionCode('SEND_ENTRY');
        ICTryFunctions.SetDocVariant(ICEntries);
        if ICTryFunctions.Run() then
            SetEntryCompleted(ICEntries)
        else
            SetEntryError(ICEntries, GetLastErrorText(), GetLastErrorCallStack());
    end;

    local procedure SetEntryCompleted(var ICEntries: Record "EOS IC Entries")
    begin
        ICEntries.Status := ICEntries.Status::Completed;
        ICEntries."Processed At" := CurrentDateTime();
        ICEntries."Error Message" := '';
        ICEntries."Call Stack" := '';
        Clear(ICEntries."Error Message Blob");
        Clear(ICEntries."Call Stack Blob");
        ICEntries.Modify(true);
    end;

    local procedure SetEntryError(var ICEntries: Record "EOS IC Entries"; ErrorText: Text; CallStackText: Text)
    begin
        ICEntries.Status := ICEntries.Status::Error;
        ICEntries."Processed At" := CurrentDateTime();
        ICEntries."Retry Count" += 1;
        ICEntries."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(ICEntries."Error Message"));
        ICEntries."Call Stack" := CopyStr(CallStackText, 1, MaxStrLen(ICEntries."Call Stack"));
        ICEntries.SetBlobFields(ICEntries.FieldNo("Error Message Blob"), ErrorText, false);
        ICEntries.SetBlobFields(ICEntries.FieldNo("Call Stack Blob"), CallStackText, false);
        ICEntries.Modify(true);
    end;
    #endregion SendEntry

    #region ProcessEntry

    procedure ProcessEntry(var ICEntries: Record "EOS IC Entries")
    var
        ICTryFunctions: Codeunit "EOS IC Try Functions";
        AlreadyProcessedErr: Label 'The entry %1 has already been processed.', Comment = '%1 = entry no.';
    begin
        ICEntries.TestField(Direction, ICEntries.Direction::Inbound);
        if ICEntries.Status = ICEntries.Status::Completed then
            Error(AlreadyProcessedErr, ICEntries."Entry No.");

        ICEntries.Status := ICEntries.Status::Processing;
        ICEntries.Modify(true);
        Commit();

        Clear(ICTryFunctions);
        ICTryFunctions.SetFunctionCode('PROCESS_ENTRY');
        ICTryFunctions.SetDocVariant(ICEntries);
        if ICTryFunctions.Run() then begin
            ICEntries."Staging Status" := ICEntries."Staging Status"::Pending;
            SetEntryCompleted(ICEntries);
        end else
            SetEntryError(ICEntries, GetLastErrorText(), GetLastErrorCallStack());
    end;

    procedure UpdateStagingStatus(ICEntryNo: Integer; StagingStatus: Enum "EOS IC Staging Status")
    var
        ICEntries: Record "EOS IC Entries";
    begin
        if not ICEntries.Get(ICEntryNo) then
            exit;

        ICEntries."Staging Status" := StagingStatus;
        ICEntries.Modify(true);
    end;

    procedure ScheduleEntryProcessing(ICEntries: Record "EOS IC Entries")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
        JobQueueCategoryCodeTxt: Label 'EOSIC', Locked = true;
        JobQueueCategoryDescriptionLbl: Label 'EOS Intercompany';
        JobDescriptionLbl: Label 'Process IC entry %1', Comment = '%1 = entry no.';
    begin
        if not JobQueueCategory.Get(JobQueueCategoryCodeTxt) then begin
            JobQueueCategory.Code := JobQueueCategoryCodeTxt;
            JobQueueCategory.Description := JobQueueCategoryDescriptionLbl;
            JobQueueCategory.Insert(true);
        end;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"EOS IC Process Entries JQ";
        JobQueueEntry.Description := CopyStr(StrSubstNo(JobDescriptionLbl, ICEntries."Entry No."), 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Parameter String" := Format(ICEntries."Entry No.");
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryCodeTxt;
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert(true);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;
    #endregion ProcessEntry
}
