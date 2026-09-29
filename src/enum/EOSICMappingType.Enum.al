namespace EOS.Solutions.Intercompany;

enum 67004 "EOS IC Mapping Type"
{
    Extensible = true;

    value(0; Value)
    {
        Caption = 'Value';
    }
    value(1; Constant)
    {
        Caption = 'Constant';
    }
    value(2; Transformation)
    {
        Caption = 'Transformation';
    }
}
