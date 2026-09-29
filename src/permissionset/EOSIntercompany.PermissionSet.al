namespace EOS.Solutions.Intercompany;
permissionset 67000 "EOS Intercompany"
{
    Assignable = true;
    Permissions =
        page "EOS IC Flows API" = X,
        page "EOS IC Remote Flows Lookup" = X,
        table "EOS IC Setup" = X,
        table "EOS IC Connections" = X,
        table "EOS IC Companies" = X,
        table "EOS IC Flows" = X,
        table "EOS IC Mapping Headers" = X,
        table "EOS IC Mapping Lines" = X,
        tabledata "EOS IC Setup" = RIMD,
        tabledata "EOS IC Connections" = RIMD,
        tabledata "EOS IC Companies" = RIMD,
        tabledata "EOS IC Flows" = RIMD,
        tabledata "EOS IC Mapping Headers" = RIMD,
        tabledata "EOS IC Mapping Lines" = RIMD;
}