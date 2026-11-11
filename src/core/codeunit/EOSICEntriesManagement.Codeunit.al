namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Threading;

codeunit 67007 "EOS IC Entries Management"
{
    #region CreateEntry
    procedure CreateEntry(SourceRecord: Variant): Integer
    var
        ICCompanies: Record "EOS IC Companies";
        ICFlows: Record "EOS IC Flows";
        RecRef: RecordRef;
        CompanyCode: Code[20];
        FlowCode: Code[20];
    begin
        RecRef := GetSourceRecordRef(SourceRecord);

        CompanyCode := GetCompanyCode(RecRef);
        if CompanyCode = '' then
            exit(0);

        ICCompanies.Get(CompanyCode);
        ICCompanies.TestField(Enabled);

        FlowCode := GetFlowCode(SourceRecord, CompanyCode);
        if FlowCode = '' then
            exit(0);

        ICFlows.Get(CompanyCode, FlowCode);
        exit(CreateEntry(SourceRecord, ICFlows));
    end;

    procedure CreateEntry(SourceRecord: Variant; ICFlows: Record "EOS IC Flows"): Integer
    var
        ICCompanies: Record "EOS IC Companies";
        ICSetup: Record "EOS IC Setup";
        ICEntries: Record "EOS IC Entries";
        ICOutMappingMgt: Codeunit "EOS IC Out. Mapping Mgt.";
        RecRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        ICDocumentHandler: Interface "EOS IC Document Handler";
        SourceDocumentNo: Code[50];
        SourceSystemId: Guid;
        PayloadJson: JsonObject;
        PayloadText: Text;
        EmptyPayloadErr: Label 'The flow %1 did not produce a payload for the document %2.', Comment = '%1 = flow code, %2 = document no.';
    begin
        ICFlows.TestField(Direction, ICFlows.Direction::Outbound);
        ICFlows.TestField(Enabled);

        RecRef := GetSourceRecordRef(SourceRecord);
        GetSourceInfo(RecRef, SourceDocumentNo);

        ICCompanies.Get(ICFlows."Company Code");
        ICCompanies.TestField(Enabled);

        SystemIdFieldRef := RecRef.Field(RecRef.SystemIdNo());
        SourceSystemId := SystemIdFieldRef.Value;
        if not ConfirmResend(RecRef.Number, SourceSystemId, ICFlows) then
            exit(0);

        ICSetup.Get();
        ICSetup.TestField("Company Code");

        // A mapping assigned to the flow builds the payload; otherwise it is built by the document handler of the company.
        if ICFlows."Mapping Code" <> '' then
            PayloadJson := ICOutMappingMgt.BuildPayload(SourceRecord, ICFlows)
        else begin
            ICDocumentHandler := ICCompanies."Interface";
            PayloadJson := ICDocumentHandler.BuildPayload(SourceRecord, ICFlows);
        end;
        if PayloadJson.Keys().Count() = 0 then
            Error(EmptyPayloadErr, ICFlows.Code, SourceDocumentNo);
        PayloadJson.WriteTo(PayloadText);

        ICEntries.Init();
        ICEntries."Entry No." := ICEntries.GetNextEntryNo();
        ICEntries."IC Transaction ID" := CreateGuid();
        ICEntries."IC Flow Code" := ICFlows.Code;
        ICEntries.Direction := ICFlows.Direction;
        ICEntries."Source Company" := ICSetup."Company Code";
        ICEntries."Target Company" := ICFlows."Company Code";
        ICEntries."Relation Table Id" := ICFlows."Relation Table Id";
        ICEntries."Relation Option Type" := ICFlows."Relation Option Type";
        ICEntries."Source No." := SourceDocumentNo;
        ICEntries."Doc. System Id" := SourceSystemId;
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
        ICEntries.CalcFields("Relation Table Name");
        case ICEntries.Status of
            ICEntries.Status::Completed:
                Message(EntrySentMsg, ICEntries."Relation Table Name", ICEntries."Source No.", ICEntries."Target Company", ICEntries."Entry No.");
            ICEntries.Status::Error:
                Message(EntryErrorMsg, ICEntries."Entry No.", ICEntries."Target Company", ICEntries."Error Message");
            else
                Message(EntryCreatedMsg, ICEntries."Entry No.", ICEntries."Relation Table Name", ICEntries."Source No.", ICEntries."Target Company");
        end;
    end;

    procedure ShowStagingRecord(ICEntries: Record "EOS IC Entries")
    var
        ICFunctions: Record "EOS IC Functions";
        StgSalesHeader: Record "EOS IC Stg. Sales Header";
        StgPurchHeader: Record "EOS IC Stg. Purch. Header";
        UnifiedStaging: Record "EOS IC Staging";
        StagingTree: Page "EOS IC Staging Tree";
        StagingNotFoundErr: Label 'No staging record was found for the entry %1.', Comment = '%1 = entry no.';
    begin
        if ICEntries."Staging Status" = ICEntries."Staging Status"::None then
            exit;

        if ICEntries."Use Staging" then begin
            UnifiedStaging.SetRange("IC Entry No.", ICEntries."Entry No.");
            if UnifiedStaging.IsEmpty() then
                Error(StagingNotFoundErr, ICEntries."Entry No.");
            StagingTree.SetICEntryNo(ICEntries."Entry No.");
            StagingTree.Run();
            exit;
        end;

        ICFunctions.Get(ICEntries."Source Company", ICEntries.Direction);
        case true of
            ICFunctions."Send Create Sales Order" = ICEntries."IC Flow Code":
                begin
                    StgSalesHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgSalesHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Sales Order", StgSalesHeader);
                end;
            ICFunctions."Send Create Purch. Order" = ICEntries."IC Flow Code":
                begin
                    StgPurchHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
                    if not StgPurchHeader.FindFirst() then
                        Error(StagingNotFoundErr, ICEntries."Entry No.");
                    Page.Run(Page::"EOS IC Stg. Purch. Order", StgPurchHeader);
                end;
            else
                OnHandleDocsShowStagingRecord(ICEntries, ICFunctions);
        end;
    end;

    procedure ShowTargetDocument(TargetDocument: Record "EOS IC Created Updated Records")
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
        DocVariant: Variant;
        TargetDocumentNotFoundErr: Label 'The target document %1 was not found.', Comment = '%1 = target document no.';
    begin
        TargetDocument.TestField("Table Id");
        TargetDocument.TestField("Doc. System Id");
        RecRef.Open(TargetDocument."Table Id");
        if not RecRef.GetBySystemId(TargetDocument."Doc. System Id") then
            Error(TargetDocumentNotFoundErr, TargetDocument."Document No.");

        DocVariant := RecRef;
        PageManagement.PageRun(DocVariant);
    end;

    procedure ShowTargetDocuments(ICEntries: Record "EOS IC Entries")
    var
        ICEntryTargetDocument: Record "EOS IC Created Updated Records";
        NoTargetDocumentsErr: Label 'No target documents are linked to entry %1.', Comment = '%1 = entry no.';
    begin
        ICEntryTargetDocument.SetRange("IC Entry No.", ICEntries."Entry No.");
        case ICEntryTargetDocument.Count() of
            0:
                Error(NoTargetDocumentsErr, ICEntries."Entry No.");
            1:
                begin
                    ICEntryTargetDocument.FindFirst();
                    ShowTargetDocument(ICEntryTargetDocument);
                end;
            else
                ShowTargetDocumentList(ICEntryTargetDocument, ICEntries."Entry No.");
        end;
    end;

    local procedure ShowTargetDocumentList(ICEntryTargetDocument: Record "EOS IC Created Updated Records"; ICEntryNo: Integer)
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
        DocVariant: Variant;
        TargetTableId: Integer;
        InconsistentTargetsErr: Label 'All target documents for entry %1 must have the same document type and table.', Comment = '%1 = entry no.';
        TargetDocumentNotFoundErr: Label 'The target document %1 was not found.', Comment = '%1 = target document no.';
    begin
        if not ICEntryTargetDocument.FindSet() then
            exit;

        TargetTableId := ICEntryTargetDocument."Table Id";
        RecRef.Open(TargetTableId);
        repeat
            if ICEntryTargetDocument."Table Id" <> TargetTableId then
                Error(InconsistentTargetsErr, ICEntryNo);

            if not RecRef.GetBySystemId(ICEntryTargetDocument."Doc. System Id") then
                Error(TargetDocumentNotFoundErr, ICEntryTargetDocument."Document No.");
            RecRef.Mark(true);
        until ICEntryTargetDocument.Next() = 0;

        RecRef.MarkedOnly(true);
        DocVariant := RecRef;
        PageManagement.PageRunList(DocVariant);
    end;

    // Returns the code of the flow to use, or '' when the user cancels the selection.
    procedure GetFlowCode(SourceRecord: Variant; CompanyCode: Code[20]): Code[20]
    var
        ICFlows: Record "EOS IC Flows";
        ICFunctions: Codeunit "EOS IC Functions";
        ICFlowsPage: Page "EOS IC Flows";
        RecRef: RecordRef;
        OptionFieldRef: FieldRef;
        OptionFieldNo, RelationOptionType : Integer;
        DocumentTypeText: Text;
        MissingCompanyCodeErr: Label 'The IC company code is required to determine the flow.';
        NoFlowFoundErr: Label 'No enabled outbound flow was found for company %1 and document type %2.', Comment = '%1 = company code, %2 = document type';
        MultipleFlowsFoundErr: Label 'More than one enabled outbound flow was found for company %1 and document type %2.', Comment = '%1 = company code, %2 = document type';
    begin
        if CompanyCode = '' then
            Error(MissingCompanyCodeErr);

        RecRef := GetSourceRecordRef(SourceRecord);
        DocumentTypeText := RecRef.Caption();

        // Flows are grouped by relation table and by the value of the option field of the source primary key (0 when absent).
        OptionFieldNo := ICFunctions.GetRecordPKOptionField(RecRef, false);
        if OptionFieldNo <> 0 then begin
            OptionFieldRef := RecRef.Field(OptionFieldNo);
            RelationOptionType := OptionFieldRef.Value();
            DocumentTypeText += ' ' + Format(OptionFieldRef.Value());
        end;

        ICFlows.SetRange("Company Code", CompanyCode);
        ICFlows.SetRange(Direction, ICFlows.Direction::Outbound);
        ICFlows.SetRange(Enabled, true);
        ICFlows.SetRange("Relation Table Id", RecRef.Number());
        ICFlows.SetRange("Relation Option Type", RelationOptionType);

        case ICFlows.Count() of
            0:
                Error(NoFlowFoundErr, CompanyCode, DocumentTypeText);
            1:
                begin
                    ICFlows.FindFirst();
                    exit(ICFlows.Code);
                end;
        end;

        if not GuiAllowed() then
            Error(MultipleFlowsFoundErr, CompanyCode, DocumentTypeText);

        ICFlowsPage.SetTableView(ICFlows);
        ICFlowsPage.LookupMode(true);
        if ICFlowsPage.RunModal() <> Action::LookupOK then
            exit('');

        ICFlowsPage.GetRecord(ICFlows);
        exit(ICFlows.Code);
    end;

    local procedure ConfirmResend(SourceTableId: Integer; SourceSystemId: Guid; ICFlows: Record "EOS IC Flows"): Boolean
    var
        ICEntries: Record "EOS IC Entries";
        AlreadySentQst: Label 'The document has already been sent to company %1 with the entry %2. Do you want to send it again?', Comment = '%1 = company code, %2 = entry no.';
    begin
        ICEntries.SetRange(Direction, ICEntries.Direction::Outbound);
        ICEntries.SetRange("Target Company", ICFlows."Company Code");
        ICEntries.SetRange("IC Flow Code", ICFlows.Code);
        ICEntries.SetRange("Relation Table Id", SourceTableId);
        ICEntries.SetRange("Doc. System Id", SourceSystemId);
        ICEntries.SetRange(Status, ICEntries.Status::Completed);
        if not ICEntries.FindLast() then
            exit(true);

        if not GuiAllowed() then
            exit(true);

        exit(Confirm(AlreadySentQst, false, ICFlows."Company Code", ICEntries."Entry No."));
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

    local procedure GetSourceInfo(RecRef: RecordRef; var DocumentNo: Code[50])
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        case RecRef.Number() of
            Database::"Sales Header":
                begin
                    RecRef.SetTable(SalesHeader);
                    DocumentNo := SalesHeader."No.";
                end;
            Database::"Purchase Header":
                begin
                    RecRef.SetTable(PurchaseHeader);
                    DocumentNo := PurchaseHeader."No.";
                end;
            else
                OnHandleGetSourceInfo(RecRef, DocumentNo);
        end;
    end;
    #endregion CreateEntry

    #region DocumentTracking
    procedure ShowDocumentEntries(DocumentRecord: Variant)
    var
        ICEntries: Record "EOS IC Entries";
        ICEntryTargetDocument: Record "EOS IC Created Updated Records";
        ICEntriesPage: Page "EOS IC Entries";
        RecRef: RecordRef;
        SystemIdFieldRef: FieldRef;
        DocumentSystemId: Guid;
    begin
        RecRef := GetSourceRecordRef(DocumentRecord);
        SystemIdFieldRef := RecRef.Field(RecRef.SystemIdNo());
        DocumentSystemId := SystemIdFieldRef.Value;

        ICEntries.Reset();
        ICEntries.SetRange("Relation Table Id", RecRef.Number);
        ICEntries.SetRange("Doc. System Id", DocumentSystemId);
        if ICEntries.FindSet() then
            repeat
                ICEntries.Mark(true);
            until ICEntries.Next() = 0;

        ICEntryTargetDocument.SetRange("Table Id", RecRef.Number);
        ICEntryTargetDocument.SetRange("Doc. System Id", DocumentSystemId);
        if ICEntryTargetDocument.FindSet() then
            repeat
                if ICEntries.Get(ICEntryTargetDocument."IC Entry No.") then
                    if ICEntries.Direction = ICEntries.Direction::Inbound then
                        ICEntries.Mark(true);
            until ICEntryTargetDocument.Next() = 0;

        ICEntries.SetRange("Relation Table Id");
        ICEntries.SetRange("Doc. System Id");
        ICEntries.MarkedOnly(true);

        ICEntriesPage.SetTableView(ICEntries);
        ICEntriesPage.RunModal();
    end;

    local procedure UpdateDocumentEntriesCount(ICEntry: Record "EOS IC Entries")
    var
        ICSetup: Record "EOS IC Setup";
        ICEntries: Record "EOS IC Entries";
        ICEntryTargetDocument: Record "EOS IC Created Updated Records";
    begin
        ICSetup.Get();
        if ICSetup."IC Entry Field No." = 0 then
            exit;

        case ICEntry.Direction of
            ICEntry.Direction::Outbound:
                begin
                    if ICEntry."Status" <> ICEntry."Status"::Completed then
                        exit;

                    UpdateDocumentEntryCount(ICSetup, ICEntries, ICEntry.Direction, ICEntry."Relation Table Id", ICEntry."Doc. System Id");
                end;
            ICEntry.Direction::Inbound:
                begin
                    if ICEntry."Staging Status" <> ICEntry."Staging Status"::Completed then
                        exit;

                    ICEntryTargetDocument.SetRange("IC Entry No.", ICEntry."Entry No.");
                    if ICEntryTargetDocument.FindSet() then
                        repeat
                            UpdateDocumentEntryCount(ICSetup, ICEntries, ICEntry.Direction, ICEntryTargetDocument."Table Id", ICEntryTargetDocument."Doc. System Id");
                        until ICEntryTargetDocument.Next() = 0;
                end;
        end;
    end;

    local procedure UpdateDocumentEntryCount(ICSetup: Record "EOS IC Setup"; ICEntries: Record "EOS IC Entries"; Direction: Enum "EOS IC Direction"; TableId: Integer; SystemId: Guid)
    var
        RecRef: RecordRef;
        EntriesCountFieldRef: FieldRef;
        TotalEntry: Integer;
    begin
        if TableId = 0 then
            exit;

        RecRef.Open(TableId);
        if not RecRef.FieldExist(ICSetup."IC Entry Field No.") then
            exit;
        if not RecRef.GetBySystemId(SystemId) then
            exit;

        TotalEntry := MarkDocumentEntries(ICEntries, Direction, TableId, SystemId);
        EntriesCountFieldRef := RecRef.Field(ICSetup."IC Entry Field No.");
        EntriesCountFieldRef.Value := TotalEntry;
        RecRef.Modify(false);
    end;

    local procedure MarkDocumentEntries(ICEntries: Record "EOS IC Entries"; Direction: Enum "EOS IC Direction"; TableId: Integer; SystemId: Guid) TotalEntry: Integer
    var
        ICEntryTargetDocument: Record "EOS IC Created Updated Records";
    begin
        case Direction of
            Direction::Outbound:
                begin
                    ICEntries.Reset();
                    ICEntries.SetRange(Direction, ICEntries.Direction::Outbound);
                    ICEntries.SetRange("Relation Table Id", TableId);
                    ICEntries.SetRange("Doc. System Id", SystemId);
                    TotalEntry := ICEntries.Count();
                end;

            Direction::Inbound:
                begin
                    ICEntries.Reset();
                    ICEntryTargetDocument.SetRange("IC Entry No.", ICEntries."Entry No.");
                    ICEntryTargetDocument.SetRange("Table Id", TableId);
                    ICEntryTargetDocument.SetRange("Doc. System Id", SystemId);
                    TotalEntry := ICEntryTargetDocument.Count();
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
        ICEntryTargetDocument: Record "EOS IC Created Updated Records";
        ICFunctions: Codeunit "EOS IC Functions";
    begin
        if ICEntries."Staging Status" <> ICEntries."Staging Status"::Completed then
            exit;

        ICEntryTargetDocument.SetRange("IC Entry No.", ICEntries."Entry No.");
        if ICEntryTargetDocument.IsEmpty() then
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

    procedure SetTargetDocument(var ICEntries: Record "EOS IC Entries"; TableId: Integer; DocumentType: Text[100]; DocumentNo: Code[50]; SystemId: Guid)
    var
        ICEntryTargetDocument: Record "EOS IC Created Updated Records";
    begin
        ICEntryTargetDocument.Init();
        ICEntryTargetDocument."IC Entry No." := ICEntries."Entry No.";
        ICEntryTargetDocument."Document Type" := DocumentType;
        ICEntryTargetDocument."Document No." := DocumentNo;
        ICEntryTargetDocument."Table Id" := TableId;
        ICEntryTargetDocument."Doc. System Id" := SystemId;
        ICEntryTargetDocument.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleDocsShowStagingRecord(ICEntries: Record "EOS IC Entries"; ICFunctions: Record "EOS IC Functions")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleGetSourceInfo(RecRef: RecordRef; var DocumentNo: Code[50])
    begin
    end;
}
