namespace EOS.Solutions.Intercompany;

using Microsoft.Foundation.NoSeries;
using System.Reflection;
using System.Utilities;

table 67006 "EOS IC Entries"
{
    DataClassification = CustomerContent;
    Caption = 'IC Entries (EIC)';
    DrillDownPageId = "EOS IC Entries";
    LookupPageId = "EOS IC Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(2; "IC Transaction ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Transaction ID';
        }
        field(3; "IC Flow Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'IC Flow Code';
            TableRelation = if (Direction = const(Outbound)) "EOS IC Flows"."Code" where("Company Code" = field("Target Company")) else if (Direction = const(Inbound)) "EOS IC Flows"."Code" where("Company Code" = field("Source Company"));
        }
        field(4; Direction; Enum "EOS IC Direction")
        {
            DataClassification = CustomerContent;
            Caption = 'Direction';
        }
        field(5; "Source Company"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Company';
        }
        field(6; "Target Company"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Target Company';
        }
        field(7; "Source Document Type"; Enum "EOS IC Flow Document Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Source Document Type';
        }
        field(8; "Source Document No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Document No.';
        }
        field(9; "Source Table Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Table Id';
        }
        field(10; "Source System Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Source System Id';
        }
        field(11; "Target Document Type"; Enum "EOS IC Flow Document Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Target Document Type';
        }
        field(12; "Target Document No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Target Document No.';
        }
        field(13; "Target Table Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Source Table Id';
        }
        field(14; "Target System Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Source System Id';
        }
        field(15; Status; Enum "EOS IC Entry Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Status';
        }
        field(16; "Processed At"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Processed At';
        }
        field(17; "Retry Count"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Retry Count';
        }
        field(18; "Error Message"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Error Message';
        }
        field(19; "Error Message Blob"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Error Message Blob';
        }
        field(20; "Call Stack"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Call Stack';
        }
        field(21; "Call Stack Blob"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Call Stack Blob';
        }
        field(22; "Request Payload"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Request Payload';
        }
        field(23; "Received Payload"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Received Payload';
        }
        field(24; "Staging Status"; Enum "EOS IC Staging Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Staging Status';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.") { Clustered = true; }
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"EOS IC Entries", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"EOS IC Entries"));
    end;

    procedure GetBlobFields(BlobFieldNo: Integer): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        case BlobFieldNo of
            Rec.FieldNo("Error Message Blob"):
                begin
                    Rec.CalcFields("Error Message Blob");
                    Rec."Error Message Blob".CreateInStream(InStr, TextEncoding::UTF8);
                    exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStr, TypeHelper.LFSeparator(), Rec.FieldName("Error Message Blob")));
                end;
            Rec.FieldNo("Call Stack Blob"):
                begin
                    Rec.CalcFields("Call Stack Blob");
                    Rec."Call Stack Blob".CreateInStream(InStr, TextEncoding::UTF8);
                    exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStr, TypeHelper.LFSeparator(), Rec.FieldName("Call Stack Blob")));
                end;
            Rec.FieldNo("Request Payload"):
                begin
                    Rec.CalcFields("Request Payload");
                    Rec."Request Payload".CreateInStream(InStr, TextEncoding::UTF8);
                    exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStr, TypeHelper.LFSeparator(), Rec.FieldName("Request Payload")));
                end;
            Rec.FieldNo("Received Payload"):
                begin
                    Rec.CalcFields("Received Payload");
                    Rec."Received Payload".CreateInStream(InStr, TextEncoding::UTF8);
                    exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStr, TypeHelper.LFSeparator(), Rec.FieldName("Received Payload")));
                end;
        end;
    end;

    procedure SetBlobFields(BlobFieldNo: Integer; NewText: Text; WithModify: Boolean)
    var
        OutStr: OutStream;
    begin
        case BlobFieldNo of
            Rec.FieldNo("Error Message Blob"):
                begin
                    Clear(Rec."Error Message Blob");
                    Rec."Error Message Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
                    OutStr.WriteText(NewText);
                    if WithModify then
                        Rec.Modify();
                end;
            Rec.FieldNo("Call Stack Blob"):
                begin
                    Clear(Rec."Call Stack Blob");
                    Rec."Call Stack Blob".CreateOutStream(OutStr, TextEncoding::UTF8);
                    OutStr.WriteText(NewText);
                    if WithModify then
                        Rec.Modify();
                end;
            Rec.FieldNo("Request Payload"):
                begin
                    Clear(Rec."Request Payload");
                    Rec."Request Payload".CreateOutStream(OutStr, TextEncoding::UTF8);
                    OutStr.WriteText(NewText);
                    if WithModify then
                        Rec.Modify();
                end;
            Rec.FieldNo("Received Payload"):
                begin
                    Clear(Rec."Received Payload");
                    Rec."Received Payload".CreateOutStream(OutStr, TextEncoding::UTF8);
                    OutStr.WriteText(NewText);
                    if WithModify then
                        Rec.Modify();
                end;
        end;
    end;

    procedure ExportBlobToJson(BlobFieldNo: Integer)
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        BlobText, FileName, FieldName : Text;
        EmptyBlobErr: Label 'There is no content to export.';
        FileNameLbl: Label '%1_%2.json', Locked = true, Comment = '%1 = entry no., %2 = field name';
    begin
        BlobText := Rec.GetBlobFields(BlobFieldNo);
        if BlobText = '' then
            Error(EmptyBlobErr);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(BlobText);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);

        case BlobFieldNo of
            Rec.FieldNo("Request Payload"):
                FieldName := Rec.FieldCaption("Request Payload");
            Rec.FieldNo("Received Payload"):
                FieldName := Rec.FieldCaption("Received Payload");
        end;
        FileName := StrSubstNo(FileNameLbl, Rec."Entry No.", DelChr(FieldName, '=', ' '));
        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
