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
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = All;
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
        area(Navigation)
        {
            action(ShowSampleStructure)
            {
                ApplicationArea = All;
                Caption = 'Json Structure';
                Image = View;
                RunObject = page "EOS IC Mapping Json Nodes";
                RunPageLink = "Mapping Code" = field(Code);
                ToolTip = 'Shows the structure of the imported Json.';
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
