// ==================================================
// Program Name   : 20251202111621_AddMerchantDocBytes.cs
// Purpose        : EF Core migration adding merchant document byte storage
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ApiApp.Migrations
{
    /// <inheritdoc />
    public partial class AddMerchantDocBytes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<byte[]>(
                name: "merchant_doc_bytes",
                table: "merchants",
                type: "bytea",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "merchant_doc_content_type",
                table: "merchants",
                type: "character varying(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "merchant_doc_size",
                table: "merchants",
                type: "bigint",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "merchant_doc_bytes",
                table: "merchants");

            migrationBuilder.DropColumn(
                name: "merchant_doc_content_type",
                table: "merchants");

            migrationBuilder.DropColumn(
                name: "merchant_doc_size",
                table: "merchants");
        }
    }
}



