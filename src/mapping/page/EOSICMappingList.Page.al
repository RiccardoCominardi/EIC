namespace EOS.Solutions.Intercompany;

page 67009 "EOS IC Mapping List"
{
    Caption = 'IC Mappings (EIC)';
    CardPageID = "EOS IC Mapping Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Mapping Headers";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field(NoOfLines; NoOfLines)
                {
                    ApplicationArea = All;
                    Caption = 'No. of Lines';
                    ToolTip = 'Specifies the number of lines of the mapping.';
                }
                field("No. of Flows"; Rec."No. of Flows")
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
            action(ImportSampleJson)
            {
                ApplicationArea = All;
                Caption = 'Import Json';
                Image = Import;
                Visible = Rec.Direction = Rec.Direction::Inbound;
                ToolTip = 'Imports an example of the Json to be received and analyzes its structure, so that the Json paths can be selected instead of typed. No data is created in Business Central.';
                trigger OnAction()
                var
                    ICJsonSampleMgt: Codeunit "EOS IC Json Sample Mgt.";
                begin
                    ICJsonSampleMgt.ImportSample(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ExportJson)
            {
                ApplicationArea = All;
                Caption = 'Export Json';
                Enabled = Rec."Json File Name" <> '';
                Image = Export;
                Visible = Rec.Direction = Rec.Direction::Inbound;
                ToolTip = 'Downloads the Json file imported for this mapping.';
                trigger OnAction()
                var
                    ICJsonSampleMgt: Codeunit "EOS IC Json Sample Mgt.";
                begin
                    ICJsonSampleMgt.ExportSampleJson(Rec);
                end;
            }
            action(ValidateMapping)
            {
                ApplicationArea = All;
                Caption = 'Validate Mapping';
                Image = CheckList;
                ToolTip = 'Checks that the configuration of the mapping is complete and consistent.';
                trigger OnAction()
                var
                    ICMappingValidation: Codeunit "EOS IC Mapping Validation";
                begin
                    ICMappingValidation.ValidateAndShowResult(Rec.Code);
                end;
            }
            action(DownloadJsonExample)
            {
                ApplicationArea = All;
                Caption = 'Download Json Example';
                Image = Download;
                Visible = Rec.Direction = Rec.Direction::Outbound;
                ToolTip = 'Generates the Json of the first records of the source table that match the table filter and downloads it. The mapping must be enabled.';
                trigger OnAction()
                var
                    ICOutMappingMgt: Codeunit "EOS IC Out. Mapping Mgt.";
                begin
                    ICOutMappingMgt.DownloadExampleFile(Rec);
                end;
            }
            action(ImportMapping)
            {
                ApplicationArea = All;
                Caption = 'Import Mapping';
                Image = Import;
                ToolTip = 'Imports an outbound mapping, with its table relations and transformation rules, from a file.';
                trigger OnAction()
                var
                    ICOutMappingExchange: Codeunit "EOS IC Out. Mapping Exchange";
                begin
                    ICOutMappingExchange.ImportMapping();
                    CurrPage.Update(false);
                end;
            }
            action(ExportMapping)
            {
                ApplicationArea = All;
                Caption = 'Export Mapping';
                Image = Export;
                ToolTip = 'Exports the selected outbound mappings, with their table relations and transformation rules. More mappings are downloaded in a zip file.';
                trigger OnAction()
                var
                    ICMappingHeaders: Record "EOS IC Mapping Headers";
                    ICOutMappingExchange: Codeunit "EOS IC Out. Mapping Exchange";
                begin
                    CurrPage.SetSelectionFilter(ICMappingHeaders);
                    ICOutMappingExchange.ExportMapping(ICMappingHeaders, false);
                end;
            }
            action(ExportMappingBase64)
            {
                ApplicationArea = All;
                Caption = 'Export Mapping (Base64)';
                Image = Export;
                ToolTip = 'Exports the selected outbound mappings as Base64 text files. More mappings are downloaded in a zip file.';
                trigger OnAction()
                var
                    ICMappingHeaders: Record "EOS IC Mapping Headers";
                    ICOutMappingExchange: Codeunit "EOS IC Out. Mapping Exchange";
                begin
                    CurrPage.SetSelectionFilter(ICMappingHeaders);
                    ICOutMappingExchange.ExportMapping(ICMappingHeaders, true);
                end;
            }
        }
        area(Navigation)
        {
            action(ShowSampleStructure)
            {
                ApplicationArea = All;
                Caption = 'Json Structure';
                Image = View;
                Visible = Rec.Direction = Rec.Direction::Inbound;
                RunObject = page "EOS IC Mapping Json Nodes";
                RunPageLink = "Mapping Code" = field(Code);
                ToolTip = 'Shows the structure of the imported Json.';
            }
            action(TableRelations)
            {
                ApplicationArea = All;
                Caption = 'Table Relations';
                Image = Relationship;
                RunObject = page "EOS IC Table Relation List";
                ToolTip = 'Shows the relations between the tables that can be used by the lines of the outbound mappings.';
            }
        }
        area(Promoted)
        {
            actionref(ValidateMapping_Promoted; ValidateMapping) { }
            group(JsonGroup)
            {
                Caption = 'Json', Locked = true;
                Image = View;
                actionref(ExportJson_Promoted; ExportJson) { }
                actionref(ImportSampleJson_Promoted; ImportSampleJson) { }
                actionref(ShowSampleStructure_Promoted; ShowSampleStructure) { }
            }
            group(OutboundGroup)
            {
                Caption = 'Outbound';
                Image = View;
                actionref(DownloadJsonExample_Promoted; DownloadJsonExample) { }
                actionref(TableRelations_Promoted; TableRelations) { }
                actionref(ImportMapping_Promoted; ImportMapping) { }
                actionref(ExportMapping_Promoted; ExportMapping) { }
                actionref(ExportMappingBase64_Promoted; ExportMappingBase64) { }
            }
        }
    }

    var
        NoOfLines: Integer;

    trigger OnAfterGetRecord()
    begin
        NoOfLines := Rec.GetNoOfLines();
    end;
}
