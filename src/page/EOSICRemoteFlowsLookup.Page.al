namespace EOS.Solutions.Intercompany;

page 67008 "EOS IC Remote Flows Lookup"
{
    Caption = 'Remote IC Flows (EIC)';
    DataCaptionExpression = Rec."Company Code";
    PageType = List;
    SourceTable = "EOS IC Flows";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;
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
                field("Local Document Type"; Rec."Local Document Type")
                {
                    ApplicationArea = All;
                }
                field("External Document Type"; Rec."External Document Type")
                {
                    ApplicationArea = All;
                }
                field("Flow Pair Id"; Rec."Flow Pair Id")
                {
                    ApplicationArea = All;
                }
                field("Auto Send"; Rec."Auto Send")
                {
                    ApplicationArea = All;
                }
                field("Auto Process"; Rec."Auto Process")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure LoadRemoteFlows(var SourceRemoteFlows: Record "EOS IC Flows" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        SourceRemoteFlows.Reset();
        if SourceRemoteFlows.FindSet() then
            repeat
                Rec := SourceRemoteFlows;
                Rec.Insert(false, true);
            until SourceRemoteFlows.Next() = 0;
    end;
}
