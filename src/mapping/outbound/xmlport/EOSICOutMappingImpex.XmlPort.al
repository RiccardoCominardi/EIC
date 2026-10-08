namespace EOS.Solutions.Intercompany;

using System.IO;

xmlport 67000 "EOS IC Out. Mapping Impex"
{
    Caption = 'IC Outbound Mapping Import/Export (EIC)';
    DefaultFieldsValidation = false;
    Encoding = UTF8;
    FormatEvaluate = Xml;
    PreserveWhiteSpace = true;
    UseRequestPage = false;

    schema
    {
        textelement(ICOutboundMapping)
        {
            textattribute(version)
            {
                trigger OnBeforePassVariable()
                begin
                    version := VersionLbl;
                end;
            }

            tableelement(ICMappingHeader; "EOS IC Mapping Headers")
            {
                AutoReplace = true;
                MinOccurs = Zero;
                XmlName = 'MappingHeader';

                fieldelement(Code; ICMappingHeader.Code)
                {
                    trigger OnAfterAssignField()
                    begin
                        PrepareReplace(ICMappingHeader.Code);
                    end;
                }
                fieldelement(Description; ICMappingHeader.Description)
                {
                }
                fieldelement(Direction; ICMappingHeader.Direction)
                {
                    trigger OnAfterAssignField()
                    begin
                        if ICMappingHeader.Direction <> ICMappingHeader.Direction::Outbound then
                            Error(NotOutboundErr, ICMappingHeader.Code);
                    end;
                }
                fieldelement(SourceTableNo; ICMappingHeader."Source Table No.")
                {
                }
                textelement(HeaderTableFilter)
                {
                    trigger OnBeforePassVariable()
                    begin
                        HeaderTableFilter := ICMappingHeader.GetTableFilter();
                    end;

                    trigger OnAfterAssignVariable()
                    var
                        OutStr: OutStream;
                    begin
                        Clear(ICMappingHeader."Table Filter");
                        if HeaderTableFilter <> '' then begin
                            ICMappingHeader."Table Filter".CreateOutStream(OutStr);
                            OutStr.WriteText(HeaderTableFilter);
                        end;
                        Clear(HeaderTableFilter);
                    end;
                }

                tableelement(ICOutMappingLine; "EOS IC Out. Mapping Lines")
                {
                    LinkFields = "Mapping Code" = field(Code);
                    LinkTable = ICMappingHeader;
                    MinOccurs = Zero;
                    SourceTableView = sorting("Mapping Code", "Line No.");
                    XmlName = 'MappingLine';

                    fieldelement(MappingCode; ICOutMappingLine."Mapping Code")
                    {
                    }
                    fieldelement(LineNo; ICOutMappingLine."Line No.")
                    {
                    }
                    fieldelement(SortNo; ICOutMappingLine."Sort No.")
                    {
                    }
                    fieldelement(LineType; ICOutMappingLine."Line Type")
                    {
                    }
                    fieldelement(TableNo; ICOutMappingLine."Table No.")
                    {
                    }
                    fieldelement(FieldNo; ICOutMappingLine."Field No.")
                    {
                    }
                    fieldelement(ParentLineNo; ICOutMappingLine."Parent Line No.")
                    {
                    }
                    fieldelement(Level; ICOutMappingLine.Level)
                    {
                    }
                    fieldelement(RecordRelation; ICOutMappingLine."Record Relation")
                    {
                    }
                    fieldelement(ParentTableNo; ICOutMappingLine."Parent Table No.")
                    {
                    }
                    fieldelement(AttributeType; ICOutMappingLine."Attribute Type")
                    {
                    }
                    textelement(LineTableFilter)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            LineTableFilter := ICOutMappingLine.GetTableFilter();
                        end;

                        trigger OnAfterAssignVariable()
                        var
                            OutStr: OutStream;
                        begin
                            Clear(ICOutMappingLine."Table Filter");
                            if LineTableFilter <> '' then begin
                                ICOutMappingLine."Table Filter".CreateOutStream(OutStr);
                                OutStr.WriteText(LineTableFilter);
                            end;
                            Clear(LineTableFilter);
                        end;
                    }
                    fieldelement(JsonTag; ICOutMappingLine."Json Tag")
                    {
                    }
                    fieldelement(IsArray; ICOutMappingLine."Is Array")
                    {
                    }
                    // Constants made only of spaces are trimmed by the XML parser, so they are exported with a placeholder.
                    textelement(Constant)
                    {
                        trigger OnBeforePassVariable()
                        begin
                            Constant := ICOutMappingLine.Constant;
                            if (Constant <> '') and (Constant.Trim() = '') then
                                Constant := Constant.Replace(' ', SpaceTagLbl);
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            ICOutMappingLine.Constant := CopyStr(Constant.Replace(SpaceTagLbl, ' '), 1, MaxStrLen(ICOutMappingLine.Constant));
                            Clear(Constant);
                        end;
                    }
                    fieldelement(Function; ICOutMappingLine."Function")
                    {
                    }
                    fieldelement(FunctionParameters; ICOutMappingLine."Function Parameters")
                    {
                    }
                    fieldelement(BlankAsNull; ICOutMappingLine."Blank as null")
                    {
                    }
                    fieldelement(FieldType; ICOutMappingLine."Field Type")
                    {
                    }
                    fieldelement(Length; ICOutMappingLine.Length)
                    {
                    }
                    fieldelement(Description; ICOutMappingLine.Description)
                    {
                    }
                    fieldelement(TransformationRule; ICOutMappingLine."Transformation Rule")
                    {
                    }
                    fieldelement(EncodeToBase64; ICOutMappingLine."Encode to Base64")
                    {
                        MinOccurs = Zero;
                    }
                    fieldelement(ConstantType; ICOutMappingLine."Constant Type")
                    {
                        MinOccurs = Zero;
                    }

                    tableelement(ICTableRelationHeader; "EOS IC Table Relation Header")
                    {
                        AutoReplace = true;
                        LinkFields = Code = field("Record Relation");
                        LinkTable = ICOutMappingLine;
                        MinOccurs = Zero;
                        SourceTableView = sorting(Code);
                        XmlName = 'TableRelationHeader';

                        fieldelement(Code; ICTableRelationHeader.Code)
                        {
                        }
                        fieldelement(Description; ICTableRelationHeader.Description)
                        {
                        }
                        fieldelement(SourceTableNo; ICTableRelationHeader."Source Table No.")
                        {
                        }
                        fieldelement(TargetTableNo; ICTableRelationHeader."Target Table No.")
                        {
                        }

                        tableelement(ICTableRelationLine; "EOS IC Table Relation Line")
                        {
                            AutoReplace = true;
                            LinkFields = Code = field(Code);
                            LinkTable = ICTableRelationHeader;
                            MinOccurs = Zero;
                            SourceTableView = sorting(Code);
                            XmlName = 'TableRelationLine';

                            fieldelement(Code; ICTableRelationLine.Code)
                            {
                            }
                            fieldelement(LineNo; ICTableRelationLine."Line No.")
                            {
                            }
                            fieldelement(SourceFieldNo; ICTableRelationLine."Source Field No.")
                            {
                            }
                            fieldelement(TargetFieldNo; ICTableRelationLine."Target Field No.")
                            {
                            }
                        }
                    }

                    tableelement(TransformationRuleTable; "Transformation Rule")
                    {
                        AutoReplace = true;
                        LinkFields = Code = field("Transformation Rule");
                        LinkTable = ICOutMappingLine;
                        MinOccurs = Zero;
                        SourceTableView = sorting(Code);
                        XmlName = 'TransformationRuleTable';

                        fieldelement(Code; TransformationRuleTable.Code)
                        {
                        }
                        fieldelement(Description; TransformationRuleTable.Description)
                        {
                        }
                        fieldelement(TransformationType; TransformationRuleTable."Transformation Type")
                        {
                        }
                        fieldelement(FindValue; TransformationRuleTable."Find Value")
                        {
                        }
                        fieldelement(ReplaceValue; TransformationRuleTable."Replace Value")
                        {
                        }
                        fieldelement(StartingText; TransformationRuleTable."Starting Text")
                        {
                        }
                        fieldelement(EndingText; TransformationRuleTable."Ending Text")
                        {
                        }
                        fieldelement(StartPosition; TransformationRuleTable."Start Position")
                        {
                        }
                        fieldelement(Length; TransformationRuleTable.Length)
                        {
                        }
                        fieldelement(DataFormat; TransformationRuleTable."Data Format")
                        {
                        }
                        fieldelement(DataFormattingCulture; TransformationRuleTable."Data Formatting Culture")
                        {
                        }
                        fieldelement(NextTransformationRule; TransformationRuleTable."Next Transformation Rule")
                        {
                        }
                        fieldelement(TableID; TransformationRuleTable."Table ID")
                        {
                        }
                        fieldelement(SourceFieldID; TransformationRuleTable."Source Field ID")
                        {
                        }
                        fieldelement(TargetFieldID; TransformationRuleTable."Target Field ID")
                        {
                        }
                        fieldelement(FieldLookupRule; TransformationRuleTable."Field Lookup Rule")
                        {
                        }
                        fieldelement(Precision; TransformationRuleTable.Precision)
                        {
                        }
                        fieldelement(Direction; TransformationRuleTable.Direction)
                        {
                        }
                        fieldelement(ExtractFromDateType; TransformationRuleTable."Extract From Date Type")
                        {
                        }
                    }
                }
            }
        }
    }

    trigger OnInitXmlPort()
    begin
        Clear(HeaderTableFilter);
        Clear(LineTableFilter);
        Clear(Constant);
    end;

    // An existing mapping is replaced by the imported one only when it is a disabled outbound mapping.
    local procedure PrepareReplace(MappingCodes: Code[20])
    var
        ExistingMapping: Record "EOS IC Mapping Headers";
        ICOutMappingLine: Record "EOS IC Out. Mapping Lines";
    begin
        if not ExistingMapping.Get(MappingCodes) then
            exit;

        if ExistingMapping.Direction <> ExistingMapping.Direction::Outbound then
            Error(NotOutboundErr, MappingCodes);
        if ExistingMapping.Enabled then
            Error(MappingEnabledErr, MappingCodes);

        ICOutMappingLine.SetRange("Mapping Code", MappingCodes);
        ICOutMappingLine.DeleteAll();
    end;

    var
        SpaceTagLbl: Label '[$S$]', Locked = true;
        VersionLbl: Label '1.0', Locked = true;
        NotOutboundErr: Label 'The mapping %1 is not an outbound mapping.', Comment = '%1 = mapping code';
        MappingEnabledErr: Label 'The mapping %1 already exists and is enabled. Disable it before importing it again.', Comment = '%1 = mapping code';
}
