namespace EOS.Solutions.Intercompany;

codeunit 67013 "EOS IC Mapping Mgt."
{
    var
        ICJsonPathMgt: Codeunit "EOS IC Json Path Mgt.";

    procedure MoveUp(MappingLine: Record "EOS IC Mapping Lines")
    begin
        MoveMappingLine(MappingLine, -1);
    end;

    procedure MoveDown(MappingLine: Record "EOS IC Mapping Lines")
    begin
        MoveMappingLine(MappingLine, 1);
    end;

    procedure CanMoveLine(MappingLine: Record "EOS IC Mapping Lines"): Boolean
    begin
        exit(not MappingLine."Is Structure" and (MappingLine."Json Path" <> '') and not IsArrayPath(MappingLine."Json Path"));
    end;

    local procedure MoveMappingLine(MappingLine: Record "EOS IC Mapping Lines"; Direction: Integer)
    var
        AdjacentMappingLine: Record "EOS IC Mapping Lines";
        ParentContext: Text;
    begin
        if not CanMoveLine(MappingLine) then
            exit;

        ParentContext := GetLineParentContext(MappingLine."Json Path");
        if not FindAdjacentMappingLine(MappingLine, AdjacentMappingLine, Direction, ParentContext) then
            exit;

        SwapLineNumbers(MappingLine, AdjacentMappingLine);
    end;

    local procedure FindAdjacentMappingLine(MappingLine: Record "EOS IC Mapping Lines"; var AdjacentMappingLine: Record "EOS IC Mapping Lines"; Direction: Integer; ParentContext: Text): Boolean
    begin
        AdjacentMappingLine.SetCurrentKey("Mapping Code", "Line No.");
        AdjacentMappingLine.SetRange("Mapping Code", MappingLine."Mapping Code");
        AdjacentMappingLine.SetRange("Array Context", MappingLine."Array Context");
        AdjacentMappingLine.SetRange("Is Structure", false);

        if Direction < 0 then begin
            AdjacentMappingLine.SetFilter("Line No.", '<%1', MappingLine."Line No.");
            if AdjacentMappingLine.FindLast() then
                repeat
                    if (AdjacentMappingLine."Json Path" <> '') and not IsArrayPath(AdjacentMappingLine."Json Path") then
                        if GetLineParentContext(AdjacentMappingLine."Json Path") = ParentContext then
                            exit(true);
                until AdjacentMappingLine.Next(-1) = 0;
        end else begin
            AdjacentMappingLine.SetFilter("Line No.", '>%1', MappingLine."Line No.");
            if AdjacentMappingLine.FindFirst() then
                repeat
                    if (AdjacentMappingLine."Json Path" <> '') and not IsArrayPath(AdjacentMappingLine."Json Path") then
                        if GetLineParentContext(AdjacentMappingLine."Json Path") = ParentContext then
                            exit(true);
                until AdjacentMappingLine.Next() = 0;
        end;

        exit(false);
    end;

    local procedure IsArrayPath(JsonPath: Text): Boolean
    var
        Steps: List of [Text];
        PathError: Text;
    begin
        if not ICJsonPathMgt.ParsePath(JsonPath, Steps, PathError) then
            exit(false);
        if Steps.Count() = 0 then
            exit(false);
        exit(ICJsonPathMgt.IsArrayStep(Steps.Get(Steps.Count())));
    end;

    local procedure GetLineParentContext(JsonPath: Text): Text
    var
        Steps: List of [Text];
        PathError: Text;
    begin
        if not ICJsonPathMgt.ParsePath(JsonPath, Steps, PathError) then
            exit('');
        if Steps.Count() = 0 then
            exit('');
        if ICJsonPathMgt.IsArrayStep(Steps.Get(Steps.Count())) then
            exit(ICJsonPathMgt.SerializeSteps(Steps, Steps.Count()));
        exit(ICJsonPathMgt.SerializeSteps(Steps, Steps.Count() - 1));
    end;

    local procedure SwapLineNumbers(var MappingLine: Record "EOS IC Mapping Lines"; var AdjacentMappingLine: Record "EOS IC Mapping Lines")
    var
        ExistingMappingLine: Record "EOS IC Mapping Lines";
        MappingLineNo: Integer;
        AdjacentLineNo: Integer;
        TempLineNo: Integer;
    begin
        MappingLineNo := MappingLine."Line No.";
        AdjacentLineNo := AdjacentMappingLine."Line No.";
        TempLineNo := -1;
        while ExistingMappingLine.Get(MappingLine."Mapping Code", TempLineNo) do
            TempLineNo -= 1;

        MappingLine.Rename(MappingLine."Mapping Code", TempLineNo);
        AdjacentMappingLine.Rename(AdjacentMappingLine."Mapping Code", MappingLineNo);
        MappingLine.Rename(MappingLine."Mapping Code", AdjacentLineNo);
    end;

    // ContextElement is the element of the payload the record is created from (the payload itself for records at the root).
    [IntegrationEvent(false, false)]
    procedure OnTransformValue(ICMappingLine: Record "EOS IC Mapping Lines"; ContextElement: JsonToken; CurrentValue: Text; var Result: Text; var Handled: Boolean)
    begin
    end;
}