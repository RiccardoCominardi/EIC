namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 67011 "EOS IC Default Doc. Handler" implements "EOS IC Document Handler"
{
    procedure BuildPayload(SourceRecord: Variant; ICFlows: Record "EOS IC Flows"): JsonObject;
    var
        RecRef: RecordRef;
    begin
        //Implement only if the mapping is unusable.
        //You can use the mapping with the transformation rule for complex json

        if not ICFlows.Enabled then
            exit;

        if not SourceRecord.IsRecord then
            exit;

        RecRef.GetTable(SourceRecord);
        case RecRef.Number of
            Database::"Purchase Header":
                exit(BuildPurchaseOrderJson(RecRef));
            Database::"Sales Header":
                exit(BuildSalesOrderJson(RecRef));
        end;
    end;

    procedure ProcessStaging(var ICEntries: Record "EOS IC Entries")
    var
        ICFunctions: Record "EOS IC Functions";
        Text000Err: Label 'No functions found for company %1 related to the selected flow.', Comment = '%1 = target company';
    begin
        ICFunctions.Get(ICEntries."Source Company", ICEntries.Direction);
        case true of
            ICFunctions."Send Create Sales Order" = ICEntries."IC Flow Code":
                if ICEntries."Use Staging" then
                    CreateSalesOrderFromStaging(ICEntries)
                else
                    CreateSalesOrder(ICEntries);
            ICFunctions."Send Create Purch. Order" = ICEntries."IC Flow Code":
                if ICEntries."Use Staging" then
                    CreatePurchaseOrderFromStaging(ICEntries)
                else
                    CreatePurchaseOrder(ICEntries);
            else
                Error(Text000Err, ICEntries."Source Company");
        end;
    end;

    procedure ShowStagingRecord(ICEntries: Record "EOS IC Entries")
    var
        ICEntriesMgt: Codeunit "EOS IC Entries Management";
    begin
        ICEntriesMgt.ShowStagingRecord(ICEntries);
    end;

    #region BuildPayloadFunctions

    local procedure BuildPurchaseOrderJson(RecRef: RecordRef): JsonObject
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OrderJson: JsonObject;
        LinesJsonArray: JsonArray;
    begin
        RecRef.SetTable(PurchaseHeader);
        OrderJson.Add('header', BuildHeaderJson(PurchaseHeader));

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                LinesJsonArray.Add(BuildLineJson(PurchaseLine));
            until PurchaseLine.Next() = 0;

        OrderJson.Add('lines', LinesJsonArray);
        exit(OrderJson);
    end;

    local procedure BuildHeaderJson(PurchaseHeader: Record "Purchase Header"): JsonObject
    var
        HeaderJson: JsonObject;
    begin
        HeaderJson.Add('no', PurchaseHeader."No.");
        HeaderJson.Add('buyFromVendorNo', PurchaseHeader."Buy-from Vendor No.");
        HeaderJson.Add('orderDate', Format(PurchaseHeader."Order Date", 0, 9));
        HeaderJson.Add('postingDate', Format(PurchaseHeader."Posting Date", 0, 9));
        HeaderJson.Add('documentDate', Format(PurchaseHeader."Document Date", 0, 9));
        HeaderJson.Add('requestedReceiptDate', Format(PurchaseHeader."Requested Receipt Date", 0, 9));
        HeaderJson.Add('currencyCode', PurchaseHeader."Currency Code");
        HeaderJson.Add('vendorOrderNo', PurchaseHeader."Vendor Order No.");
        HeaderJson.Add('yourReference', PurchaseHeader."Your Reference");
        HeaderJson.Add('paymentTermsCode', PurchaseHeader."Payment Terms Code");
        HeaderJson.Add('shipmentMethodCode', PurchaseHeader."Shipment Method Code");
        HeaderJson.Add('locationCode', PurchaseHeader."Location Code");
        exit(HeaderJson);
    end;

    local procedure BuildLineJson(PurchaseLine: Record "Purchase Line"): JsonObject
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('lineNo', PurchaseLine."Line No.");
        LineJson.Add('type', Format(PurchaseLine.Type, 0, 9));
        LineJson.Add('no', PurchaseLine."No.");
        LineJson.Add('description', PurchaseLine.Description);
        LineJson.Add('quantity', PurchaseLine.Quantity);
        LineJson.Add('unitOfMeasureCode', PurchaseLine."Unit of Measure Code");
        LineJson.Add('directUnitCost', PurchaseLine."Direct Unit Cost");
        LineJson.Add('lineDiscountPercent', PurchaseLine."Line Discount %");
        LineJson.Add('lineAmount', PurchaseLine."Line Amount");
        LineJson.Add('locationCode', PurchaseLine."Location Code");
        LineJson.Add('requestedReceiptDate', Format(PurchaseLine."Requested Receipt Date", 0, 9));
        LineJson.Add('variantCode', PurchaseLine."Variant Code");
        exit(LineJson);
    end;

    local procedure BuildSalesOrderJson(RecRef: RecordRef): JsonObject
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderJson: JsonObject;
        LinesJsonArray: JsonArray;
    begin
        RecRef.SetTable(SalesHeader);
        OrderJson.Add('header', BuildHeaderJson(SalesHeader));

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                LinesJsonArray.Add(BuildLineJson(SalesLine));
            until SalesLine.Next() = 0;

        OrderJson.Add('lines', LinesJsonArray);
        exit(OrderJson);
    end;

    local procedure BuildHeaderJson(SalesHeader: Record "Sales Header"): JsonObject
    var
        HeaderJson: JsonObject;
    begin
        HeaderJson.Add('no', SalesHeader."No.");
        HeaderJson.Add('sellToCustomerNo', SalesHeader."Sell-to Customer No.");
        HeaderJson.Add('orderDate', Format(SalesHeader."Order Date", 0, 9));
        HeaderJson.Add('postingDate', Format(SalesHeader."Posting Date", 0, 9));
        HeaderJson.Add('documentDate', Format(SalesHeader."Document Date", 0, 9));
        HeaderJson.Add('requestedDeliveryDate', Format(SalesHeader."Requested Delivery Date", 0, 9));
        HeaderJson.Add('currencyCode', SalesHeader."Currency Code");
        HeaderJson.Add('externalDocumentNo', SalesHeader."External Document No.");
        HeaderJson.Add('yourReference', SalesHeader."Your Reference");
        HeaderJson.Add('paymentTermsCode', SalesHeader."Payment Terms Code");
        HeaderJson.Add('shipmentMethodCode', SalesHeader."Shipment Method Code");
        HeaderJson.Add('locationCode', SalesHeader."Location Code");
        exit(HeaderJson);
    end;

    local procedure BuildLineJson(SalesLine: Record "Sales Line"): JsonObject
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('lineNo', SalesLine."Line No.");
        LineJson.Add('type', Format(SalesLine.Type, 0, 9));
        LineJson.Add('no', SalesLine."No.");
        LineJson.Add('description', SalesLine.Description);
        LineJson.Add('quantity', SalesLine.Quantity);
        LineJson.Add('unitOfMeasureCode', SalesLine."Unit of Measure Code");
        LineJson.Add('unitPrice', SalesLine."Unit Price");
        LineJson.Add('lineDiscountPercent', SalesLine."Line Discount %");
        LineJson.Add('lineAmount', SalesLine."Line Amount");
        LineJson.Add('locationCode', SalesLine."Location Code");
        LineJson.Add('requestedDeliveryDate', Format(SalesLine."Requested Delivery Date", 0, 9));
        LineJson.Add('variantCode', SalesLine."Variant Code");
        exit(LineJson);
    end;

    #endregion BuildPayloadFunctions

    #region ProcessStaging

    procedure CreateSalesOrder(var ICEntries: Record "EOS IC Entries")
    var
        StgSalesHeader: Record "EOS IC Stg. Sales Header";
        SalesHeader: Record "Sales Header";
        ICEntriesMgt: Codeunit "EOS IC Entries Management";
        StagingNotFoundErr: Label 'No staging record was found for the entry %1.', Comment = '%1 = entry no.';
        DocumentTypeLbl: Label 'Sales Order';
    begin
        StgSalesHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
        if not StgSalesHeader.FindFirst() then
            Error(StagingNotFoundErr, ICEntries."Entry No.");

        CreateSalesHeader(SalesHeader, StgSalesHeader);
        CreateSalesLines(SalesHeader, StgSalesHeader."Entry No.");
        ICEntriesMgt.SetTargetDocument(ICEntries, Database::"Sales Header", DocumentTypeLbl, SalesHeader."No.", SalesHeader.SystemId);
    end;

    procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; StgSalesHeader: Record "EOS IC Stg. Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
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

        SalesHeader.Modify(true);
    end;

    procedure CreateSalesLines(SalesHeader: Record "Sales Header"; StagingEntryNo: Integer)
    var
        StgSalesLine: Record "EOS IC Stg. Sales Line";
        SalesLine: Record "Sales Line";
    begin
        StgSalesLine.SetRange("Entry No.", StagingEntryNo);
        if not StgSalesLine.FindSet() then
            exit;

        repeat
            Clear(SalesLine);
            SalesLine.Init();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." := StgSalesLine."Line No.";
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
        ICEntriesMgt: Codeunit "EOS IC Entries Management";
        StagingNotFoundErr: Label 'No staging record was found for the entry %1.', Comment = '%1 = entry no.';
        DocumentTypeLbl: Label 'Purchase Order';
    begin
        StgPurchHeader.SetRange("IC Entry No.", ICEntries."Entry No.");
        if not StgPurchHeader.FindFirst() then
            Error(StagingNotFoundErr, ICEntries."Entry No.");

        CreatePurchaseHeader(PurchaseHeader, StgPurchHeader);
        CreatePurchaseLines(PurchaseHeader, StgPurchHeader."Entry No.");
        ICEntriesMgt.SetTargetDocument(ICEntries, Database::"Purchase Header", DocumentTypeLbl, PurchaseHeader."No.", PurchaseHeader.SystemId);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; StgPurchHeader: Record "EOS IC Stg. Purch. Header")
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
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

        PurchaseHeader.Modify(true);
    end;

    procedure CreatePurchaseLines(PurchaseHeader: Record "Purchase Header"; StagingEntryNo: Integer)
    var
        StgPurchLine: Record "EOS IC Stg. Purch. Line";
        PurchaseLine: Record "Purchase Line";
    begin
        StgPurchLine.SetRange("Entry No.", StagingEntryNo);
        if not StgPurchLine.FindSet() then
            exit;

        repeat
            Clear(PurchaseLine);
            PurchaseLine.Init();
            PurchaseLine."Document Type" := PurchaseHeader."Document Type";
            PurchaseLine."Document No." := PurchaseHeader."No.";
            PurchaseLine."Line No." := StgPurchLine."Line No.";
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
    #endregion ProcessStaging

    #region ProcessUnifiedStaging
    // Unified staging examples: the header values are on the root record, the lines on its child records (Json names as written by BuildPayload).

    procedure CreateSalesOrderFromStaging(var ICEntries: Record "EOS IC Entries")
    var
        HeaderStaging: Record "EOS IC Staging";
        SalesHeader: Record "Sales Header";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        ICEntriesMgt: Codeunit "EOS IC Entries Management";
        DocumentTypeLbl: Label 'Sales Order';
    begin
        StagingMgt.GetRootStagingRecord(ICEntries."Entry No.", HeaderStaging);

        CreateSalesHeaderFromStaging(SalesHeader, HeaderStaging);
        CreateSalesLinesFromStaging(SalesHeader, HeaderStaging);
        ICEntriesMgt.SetTargetDocument(ICEntries, Database::"Sales Header", DocumentTypeLbl, SalesHeader."No.", SalesHeader.SystemId);
    end;

    procedure CreateSalesHeaderFromStaging(var SalesHeader: Record "Sales Header"; HeaderStaging: Record "EOS IC Staging")
    var
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        Value: Variant;
    begin
        StagingMgt.GetRequiredStagingValue(HeaderStaging, 'sellToCustomerNo', Value);

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Value);

        // Missing, null or blank values are not copied, so that the defaults of the customer are kept.
        if StagingMgt.GetStagingValue(HeaderStaging, 'postingDate', Value) then
            SalesHeader.Validate("Posting Date", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'orderDate', Value) then
            SalesHeader.Validate("Order Date", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'documentDate', Value) then
            SalesHeader.Validate("Document Date", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'requestedDeliveryDate', Value) then
            SalesHeader.Validate("Requested Delivery Date", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'currencyCode', Value) then
            SalesHeader.Validate("Currency Code", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'externalDocumentNo', Value) then
            SalesHeader.Validate("External Document No.", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'yourReference', Value) then
            SalesHeader.Validate("Your Reference", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'paymentTermsCode', Value) then
            SalesHeader.Validate("Payment Terms Code", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'shipmentMethodCode', Value) then
            SalesHeader.Validate("Shipment Method Code", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'locationCode', Value) then
            SalesHeader.Validate("Location Code", Value);

        SalesHeader.Modify(true);
    end;

    procedure CreateSalesLinesFromStaging(SalesHeader: Record "Sales Header"; HeaderStaging: Record "EOS IC Staging")
    var
        LineStaging: Record "EOS IC Staging";
        SalesLine: Record "Sales Line";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        Value: Variant;
        DescriptionText: Text;
    begin
        StagingMgt.SetChildStagingRecords(LineStaging, HeaderStaging, 'lines');
        if not LineStaging.FindSet() then
            exit;

        repeat
            Clear(SalesLine);
            SalesLine.Init();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." := StagingMgt.GetIntegerValue(LineStaging, 'lineNo');
            SalesLine.Insert(true);

            // The type is mapped on an Integer staging field with the Enum/Option source Sales Line > Type.
            SalesLine.Validate(Type, "Sales Line Type".FromInteger(StagingMgt.GetIntegerValue(LineStaging, 'type')));
            if StagingMgt.GetStagingValue(LineStaging, 'no', Value) then
                SalesLine.Validate("No.", Value);
            if StagingMgt.GetStagingValue(LineStaging, 'variantCode', Value) then
                SalesLine.Validate("Variant Code", Value);
            if StagingMgt.GetStagingValue(LineStaging, 'locationCode', Value) then
                SalesLine.Validate("Location Code", Value);
            if StagingMgt.GetStagingValue(LineStaging, 'unitOfMeasureCode', Value) then
                SalesLine.Validate("Unit of Measure Code", Value);
            SalesLine.Validate(Quantity, StagingMgt.GetDecimalValue(LineStaging, 'quantity'));
            SalesLine.Validate("Unit Price", StagingMgt.GetDecimalValue(LineStaging, 'unitPrice'));
            SalesLine.Validate("Line Discount %", StagingMgt.GetDecimalValue(LineStaging, 'lineDiscountPercent'));
            if StagingMgt.GetStagingValue(LineStaging, 'requestedDeliveryDate', Value) then
                SalesLine.Validate("Requested Delivery Date", Value);
            DescriptionText := StagingMgt.GetTextValue(LineStaging, 'description');
            if DescriptionText <> '' then
                SalesLine.Description := CopyStr(DescriptionText, 1, MaxStrLen(SalesLine.Description));
            SalesLine.Modify(true);
        until LineStaging.Next() = 0;
    end;

    procedure CreatePurchaseOrderFromStaging(var ICEntries: Record "EOS IC Entries")
    var
        HeaderStaging: Record "EOS IC Staging";
        PurchaseHeader: Record "Purchase Header";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        ICEntriesMgt: Codeunit "EOS IC Entries Management";
        DocumentTypeLbl: Label 'Purchase Order';
    begin
        StagingMgt.GetRootStagingRecord(ICEntries."Entry No.", HeaderStaging);

        CreatePurchaseHeaderFromStaging(PurchaseHeader, HeaderStaging);
        CreatePurchaseLinesFromStaging(PurchaseHeader, HeaderStaging);
        ICEntriesMgt.SetTargetDocument(ICEntries, Database::"Purchase Header", DocumentTypeLbl, PurchaseHeader."No.", PurchaseHeader.SystemId);
    end;

    procedure CreatePurchaseHeaderFromStaging(var PurchaseHeader: Record "Purchase Header"; HeaderStaging: Record "EOS IC Staging")
    var
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        Value: Variant;
    begin
        StagingMgt.GetRequiredStagingValue(HeaderStaging, 'buyFromVendorNo', Value);

        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Value);

        // Missing, null or blank values are not copied, so that the defaults of the vendor are kept.
        if StagingMgt.GetStagingValue(HeaderStaging, 'postingDate', Value) then
            PurchaseHeader.Validate("Posting Date", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'orderDate', Value) then
            PurchaseHeader.Validate("Order Date", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'documentDate', Value) then
            PurchaseHeader.Validate("Document Date", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'requestedReceiptDate', Value) then
            PurchaseHeader.Validate("Requested Receipt Date", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'currencyCode', Value) then
            PurchaseHeader.Validate("Currency Code", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'vendorOrderNo', Value) then
            PurchaseHeader.Validate("Vendor Order No.", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'yourReference', Value) then
            PurchaseHeader.Validate("Your Reference", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'paymentTermsCode', Value) then
            PurchaseHeader.Validate("Payment Terms Code", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'shipmentMethodCode', Value) then
            PurchaseHeader.Validate("Shipment Method Code", Value);
        if StagingMgt.GetStagingValue(HeaderStaging, 'locationCode', Value) then
            PurchaseHeader.Validate("Location Code", Value);

        PurchaseHeader.Modify(true);
    end;

    procedure CreatePurchaseLinesFromStaging(PurchaseHeader: Record "Purchase Header"; HeaderStaging: Record "EOS IC Staging")
    var
        LineStaging: Record "EOS IC Staging";
        PurchaseLine: Record "Purchase Line";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
        Value: Variant;
        DescriptionText: Text;
    begin
        StagingMgt.SetChildStagingRecords(LineStaging, HeaderStaging, 'lines');
        if not LineStaging.FindSet() then
            exit;

        repeat
            Clear(PurchaseLine);
            PurchaseLine.Init();
            PurchaseLine."Document Type" := PurchaseHeader."Document Type";
            PurchaseLine."Document No." := PurchaseHeader."No.";
            PurchaseLine."Line No." := StagingMgt.GetIntegerValue(LineStaging, 'lineNo');
            PurchaseLine.Insert(true);

            // The type is mapped on an Integer staging field with the Enum/Option source Purchase Line > Type.
            PurchaseLine.Validate(Type, "Purchase Line Type".FromInteger(StagingMgt.GetIntegerValue(LineStaging, 'type')));
            if StagingMgt.GetStagingValue(LineStaging, 'no', Value) then
                PurchaseLine.Validate("No.", Value);
            if StagingMgt.GetStagingValue(LineStaging, 'variantCode', Value) then
                PurchaseLine.Validate("Variant Code", Value);
            if StagingMgt.GetStagingValue(LineStaging, 'locationCode', Value) then
                PurchaseLine.Validate("Location Code", Value);
            if StagingMgt.GetStagingValue(LineStaging, 'unitOfMeasureCode', Value) then
                PurchaseLine.Validate("Unit of Measure Code", Value);
            PurchaseLine.Validate(Quantity, StagingMgt.GetDecimalValue(LineStaging, 'quantity'));
            PurchaseLine.Validate("Direct Unit Cost", StagingMgt.GetDecimalValue(LineStaging, 'directUnitCost'));
            PurchaseLine.Validate("Line Discount %", StagingMgt.GetDecimalValue(LineStaging, 'lineDiscountPercent'));
            if StagingMgt.GetStagingValue(LineStaging, 'requestedReceiptDate', Value) then
                PurchaseLine.Validate("Requested Receipt Date", Value);
            DescriptionText := StagingMgt.GetTextValue(LineStaging, 'description');
            if DescriptionText <> '' then
                PurchaseLine.Description := CopyStr(DescriptionText, 1, MaxStrLen(PurchaseLine.Description));
            PurchaseLine.Modify(true);
        until LineStaging.Next() = 0;
    end;
    #endregion ProcessUnifiedStaging
}