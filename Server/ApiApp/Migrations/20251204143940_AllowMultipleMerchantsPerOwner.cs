// ==================================================
// Program Name   : 20251204143940_AllowMultipleMerchantsPerOwner.cs
// Purpose        : EF Core migration to allow multiple merchants per owner
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



