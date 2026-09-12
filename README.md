# 🚀 BLUSH GAMING PLATFORM - SKELETON BOILERPLATE (EXE201)

Đây là khung sườn dự án (Boilerplate Repository) chuẩn 3-Layer cho dự án **BLUSH**. 
Repository được chia sẵn 2 phần riêng biệt: **`frontend/` (React + Vite)** và **`backend/` (ASP.NET Core Web API .NET 8)**.

---

## 🛠️ CẤU TRÚC REPOSITORY (FOLDER STRUCTURE)

```text
BLUSH-PROJECT/
├── 📄 .gitignore                <-- Cấu hình bỏ qua file build & node_modules
├── 📄 README.md                 <-- Hướng dẫn nhóm & quy trình Git
│
├── 📱 frontend/                 (DỰ ÁN FRONTEND REACT + VITE)
│   ├── package.json
│   ├── vite.config.js
│   └── src/
│       ├── api/                 (Data Access Layer: Cấu hình Axios API Client)
│       ├── services/            (Business Logic Layer: Các dịch vụ gọi Backend API)
│       └── components/          (Presentation Layer: Giao diện UI phân chia theo role)
│           ├── user/            (Module Game thủ: Home, Auth, Matchmaking, Chat, Quests)
│           ├── staff/           (Module Kiểm duyệt viên: Reports, IceBreakers)
│           └── admin/           (Module Quản trị viên: Analytics, CostStructure)
│
└── 🌐 backend/                  (DỰ ÁN BACKEND ASP.NET CORE WEB API 3-LAYER)
    ├── Blush.Api.csproj
    ├── Program.cs               (Cấu hình CORS, Swagger, Dependency Injection)
    ├── Controllers/             (Layer 1: Controllers nhận HTTP Request từ React)
    ├── Services/                (Layer 2: Services xử lý Logic C#)
    │   ├── Interfaces/          (Định nghĩa Interface service)
    │   └── Implementations/     (Cài đặt Service logic)
    └── DataAccess/              (Layer 3: EF Core DbContext & SQL Server Entities)
```

---

## 👥 HƯỚNG DẪN PHÂN CÔNG CÔNG VIỆC TRONG NHÓM

| Thành viên | Trách nhiệm | Thư mục phụ trách chính |
| :--- | :--- | :--- |
| **Frontend Dev 1** | Làm giao diện User (Home, Ghép đội, Chat, Quests) | `frontend/src/components/user/` |
| **Frontend Dev 2** | Làm giao diện Admin, Staff & Nâng cấp VIP | `frontend/src/components/admin/` & `staff/` |
| **Backend Dev 1** | Viết API Xác thực, Ghép đội & AI Starter | `backend/Controllers/` & `backend/Services/` |
| **Backend Dev 2** | Viết API Quest, Nạp tiền VietQR PayOS & CSDL | `backend/DataAccess/` & `backend/Services/` |

---

## 💻 HƯỚNG DẪN CHẠY DỰ ÁN DƯỚI LOCAL (LOCAL DEVELOPMENT)

### 1. Khởi chạy Frontend (React + Vite):
```bash
# Bước 1: Di chuyển vào thư mục frontend
cd frontend

# Bước 2: Cài đặt các thư viện phụ thuộc
npm install

# Bước 3: Chạy сервер dev
npm run dev
# -> Mở trình duyệt truy cập: http://localhost:5173
```

### 2. Khởi chạy Backend (.NET Web API):
```bash
# Bước 1: Di chuyển vào thư mục backend
cd backend

# Bước 2: Restore packages & Chạy server API
dotnet run
# -> Mở trình duyệt xem API Swagger UI: https://localhost:7001/swagger
```

---

## 🌿 QUY TRÌNH LÀM VIỆC VỚI GIT (GIT WORKFLOW)

1. **Clone dự án về máy:**
   ```bash
   git clone <URL_GITHUB_REPOSITROYY>
   cd BLUSH-PROJECT
   ```

2. **Tạo nhánh (Branch) riêng trước khi làm tính năng được phân công:**
   ```bash
   # Ví dụ làm tính năng ghép đội Frontend:
   git checkout -b feature/frontend-matchmaking

   # Ví dụ làm API nạp tiền Backend:
   git checkout -b feature/backend-payos
   ```

3. **Commit và Push code lên GitHub:**
   ```bash
   git add .
   git commit -m "feat: Add PayOS checkout API endpoint"
   git push origin feature/backend-payos
   ```

4. **Tạo Pull Request (PR) trên GitHub** để Leader review code trước khi gộp (Merge) vào nhánh `main`.
