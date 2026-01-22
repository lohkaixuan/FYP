# 📱 Multi-Modal Digital Wallet Application with Multi-Bank Integration

多模式多银行整合数码钱包系统

---

## 📌 Project Overview | 项目简介

**English 🇬🇧**
This Final Year Project (FYP) focuses on the design and development of a **Multi-Modal Digital Wallet Application with Multi-Bank Integration**.
The system unifies multiple payment technologies—**QR payment, NFC tap-to-pay, and interbank transfers**—into a single mobile application, while enabling **multi-bank account linking**, **real-time consolidated balances**, and **integrated personal financial management**.

Unlike many existing digital wallets that rely on stored-value models or isolated databases, this system adopts a **direct bank-linked architecture** using a centralized backend and a **PostgreSQL (Neon) relational database**, ensuring data consistency, scalability, and transactional integrity.

**中文 🇨🇳**
本最终年项目（FYP）旨在设计与开发一个 **多模式、多银行整合的数码钱包应用系统**。
系统将 **QR 支付、NFC 轻触支付及银行转账** 整合至单一移动平台，并支持 **多银行账户连接、实时余额整合与个人财务管理功能**。

本系统不采用储值型钱包或 Firebase NoSQL 架构，而是使用 **Neon PostgreSQL 关系型数据库** 作为核心数据层，通过后端统一管理银行数据，以确保 **数据一致性、可扩展性与交易可靠性**。

---

## 🎯 Project Objectives | 项目目标

* **English**

  * Integrate multiple bank accounts into one digital wallet
  * Support multi-modal payments (QR, NFC, interbank transfer)
  * Provide real-time consolidated financial data
  * Enable budgeting, spending categorization, and monthly reports
  * Ensure secure authentication and controlled data access

* **中文**

  * 将多家银行账户整合至单一数码钱包
  * 支持多种支付方式（QR、NFC、银行转账）
  * 提供实时的统一财务视图
  * 提供预算管理、消费分类与月度总结
  * 确保系统安全与数据访问控制

---

## 🛠️ Technology Stack | 技术栈

| Layer            | Technology                                    |
| ---------------- | --------------------------------------------- |
| Mobile Frontend  | Flutter (Dart)                                |
| Backend API      | Node.js + Express.js                          |
| Database         | **Neon PostgreSQL (Cloud-hosted PostgreSQL)** |
| ORM / Query      | SQL / Parameterized Queries                   |
| Authentication   | JWT (JSON Web Token)                          |
| Bank Integration | Simulated Open Banking API                    |
| Deployment       | Docker / Cloud VM                             |
| Tools            | VS Code, Postman, GitHub                      |

**中文说明 🐟**
系统采用 **Neon PostgreSQL（云端 PostgreSQL）** 作为主数据库，负责存储用户、银行账户、交易记录、预算与报表数据。
相比 Firebase，PostgreSQL 提供更强的 **关系约束、事务一致性（ACID）及复杂查询能力**，更适合金融系统。

---

## 🔐 Key Features | 核心功能

### 👤 User Features | 用户功能

* Multi-bank account linking
* Unified wallet dashboard (all banks)
* QR code payment & NFC tap-to-pay
* Real-time transaction history
* Automatic expense categorization
* Budget tracking & monthly financial summaries

### 🏦 System Features | 系统功能

* Centralized backend with PostgreSQL database
* Secure RESTful API communication
* Transaction-safe data handling (ACID-compliant)
* Scalable architecture for future bank integration

---

## 🗄️ Database Design | 数据库设计（PostgreSQL）

* Users
* BankAccounts
* Transactions
* Wallets
* Budgets
* MonthlyReports

**English**
A relational database schema is used to ensure strong data consistency between users, banks, and transactions. PostgreSQL transactions guarantee reliable financial record management.

**中文**
系统采用关系型数据库结构，确保用户、银行账户与交易数据之间的强一致性，并通过 PostgreSQL 事务机制保证金融数据的可靠性。

---

## 🧪 Development Methodology | 开发方法

**English**
The project follows the **Kanban Agile Methodology**, suitable for solo development and continuous delivery. Tasks progress through *To Do → In Progress → Done* with Work-In-Progress (WIP) limits.

**中文**
本项目采用 **Kanban 敏捷开发方法**，适合个人开发与持续交付，通过任务可视化与 WIP 控制提升开发效率。

---

## 📊 Research & Validation | 用户研究

* Online survey with **38 respondents**
* Key findings:

  * High usage of multiple payment apps
  * Strong demand for multi-bank integration
  * Need for budgeting & spending insights
  * Preference for real-time financial visibility

---

## 🌱 Sustainable Development Goal | 可持续发展目标

This project aligns with **UN SDG 9 – Industry, Innovation & Infrastructure** by promoting:

* Interoperable financial systems
* Secure digital payment infrastructure
* Financial inclusion through technology

---

## 🚀 Future Enhancements | 未来拓展

* Real open-banking API integration
* AI-based expense prediction & analytics
* Advanced fraud detection mechanisms
* iOS platform support
* Cross-border and multi-currency payments

---

## 👨‍🎓 Author | 作者信息

**Name:** Loh Kai Xuan
**TP Number:** TP074510
**Programme:** Bachelor of Science (Hons) Software Engineering
**University:** Asia Pacific University of Technology & Innovation (APU)

---

## 📄 Disclaimer | 声明

**English**
This project is developed for **academic purposes only**.
All banking integrations are simulated, and no real financial transactions are processed.

**中文**
本系统仅用于学术研究用途，所有银行接口均为模拟环境，不涉及真实金融交易。
