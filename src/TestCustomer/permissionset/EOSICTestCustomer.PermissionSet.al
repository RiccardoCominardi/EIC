namespace EOS.Solutions.Intercompany;
permissionset 67001 "EOS IC Test Customer"
{
    Assignable = true;
    Permissions =
        table "EOS IC Stg. Sales Header" = X,
        table "EOS IC Stg. Sales Line" = X,
        table "EOS IC Stg. Purch. Header" = X,
        table "EOS IC Stg. Purch. Line" = X,
        table "EOS IC Stg. Shpt. Header" = X,
        table "EOS IC Stg. Shpt. Line" = X,
        table "EOS IC Stg. Rcpt. Header" = X,
        table "EOS IC Stg. Rcpt. Line" = X,
        table "EOS IC Stg. Item" = X,
        tabledata "EOS IC Stg. Sales Header" = RIMD,
        tabledata "EOS IC Stg. Sales Line" = RIMD,
        tabledata "EOS IC Stg. Purch. Header" = RIMD,
        tabledata "EOS IC Stg. Purch. Line" = RIMD,
        tabledata "EOS IC Stg. Shpt. Header" = RIMD,
        tabledata "EOS IC Stg. Shpt. Line" = RIMD,
        tabledata "EOS IC Stg. Rcpt. Header" = RIMD,
        tabledata "EOS IC Stg. Rcpt. Line" = RIMD,
        tabledata "EOS IC Stg. Item" = RIMD;
}