namespace EOS.Solutions.Intercompany;

using System.Utilities;

page 67021 "EOS IC Table Value Type List"
{
    Caption = 'Table Value Type List (EIC)';
    DataCaptionExpression = '';
    PageType = List;
    SourceTable = Integer;
    SourceTableView = sorting(Number) where(Number = filter(0 .. 19));
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Number; Rec.Number)
                {
                    ApplicationArea = All;
                    Caption = 'Option No.';
                }
                field(MyField; gTxtArrayValue[Rec.Number + 1])
                {
                    ApplicationArea = All;
                    Caption = 'Option Value';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::Cancel, Action::LookupCancel] then
            CancelOnPush();
        if CloseAction = Action::LookupOK then
            LookupOKOnPush();
    end;

    var
        gTxtArrayValue: array[20] of Text[30];
        gTxtTypeFilter: Text[30];

    procedure SetValue(iTxtArrayValue: array[20] of Text[30])
    var
        lIntCount: Integer;
    begin
        for lIntCount := 1 to ArrayLen(gTxtArrayValue) do
            gTxtArrayValue[lIntCount] := iTxtArrayValue[lIntCount];
    end;

    procedure GetTypeFilter(): Text[30]
    begin
        exit(gTxtTypeFilter);
    end;

    procedure GetOptionType(): Integer
    begin
        exit(Rec.Number);
    end;

    local procedure LookupOKOnPush()
    begin
        gTxtTypeFilter := '';
        CurrPage.SetSelectionFilter(Rec);
        if Rec.Find('-') then
            repeat
                gTxtTypeFilter := CopyStr(gTxtTypeFilter + Format(Rec.Number) + '|', 1, MaxStrLen(gTxtTypeFilter));
            until Rec.Next() = 0;
        gTxtTypeFilter := DelChr(gTxtTypeFilter, '<', '|');
        gTxtTypeFilter := DelChr(gTxtTypeFilter, '>', '|');
    end;

    local procedure CancelOnPush()
    begin
        gTxtTypeFilter := '';
        CurrPage.SetSelectionFilter(Rec);
        if Rec.Find('-') then
            repeat
                gTxtTypeFilter := CopyStr(gTxtTypeFilter + Format(Rec.Number) + '|', 1, MaxStrLen(gTxtTypeFilter));
            until Rec.Next() = 0;
        gTxtTypeFilter := DelChr(gTxtTypeFilter, '<', '|');
        gTxtTypeFilter := DelChr(gTxtTypeFilter, '>', '|');
    end;
}