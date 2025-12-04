using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ApiApp.Migrations
{
    /// <inheritdoc />
    public partial class AllowMultipleMerchantsPerOwner : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_merchants_owner_user_id",
                table: "merchants");

            migrationBuilder.AddColumn<Guid>(
                name: "MerchantId",
                table: "users",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_MerchantId",
                table: "users",
                column: "MerchantId");

            migrationBuilder.CreateIndex(
                name: "IX_merchants_owner_user_id",
                table: "merchants",
                column: "owner_user_id",
                unique: true,
                filter: "\"is_deleted\" = false");

            migrationBuilder.AddForeignKey(
                name: "FK_users_merchants_MerchantId",
                table: "users",
                column: "MerchantId",
                principalTable: "merchants",
                principalColumn: "merchant_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_users_merchants_MerchantId",
                table: "users");

            migrationBuilder.DropIndex(
                name: "IX_users_MerchantId",
                table: "users");

            migrationBuilder.DropIndex(
                name: "IX_merchants_owner_user_id",
                table: "merchants");

            migrationBuilder.DropColumn(
                name: "MerchantId",
                table: "users");

            migrationBuilder.CreateIndex(
                name: "IX_merchants_owner_user_id",
                table: "merchants",
                column: "owner_user_id",
                unique: true);
        }
    }
}
