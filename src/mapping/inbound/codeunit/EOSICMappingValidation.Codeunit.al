namespace EOS.Solutions.Intercompany;

using System.Text;

codeunit 67015 "EOS IC Mapping Validation"
{
    var
        ICStagingMgt: Codeunit "EOS IC Staging Mgt.";

    procedure ValidateMapping(MappingCode: Code[20]; ForExecution: Boolean; CheckSample: Boolean; var Issues: List of [Text]): Boolean
    var
        ICMapping: Record "EOS IC Mapping Headers";
        ICOutMappingValidation: Codeunit "EOS IC Out. Mapping Validation";
        MappingNotFoundErr: Label 'The mapping %1 does not exist.', Comment = '%1 = mapping code';
    begin
        Clear(Issues);
        if not ICMapping.Get(MappingCode) then begin
            Issues.Add(StrSubstNo(MappingNotFoundErr, MappingCode));
            exit(false);
        end;

        if ICMapping.Direction = ICMapping.Direction::Outbound then
            exit(ICOutMappingValidation.ValidateMapping(MappingCode, Issues));

        ICStagingMgt.ValidateMapping(MappingCode, ForExecution, CheckSample, Issues);
        exit(Issues.Count() = 0);
    end;

    procedure CheckForExecution(MappingCode: Code[20])
    var
        Issues: List of [Text];
        NotValidErr: Label 'The mapping %1 is not valid:\%2', Comment = '%1 = mapping code, %2 = list of problems';
    begin
        if not ValidateMapping(MappingCode, true, false, Issues) then
            Error(NotValidErr, MappingCode, GetIssuesText(Issues));
    end;

    procedure CheckForActivation(MappingCode: Code[20])
    var
        Issues: List of [Text];
        NotValidErr: Label 'The mapping %1 cannot be enabled because it is not valid:\%2', Comment = '%1 = mapping code, %2 = list of problems';
    begin
        if not ValidateMapping(MappingCode, false, true, Issues) then
            Error(NotValidErr, MappingCode, GetIssuesText(Issues));
    end;

    procedure ValidateAndShowResult(MappingCode: Code[20])
    var
        Issues: List of [Text];
        ValidMsg: Label 'The mapping %1 is valid.', Comment = '%1 = mapping code';
        NotValidMsg: Label 'The mapping %1 is not valid:\%2', Comment = '%1 = mapping code, %2 = list of problems';
    begin
        if ValidateMapping(MappingCode, false, true, Issues) then
            Message(ValidMsg, MappingCode)
        else
            Message(NotValidMsg, MappingCode, GetIssuesText(Issues));
    end;

    procedure GetIssuesText(Issues: List of [Text]): Text
    var
        Result: TextBuilder;
        Issue: Text;
    begin
        foreach Issue in Issues do
            Result.AppendLine(Issue);
        exit(Result.ToText());
    end;
}