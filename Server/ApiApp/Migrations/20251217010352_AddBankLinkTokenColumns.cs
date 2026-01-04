// ==================================================
// Program Name   : 20251217010352_AddBankLinkTokenColumns.cs
// Purpose        : EF Core migration adding bank link token columns
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
    public partial class AddBankLinkTokenColumns : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ===== make existing columns wider / safer =====
            migrationBuilder.AlterColumn<string>(
                name: "external_account_ref",
                table: "bank_links",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(120)",
                oldMaxLength: 120);

            migrationBuilder.AlterColumn<string>(
                name: "display_name",
                table: "bank_links",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(120)",
                oldMaxLength: 120,
                oldNullable: true);

            // ===== SAFE ADD COLUMNS (won't crash if already exists) =====
            migrationBuilder.Sql(@"
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'bank_links'
          AND column_name = 'external_access_token_enc'
    ) THEN
        ALTER TABLE public.bank_links
        ADD COLUMN external_access_token_enc text;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'bank_links'
          AND column_name = 'external_raw_json'
    ) THEN
        ALTER TABLE public.bank_links
        ADD COLUMN external_raw_json text;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'bank_links'
          AND column_name = 'external_token_expires_at'
    ) THEN
        ALTER TABLE public.bank_links
        ADD COLUMN external_token_expires_at timestamptz;
    END IF;
END $$;
");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // rollback (only if you ever downgrade)
            migrationBuilder.DropColumn(
                name: "external_access_token_enc",
                table: "bank_links");

            migrationBuilder.DropColumn(
                name: "external_raw_json",
                table: "bank_links");

            migrationBuilder.DropColumn(
                name: "external_token_expires_at",
                table: "bank_links");

            migrationBuilder.AlterColumn<string>(
                name: "external_account_ref",
                table: "bank_links",
                type: "character varying(120)",
                maxLength: 120,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "display_name",
                table: "bank_links",
                type: "character varying(120)",
                maxLength: 120,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");
        }
    }
}



