// ==================================================
// Program Name   : BaseAccount.cs
// Purpose        : Base account abstraction for banking accounts
// Developer      : Mr. Loh Kai Xuan 
// Student ID     : TP074510 
// Course         : Bachelor of Software Engineering (Hons) 
// Created Date   : 15 November 2025
// Last Modified  : 4 January 2026 
// ==================================================
public interface IAccount
{
    string AccountId { get; }
    decimal Balance { get; set; }
}