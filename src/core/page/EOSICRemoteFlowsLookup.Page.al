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
                    ToolTip = 'Specifies the unique code of the remote flow.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the remote flow.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the remote flow sends or receives data.';
                }
                field("Relation Table Id"; Rec."Relation Table Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the table associated with the remote flow.';
                }
                field("Relation Option Type"; Rec."Relation Option Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the option value used to identify the remote document type.';
                }
                field("Relation Table Name"; Rec."Relation Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the table associated with the remote flow.';
                }
                field("Flow Pair Id"; Rec."Flow Pair Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the identifier used to match this remote flow with a local flow.';
                }
                field("Auto Send"; Rec."Auto Send")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the remote flow sends entries automatically.';
                }
                field("Auto Process"; Rec."Auto Process")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the remote flow processes entries automatically.';
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
