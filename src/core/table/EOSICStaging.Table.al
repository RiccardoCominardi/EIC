namespace EOS.Solutions.Intercompany;

using System.Security.User;

table 67011 "EOS IC Staging"
{
    DataClassification = CustomerContent;
    Caption = 'IC Staging (EIC)';

    fields
    {
        field(1; "Staging Record ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Staging Record ID';
            ToolTip = 'Specifies the unique identifier of this staging record.';
        }
        field(2; "IC Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'IC Entry No.';
            ToolTip = 'Specifies the intercompany entry that owns this staging record.';
            TableRelation = "EOS IC Entries"."Entry No.";
        }
        field(3; "Parent Record ID"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Parent Record ID';
            ToolTip = 'Specifies the identifier of the parent staging record.';
        }
        field(4; Level; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Level';
            ToolTip = 'Specifies the nesting depth of this staging record.';
        }
        field(5; "Sequence No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Sequence No.';
            ToolTip = 'Specifies the sequence of this record within its parent array.';
        }
        field(6; "Tree Order"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Tree Order';
            ToolTip = 'Specifies the position of this record in the staging tree.';
        }
        field(7; "Mapping Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Mapping Code';
            ToolTip = 'Specifies the mapping used to create this staging record.';
            TableRelation = "EOS IC Mapping Headers".Code;
        }
        field(8; "Node Identifier"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Node Identifier';
            ToolTip = 'Specifies the identifier or JSON path of the source node.';
        }
        field(9; "Node Type"; Enum "EOS IC Json Node Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Node Type';
            ToolTip = 'Specifies whether the source node is an object, array, or value.';
        }
        field(10; "Source Company"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Company';
            ToolTip = 'Specifies the company that sent the source data.';
        }
        field(11; "IC Flow Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'IC Flow Code';
            ToolTip = 'Specifies the inbound flow used to receive this staging record.';
        }
        field(12; "Manually Modified"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Manually Modified';
            ToolTip = 'Indicates whether a value in this staging record was changed manually.';
            Editable = false;
        }
        field(13; "Manually Modified At"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Manually Modified At';
            ToolTip = 'Specifies when a value in this staging record was last changed manually.';
            Editable = false;
        }
        field(14; "Manually Modified By"; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Manually Modified By';
            ToolTip = 'Specifies the user who last changed a value in this staging record.';
            Editable = false;
        }
        field(15; "Error Message"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Error Message';
            ToolTip = 'Specifies the error reported while processing this staging record.';
            Editable = false;
        }
        field(20; "Text 1"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 1', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(21; "Text 2"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 2', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(22; "Text 3"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 3', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(23; "Text 4"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 4', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(24; "Text 5"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 5', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(25; "Text 6"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 6', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(26; "Text 7"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 7', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(27; "Text 8"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 8', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(28; "Text 9"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 9', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(29; "Text 10"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 10', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(30; "Decimal 1"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 1', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(31; "Decimal 2"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 2', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(32; "Decimal 3"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 3', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(33; "Decimal 4"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 4', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(34; "Decimal 5"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 5', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(35; "Decimal 6"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 6', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(36; "Decimal 7"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 7', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(37; "Decimal 8"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 8', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(38; "Decimal 9"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 9', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(39; "Decimal 10"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 10', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(40; "Integer 1"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 1', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(41; "Integer 2"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 2', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(42; "Integer 3"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 3', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(43; "Integer 4"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 4', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(44; "Integer 5"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 5', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(45; "Integer 6"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 6', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(46; "Integer 7"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 7', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(47; "Integer 8"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 8', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(48; "Integer 9"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 9', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(49; "Integer 10"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 10', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(50; "BigInteger 1"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 1', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(51; "BigInteger 2"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 2', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(52; "BigInteger 3"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 3', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(53; "BigInteger 4"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 4', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(54; "BigInteger 5"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 5', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(55; "BigInteger 6"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 6', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(56; "BigInteger 7"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 7', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(57; "BigInteger 8"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 8', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(58; "BigInteger 9"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 9', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(59; "BigInteger 10"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 10', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(60; "GUID 1"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 1', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(61; "GUID 2"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 2', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(62; "GUID 3"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 3', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(63; "GUID 4"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 4', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(64; "GUID 5"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 5', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(65; "GUID 6"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 6', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(66; "GUID 7"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 7', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(67; "GUID 8"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 8', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(68; "GUID 9"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 9', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(69; "GUID 10"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 10', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(70; "Boolean 1"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 1', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(71; "Boolean 2"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 2', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(72; "Boolean 3"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 3', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(73; "Boolean 4"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 4', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(74; "Boolean 5"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 5', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(75; "Boolean 6"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 6', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(76; "Boolean 7"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 7', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(77; "Boolean 8"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 8', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(78; "Boolean 9"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 9', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(79; "Boolean 10"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 10', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(80; "Date 1"; Date) { DataClassification = CustomerContent; Caption = 'Date 1', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(81; "Date 2"; Date) { DataClassification = CustomerContent; Caption = 'Date 2', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(82; "Date 3"; Date) { DataClassification = CustomerContent; Caption = 'Date 3', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(83; "Date 4"; Date) { DataClassification = CustomerContent; Caption = 'Date 4', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(84; "Date 5"; Date) { DataClassification = CustomerContent; Caption = 'Date 5', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(85; "Date 6"; Date) { DataClassification = CustomerContent; Caption = 'Date 6', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(86; "Date 7"; Date) { DataClassification = CustomerContent; Caption = 'Date 7', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(87; "Date 8"; Date) { DataClassification = CustomerContent; Caption = 'Date 8', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(88; "Date 9"; Date) { DataClassification = CustomerContent; Caption = 'Date 9', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(89; "Date 10"; Date) { DataClassification = CustomerContent; Caption = 'Date 10', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(90; "DateTime 1"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 1', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(91; "DateTime 2"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 2', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(92; "DateTime 3"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 3', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(93; "DateTime 4"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 4', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(94; "DateTime 5"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 5', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(95; "DateTime 6"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 6', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(96; "DateTime 7"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 7', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(97; "DateTime 8"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 8', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(98; "DateTime 9"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 9', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(99; "DateTime 10"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 10', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(100; "Time 1"; Time) { DataClassification = CustomerContent; Caption = 'Time 1', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(101; "Time 2"; Time) { DataClassification = CustomerContent; Caption = 'Time 2', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(102; "Time 3"; Time) { DataClassification = CustomerContent; Caption = 'Time 3', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(103; "Time 4"; Time) { DataClassification = CustomerContent; Caption = 'Time 4', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(104; "Time 5"; Time) { DataClassification = CustomerContent; Caption = 'Time 5', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(105; "Time 6"; Time) { DataClassification = CustomerContent; Caption = 'Time 6', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(106; "Time 7"; Time) { DataClassification = CustomerContent; Caption = 'Time 7', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(107; "Time 8"; Time) { DataClassification = CustomerContent; Caption = 'Time 8', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(108; "Time 9"; Time) { DataClassification = CustomerContent; Caption = 'Time 9', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(109; "Time 10"; Time) { DataClassification = CustomerContent; Caption = 'Time 10', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(110; "Text 11"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 11', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(111; "Text 12"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 12', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(112; "Text 13"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 13', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(113; "Text 14"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 14', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(114; "Text 15"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 15', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(115; "Text 16"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 16', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(116; "Text 17"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 17', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(117; "Text 18"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 18', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(118; "Text 19"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 19', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(119; "Text 20"; Text[2048]) { DataClassification = CustomerContent; Caption = 'Text 20', Locked = true; ToolTip = 'Specifies the text value stored in this staging field.'; }
        field(120; "Decimal 11"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 11', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(121; "Decimal 12"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 12', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(122; "Decimal 13"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 13', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(123; "Decimal 14"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 14', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(124; "Decimal 15"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 15', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(125; "Decimal 16"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 16', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(126; "Decimal 17"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 17', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(127; "Decimal 18"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 18', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(128; "Decimal 19"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 19', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(129; "Decimal 20"; Decimal) { DataClassification = CustomerContent; Caption = 'Decimal 20', Locked = true; ToolTip = 'Specifies the decimal value stored in this staging field.'; }
        field(130; "Integer 11"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 11', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(131; "Integer 12"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 12', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(132; "Integer 13"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 13', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(133; "Integer 14"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 14', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(134; "Integer 15"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 15', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(135; "Integer 16"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 16', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(136; "Integer 17"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 17', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(137; "Integer 18"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 18', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(138; "Integer 19"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 19', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(139; "Integer 20"; Integer) { DataClassification = CustomerContent; Caption = 'Integer 20', Locked = true; ToolTip = 'Specifies the integer value stored in this staging field.'; }
        field(140; "BigInteger 11"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 11', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(141; "BigInteger 12"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 12', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(142; "BigInteger 13"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 13', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(143; "BigInteger 14"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 14', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(144; "BigInteger 15"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 15', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(145; "BigInteger 16"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 16', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(146; "BigInteger 17"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 17', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(147; "BigInteger 18"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 18', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(148; "BigInteger 19"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 19', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(149; "BigInteger 20"; BigInteger) { DataClassification = CustomerContent; Caption = 'BigInteger 20', Locked = true; ToolTip = 'Specifies the large integer value stored in this staging field.'; }
        field(150; "GUID 11"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 11', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(151; "GUID 12"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 12', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(152; "GUID 13"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 13', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(153; "GUID 14"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 14', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(154; "GUID 15"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 15', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(155; "GUID 16"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 16', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(156; "GUID 17"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 17', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(157; "GUID 18"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 18', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(158; "GUID 19"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 19', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(159; "GUID 20"; Guid) { DataClassification = CustomerContent; Caption = 'GUID 20', Locked = true; ToolTip = 'Specifies the unique identifier value stored in this staging field.'; }
        field(160; "Boolean 11"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 11', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(161; "Boolean 12"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 12', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(162; "Boolean 13"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 13', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(163; "Boolean 14"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 14', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(164; "Boolean 15"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 15', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(165; "Boolean 16"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 16', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(166; "Boolean 17"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 17', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(167; "Boolean 18"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 18', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(168; "Boolean 19"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 19', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(169; "Boolean 20"; Boolean) { DataClassification = CustomerContent; Caption = 'Boolean 20', Locked = true; ToolTip = 'Specifies whether the staging field value is true or false.'; }
        field(170; "Date 11"; Date) { DataClassification = CustomerContent; Caption = 'Date 11', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(171; "Date 12"; Date) { DataClassification = CustomerContent; Caption = 'Date 12', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(172; "Date 13"; Date) { DataClassification = CustomerContent; Caption = 'Date 13', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(173; "Date 14"; Date) { DataClassification = CustomerContent; Caption = 'Date 14', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(174; "Date 15"; Date) { DataClassification = CustomerContent; Caption = 'Date 15', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(175; "Date 16"; Date) { DataClassification = CustomerContent; Caption = 'Date 16', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(176; "Date 17"; Date) { DataClassification = CustomerContent; Caption = 'Date 17', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(177; "Date 18"; Date) { DataClassification = CustomerContent; Caption = 'Date 18', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(178; "Date 19"; Date) { DataClassification = CustomerContent; Caption = 'Date 19', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(179; "Date 20"; Date) { DataClassification = CustomerContent; Caption = 'Date 20', Locked = true; ToolTip = 'Specifies the date value stored in this staging field.'; }
        field(180; "DateTime 11"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 11', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(181; "DateTime 12"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 12', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(182; "DateTime 13"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 13', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(183; "DateTime 14"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 14', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(184; "DateTime 15"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 15', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(185; "DateTime 16"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 16', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(186; "DateTime 17"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 17', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(187; "DateTime 18"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 18', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(188; "DateTime 19"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 19', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(189; "DateTime 20"; DateTime) { DataClassification = CustomerContent; Caption = 'DateTime 20', Locked = true; ToolTip = 'Specifies the date and time value stored in this staging field.'; }
        field(190; "Time 11"; Time) { DataClassification = CustomerContent; Caption = 'Time 11', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(191; "Time 12"; Time) { DataClassification = CustomerContent; Caption = 'Time 12', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(192; "Time 13"; Time) { DataClassification = CustomerContent; Caption = 'Time 13', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(193; "Time 14"; Time) { DataClassification = CustomerContent; Caption = 'Time 14', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(194; "Time 15"; Time) { DataClassification = CustomerContent; Caption = 'Time 15', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(195; "Time 16"; Time) { DataClassification = CustomerContent; Caption = 'Time 16', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(196; "Time 17"; Time) { DataClassification = CustomerContent; Caption = 'Time 17', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(197; "Time 18"; Time) { DataClassification = CustomerContent; Caption = 'Time 18', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(198; "Time 19"; Time) { DataClassification = CustomerContent; Caption = 'Time 19', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
        field(199; "Time 20"; Time) { DataClassification = CustomerContent; Caption = 'Time 20', Locked = true; ToolTip = 'Specifies the time value stored in this staging field.'; }
    }

    keys
    {
        key(Key1; "Staging Record ID") { Clustered = true; }
        key(EntryOrder; "IC Entry No.", "Tree Order") { }
        key(EntryParentSequence; "IC Entry No.", "Parent Record ID", "Sequence No.") { }
    }

    trigger OnModify()
    var
        UserSetup: Record "User Setup";
        StagingMgt: Codeunit "EOS IC Staging Mgt.";
    begin
        UserSetup.Get(UserId());
        UserSetup.TestField("EOS IC Admin");
        StagingMgt.UpdateManualValueStates(Rec, xRec);
        Rec."Manually Modified" := true;
        Rec."Manually Modified At" := CurrentDateTime();
        Rec."Manually Modified By" := CopyStr(UserId(), 1, MaxStrLen(Rec."Manually Modified By"));
    end;
}