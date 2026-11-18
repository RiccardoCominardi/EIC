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
                CreateSalesOrderFromStaging(ICEntries);
            ICFunctions."Send Create Purch. Order" = ICEntries."IC Flow Code":
                CreatePurchaseOrderFromStaging(ICEntries);
            else
                Error(Text000Err, ICEntries."Source Company");
        end;
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
    // Unified staging examples: the header values are on the root record, the lines on its child records (Json names as written by BuildPayload).

    procedure CreateSalesOrderFromStaging(var ICEntries: Record "EOS IC Entries")
    var
        RootStaging: Record "EOS IC Staging";
        HeaderStaging: Record "EOS IC Staging";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
    begin
        StagingMgt.GetRootStagingRecord(ICEntries."Entry No.", RootStaging);
        StagingMgt.SetChildStagingRecords(HeaderStaging, RootStaging, 'header');
        if not HeaderStaging.FindSet() then
            exit;

        repeat
            CreateSalesOrderFromStagingHeader(ICEntries, HeaderStaging);
        until HeaderStaging.Next() = 0;
    end;

    local procedure CreateSalesOrderFromStagingHeader(var ICEntries: Record "EOS IC Entries"; HeaderStaging: Record "EOS IC Staging")
    var
        SalesHeader: Record "Sales Header";
        ICEntriesMgt: Codeunit "EOS IC Entries Management";
        DocumentTypeLbl: Label 'Sales Order';
    begin
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
        RootStaging: Record "EOS IC Staging";
        HeaderStaging: Record "EOS IC Staging";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
    begin
        StagingMgt.GetRootStagingRecord(ICEntries."Entry No.", RootStaging);
        StagingMgt.SetChildStagingRecords(HeaderStaging, RootStaging, 'header');
        if not HeaderStaging.FindSet() then
            exit;

        repeat
            CreatePurchaseOrderFromStagingHeader(ICEntries, HeaderStaging);
        until HeaderStaging.Next() = 0;
    end;

    local procedure CreatePurchaseOrderFromStagingHeader(var ICEntries: Record "EOS IC Entries"; HeaderStaging: Record "EOS IC Staging")
    var
        PurchaseHeader: Record "Purchase Header";
        ICEntriesMgt: Codeunit "EOS IC Entries Management";
        DocumentTypeLbl: Label 'Purchase Order';
    begin
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