# 🚀 BLUSH GAMING PLATFORM - SKELETON BOILERPLATE (EXE201)

Đây là khung sườn dự án (Boilerplate Repository) chuẩn cho dự án **BLUSH**. 
Repository được chia sẵn 3 phần riêng biệt vô cùng dễ quản lý và phân công công việc:

1. **`backend/`** (ASP.NET Core 8 Web API - C#)
2. **`frontend/`** (Flutter Mobile App - Dart)
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
├── 📁 frontend/                       <-- FRONTEND MOBILE APP (FLUTTER / DART)
│   ├── 📁 lib/                        <-- Code Flutter Widgets, Screens, Models, API Services
│   │   ├── 📄 main.dart
│   │   ├── 📁 api/                    <-- Kết nối RESTful API với Backend .NET
│   │   ├── 📁 models/                 <-- Model dữ liệu (User, Quest, Lobby, Message)
│   │   └── 📁 screens/                <-- Màn hình App (Auth, Home, Matching, Chat, Profile, VIP)
│   ├── 📄 pubspec.yaml
│   └── 📄 README.md
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

### 2. Dành cho Frontend Mobile Developer (Thư mục `frontend/` - Flutter):
1. Mở thư mục `frontend/` bằng VS Code / Android Studio có cài Flutter SDK.
2. Chạy `flutter pub get` để cài các gói thư viện (`http`, `provider`, `shared_preferences`...).
3. Chạy `flutter run` để chạy App Flutter trên điện thoại thật hoặc Emulator Android/iOS.
