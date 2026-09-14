# 🚀 BLUSH GAMING PLATFORM - SKELETON BOILERPLATE (EXE201)

Đây là khung sườn dự án (Boilerplate Repository) chuẩn cho dự án **BLUSH**. 
Repository được chia sẵn 3 phần riêng biệt vô cùng dễ quản lý và phân công công việc:

1. **`backend/`** (ASP.NET Core 8 Web API - C#)
2. **`frontend/`** (React 19 + Vite - JavaScript)
3. **`database/`** (SQL Server Scripts & Documentation)

---

## 📂 SƠ ĐỒ CẤU TRÚC THƯ MỤC REPOSITORY

```text
BLUSH-Gaming-Platform/
│
├── 📁 backend/                        <-- CỐT LÕI BACKEND (.NET 8 WEB API)
│   ├── 📁 Controllers/                <-- Tầng 1: API Controllers (UserController, QuestController...)
│   ├── 📁 Services/                   <-- Tầng 2: Business Logic Services (Interfaces & Implementations)
│   ├── 📁 DataAccess/                 <-- Tầng 3: EF Core DbContext & Entities (SQL Server)
│   ├── 📄 Program.cs                  <-- Cấu hình Dependency Injection & Swagger UI
│   ├── 📄 appsettings.json            <-- Chuỗi kết nối Database & Secret keys
│   └── 📄 Blush.Api.csproj
│
├── 📁 frontend/                       <-- CỐT LÕI FRONTEND (REACT 19 + VITE)
│   ├── 📁 src/
│   │   ├── 📁 components/             <-- Tầng 1: UI Components (User / Staff / Admin)
│   │   ├── 📁 services/               <-- Tầng 2: Business Logic (paymentService, questService)
│   │   └── 📁 api/                    <-- Tầng 3: Data Access Client (apiClient.js gọi Backend)
│   ├── 📄 package.json
│   └── 📄 vite.config.js
│
└── 📁 database/                       <-- CƠ SỞ DỮ LIỆU SQL SERVER
    ├── 📄 script_database.sql         <-- Script T-SQL khởi tạo BlushDb (6 Modules + Seed Data)
    └── 📄 README.md                   <-- Hướng dẫn chạy script trên SSMS
```

---

## 🛠️ HƯỚNG DẪN CHẠY VÀ PHÂN CÔNG CÔNG VIỆC

### 1. Dành cho Backend Developer (Thư mục `backend/` & `database/`):
1. Mở file `database/script_database.sql` chạy trên **SQL Server (SSMS)** để tạo CSDL `BlushDb`.
2. Mở thư mục `backend/` bằng Visual Studio 2022 hoặc VS Code.
3. Chạy lệnh `dotnet run` hoặc bấm **F5**. Trang Swagger API sẽ tự động mở tại `https://localhost:7001/swagger`.

### 2. Dành cho Frontend Developer (Thư mục `frontend/`):
1. Mở thư mục `frontend/` bằng VS Code.
2. Chạy `npm install` để cài thư viện.
3. Chạy `npm run dev` để chạy giao diện React tại `http://localhost:5173`.
