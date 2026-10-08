namespace EOS.Solutions.Intercompany;

// The legacy mapping tables stay in the permission set until their data has been migrated.
#pragma warning disable AL0432
permissionset 67000 "EOS IC Intercompany"
{
    Assignable = true;
    Permissions =
        page "EOS IC Flows API" = X,
        page "EOS IC Entries API" = X,
        page "EOS IC Entry Update API" = X,
        page "EOS IC Remote Flows Lookup" = X,
        table "EOS IC Setup" = X,
        table "EOS IC Connections" = X,
        table "EOS IC Companies" = X,
        table "EOS IC Flows" = X,
        table "EOS IC Mapping Headers" = X,
        table "EOS IC Mapping Lines" = X,
        table "EOS IC Mapping Json Node" = X,
        table "EOS IC Out. Mapping Lines" = X,
        table "EOS IC Table Relation Header" = X,
        table "EOS IC Table Relation Line" = X,
        table "EOS IC Entries" = X,
        tabledata "EOS IC Setup" = RIMD,
        tabledata "EOS IC Connections" = RIMD,
        tabledata "EOS IC Companies" = RIMD,
        tabledata "EOS IC Flows" = RIMD,
        tabledata "EOS IC Mapping Headers" = RIMD,
        tabledata "EOS IC Mapping Lines" = RIMD,
        tabledata "EOS IC Mapping Json Node" = RIMD,
        tabledata "EOS IC Out. Mapping Lines" = RIMD,
        tabledata "EOS IC Table Relation Header" = RIMD,
        tabledata "EOS IC Table Relation Line" = RIMD,
        tabledata "EOS IC Entries" = RIMD;
}