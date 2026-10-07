namespace EOS.Solutions.Intercompany;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Threading;

codeunit 67007 "EOS IC Entries Management"
{
    #region CreateEntry
    procedure CreateEntry(SourceRecord: Variant): Integer
    var
        ICCompanies: Record "EOS IC Companies";
        ICFlows: Record "EOS IC Flows";
        ICSetup: Record "EOS IC Setup";
        ICEntries: Record "EOS IC Entries";
        RecRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        ICDocumentHandler: Interface "EOS IC Document Handler";
        SourceDocumentType: Enum "EOS IC Document Types";
        CompanyCode: Code[20];
        SourceDocumentNo: Code[50];
        SourceSystemId: Guid;
        PayloadJson: JsonObject;
        PayloadText: Text;
        EmptyPayloadErr: Label 'The flow %1 did not produce a payload for the document %2.', Comment = '%1 = flow code, %2 = document no.';
    begin
        RecRef := GetSourceRecordRef(SourceRecord);
        GetSourceInfo(RecRef, SourceDocumentType, SourceDocumentNo);

        CompanyCode := GetCompanyCode(RecRef);
        if CompanyCode = '' then
            exit(0);

        ICCompanies.Get(CompanyCode);
        ICCompanies.TestField(Enabled);

        ICFlows.Get(CompanyCode, GetFlowCode(SourceRecord, CompanyCode));

        SystemIdFieldRef := RecRef.Field(RecRef.SystemIdNo());
        SourceSystemId := SystemIdFieldRef.Value;
        if not ConfirmResend(RecRef.Number, SourceSystemId, CompanyCode) then
            exit(0);

        ICSetup.Get();
        ICSetup.TestField("Company Code");

        ICDocumentHandler := ICCompanies."Interface";
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
            ICEntries."Target Document Type"::"ES Sales Order":
                begin
                    StgSalesHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgSalesHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Sales Order", StgSalesHeader);
                end;
            ICEntries."Target Document Type"::"ES Purchase Order":
                begin
                    StgPurchHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgPurchHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Purch. Order", StgPurchHeader);
                end;
            ICEntries."Target Document Type"::"ES Shipment":
                begin
                    StgShptHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgShptHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Shipment", StgShptHeader);
                end;
            ICEntries."Target Document Type"::"ES Receipt":
                begin
                    StgRcptHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgRcptHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Receipt", StgRcptHeader);
                end;
            ICEntries."Target Document Type"::"ES Item":
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
        SourceDocumentType: Enum "EOS IC Document Types";
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

    local procedure GetCompanyCode(RecRef: RecordRef) CompanyCode: Code[20]
    var
        ICSetup: Record "EOS IC Setup";
        CompanyCodeFieldRef: FieldRef;
    begin
        ICSetup.Get();
        if RecRef.FieldExist(ICSetup."Company Code Field No.") then begin
            CompanyCodeFieldRef := RecRef.Field(ICSetup."Company Code Field No.");
            // The same field number can hold another type on tables that do not carry the company code.
            if CompanyCodeFieldRef.Type in [FieldType::Code, FieldType::Text] then
                CompanyCode := CopyStr(Format(CompanyCodeFieldRef.Value), 1, MaxStrLen(CompanyCode));
        end;

        if CompanyCode = '' then
            CompanyCode := LookupCompanyCode();
    end;

    local procedure LookupCompanyCode(): Code[20]
    var
        ICCompanies: Record "EOS IC Companies";
        ICCompaniesPage: Page "EOS IC Companies";
        MissingCompanyCodeErr: Label 'The IC company code is required to send the document.';
    begin
        if not GuiAllowed() then
            Error(MissingCompanyCodeErr);

        ICCompanies.SetRange(Enabled, true);
        ICCompaniesPage.SetTableView(ICCompanies);
        ICCompaniesPage.LookupMode(true);
        if ICCompaniesPage.RunModal() <> Action::LookupOK then
            exit('');

        ICCompaniesPage.GetRecord(ICCompanies);
        exit(ICCompanies.Code);
    end;

    local procedure GetSourceRecordRef(SourceRecord: Variant) RecRef: RecordRef
    var
        InvalidSourceErr: Label 'The source must be a record.';
    begin
        if not SourceRecord.IsRecord() then
            Error(InvalidSourceErr);

        RecRef.GetTable(SourceRecord);
    end;

    local procedure GetSourceInfo(RecRef: RecordRef; var DocumentType: Enum "EOS IC Document Types"; var DocumentNo: Code[50])
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
                    DocumentType := DocumentType::"ES Sales Order";
                    DocumentNo := SalesHeader."No.";
                end;
            Database::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    DocumentType := DocumentType::"ES Purchase Order";
                    DocumentNo := PurchaseHeader."No.";
                end;
            Database::"Sales Shipment Header":
                begin
                    RecRef.SetTable(SalesShipmentHeader);
                    DocumentType := DocumentType::"ES Shipment";
                    DocumentNo := SalesShipmentHeader."No.";
                end;
            Database::"Purch. Rcpt. Header":
                begin
                    RecRef.SetTable(PurchRcptHeader);
                    DocumentType := DocumentType::"ES Receipt";
                    DocumentNo := PurchRcptHeader."No.";
                end;
            Database::Item:
                begin
                    RecRef.SetTable(Item);
                    DocumentType := DocumentType::"ES Item";
                    DocumentNo := Item."No.";
                end;
            else
                Error(UnsupportedTableErr, RecRef.Name);
        end;
    end;
    #endregion CreateEntry

    #region DocumentTracking
    procedure ShowDocumentEntries(DocumentRecord: Variant)
    var
        ICEntries: Record "EOS IC Entries";
        ICEntriesPage: Page "EOS IC Entries";
        RecRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        DocumentSystemId: Guid;
    begin
        RecRef := GetSourceRecordRef(DocumentRecord);
        SystemIdFieldRef := RecRef.Field(RecRef.SystemIdNo());
        DocumentSystemId := SystemIdFieldRef.Value;

        ICEntries.Reset();
        ICEntries.SetRange("Source Table Id", RecRef.Number);
        ICEntries.SetRange("Source System Id", DocumentSystemId);
        if ICEntries.FindSet() then
            repeat
                ICEntries.Mark(true);
            until ICEntries.Next() = 0;

        ICEntries.SetRange("Target Table Id", RecRef.Number);
        ICEntries.SetRange("Target System Id", DocumentSystemId);
        if ICEntries.FindSet() then
            repeat
                ICEntries.Mark(true);
            until ICEntries.Next() = 0;

        ICEntries.SetRange("Source Table Id");
        ICEntries.SetRange("Target Table Id");
        ICEntries.SetRange("Source System Id");
        ICEntries.SetRange("Target System Id");
        ICEntries.MarkedOnly(true);

        ICEntriesPage.SetTableView(ICEntries);
        ICEntriesPage.RunModal();
    end;

    local procedure UpdateDocumentEntriesCount(ICEntry: Record "EOS IC Entries")
    var
        ICSetup: Record "EOS IC Setup";
        ICEntries: Record "EOS IC Entries";
        RecRef: RecordRef;
        EntriesCountFieldRef: FieldRef;
        TotalEntry, TableIdToUpdate : Integer;
        SystemIdToUpdate: Guid;
    begin
        case ICEntry.Direction of
            ICEntry.Direction::Outbound:
                begin
                    if ICEntry."Status" <> ICEntry."Status"::Completed then
                        exit;

                    TableIdToUpdate := ICEntry."Source Table Id";
                    SystemIdToUpdate := ICEntry."Source System Id";
                end;
            ICEntry.Direction::Inbound:
                begin
                    if ICEntry."Staging Status" <> ICEntry."Staging Status"::Completed then
                        exit;

                    TableIdToUpdate := ICEntry."Target Table Id";
                    SystemIdToUpdate := ICEntry."Target System Id";
                end;
        end;

        ICSetup.Get();
        if (ICSetup."IC Entry Field No." = 0) or (TableIdToUpdate = 0) then
            exit;

        RecRef.Open(TableIdToUpdate);
        if not RecRef.FieldExist(ICSetup."IC Entry Field No.") then
            exit;
        if not RecRef.GetBySystemId(SystemIdToUpdate) then
            exit;

        TotalEntry := MarkDocumentEntries(ICEntries, ICEntry.Direction, TableIdToUpdate, SystemIdToUpdate);
        EntriesCountFieldRef := RecRef.Field(ICSetup."IC Entry Field No.");
        EntriesCountFieldRef.Value := TotalEntry;
        RecRef.Modify(false);
    end;

    local procedure MarkDocumentEntries(ICEntries: Record "EOS IC Entries"; Direction: Enum "EOS IC Direction"; TableId: Integer; SystemId: Guid) TotalEntry: Integer
    begin
        case Direction of
            Direction::Outbound:
                begin
                    ICEntries.Reset();
                    ICEntries.SetRange(Direction, ICEntries.Direction::Outbound);
                    ICEntries.SetRange("Source Table Id", TableId);
                    ICEntries.SetRange("Source System Id", SystemId);
                    TotalEntry := ICEntries.Count();
                end;

            Direction::Inbound:
                begin
                    ICEntries.Reset();
                    ICEntries.SetRange(Direction, ICEntries.Direction::Inbound);
                    ICEntries.SetRange("Target Table Id", TableId);
                    ICEntries.SetRange("Target System Id", SystemId);
                    TotalEntry := ICEntries.Count();
                end;
        end;
    end;
    #endregion DocumentTracking

    #region SendEntry
    procedure SendEntry(var ICEntries: Record "EOS IC Entries")
    var
        ICTryFunctions: Codeunit "EOS IC Try Functions";
        AlreadyCompletedErr: Label 'The entry %1 has already been sent.', Comment = '%1 = entry no.';
        NewStatus: Enum "EOS IC Entry Status";
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
            NewStatus := NewStatus::Completed
        else
            NewStatus := NewStatus::Error;

        SetICEntryStatusInfos(ICEntries, NewStatus);
        UpdateDocumentEntriesCount(ICEntries);
    end;

    #endregion SendEntry

    #region ProcessEntry

    procedure ProcessEntry(var ICEntries: Record "EOS IC Entries")
    var
        ICFlows: Record "EOS IC Flows";
        ICTryFunctions: Codeunit "EOS IC Try Functions";
        NewStatus: Enum "EOS IC Entry Status";
        NewStagingStatus: Enum "EOS IC Staging Status";
        AlreadyProcessedErr: Label 'The entry %1 has already been processed.', Comment = '%1 = entry no.';
    begin
        ICFlows.Get(ICEntries."Source Company", ICEntries."IC Flow Code");
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
            NewStatus := NewStatus::Completed;
            NewStagingStatus := NewStagingStatus::Pending;
        end else
            NewStatus := NewStatus::Error;

        SetICEntryStatusInfos(ICEntries, NewStatus);
        SetICEntryStagingStatusInfos(ICEntries, NewStagingStatus);

        if ICEntries.Status = ICEntries.Status::Completed then
            if ICFlows."Auto Create Documents" then
                ProcessStaging(ICEntries);
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

    #region ProcessStaging
    procedure ProcessStaging(var ICEntries: Record "EOS IC Entries")
    var
        ICTryFunctions: Codeunit "EOS IC Try Functions";
        RecRef: RecordRef;
        NewStagingStatus: Enum "EOS IC Staging Status";
        DocVariant: Variant;
    begin
        ICEntries.TestField(Direction, ICEntries.Direction::Inbound);
        ICEntries.TestField(Status, ICEntries.Status::Completed);

        ICEntries."Staging Status" := ICEntries."Staging Status"::Processing;
        ICEntries.Modify(true);
        Commit();

        Clear(ICTryFunctions);
        ICTryFunctions.SetFunctionCode('PROCESS_STAGING');
        ICTryFunctions.SetDocVariant(ICEntries);
        if ICTryFunctions.Run() then
            NewStagingStatus := NewStagingStatus::Completed
        else
            NewStagingStatus := NewStagingStatus::Error;

        DocVariant := ICTryFunctions.GetDocVariant();
        RecRef.GetTable(DocVariant);
        RecRef.SetTable(ICEntries);
        SetICEntryStagingStatusInfos(ICEntries, NewStagingStatus);
        UpdateDocumentEntriesCount(ICEntries);
        UpdateSourceICEntry(ICEntries);
    end;

    local procedure UpdateSourceICEntry(ICEntries: Record "EOS IC Entries")
    var
        ICFunctions: Codeunit "EOS IC Functions";
    begin
        if ICEntries."Staging Status" <> ICEntries."Staging Status"::Completed then
            exit;

        if ICEntries."Target Document No." = '' then
            exit;

        ICFunctions.UpdateSourceEntry(ICEntries);
    end;


    #endregion ProcessStaging

    local procedure SetICEntryStatusInfos(var ICEntries: record "EOS IC Entries"; NewStatus: Enum "EOS IC Entry Status")
    begin
        ICEntries."Status" := NewStatus;
        case NewStatus of
            NewStatus::Completed:
                begin
                    ICEntries."Processed At" := CurrentDateTime();
                    ICEntries."Error Message" := '';
                    ICEntries."Call Stack" := '';
                    Clear(ICEntries."Error Message Blob");
                    Clear(ICEntries."Call Stack Blob");
                end;
            NewStatus::Error:
                begin
                    ICEntries."Processed At" := CurrentDateTime();
                    ICEntries."Retry Count" += 1;
                    ICEntries."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(ICEntries."Error Message"));
                    ICEntries."Call Stack" := CopyStr(GetLastErrorCallStack(), 1, MaxStrLen(ICEntries."Call Stack"));
                    ICEntries.SetBlobFields(ICEntries.FieldNo("Error Message Blob"), GetLastErrorText(), false);
                    ICEntries.SetBlobFields(ICEntries.FieldNo("Call Stack Blob"), GetLastErrorCallStack(), false);
                end;
        end;
        ICEntries.Modify();
    end;

    local procedure SetICEntryStagingStatusInfos(var ICEntries: record "EOS IC Entries"; NewStatus: Enum "EOS IC Staging Status")
    begin
        ICEntries."Staging Status" := NewStatus;
        case NewStatus of
            NewStatus::Completed:
                begin
                    ICEntries."Processed At" := CurrentDateTime();
                    ICEntries."Error Message" := '';
                    ICEntries."Call Stack" := '';
                    Clear(ICEntries."Error Message Blob");
                    Clear(ICEntries."Call Stack Blob");
                end;
            NewStatus::Error:
                begin
                    ICEntries."Processed At" := CurrentDateTime();
                    ICEntries."Retry Count" += 1;
                    ICEntries."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(ICEntries."Error Message"));
                    ICEntries."Call Stack" := CopyStr(GetLastErrorCallStack(), 1, MaxStrLen(ICEntries."Call Stack"));
                    ICEntries.SetBlobFields(ICEntries.FieldNo("Error Message Blob"), GetLastErrorText(), false);
                    ICEntries.SetBlobFields(ICEntries.FieldNo("Call Stack Blob"), GetLastErrorCallStack(), false);
                end;
        end;
        ICEntries.Modify();
    end;
}
