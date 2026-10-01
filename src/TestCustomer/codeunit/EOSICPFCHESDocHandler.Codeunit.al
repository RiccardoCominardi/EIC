namespace EOS_Solutions.EOS_Intercompany;

using EOS.Solutions.Intercompany;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 67012 "EOS IC PFCH ES Doc. Handler" implements "EOS IC Document Handler"
{
    var
        ICFunctions: Codeunit "EOS IC Functions";

    procedure BuildPayload(SourceRecord: Variant; ICFlows: Record "EOS IC Flows"): JsonObject;
    var
        RecRef: RecordRef;
    begin
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
            Database::"Purch. Rcpt. Header":
                exit(BuildReceiptJson(RecRef));
            Database::"Sales Shipment Header":
                exit(BuildShipmentJson(RecRef));
            Database::Item:
                exit(BuildItemJson(RecRef));
        end;
    end;

    procedure LoadStaging(ICEntries: Record "EOS IC Entries")
    var
        HeaderObject: JsonObject;
        LinesArray: JsonArray;
        UnsupportedDocumentTypeErr: Label 'The document type %1 is not supported by the staging process.', Comment = '%1 = document type';
    begin
        ICEntries.TestField(Direction, ICEntries.Direction::Inbound);
        ReadPayload(ICEntries, HeaderObject, LinesArray);

        case ICEntries."Target Document Type" of
            ICEntries."Target Document Type"::"Sales Order":
                case ICEntries."Source Document Type" of
                    ICEntries."Source Document Type"::"Purchase Order":
                        PopulateSalesOrderFromPurchaseOrder(ICEntries."Entry No.", HeaderObject, LinesArray);
                end;
            ICEntries."Target Document Type"::"Purchase Order":
                case ICEntries."Source Document Type" of
                    ICEntries."Source Document Type"::"Sales Order":
                        PopulatePurchaseOrderFromSalesOrder(ICEntries."Entry No.", HeaderObject, LinesArray);
                end;
            ICEntries."Target Document Type"::Shipment:
                case ICEntries."Source Document Type" of
                    ICEntries."Source Document Type"::Receipt:
                        PopulateShipmentFromReceipt(ICEntries."Entry No.", HeaderObject, LinesArray);
                end;
            ICEntries."Target Document Type"::Receipt:
                case ICEntries."Source Document Type" of
                    ICEntries."Source Document Type"::Shipment:
                        PopulateReceiptFromShipment(ICEntries."Entry No.", HeaderObject, LinesArray);
                end;
            ICEntries."Target Document Type"::Item:
                case ICEntries."Source Document Type" of
                    ICEntries."Source Document Type"::Item:
                        PopulateItem(ICEntries."Entry No.", HeaderObject);
                end;
            else
                Error(UnsupportedDocumentTypeErr, ICEntries."Target Document Type");
        end;
    end;

    procedure ProcessStaging(var ICEntries: Record "EOS IC Entries")
    var
        ICEntriesManagement: Codeunit "EOS IC Entries Management";
        UnsupportedDocumentTypeErr: Label 'The document type %1 is not supported by the document creation process.', Comment = '%1 = document type';
    begin
        case ICEntries."Target Document Type" of
            ICEntries."Target Document Type"::"Sales Order":
                ICEntriesManagement.CreateSalesOrder(ICEntries);
            ICEntries."Target Document Type"::"Purchase Order":
                ICEntriesManagement.CreatePurchaseOrder(ICEntries);
            ICEntries."Target Document Type"::Item:
                ICEntriesManagement.CreateItem(ICEntries);
            else
                Error(UnsupportedDocumentTypeErr, ICEntries."Target Document Type");
        end;
    end;


    #region BuildPayloadFunctions
    local procedure BuildItemJson(RecRef: RecordRef): JsonObject
    var
        Item: Record Item;
        ItemJson: JsonObject;
    begin
        RecRef.SetTable(Item);
        ItemJson.Add('header', BuildHeaderJson(Item));
        exit(ItemJson);
    end;

    local procedure BuildHeaderJson(Item: Record Item): JsonObject
    var
        HeaderJson: JsonObject;
    begin
        HeaderJson.Add('no', Item."No.");
        HeaderJson.Add('description', Item.Description);
        HeaderJson.Add('description2', Item."Description 2");
        HeaderJson.Add('type', Format(Item.Type, 0, 9));
        HeaderJson.Add('baseUnitOfMeasure', Item."Base Unit of Measure");
        HeaderJson.Add('itemCategoryCode', Item."Item Category Code");
        HeaderJson.Add('genProdPostingGroup', Item."Gen. Prod. Posting Group");
        HeaderJson.Add('inventoryPostingGroup', Item."Inventory Posting Group");
        HeaderJson.Add('vatProdPostingGroup', Item."VAT Prod. Posting Group");
        HeaderJson.Add('unitPrice', Item."Unit Price");
        HeaderJson.Add('unitCost', Item."Unit Cost");
        HeaderJson.Add('blocked', Item.Blocked);
        HeaderJson.Add('gtin', Item.GTIN);
        exit(HeaderJson);
    end;

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

    local procedure BuildReceiptJson(RecRef: RecordRef): JsonObject
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ReceiptJson: JsonObject;
        LinesJsonArray: JsonArray;
    begin
        RecRef.SetTable(PurchRcptHeader);
        ReceiptJson.Add('header', BuildHeaderJson(PurchRcptHeader));

        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        if PurchRcptLine.FindSet() then
            repeat
                LinesJsonArray.Add(BuildLineJson(PurchRcptLine));
            until PurchRcptLine.Next() = 0;

        ReceiptJson.Add('lines', LinesJsonArray);
        exit(ReceiptJson);
    end;

    local procedure BuildHeaderJson(PurchRcptHeader: Record "Purch. Rcpt. Header"): JsonObject
    var
        HeaderJson: JsonObject;
    begin
        HeaderJson.Add('no', PurchRcptHeader."No.");
        HeaderJson.Add('buyFromVendorNo', PurchRcptHeader."Buy-from Vendor No.");
        HeaderJson.Add('postingDate', Format(PurchRcptHeader."Posting Date", 0, 9));
        HeaderJson.Add('orderNo', PurchRcptHeader."Order No.");
        HeaderJson.Add('vendorShipmentNo', PurchRcptHeader."Vendor Shipment No.");
        HeaderJson.Add('locationCode', PurchRcptHeader."Location Code");
        exit(HeaderJson);
    end;

    local procedure BuildLineJson(PurchRcptLine: Record "Purch. Rcpt. Line"): JsonObject
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('lineNo', PurchRcptLine."Line No.");
        LineJson.Add('type', Format(PurchRcptLine.Type, 0, 9));
        LineJson.Add('no', PurchRcptLine."No.");
        LineJson.Add('description', PurchRcptLine.Description);
        LineJson.Add('quantity', PurchRcptLine.Quantity);
        LineJson.Add('unitOfMeasureCode', PurchRcptLine."Unit of Measure Code");
        LineJson.Add('locationCode', PurchRcptLine."Location Code");
        LineJson.Add('variantCode', PurchRcptLine."Variant Code");
        LineJson.Add('orderNo', PurchRcptLine."Order No.");
        LineJson.Add('orderLineNo', PurchRcptLine."Order Line No.");
        exit(LineJson);
    end;

    local procedure BuildShipmentJson(RecRef: RecordRef): JsonObject
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ShipmentJson: JsonObject;
        LinesJsonArray: JsonArray;
    begin
        RecRef.SetTable(SalesShipmentHeader);
        ShipmentJson.Add('header', BuildHeaderJson(SalesShipmentHeader));

        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        if SalesShipmentLine.FindSet() then
            repeat
                LinesJsonArray.Add(BuildLineJson(SalesShipmentLine));
            until SalesShipmentLine.Next() = 0;

        ShipmentJson.Add('lines', LinesJsonArray);
        exit(ShipmentJson);
    end;

    local procedure BuildHeaderJson(SalesShipmentHeader: Record "Sales Shipment Header"): JsonObject
    var
        HeaderJson: JsonObject;
    begin
        HeaderJson.Add('no', SalesShipmentHeader."No.");
        HeaderJson.Add('sellToCustomerNo', SalesShipmentHeader."Sell-to Customer No.");
        HeaderJson.Add('postingDate', Format(SalesShipmentHeader."Posting Date", 0, 9));
        HeaderJson.Add('orderNo', SalesShipmentHeader."Order No.");
        HeaderJson.Add('externalDocumentNo', SalesShipmentHeader."External Document No.");
        HeaderJson.Add('locationCode', SalesShipmentHeader."Location Code");
        exit(HeaderJson);
    end;

    local procedure BuildLineJson(SalesShipmentLine: Record "Sales Shipment Line"): JsonObject
    var
        LineJson: JsonObject;
    begin
        LineJson.Add('lineNo', SalesShipmentLine."Line No.");
        LineJson.Add('type', Format(SalesShipmentLine.Type, 0, 9));
        LineJson.Add('no', SalesShipmentLine."No.");
        LineJson.Add('description', SalesShipmentLine.Description);
        LineJson.Add('quantity', SalesShipmentLine.Quantity);
        LineJson.Add('unitOfMeasureCode', SalesShipmentLine."Unit of Measure Code");
        LineJson.Add('locationCode', SalesShipmentLine."Location Code");
        LineJson.Add('variantCode', SalesShipmentLine."Variant Code");
        LineJson.Add('orderNo', SalesShipmentLine."Order No.");
        LineJson.Add('orderLineNo', SalesShipmentLine."Order Line No.");
        exit(LineJson);
    end;

    #endregion BuildPayloadFunctions

    #region LoadStaging
    local procedure ReadPayload(ICEntries: Record "EOS IC Entries"; var HeaderObject: JsonObject; var LinesArray: JsonArray)
    var
        PayloadObject: JsonObject;
        JsonToken: JsonToken;
        InvalidPayloadErr: Label 'The received payload of the entry %1 is not a valid JSON.', Comment = '%1 = entry no.';
        MissingHeaderErr: Label 'The received payload of the entry %1 does not contain the header.', Comment = '%1 = entry no.';
    begin
        if not PayloadObject.ReadFrom(ICEntries.GetBlobFields(ICEntries.FieldNo("Received Payload"))) then
            Error(InvalidPayloadErr, ICEntries."Entry No.");

        if not PayloadObject.Get('header', JsonToken) then
            Error(MissingHeaderErr, ICEntries."Entry No.");
        HeaderObject := JsonToken.AsObject();

        if PayloadObject.Get('lines', JsonToken) then
            LinesArray := JsonToken.AsArray();
    end;

    local procedure PopulateSalesOrderFromPurchaseOrder(ICEntryNo: Integer; HeaderObject: JsonObject; LinesArray: JsonArray)
    var
        StgSalesHeader: Record "EOS IC Stg. Sales Header";
        StgSalesLine: Record "EOS IC Stg. Sales Line";
        LineToken: JsonToken;
        LineObject: JsonObject;
    begin
        StgSalesHeader.Init();
        StgSalesHeader."Entry No." := StgSalesHeader.GetNextEntryNo();
        StgSalesHeader."IC Entry No." := ICEntryNo;
        StgSalesHeader.Status := StgSalesHeader.Status::Pending;
        StgSalesHeader."External Document No." := CopyStr(ICFunctions.GetText(HeaderObject, 'no'), 1, MaxStrLen(StgSalesHeader."External Document No."));
        StgSalesHeader."Order Date" := ICFunctions.GetDate(HeaderObject, 'orderDate');
        StgSalesHeader."Posting Date" := ICFunctions.GetDate(HeaderObject, 'postingDate');
        StgSalesHeader."Document Date" := ICFunctions.GetDate(HeaderObject, 'documentDate');
        StgSalesHeader."Requested Delivery Date" := ICFunctions.GetDate(HeaderObject, 'requestedReceiptDate');
        StgSalesHeader."Currency Code" := CopyStr(ICFunctions.GetText(HeaderObject, 'currencyCode'), 1, MaxStrLen(StgSalesHeader."Currency Code"));
        StgSalesHeader."Your Reference" := CopyStr(ICFunctions.GetText(HeaderObject, 'yourReference'), 1, MaxStrLen(StgSalesHeader."Your Reference"));
        StgSalesHeader."Payment Terms Code" := CopyStr(ICFunctions.GetText(HeaderObject, 'paymentTermsCode'), 1, MaxStrLen(StgSalesHeader."Payment Terms Code"));
        StgSalesHeader."Shipment Method Code" := CopyStr(ICFunctions.GetText(HeaderObject, 'shipmentMethodCode'), 1, MaxStrLen(StgSalesHeader."Shipment Method Code"));
        StgSalesHeader.Insert(true);

        foreach LineToken in LinesArray do begin
            LineObject := LineToken.AsObject();
            StgSalesLine.Init();
            StgSalesLine."Entry No." := StgSalesHeader."Entry No.";
            StgSalesLine."Line No." := ICFunctions.GetInteger(LineObject, 'lineNo');
            StgSalesLine.Type := CopyStr(ICFunctions.GetText(LineObject, 'type'), 1, MaxStrLen(StgSalesLine.Type));
            StgSalesLine."No." := CopyStr(ICFunctions.GetText(LineObject, 'no'), 1, MaxStrLen(StgSalesLine."No."));
            StgSalesLine.Description := CopyStr(ICFunctions.GetText(LineObject, 'description'), 1, MaxStrLen(StgSalesLine.Description));
            StgSalesLine.Quantity := ICFunctions.GetDecimal(LineObject, 'quantity');
            StgSalesLine."Unit of Measure Code" := CopyStr(ICFunctions.GetText(LineObject, 'unitOfMeasureCode'), 1, MaxStrLen(StgSalesLine."Unit of Measure Code"));
            StgSalesLine."Unit Price" := ICFunctions.GetDecimal(LineObject, 'directUnitCost');
            StgSalesLine."Line Discount %" := ICFunctions.GetDecimal(LineObject, 'lineDiscountPercent');
            StgSalesLine."Line Amount" := ICFunctions.GetDecimal(LineObject, 'lineAmount');
            StgSalesLine."Requested Delivery Date" := ICFunctions.GetDate(LineObject, 'requestedReceiptDate');
            StgSalesLine."Variant Code" := CopyStr(ICFunctions.GetText(LineObject, 'variantCode'), 1, MaxStrLen(StgSalesLine."Variant Code"));
            StgSalesLine.Insert(true);
        end;
    end;

    local procedure PopulatePurchaseOrderFromSalesOrder(ICEntryNo: Integer; HeaderObject: JsonObject; LinesArray: JsonArray)
    var
        StgPurchHeader: Record "EOS IC Stg. Purch. Header";
        StgPurchLine: Record "EOS IC Stg. Purch. Line";
        LineToken: JsonToken;
        LineObject: JsonObject;
    begin
        StgPurchHeader.Init();
        StgPurchHeader."Entry No." := StgPurchHeader.GetNextEntryNo();
        StgPurchHeader."IC Entry No." := ICEntryNo;
        StgPurchHeader.Status := StgPurchHeader.Status::Pending;
        StgPurchHeader."Vendor Order No." := CopyStr(ICFunctions.GetText(HeaderObject, 'no'), 1, MaxStrLen(StgPurchHeader."Vendor Order No."));
        StgPurchHeader."Order Date" := ICFunctions.GetDate(HeaderObject, 'orderDate');
        StgPurchHeader."Posting Date" := ICFunctions.GetDate(HeaderObject, 'postingDate');
        StgPurchHeader."Document Date" := ICFunctions.GetDate(HeaderObject, 'documentDate');
        StgPurchHeader."Requested Receipt Date" := ICFunctions.GetDate(HeaderObject, 'requestedDeliveryDate');
        StgPurchHeader."Currency Code" := CopyStr(ICFunctions.GetText(HeaderObject, 'currencyCode'), 1, MaxStrLen(StgPurchHeader."Currency Code"));
        StgPurchHeader."Your Reference" := CopyStr(ICFunctions.GetText(HeaderObject, 'yourReference'), 1, MaxStrLen(StgPurchHeader."Your Reference"));
        StgPurchHeader."Payment Terms Code" := CopyStr(ICFunctions.GetText(HeaderObject, 'paymentTermsCode'), 1, MaxStrLen(StgPurchHeader."Payment Terms Code"));
        StgPurchHeader."Shipment Method Code" := CopyStr(ICFunctions.GetText(HeaderObject, 'shipmentMethodCode'), 1, MaxStrLen(StgPurchHeader."Shipment Method Code"));
        StgPurchHeader.Insert(true);

        foreach LineToken in LinesArray do begin
            LineObject := LineToken.AsObject();
            StgPurchLine.Init();
            StgPurchLine."Entry No." := StgPurchHeader."Entry No.";
            StgPurchLine."Line No." := ICFunctions.GetInteger(LineObject, 'lineNo');
            StgPurchLine.Type := CopyStr(ICFunctions.GetText(LineObject, 'type'), 1, MaxStrLen(StgPurchLine.Type));
            StgPurchLine."No." := CopyStr(ICFunctions.GetText(LineObject, 'no'), 1, MaxStrLen(StgPurchLine."No."));
            StgPurchLine.Description := CopyStr(ICFunctions.GetText(LineObject, 'description'), 1, MaxStrLen(StgPurchLine.Description));
            StgPurchLine.Quantity := ICFunctions.GetDecimal(LineObject, 'quantity');
            StgPurchLine."Unit of Measure Code" := CopyStr(ICFunctions.GetText(LineObject, 'unitOfMeasureCode'), 1, MaxStrLen(StgPurchLine."Unit of Measure Code"));
            StgPurchLine."Direct Unit Cost" := ICFunctions.GetDecimal(LineObject, 'unitPrice');
            StgPurchLine."Line Discount %" := ICFunctions.GetDecimal(LineObject, 'lineDiscountPercent');
            StgPurchLine."Line Amount" := ICFunctions.GetDecimal(LineObject, 'lineAmount');
            StgPurchLine."Requested Receipt Date" := ICFunctions.GetDate(LineObject, 'requestedDeliveryDate');
            StgPurchLine."Variant Code" := CopyStr(ICFunctions.GetText(LineObject, 'variantCode'), 1, MaxStrLen(StgPurchLine."Variant Code"));
            StgPurchLine.Insert(true);
        end;
    end;

    local procedure PopulateShipmentFromReceipt(ICEntryNo: Integer; HeaderObject: JsonObject; LinesArray: JsonArray)
    var
        StgShptHeader: Record "EOS IC Stg. Shpt. Header";
        StgShptLine: Record "EOS IC Stg. Shpt. Line";
        LineToken: JsonToken;
        LineObject: JsonObject;
    begin
        StgShptHeader.Init();
        StgShptHeader."Entry No." := StgShptHeader.GetNextEntryNo();
        StgShptHeader."IC Entry No." := ICEntryNo;
        StgShptHeader.Status := StgShptHeader.Status::Pending;
        StgShptHeader."External Document No." := CopyStr(ICFunctions.GetText(HeaderObject, 'no'), 1, MaxStrLen(StgShptHeader."External Document No."));
        StgShptHeader."Posting Date" := ICFunctions.GetDate(HeaderObject, 'postingDate');
        StgShptHeader.Insert(true);

        foreach LineToken in LinesArray do begin
            LineObject := LineToken.AsObject();
            StgShptLine.Init();
            StgShptLine."Entry No." := StgShptHeader."Entry No.";
            StgShptLine."Line No." := ICFunctions.GetInteger(LineObject, 'lineNo');
            StgShptLine.Type := CopyStr(ICFunctions.GetText(LineObject, 'type'), 1, MaxStrLen(StgShptLine.Type));
            StgShptLine."No." := CopyStr(ICFunctions.GetText(LineObject, 'no'), 1, MaxStrLen(StgShptLine."No."));
            StgShptLine.Description := CopyStr(ICFunctions.GetText(LineObject, 'description'), 1, MaxStrLen(StgShptLine.Description));
            StgShptLine.Quantity := ICFunctions.GetDecimal(LineObject, 'quantity');
            StgShptLine."Unit of Measure Code" := CopyStr(ICFunctions.GetText(LineObject, 'unitOfMeasureCode'), 1, MaxStrLen(StgShptLine."Unit of Measure Code"));
            StgShptLine."Variant Code" := CopyStr(ICFunctions.GetText(LineObject, 'variantCode'), 1, MaxStrLen(StgShptLine."Variant Code"));
            StgShptLine.Insert(true);
        end;
    end;

    local procedure PopulateReceiptFromShipment(ICEntryNo: Integer; HeaderObject: JsonObject; LinesArray: JsonArray)
    var
        StgRcptHeader: Record "EOS IC Stg. Rcpt. Header";
        StgRcptLine: Record "EOS IC Stg. Rcpt. Line";
        LineToken: JsonToken;
        LineObject: JsonObject;
    begin
        StgRcptHeader.Init();
        StgRcptHeader."Entry No." := StgRcptHeader.GetNextEntryNo();
        StgRcptHeader."IC Entry No." := ICEntryNo;
        StgRcptHeader.Status := StgRcptHeader.Status::Pending;
        StgRcptHeader."Vendor Shipment No." := CopyStr(ICFunctions.GetText(HeaderObject, 'no'), 1, MaxStrLen(StgRcptHeader."Vendor Shipment No."));
        StgRcptHeader."Posting Date" := ICFunctions.GetDate(HeaderObject, 'postingDate');
        StgRcptHeader.Insert(true);

        foreach LineToken in LinesArray do begin
            LineObject := LineToken.AsObject();
            StgRcptLine.Init();
            StgRcptLine."Entry No." := StgRcptHeader."Entry No.";
            StgRcptLine."Line No." := ICFunctions.GetInteger(LineObject, 'lineNo');
            StgRcptLine.Type := CopyStr(ICFunctions.GetText(LineObject, 'type'), 1, MaxStrLen(StgRcptLine.Type));
            StgRcptLine."No." := CopyStr(ICFunctions.GetText(LineObject, 'no'), 1, MaxStrLen(StgRcptLine."No."));
            StgRcptLine.Description := CopyStr(ICFunctions.GetText(LineObject, 'description'), 1, MaxStrLen(StgRcptLine.Description));
            StgRcptLine.Quantity := ICFunctions.GetDecimal(LineObject, 'quantity');
            StgRcptLine."Unit of Measure Code" := CopyStr(ICFunctions.GetText(LineObject, 'unitOfMeasureCode'), 1, MaxStrLen(StgRcptLine."Unit of Measure Code"));
            StgRcptLine."Variant Code" := CopyStr(ICFunctions.GetText(LineObject, 'variantCode'), 1, MaxStrLen(StgRcptLine."Variant Code"));
            StgRcptLine.Insert(true);
        end;
    end;

    local procedure PopulateItem(ICEntryNo: Integer; HeaderObject: JsonObject)
    var
        StgItem: Record "EOS IC Stg. Item";
    begin
        StgItem.Init();
        StgItem."Entry No." := StgItem.GetNextEntryNo();
        StgItem."IC Entry No." := ICEntryNo;
        StgItem.Status := StgItem.Status::Pending;
        StgItem."No." := CopyStr(ICFunctions.GetText(HeaderObject, 'no'), 1, MaxStrLen(StgItem."No."));
        StgItem.Description := CopyStr(ICFunctions.GetText(HeaderObject, 'description'), 1, MaxStrLen(StgItem.Description));
        StgItem."Description 2" := CopyStr(ICFunctions.GetText(HeaderObject, 'description2'), 1, MaxStrLen(StgItem."Description 2"));
        StgItem.Type := CopyStr(ICFunctions.GetText(HeaderObject, 'type'), 1, MaxStrLen(StgItem.Type));
        StgItem."Base Unit of Measure" := CopyStr(ICFunctions.GetText(HeaderObject, 'baseUnitOfMeasure'), 1, MaxStrLen(StgItem."Base Unit of Measure"));
        StgItem."Item Category Code" := CopyStr(ICFunctions.GetText(HeaderObject, 'itemCategoryCode'), 1, MaxStrLen(StgItem."Item Category Code"));
        StgItem."Gen. Prod. Posting Group" := CopyStr(ICFunctions.GetText(HeaderObject, 'genProdPostingGroup'), 1, MaxStrLen(StgItem."Gen. Prod. Posting Group"));
        StgItem."Inventory Posting Group" := CopyStr(ICFunctions.GetText(HeaderObject, 'inventoryPostingGroup'), 1, MaxStrLen(StgItem."Inventory Posting Group"));
        StgItem."VAT Prod. Posting Group" := CopyStr(ICFunctions.GetText(HeaderObject, 'vatProdPostingGroup'), 1, MaxStrLen(StgItem."VAT Prod. Posting Group"));
        StgItem."Unit Price" := ICFunctions.GetDecimal(HeaderObject, 'unitPrice');
        StgItem."Unit Cost" := ICFunctions.GetDecimal(HeaderObject, 'unitCost');
        StgItem.Blocked := ICFunctions.GetBoolean(HeaderObject, 'blocked');
        StgItem.GTIN := CopyStr(ICFunctions.GetText(HeaderObject, 'gtin'), 1, MaxStrLen(StgItem.GTIN));
        StgItem.Insert(true);
    end;

    #endregion LoadStaging
}