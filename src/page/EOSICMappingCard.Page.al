namespace EOS.Solutions.Intercompany;

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
            part(Lines; "EOS IC Mapping Lines Subpage")
            {
                ApplicationArea = All;
                Caption = 'Lines';
                SubPageLink = "Mapping Code" = field(Code);
                UpdatePropagation = Both;
                Editable = not Rec.Enabled;
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
        }
    }
}
