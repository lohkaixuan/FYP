// ==================================================
// Program Name   : 20251217011318_FixBankLinkExternalRawJsonType.cs
// Purpose        : EF Core migration to fix BankLink external raw JSON type
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using System.Text.Json;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ApiApp.Migrations
{
    /// <inheritdoc />
    public partial class FixBankLinkExternalRawJsonType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<JsonDocument>(
                name: "external_raw_json",
                table: "bank_links",
                type: "jsonb",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "external_raw_json",
                table: "bank_links",
                type: "text",
                nullable: true,
                oldClrType: typeof(JsonDocument),
                oldType: "jsonb",
                oldNullable: true);
        }
    }
}



