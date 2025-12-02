using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ApiApp.Migrations
{
    /// <inheritdoc />
    public partial class AddPdfUrlToReport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // --- CONSOLIDATED FIX: Check if reports table exists, if not, create it. ---
            
            // 1. Create the reports table (Copied from 20251201060013_AddReportTable.cs)
            migrationBuilder.CreateTable(
                name: "reports",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    role = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    month = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    pdf_data = table.Column<byte[]>(type: "bytea", nullable: true),
                    content_type = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    chart_json = table.Column<string>(type: "text", nullable: true),
                    // Note: We are deliberately NOT adding pdf_url here yet.
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    last_update = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    is_deleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_reports", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_reports_role_month_created_by",
                table: "reports",
                columns: new[] { "role", "month", "created_by" },
                unique: true);

            // 2. Add the NEW column (pdf_url)
            migrationBuilder.AddColumn<string>(
                name: "pdf_url",
                table: "reports",
                type: "character varying(256)",
                maxLength: 256,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // For a clean rollback, drop the entire table
            migrationBuilder.DropTable(
                name: "reports");
        }
    }
}