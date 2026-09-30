namespace EOS.Solutions.Intercompany;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;

codeunit 67008 "EOS IC Events"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterValidateEvent, 'Sell-to Customer No.', false, false)]
    local procedure SalesHeaderOnAfterValidateSellToCustomerNo(var Rec: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        if Customer.Get(Rec."Sell-to Customer No.") then
            Rec."EOS IC Company" := Customer."EOS IC Company"
        else
            Rec."EOS IC Company" := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterValidateEvent, 'Buy-from Vendor No.', false, false)]
    local procedure PurchaseHeaderOnAfterValidateBuyFromVendorNo(var Rec: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Buy-from Vendor No.") then
            Rec."EOS IC Company" := Vendor."EOS IC Company"
        else
            Rec."EOS IC Company" := '';
    end;
}
