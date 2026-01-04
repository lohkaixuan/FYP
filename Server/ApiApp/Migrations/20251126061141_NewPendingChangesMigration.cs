// ==================================================
// Program Name   : 20251126061141_NewPendingChangesMigration.cs
// Purpose        : EF Core migration for pending changes
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
    public partial class NewPendingChangesMigration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "is_deleted",
                table: "users",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "is_deleted",
                table: "users");
        }
    }
}
