namespace EOS.Solutions.Intercompany;

using System.Environment;
using System.IO;
using System.Text;
using System.Utilities;

codeunit 67020 "EOS IC Out. Mapping Exchange"
{
    procedure ImportMapping()
    var
        ICOutMappingImpex: XmlPort "EOS IC Out. Mapping Impex";
        InStr: InStream;
        FileName: Text;
        DialogTitleLbl: Label 'Import Mapping';
        FileFilterLbl: Label 'Xml files (*.xml)|*.xml|All files (*.*)|*.*', Locked = true;
    begin
        if not UploadIntoStream(DialogTitleLbl, '', FileFilterLbl, FileName, InStr) then
            exit;

        ICOutMappingImpex.SetSource(InStr);
        ICOutMappingImpex.Import();
    end;

    // A single mapping is downloaded as file; more mappings are downloaded in a zip file with one file per mapping.
    procedure ExportMapping(var ICMappingHeader: Record "EOS IC Mapping Headers"; AsBase64: Boolean)
    var
        ICMappingHeader2: Record "EOS IC Mapping Headers";
        EnvironmentInformation: Codeunit "Environment Information";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        FileInStr: InStream;
        EnvironmentText: Text;
        FileName: Text;
        FileExtension: Text;
        SingleFile: Boolean;
        NotOutboundErr: Label 'Only outbound mappings can be exported.';
        ZipFileNameLbl: Label '%1_%2_%3.zip', Locked = true, Comment = '%1 = environment, %2 = table caption, %3 = file extension';
        FileNameLbl: Label '%1_%2.%3', Locked = true, Comment = '%1 = mapping code, %2 = environment, %3 = file extension';
        DialogTitleLbl: Label 'Export Mapping';
    begin
        ICMappingHeader2.Copy(ICMappingHeader);
        ICMappingHeader2.SetRange(Direction, ICMappingHeader2.Direction::Inbound);
        if not ICMappingHeader2.IsEmpty() then
            Error(NotOutboundErr);

        if not ICMappingHeader.FindSet() then
            exit;

        SingleFile := ICMappingHeader.Count() = 1;
        if not SingleFile then
            DataCompression.CreateZipArchive();

        EnvironmentText := StrSubstNo('%1_%2', DelChr(EnvironmentInformation.GetEnvironmentName(), '=', ' '), DelChr(CompanyName(), '=', ' '));
        EnvironmentText := ConvertStr(EnvironmentText, '\/():|*?<>', '__________');

        if AsBase64 then
            FileExtension := 'base64'
        else
            FileExtension := 'xml';

        repeat
            FileName := ConvertStr(StrSubstNo(FileNameLbl, ICMappingHeader.Code, EnvironmentText, FileExtension), '\/():|*?<>', '__________');

            Clear(TempBlob);
            ExportToBlob(ICMappingHeader, AsBase64, TempBlob);

            if not SingleFile then begin
                TempBlob.CreateInStream(FileInStr, TextEncoding::UTF8);
                DataCompression.AddEntry(FileInStr, FileName);
            end;
        until ICMappingHeader.Next() = 0;

        if not SingleFile then begin
            Clear(TempBlob);
            DataCompression.SaveZipArchive(TempBlob);
            FileName := ConvertStr(StrSubstNo(ZipFileNameLbl, EnvironmentText, ICMappingHeader.TableCaption(), FileExtension), '\/():|*?<>', '__________');
        end;

        TempBlob.CreateInStream(FileInStr, TextEncoding::UTF8);
        DownloadFromStream(FileInStr, DialogTitleLbl, '', '', FileName);
    end;

    local procedure ExportToBlob(ICMappingHeader: Record "EOS IC Mapping Headers"; AsBase64: Boolean; var TempBlob: Codeunit "Temp Blob")
    var
        Base64Convert: Codeunit "Base64 Convert";
        XmlBlob: Codeunit "Temp Blob";
        XmlInStr: InStream;
        FileOutStr: OutStream;
    begin
        if not AsBase64 then begin
            ExportXml(ICMappingHeader, TempBlob);
            exit;
        end;

        ExportXml(ICMappingHeader, XmlBlob);
        XmlBlob.CreateInStream(XmlInStr, TextEncoding::UTF8);
        TempBlob.CreateOutStream(FileOutStr, TextEncoding::UTF8);
        FileOutStr.WriteText(Base64Convert.ToBase64(XmlInStr));
    end;

    local procedure ExportXml(ICMappingHeader: Record "EOS IC Mapping Headers"; var TempBlob: Codeunit "Temp Blob")
    var
        ICOutMappingImpex: XmlPort "EOS IC Out. Mapping Impex";
        FileOutStr: OutStream;
    begin
        ICMappingHeader.SetRecFilter();

        TempBlob.CreateOutStream(FileOutStr, TextEncoding::UTF8);
        ICOutMappingImpex.SetTableView(ICMappingHeader);
        ICOutMappingImpex.SetDestination(FileOutStr);
        ICOutMappingImpex.Export();
    end;
}
