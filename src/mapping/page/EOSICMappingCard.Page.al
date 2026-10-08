namespace EOS.Solutions.Intercompany;

using System.Reflection;

page 67010 "EOS IC Mapping Card"
{
    Caption = 'IC Mapping Card (EIC)';
    PageType = Document;
    UsageCategory = None;
    RefreshOnActivate = true;
    SourceTable = "EOS IC Mapping Headers";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
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
                    Editable = not Rec.Enabled;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("No. of Flows"; Rec."No. of Flows")
                {
                    ApplicationArea = All;
                }
            }
            group(Json)
            {
                Caption = 'Json';
                Visible = Rec.Direction = Rec.Direction::Inbound;
                field("Json File Name"; Rec."Json File Name")
                {
                    ApplicationArea = All;
                    Caption = 'Json File Name';
                }
                field("Json Imported At"; Rec."Json Imported At")
                {
                    ApplicationArea = All;
                    Caption = 'Json Imported At';
                }
            }
            group(Source)
            {
                Caption = 'Source';
                Visible = Rec.Direction = Rec.Direction::Outbound;
                field("Source Table No."; Rec."Source Table No.")
                {
                    ApplicationArea = All;
                    Editable = not Rec.Enabled;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Source Table Name"; Rec."Source Table Name")
                {
                    ApplicationArea = All;
                }
                field(TableFilterFld; TableFilterText)
                {
                    ApplicationArea = All;
                    Caption = 'Example Table Filter';
                    Editable = false;
                    ToolTip = 'Specifies the filter on the source table used to generate the example file.';

                    trigger OnAssistEdit()
                    begin
                        OpenFilterPageBuilder();
                    end;
                }
            }
            part(Lines; "EOS IC Mapping Lines Subpage")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = "Mapping Code" = field(Code);
                UpdatePropagation = Both;
                Editable = not Rec.Enabled;
                Visible = Rec.Direction = Rec.Direction::Inbound;
            }
            part(OutboundLines; "EOS IC Out. Mapping Lines Sub")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = "Mapping Code" = field(Code);
                UpdatePropagation = Both;
                Editable = not Rec.Enabled;
                Visible = Rec.Direction = Rec.Direction::Outbound;
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
                Visible = Rec.Direction = Rec.Direction::Outbound;
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
                Visible = Rec.Direction = Rec.Direction::Outbound;
                ToolTip = 'Exports the outbound mapping, with its table relations and transformation rules, to a file.';
                trigger OnAction()
                var
                    ICMappingHeaders: Record "EOS IC Mapping Headers";
                    ICOutMappingExchange: Codeunit "EOS IC Out. Mapping Exchange";
                begin
                    ICMappingHeaders.SetRange(Code, Rec.Code);
                    ICOutMappingExchange.ExportMapping(ICMappingHeaders, false);
                end;
            }
            action(ExportMappingBase64)
            {
                ApplicationArea = All;
                Caption = 'Export Mapping (Base64)';
                Image = Export;
                Visible = Rec.Direction = Rec.Direction::Outbound;
                ToolTip = 'Exports the outbound mapping as a Base64 text file.';
                trigger OnAction()
                var
                    ICMappingHeaders: Record "EOS IC Mapping Headers";
                    ICOutMappingExchange: Codeunit "EOS IC Out. Mapping Exchange";
                begin
                    ICMappingHeaders.SetRange(Code, Rec.Code);
                    ICOutMappingExchange.ExportMapping(ICMappingHeaders, true);
                end;
            }
        }
        area(Navigation)
        {
            action(TableRelations)
            {
                ApplicationArea = All;
                Caption = 'Table Relations';
                Image = Relationship;
                Visible = Rec.Direction = Rec.Direction::Outbound;
                RunObject = page "EOS IC Table Relation List";
                ToolTip = 'Shows the relations between the tables that can be used by the lines of the outbound mappings.';
            }
        }
        area(Promoted)
        {
            actionref(ValidateMapping_Promoted; ValidateMapping) { }
            group(InboundJson)
            {
                Caption = 'Json', Locked = true;
                Image = View;
                actionref(ExportJson_Promoted; ExportJson) { }
                actionref(ImportSampleJson_Promoted; ImportSampleJson) { }
                actionref(ShowSampleStructure_Promoted; ShowSampleStructure) { }
            }
            group(OutboundJson)
            {
                Caption = 'Json', Locked = true;
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
        TableFilterText: Text;

    trigger OnAfterGetRecord()
    begin
        TableFilterText := Rec.GetTableFilter();
    end;

    local procedure OpenFilterPageBuilder()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        FilterPageBuilderPage: FilterPageBuilder;
        FilterName: Text;
    begin
        Rec.TestField(Direction, Rec.Direction::Outbound);
        Rec.TestField(Enabled, false);
        Rec.TestField("Source Table No.");
        AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Rec."Source Table No.");
        FilterName := AllObjWithCaption."Object Caption";

        FilterPageBuilderPage.AddTable(FilterName, Rec."Source Table No.");
        if TableFilterText <> '' then
            FilterPageBuilderPage.SetView(FilterName, TableFilterText);
        if FilterPageBuilderPage.RunModal() then begin
            TableFilterText := FilterPageBuilderPage.GetView(FilterName, false);
            Rec.SetTableFilter(TableFilterText);
            Rec.Modify(true);
        end;
    end;
}
