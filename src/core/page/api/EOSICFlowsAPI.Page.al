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
                    ToolTip = 'Specifies the unique system ID of the flow.';
                    Editable = false;
                }
                field(companyCode; Rec."Company Code")
                {
                    Caption = 'Company Code';
                    ToolTip = 'Specifies the code of the company that owns the flow.';
                    Editable = false;
                }
                field(code; Rec."Code")
                {
                    Caption = 'Code';
                    ToolTip = 'Specifies the unique code of the flow within the company.';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the flow.';
                    Editable = false;
                }
                field(direction; Rec.Direction)
                {
                    Caption = 'Direction';
                    ToolTip = 'Specifies whether the flow sends data to or receives data from another company.';
                    Editable = false;
                }
                field(directionOrdinal; DirectionOrdinal)
                {
                    Caption = 'Direction Ordinal';
                    ToolTip = 'Specifies the numeric ordinal of the flow direction.';
                    Editable = false;
                }
                field(relationTableId; Rec."Relation Table Id")
                {
                    Caption = 'Relation Table Id';
                    ToolTip = 'Specifies the ID of the table associated with the flow.';
                }
                field(relationOptionType; Rec."Relation Option Type")
                {
                    Caption = 'Relation Option Type';
                    ToolTip = 'Specifies the option value used to identify the source document type.';
                }
                field(relationTableName; Rec."Relation Table Name")
                {
                    Caption = 'Relation Table Name';
                    ToolTip = 'Specifies the name of the table associated with the flow.';
                }
                field(flowTypeOrdinal; flowTypeOrdinal)
                {
                    Caption = 'Flow Type Ordinal';
                    ToolTip = 'Specifies the numeric ordinal of the flow type.';
                    Editable = false;
                }
                field(flowPairId; Rec."Flow Pair Id")
                {
                    Caption = 'Flow Pair Id';
                    ToolTip = 'Specifies the identifier used to pair this flow with a flow in the remote company.';
                }
                field(autoCreateDocuments; Rec."Auto Create Documents")
                {
                    Caption = 'Auto Create Documents';
                    ToolTip = 'Specifies whether documents are created automatically from inbound staging data.';
                    Editable = false;
                }
                field(enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the flow is available for processing.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DirectionOrdinal := Rec.Direction.AsInteger();
    end;

    var
        DirectionOrdinal, flowTypeOrdinal : Integer;
}