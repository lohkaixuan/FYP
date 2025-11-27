using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ApiApp.Migrations
{
    /// <inheritdoc />
    public partial class SyncProviderOwnerSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_merchants_users_owner_user_id",
                table: "merchants");

            migrationBuilder.CreateIndex(
                name: "IX_providers_owner_user_id",
                table: "providers",
                column: "owner_user_id");

            migrationBuilder.AddForeignKey(
                name: "FK_merchants_users_owner_user_id",
                table: "merchants",
                column: "owner_user_id",
                principalTable: "users",
                principalColumn: "user_id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_providers_users_owner_user_id",
                table: "providers",
                column: "owner_user_id",
                principalTable: "users",
                principalColumn: "user_id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_merchants_users_owner_user_id",
                table: "merchants");

            migrationBuilder.DropForeignKey(
                name: "FK_providers_users_owner_user_id",
                table: "providers");

            migrationBuilder.DropIndex(
                name: "IX_providers_owner_user_id",
                table: "providers");

            migrationBuilder.AddForeignKey(
                name: "FK_merchants_users_owner_user_id",
                table: "merchants",
                column: "owner_user_id",
                principalTable: "users",
                principalColumn: "user_id");
        }
    }
}
