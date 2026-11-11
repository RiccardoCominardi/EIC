namespace EOS.Solutions.Intercompany;

enum 67004 "EOS IC Value Types"
{
    Extensible = true;

    value(0; Unchanged)
    {
        Caption = 'Unchanged';
    }
    value(1; Constant)
    {
        Caption = 'Constant';
    }
    value(2; Transformation)
    {
        Caption = 'Transformation';
    }
    value(3; "External Management")
    {
        Caption = 'External Management';
    }
}
