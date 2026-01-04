// ==================================================
// Program Name   : 20251023060917_Init_Clean_NoPgEnum.cs
// Purpose        : Initial EF Core migration without PostgreSQL enums
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ApiApp.Migrations
{
    /// <inheritdoc />
    public partial class Init_Clean_NoPgEnum : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "budgets",
                columns: table => new
                {
                    budget_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    limit_amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    cycle_start = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    cycle_end = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_budgets", x => x.budget_id);
                });

            migrationBuilder.CreateTable(
                name: "providers",
                columns: table => new
                {
                    provider_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    base_url = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    enabled = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_providers", x => x.provider_id);
                });

            migrationBuilder.CreateTable(
                name: "roles",
                columns: table => new
                {
                    role_id = table.Column<Guid>(type: "uuid", nullable: false),
                    role_name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_roles", x => x.role_id);
                });

            migrationBuilder.CreateTable(
                name: "transactions",
                columns: table => new
                {
                    transaction_id = table.Column<Guid>(type: "uuid", nullable: false),
                    transaction_type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    transaction_from = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    transaction_to = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    from_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    to_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    from_merchant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    to_merchant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    from_bank_id = table.Column<Guid>(type: "uuid", nullable: true),
                    to_bank_id = table.Column<Guid>(type: "uuid", nullable: true),
                    from_wallet_id = table.Column<Guid>(type: "uuid", nullable: true),
                    to_wallet_id = table.Column<Guid>(type: "uuid", nullable: true),
                    transaction_amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    transaction_timestamp = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    transaction_item = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                    transaction_detail = table.Column<string>(type: "character varying(400)", maxLength: 400, nullable: true),
                    category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    payment_method = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: true),
                    transaction_status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    predicted_category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    predicted_confidence = table.Column<double>(type: "double precision", nullable: true),
                    final_category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    ml_text = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_transactions", x => x.transaction_id);
                });

            migrationBuilder.CreateTable(
                name: "bank_links",
                columns: table => new
                {
                    link_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    merchant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    provider_id = table.Column<Guid>(type: "uuid", nullable: false),
                    external_account_ref = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    display_name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_bank_links", x => x.link_id);
                    table.ForeignKey(
                        name: "FK_bank_links_providers_provider_id",
                        column: x => x.provider_id,
                        principalTable: "providers",
                        principalColumn: "provider_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "provider_credentials",
                columns: table => new
                {
                    cred_id = table.Column<Guid>(type: "uuid", nullable: false),
                    provider_id = table.Column<Guid>(type: "uuid", nullable: false),
                    type = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    value_plain = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_provider_credentials", x => x.cred_id);
                    table.ForeignKey(
                        name: "FK_provider_credentials_providers_provider_id",
                        column: x => x.provider_id,
                        principalTable: "providers",
                        principalColumn: "provider_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    user_age = table.Column<int>(type: "integer", nullable: true),
                    user_role = table.Column<Guid>(type: "uuid", nullable: false),
                    user_password = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    user_phone_number = table.Column<string>(type: "character varying(25)", maxLength: 25, nullable: true),
                    user_email = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    user_ic_number = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    user_passcode = table.Column<string>(type: "character varying(6)", maxLength: 6, nullable: true),
                    user_balance = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    jwt_token = table.Column<string>(type: "character varying(1024)", maxLength: 1024, nullable: true),
                    last_login = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.user_id);
                    table.ForeignKey(
                        name: "FK_users_roles_user_role",
                        column: x => x.user_role,
                        principalTable: "roles",
                        principalColumn: "role_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "merchants",
                columns: table => new
                {
                    merchant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    merchant_name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    merchant_phone_number = table.Column<string>(type: "character varying(25)", maxLength: 25, nullable: true),
                    merchant_doc = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: true),
                    owner_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_merchants", x => x.merchant_id);
                    table.ForeignKey(
                        name: "FK_merchants_users_owner_user_id",
                        column: x => x.owner_user_id,
                        principalTable: "users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "bank_accounts",
                columns: table => new
                {
                    bank_account_id = table.Column<Guid>(type: "uuid", nullable: false),
                    bank_account_number = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    bank_username = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    bank_userpassword = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                    bank_user_balance = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    bank_type = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    bank_account_category = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    merchant_id = table.Column<Guid>(type: "uuid", nullable: true),
                    bank_link_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_bank_accounts", x => x.bank_account_id);
                    table.ForeignKey(
                        name: "FK_bank_accounts_bank_links_bank_link_id",
                        column: x => x.bank_link_id,
                        principalTable: "bank_links",
                        principalColumn: "link_id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_bank_accounts_merchants_merchant_id",
                        column: x => x.merchant_id,
                        principalTable: "merchants",
                        principalColumn: "merchant_id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_bank_accounts_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "wallets",
                columns: table => new
                {
                    wallet_id = table.Column<Guid>(type: "uuid", nullable: false),
                    wallet_number = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    wallet_balance = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    merchant_id = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_wallets", x => x.wallet_id);
                    table.ForeignKey(
                        name: "FK_wallets_merchants_merchant_id",
                        column: x => x.merchant_id,
                        principalTable: "merchants",
                        principalColumn: "merchant_id");
                    table.ForeignKey(
                        name: "FK_wallets_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_bank_accounts_bank_account_number",
                table: "bank_accounts",
                column: "bank_account_number",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_bank_accounts_bank_link_id",
                table: "bank_accounts",
                column: "bank_link_id");

            migrationBuilder.CreateIndex(
                name: "IX_bank_accounts_merchant_id",
                table: "bank_accounts",
                column: "merchant_id");

            migrationBuilder.CreateIndex(
                name: "IX_bank_accounts_user_id",
                table: "bank_accounts",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_bank_links_provider_id",
                table: "bank_links",
                column: "provider_id");

            migrationBuilder.CreateIndex(
                name: "IX_bank_links_user_id_provider_id_external_account_ref",
                table: "bank_links",
                columns: new[] { "user_id", "provider_id", "external_account_ref" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_budgets_user_id_category_cycle_start_cycle_end",
                table: "budgets",
                columns: new[] { "user_id", "category", "cycle_start", "cycle_end" });

            migrationBuilder.CreateIndex(
                name: "IX_merchants_owner_user_id",
                table: "merchants",
                column: "owner_user_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_provider_credentials_provider_id_type",
                table: "provider_credentials",
                columns: new[] { "provider_id", "type" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_transactions_payment_method",
                table: "transactions",
                column: "payment_method");

            migrationBuilder.CreateIndex(
                name: "IX_transactions_transaction_status",
                table: "transactions",
                column: "transaction_status");

            migrationBuilder.CreateIndex(
                name: "IX_transactions_transaction_timestamp",
                table: "transactions",
                column: "transaction_timestamp");

            migrationBuilder.CreateIndex(
                name: "IX_users_user_email",
                table: "users",
                column: "user_email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_user_ic_number",
                table: "users",
                column: "user_ic_number",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_user_phone_number",
                table: "users",
                column: "user_phone_number",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_user_role",
                table: "users",
                column: "user_role");

            migrationBuilder.CreateIndex(
                name: "IX_wallets_merchant_id",
                table: "wallets",
                column: "merchant_id");

            migrationBuilder.CreateIndex(
                name: "IX_wallets_user_id",
                table: "wallets",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_wallets_wallet_number",
                table: "wallets",
                column: "wallet_number",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "bank_accounts");

            migrationBuilder.DropTable(
                name: "budgets");

            migrationBuilder.DropTable(
                name: "provider_credentials");

            migrationBuilder.DropTable(
                name: "transactions");

            migrationBuilder.DropTable(
                name: "wallets");

            migrationBuilder.DropTable(
                name: "bank_links");

            migrationBuilder.DropTable(
                name: "merchants");

            migrationBuilder.DropTable(
                name: "providers");

            migrationBuilder.DropTable(
                name: "users");

            migrationBuilder.DropTable(
                name: "roles");
        }
    }
}
