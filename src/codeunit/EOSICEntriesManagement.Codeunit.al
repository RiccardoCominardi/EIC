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
        ICFlows.Get(ICEntries."Target Company", ICEntries."IC Flow Code");
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

        if ICFlows."Auto Create Documents" then
            ProcessStaging(ICEntries);
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

    procedure CreateSalesOrder(var ICEntries: Record "EOS IC Entries")
    var
        StgSalesHeader: Record "EOS IC Stg. Sales Header";
        SalesHeader: Record "Sales Header";
        StagingNotFoundErr: Label 'No staging record was found for the entry %1.', Comment = '%1 = entry no.';
    begin
        StgSalesHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
        if not StgSalesHeader.FindFirst() then
            Error(StagingNotFoundErr, ICEntries."Entry No.");

        CreateSalesHeader(SalesHeader, StgSalesHeader, ICEntries);
        CreateSalesLines(SalesHeader, StgSalesHeader."Entry No.");

        StgSalesHeader.Status := StgSalesHeader.Status::Completed;
        StgSalesHeader.Modify();

        SetTargetDocument(ICEntries, Database::"Sales Header", SalesHeader."No.", SalesHeader.SystemId);
    end;

    procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; StgSalesHeader: Record "EOS IC Stg. Sales Header"; ICEntries: Record "EOS IC Entries")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreateSalesHeader(SalesHeader, StgSalesHeader, IsHandled);
        if IsHandled then
            exit;

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        OnBeforeInsertSalesHeader(SalesHeader, StgSalesHeader);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", StgSalesHeader."Sell-to Customer No.");

        // Blank values are not copied, so that the defaults of the customer are kept.
        if StgSalesHeader."Posting Date" <> 0D then
            SalesHeader.Validate("Posting Date", StgSalesHeader."Posting Date");
        if StgSalesHeader."Order Date" <> 0D then
            SalesHeader.Validate("Order Date", StgSalesHeader."Order Date");
        if StgSalesHeader."Document Date" <> 0D then
            SalesHeader.Validate("Document Date", StgSalesHeader."Document Date");
        if StgSalesHeader."Requested Delivery Date" <> 0D then
            SalesHeader.Validate("Requested Delivery Date", StgSalesHeader."Requested Delivery Date");
        if StgSalesHeader."Currency Code" <> '' then
            SalesHeader.Validate("Currency Code", StgSalesHeader."Currency Code");
        if StgSalesHeader."External Document No." <> '' then
            SalesHeader.Validate("External Document No.", StgSalesHeader."External Document No.");
        if StgSalesHeader."Your Reference" <> '' then
            SalesHeader.Validate("Your Reference", StgSalesHeader."Your Reference");
        if StgSalesHeader."Payment Terms Code" <> '' then
            SalesHeader.Validate("Payment Terms Code", StgSalesHeader."Payment Terms Code");
        if StgSalesHeader."Shipment Method Code" <> '' then
            SalesHeader.Validate("Shipment Method Code", StgSalesHeader."Shipment Method Code");
        if StgSalesHeader."Location Code" <> '' then
            SalesHeader.Validate("Location Code", StgSalesHeader."Location Code");

        OnBeforeModifySalesHeader(SalesHeader, StgSalesHeader);
        SalesHeader."EOS IC Entry No." := ICEntries."Entry No.";
        SalesHeader.Modify(true);
    end;

    procedure CreateSalesLines(SalesHeader: Record "Sales Header"; StagingEntryNo: Integer)
    var
        StgSalesLine: Record "EOS IC Stg. Sales Line";
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        OnBeforeCreateSalesLine(SalesLine, StgSalesLine, IsHandled);
        if IsHandled then
            exit;

        StgSalesLine.SetRange("Entry No.", StagingEntryNo);
        if not StgSalesLine.FindSet() then
            exit;

        repeat
            Clear(SalesLine);
            SalesLine.Init();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." := StgSalesLine."Line No.";
            OnBeforeInsertSalesLine(SalesLine, StgSalesLine);
            SalesLine.Insert(true);

            SalesLine.Validate(Type, GetSalesLineType(StgSalesLine.Type));
            if StgSalesLine."No." <> '' then
                SalesLine.Validate("No.", StgSalesLine."No.");
            if StgSalesLine."Variant Code" <> '' then
                SalesLine.Validate("Variant Code", StgSalesLine."Variant Code");
            if StgSalesLine."Location Code" <> '' then
                SalesLine.Validate("Location Code", StgSalesLine."Location Code");
            if StgSalesLine."Unit of Measure Code" <> '' then
                SalesLine.Validate("Unit of Measure Code", StgSalesLine."Unit of Measure Code");
            SalesLine.Validate(Quantity, StgSalesLine.Quantity);
            SalesLine.Validate("Unit Price", StgSalesLine."Unit Price");
            SalesLine.Validate("Line Discount %", StgSalesLine."Line Discount %");
            if StgSalesLine."Requested Delivery Date" <> 0D then
                SalesLine.Validate("Requested Delivery Date", StgSalesLine."Requested Delivery Date");
            if StgSalesLine.Description <> '' then
                SalesLine.Description := StgSalesLine.Description;
            OnBeforeModifySalesLine(SalesLine, StgSalesLine);
            SalesLine.Modify(true);
        until StgSalesLine.Next() = 0;
    end;

    local procedure GetSalesLineType(TypeText: Text): Enum "Sales Line Type"
    var
        SalesLineType: Enum "Sales Line Type";
        InvalidLineTypeErr: Label 'The line type "%1" is not valid for a sales line.', Comment = '%1 = line type';
    begin
        if TypeText = '' then
            exit(SalesLineType::" ");

        if not Evaluate(SalesLineType, TypeText, 9) then
            Error(InvalidLineTypeErr, TypeText);
        exit(SalesLineType);
    end;

    procedure CreatePurchaseOrder(var ICEntries: Record "EOS IC Entries")
    var
        StgPurchHeader: Record "EOS IC Stg. Purch. Header";
        PurchaseHeader: Record "Purchase Header";
        StagingNotFoundErr: Label 'No staging record was found for the entry %1.', Comment = '%1 = entry no.';
    begin
        StgPurchHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
        if not StgPurchHeader.FindFirst() then
            Error(StagingNotFoundErr, ICEntries."Entry No.");

        CreatePurchaseHeader(PurchaseHeader, StgPurchHeader, ICEntries);
        CreatePurchaseLines(PurchaseHeader, StgPurchHeader."Entry No.");

        StgPurchHeader.Status := StgPurchHeader.Status::Completed;
        StgPurchHeader.Modify();

        SetTargetDocument(ICEntries, Database::"Purchase Header", PurchaseHeader."No.", PurchaseHeader.SystemId);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; StgPurchHeader: Record "EOS IC Stg. Purch. Header"; ICEntries: Record "EOS IC Entries")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreatePurchaseHeader(PurchaseHeader, StgPurchHeader, IsHandled);
        if IsHandled then
            exit;

        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        OnBeforeInsertPurchaseHeader(PurchaseHeader, StgPurchHeader);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", StgPurchHeader."Buy-from Vendor No.");

        // Blank values are not copied, so that the defaults of the vendor are kept.
        if StgPurchHeader."Posting Date" <> 0D then
            PurchaseHeader.Validate("Posting Date", StgPurchHeader."Posting Date");
        if StgPurchHeader."Order Date" <> 0D then
            PurchaseHeader.Validate("Order Date", StgPurchHeader."Order Date");
        if StgPurchHeader."Document Date" <> 0D then
            PurchaseHeader.Validate("Document Date", StgPurchHeader."Document Date");
        if StgPurchHeader."Requested Receipt Date" <> 0D then
            PurchaseHeader.Validate("Requested Receipt Date", StgPurchHeader."Requested Receipt Date");
        if StgPurchHeader."Currency Code" <> '' then
            PurchaseHeader.Validate("Currency Code", StgPurchHeader."Currency Code");
        if StgPurchHeader."Vendor Order No." <> '' then
            PurchaseHeader.Validate("Vendor Order No.", StgPurchHeader."Vendor Order No.");
        if StgPurchHeader."Your Reference" <> '' then
            PurchaseHeader.Validate("Your Reference", StgPurchHeader."Your Reference");
        if StgPurchHeader."Payment Terms Code" <> '' then
            PurchaseHeader.Validate("Payment Terms Code", StgPurchHeader."Payment Terms Code");
        if StgPurchHeader."Shipment Method Code" <> '' then
            PurchaseHeader.Validate("Shipment Method Code", StgPurchHeader."Shipment Method Code");
        if StgPurchHeader."Location Code" <> '' then
            PurchaseHeader.Validate("Location Code", StgPurchHeader."Location Code");

        OnBeforeModifyPurchaseHeader(PurchaseHeader, StgPurchHeader);
        PurchaseHeader."EOS IC Entry No." := ICEntries."Entry No.";
        PurchaseHeader.Modify(true);
    end;

    procedure CreatePurchaseLines(PurchaseHeader: Record "Purchase Header"; StagingEntryNo: Integer)
    var
        StgPurchLine: Record "EOS IC Stg. Purch. Line";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        OnBeforeCreatePurchaseLine(PurchaseLine, StgPurchLine, IsHandled);
        if IsHandled then
            exit;

        StgPurchLine.SetRange("Entry No.", StagingEntryNo);
        if not StgPurchLine.FindSet() then
            exit;

        repeat
            Clear(PurchaseLine);
            IsHandled := false;

            PurchaseLine.Init();
            PurchaseLine."Document Type" := PurchaseHeader."Document Type";
            PurchaseLine."Document No." := PurchaseHeader."No.";
            PurchaseLine."Line No." := StgPurchLine."Line No.";
            OnBeforeInsertPurchaseLine(PurchaseLine, StgPurchLine);
            PurchaseLine.Insert(true);

            PurchaseLine.Validate(Type, GetPurchaseLineType(StgPurchLine.Type));
            if StgPurchLine."No." <> '' then
                PurchaseLine.Validate("No.", StgPurchLine."No.");
            if StgPurchLine."Variant Code" <> '' then
                PurchaseLine.Validate("Variant Code", StgPurchLine."Variant Code");
            if StgPurchLine."Location Code" <> '' then
                PurchaseLine.Validate("Location Code", StgPurchLine."Location Code");
            if StgPurchLine."Unit of Measure Code" <> '' then
                PurchaseLine.Validate("Unit of Measure Code", StgPurchLine."Unit of Measure Code");
            PurchaseLine.Validate(Quantity, StgPurchLine.Quantity);
            PurchaseLine.Validate("Direct Unit Cost", StgPurchLine."Direct Unit Cost");
            PurchaseLine.Validate("Line Discount %", StgPurchLine."Line Discount %");
            if StgPurchLine."Requested Receipt Date" <> 0D then
                PurchaseLine.Validate("Requested Receipt Date", StgPurchLine."Requested Receipt Date");
            if StgPurchLine.Description <> '' then
                PurchaseLine.Description := StgPurchLine.Description;
            OnBeforeModifyPurchaseLine(PurchaseLine, StgPurchLine);
            PurchaseLine.Modify(true);
        until StgPurchLine.Next() = 0;
    end;

    procedure GetPurchaseLineType(TypeText: Text): Enum "Purchase Line Type"
    var
        PurchaseLineType: Enum "Purchase Line Type";
        InvalidLineTypeErr: Label 'The line type "%1" is not valid for a purchase line.', Comment = '%1 = line type';
    begin
        if TypeText = '' then
            exit(PurchaseLineType::" ");

        if not Evaluate(PurchaseLineType, TypeText, 9) then
            Error(InvalidLineTypeErr, TypeText);
        exit(PurchaseLineType);
    end;

    procedure CreateItem(var ICEntries: Record "EOS IC Entries")
    var
        StgItem: Record "EOS IC Stg. Item";
        Item: Record Item;
        ItemType: Enum "Item Type";
        IsHandled: Boolean;
        StagingNotFoundErr: Label 'No staging record was found for the entry %1.', Comment = '%1 = entry no.';
        ItemAlreadyExistsErr: Label 'The item %1 already exists.', Comment = '%1 = item no.';
        InvalidItemTypeErr: Label 'The item type "%1" is not valid.', Comment = '%1 = item type';
    begin
        StgItem.SetRange("IC Entry No.", ICEntries."Entry No.");
        if not StgItem.FindFirst() then
            Error(StagingNotFoundErr, ICEntries."Entry No.");

        OnBeforeCreateItem(Item, StgItem, IsHandled);
        if IsHandled then
            exit;

        StgItem.TestField("No.");
        if Item.Get(StgItem."No.") then
            Error(ItemAlreadyExistsErr, StgItem."No.");

        if StgItem.Type <> '' then
            if not Evaluate(ItemType, StgItem.Type, 9) then
                Error(InvalidItemTypeErr, StgItem.Type);

        Item.Init();
        Item."No." := StgItem."No.";
        OnBeforeInsertItem(Item, StgItem);
        Item.Insert(true);

        // Type and category are validated first because they set defaults that the explicit values must override.
        if StgItem.Type <> '' then
            Item.Validate(Type, ItemType);
        if StgItem."Item Category Code" <> '' then
            Item.Validate("Item Category Code", StgItem."Item Category Code");
        Item.Validate(Description, StgItem.Description);
        Item.Validate("Description 2", StgItem."Description 2");
        if StgItem."Base Unit of Measure" <> '' then
            Item.Validate("Base Unit of Measure", StgItem."Base Unit of Measure");
        if StgItem."Gen. Prod. Posting Group" <> '' then
            Item.Validate("Gen. Prod. Posting Group", StgItem."Gen. Prod. Posting Group");
        if StgItem."Inventory Posting Group" <> '' then
            Item.Validate("Inventory Posting Group", StgItem."Inventory Posting Group");
        if StgItem."VAT Prod. Posting Group" <> '' then
            Item.Validate("VAT Prod. Posting Group", StgItem."VAT Prod. Posting Group");
        Item.Validate("Unit Price", StgItem."Unit Price");
        Item.Validate("Unit Cost", StgItem."Unit Cost");
        Item.Validate(Blocked, StgItem.Blocked);
        Item.Validate(GTIN, StgItem.GTIN);

        OnBeforeModifyItem(Item, StgItem);
        Item.Validate("EOS IC Entry No.", ICEntries."Entry No.");
        Item.Modify(true);

        StgItem.Status := StgItem.Status::Completed;
        StgItem.Modify();

        SetTargetDocument(ICEntries, Database::Item, Item."No.", Item.SystemId);
    end;

    local procedure SetTargetDocument(var ICEntries: Record "EOS IC Entries"; TableId: Integer; DocumentNo: Code[50]; SystemId: Guid)
    begin
        ICEntries."Target Table Id" := TableId;
        ICEntries."Target Document No." := DocumentNo;
        ICEntries."Target System Id" := SystemId;
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesHeader(var SalesHeader: Record "Sales Header"; StgSalesHeader: Record "EOS IC Stg. Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesHeader(var SalesHeader: Record "Sales Header"; StgSalesHeader: Record "EOS IC Stg. Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesHeader(var SalesHeader: Record "Sales Header"; StgSalesHeader: Record "EOS IC Stg. Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; StgPurchHeader: Record "EOS IC Stg. Purch. Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; StgPurchHeader: Record "EOS IC Stg. Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; StgPurchHeader: Record "EOS IC Stg. Purch. Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItem(var Item: Record Item; StgItem: Record "EOS IC Stg. Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItem(var Item: Record Item; StgItem: Record "EOS IC Stg. Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyItem(var Item: Record Item; StgItem: Record "EOS IC Stg. Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesLine(var SalesLine: Record "Sales Line"; StgSalesLine: Record "EOS IC Stg. Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesLine(var SalesLine: Record "Sales Line"; StgSalesLine: Record "EOS IC Stg. Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesLine(var SalesLine: Record "Sales Line"; StgSalesLine: Record "EOS IC Stg. Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; StgPurchLine: Record "EOS IC Stg. Purch. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchaseLine(var PurchaseLine: Record "Purchase Line"; StgPurchLine: Record "EOS IC Stg. Purch. Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; StgPurchLine: Record "EOS IC Stg. Purch. Line")
    begin
    end;
}
