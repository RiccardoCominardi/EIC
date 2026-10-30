namespace EOS.Solutions.Intercompany;

page 67007 "EOS IC Flows API"
{
    PageType = API;
    APIPublisher = 'eos';
    APIGroup = 'eci';
    APIVersion = 'v1.0';
    EntityName = 'flow';
    EntitySetName = 'flows';
    SourceTable = "EOS IC Flows";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Extensible = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(companyCode; Rec."Company Code")
                {
                    Caption = 'Company Code';
                    Editable = false;
                }
                field(code; Rec."Code")
                {
                    Caption = 'Code';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(direction; Rec.Direction)
                {
                    Caption = 'Direction';
                    Editable = false;
                }
                field(directionOrdinal; DirectionOrdinal)
                {
                    Caption = 'Direction Ordinal';
                    Editable = false;
                }
                field(localDocumentType; Rec."Local Flow Type")
                {
                    Caption = 'Local Flow Type';
                    Editable = false;
                }
                field(localDocumentTypeOrdinal; LocalDocumentTypeOrdinal)
                {
                    Caption = 'Local Flow Type Ordinal';
                    Editable = false;
                }
                field(externalDocumentType; Rec."External Flow Type")
                {
                    Caption = 'External Flow Type';
                    Editable = false;
                }
                field(externalDocumentTypeOrdinal; ExternalDocumentTypeOrdinal)
                {
                    Caption = 'External Flow Type Ordinal';
                    Editable = false;
                }
                field(flowPairId; Rec."Flow Pair Id")
                {
                    Caption = 'Flow Pair Id';
                }
                field(autoCreateDocuments; Rec."Auto Create Documents")
                {
                    Caption = 'Auto Create Documents';
                    Editable = false;
                }
                field(enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DirectionOrdinal := Rec.Direction.AsInteger();
        LocalDocumentTypeOrdinal := Rec."Local Flow Type".AsInteger();
        ExternalDocumentTypeOrdinal := Rec."External Flow Type".AsInteger();
    end;

    var
        DirectionOrdinal, LocalDocumentTypeOrdinal, ExternalDocumentTypeOrdinal : Integer;
}