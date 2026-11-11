namespace EOS.Solutions.Intercompany;

using System.Text;

page 67000 "EOS IC Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "EOS IC Setup";
    Caption = 'IC Setup (EIC)';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("Company Code"; Rec."Company Code")
                {
                    ApplicationArea = All;
                }
                field("Interface Company"; Rec."Interface Company")
                {
                    ApplicationArea = All;
                }
                field("Enable Unified Staging"; Rec."Enable Unified Staging")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that new inbound entries use the unified staging table.';
                }
            }
            group(DocumentFields)
            {
                Caption = 'Document Fields';
                field("Company Code Field No."; Rec."Company Code Field No.")
                {
                    ApplicationArea = All;
                }
                field("IC Entry Field No."; Rec."IC Entry Field No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateTestInboundEntry)
            {
                ApplicationArea = All;
                Caption = 'Create Test Inbound Entry';
                Image = Import;
                Enabled = Rec.Enabled and Rec."Enable Unified Staging";
                ToolTip = 'Creates a pending inbound EIC Entry using the TEST mapping and the sample Json payload.';

                trigger OnAction()
                var
                    ICEntries: Record "EOS IC Entries";
                    ICFlows: Record "EOS IC Flows";
                    ICMapping: Record "EOS IC Mapping Headers";
                    PayloadToken: JsonToken;
                    PayloadText: Text;
                    FlowCount: Integer;
                    TestMappingCode: Code[20];
                    MappingNotFoundErr: Label 'The inbound mapping %1 was not found.', Comment = '%1 = mapping code';
                    MappingNotReadyErr: Label 'The mapping %1 must be enabled and configured for unified staging.', Comment = '%1 = mapping code';
                    NoTestFlowErr: Label 'No enabled inbound flow uses mapping %1.', Comment = '%1 = mapping code';
                    MultipleTestFlowsErr: Label 'More than one enabled inbound flow uses mapping %1. Keep only one for this test action.', Comment = '%1 = mapping code';
                    InvalidPayloadErr: Label 'The test Json payload is invalid.';
                    EntryCreatedMsg: Label 'Inbound EIC Entry %1 was created for flow %2. Process it from the IC Entries page to populate staging.', Comment = '%1 = Entry No., %2 = flow code';
                begin
                    Rec.TestField(Enabled, true);
                    Rec.TestField("Company Code");
                    Rec.TestField("Enable Unified Staging", true);

                    TestMappingCode := 'TEST';
                    if not ICMapping.Get(TestMappingCode) then
                        Error(MappingNotFoundErr, TestMappingCode);
                    if not ICMapping.Enabled or not ICMapping."Unified Staging" or (ICMapping.Direction <> ICMapping.Direction::Inbound) then
                        Error(MappingNotReadyErr, TestMappingCode);

                    ICFlows.SetRange(Direction, ICFlows.Direction::Inbound);
                    ICFlows.SetRange("Mapping Code", TestMappingCode);
                    ICFlows.SetRange(Enabled, true);
                    FlowCount := ICFlows.Count();
                    case FlowCount of
                        0:
                            Error(NoTestFlowErr, TestMappingCode);
                        1:
                            ICFlows.FindFirst();
                        else
                            Error(MultipleTestFlowsErr, TestMappingCode);
                    end;

                    PayloadText := GetTestInboundPayload();
                    if not PayloadToken.ReadFrom(PayloadText) then
                        Error(InvalidPayloadErr);

                    ICEntries.Init();
                    ICEntries."Entry No." := ICEntries.GetNextEntryNo();
                    ICEntries."IC Transaction ID" := CreateGuid();
                    ICEntries."IC Flow Code" := ICFlows.Code;
                    ICEntries.Direction := ICEntries.Direction::Inbound;
                    ICEntries."Source Company" := ICFlows."Company Code";
                    ICEntries."Target Company" := Rec."Company Code";
                    ICEntries."Relation Table Id" := ICFlows."Relation Table Id";
                    ICEntries."Relation Option Type" := ICFlows."Relation Option Type";
                    ICEntries."Use Staging" := true;
                    ICEntries.Status := ICEntries.Status::Pending;
                    ICEntries."Staging Status" := ICEntries."Staging Status"::None;
                    ICEntries.SetBlobFields(ICEntries.FieldNo("Received Payload"), PayloadText, false);
                    ICEntries.Insert(true);

                    Message(EntryCreatedMsg, ICEntries."Entry No.", ICFlows.Code);
                end;
            }
        }
        area(Navigation)
        {
            action(ICEntries)
            {
                ApplicationArea = All;
                Caption = 'IC Entries';
                Image = Log;
                RunObject = page "EOS IC Entries";
            }
            action(StringTransformations)
            {
                ApplicationArea = All;
                Caption = 'String Transformations';
                Image = Translations;
                RunObject = page "EOS IC String Transformations";
                ToolTip = 'Shows the string transformations that can be assigned to the lines of the mappings.';
            }
        }
        area(Promoted)
        {
            actionref(CreateTestInboundEntry_Promoted; CreateTestInboundEntry) { }
            actionref(ICEntries_Promoted; ICEntries) { }
            actionref(StringTransformations_Promoted; StringTransformations) { }
        }
    }

    local procedure GetTestInboundPayload(): Text
    var
        PayloadBuilder: TextBuilder;
    begin
        PayloadBuilder.AppendLine('{"header": {');
        PayloadBuilder.AppendLine('"no": "101009",');
        PayloadBuilder.AppendLine('"sellToCustomerNo": "38128456",');
        PayloadBuilder.AppendLine('"orderDate": "2028-01-21",');
        PayloadBuilder.AppendLine('"postingDate": "2028-01-30",');
        PayloadBuilder.AppendLine('"documentDate": "2028-01-21",');
        PayloadBuilder.AppendLine('"requestedDeliveryDate": "",');
        PayloadBuilder.AppendLine('"currencyCode": "EUR",');
        PayloadBuilder.AppendLine('"externalDocumentNo": "",');
        PayloadBuilder.AppendLine('"yourReference": "",');
        PayloadBuilder.AppendLine('"paymentTermsCode": "1M(8D)",');
        PayloadBuilder.AppendLine('"shipmentMethodCode": "EXW",');
        PayloadBuilder.AppendLine('"locationCode": "RED",');
        PayloadBuilder.AppendLine('"lines": [');
        PayloadBuilder.AppendLine('{');
        PayloadBuilder.AppendLine('"lineNo": 10000,');
        PayloadBuilder.AppendLine('"type": "2",');
        PayloadBuilder.AppendLine('"no": "1976-W",');
        PayloadBuilder.AppendLine('"description": "INNSBRUCK Storage Unit/W.Door",');
        PayloadBuilder.AppendLine('"quantity": 5.0,');
        PayloadBuilder.AppendLine('"unitOfMeasureCode": "PCS",');
        PayloadBuilder.AppendLine('"unitPrice": 396.562,');
        PayloadBuilder.AppendLine('"lineDiscountPercent": 0.0,');
        PayloadBuilder.AppendLine('"lineAmount": 1982.81,');
        PayloadBuilder.AppendLine('"locationCode": "GREEN",');
        PayloadBuilder.AppendLine('"requestedDeliveryDate": "",');
        PayloadBuilder.AppendLine('"variantCode": "",');
        PayloadBuilder.AppendLine('"lots": [');
        PayloadBuilder.AppendLine('{"no": "TEST", "quantity": 5, "description": "Prova"},');
        PayloadBuilder.AppendLine('{"no": "TEST2", "quantity": 10, "description": "Prova 2"}');
        PayloadBuilder.AppendLine(']');
        PayloadBuilder.AppendLine('},');
        PayloadBuilder.AppendLine('{');
        PayloadBuilder.AppendLine('"lineNo": 20000,');
        PayloadBuilder.AppendLine('"type": "2",');
        PayloadBuilder.AppendLine('"no": "1964-W",');
        PayloadBuilder.AppendLine('"description": "INNSBRUCK Storage Unit/G.Door",');
        PayloadBuilder.AppendLine('"quantity": 2.0,');
        PayloadBuilder.AppendLine('"unitOfMeasureCode": "PCS",');
        PayloadBuilder.AppendLine('"unitPrice": 452.152,');
        PayloadBuilder.AppendLine('"lineDiscountPercent": 0.0,');
        PayloadBuilder.AppendLine('"lineAmount": 904.3,');
        PayloadBuilder.AppendLine('"locationCode": "GREEN",');
        PayloadBuilder.AppendLine('"requestedDeliveryDate": "",');
        PayloadBuilder.AppendLine('"variantCode": "",');
        PayloadBuilder.AppendLine('"lots": [');
        PayloadBuilder.AppendLine('{"no": "TEST", "quantity": 5, "description": "Prova"},');
        PayloadBuilder.AppendLine('{"no": "TEST2", "quantity": 10, "description": "Prova 2"}');
        PayloadBuilder.AppendLine(']');
        PayloadBuilder.AppendLine('}');
        PayloadBuilder.AppendLine(']');
        PayloadBuilder.AppendLine('}}');
        exit(PayloadBuilder.ToText());
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}