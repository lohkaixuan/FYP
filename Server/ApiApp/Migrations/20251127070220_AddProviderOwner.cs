using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ApiApp.Migrations
{
    /// <inheritdoc />
    public partial class AddProviderOwner : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "owner_user_id",
                table: "providers",
                type: "uuid",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "owner_user_id",
                table: "providers");
        }
    }
}
