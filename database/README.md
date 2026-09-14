# 💾 BLUSH DATABASE MODULE (SQL SERVER)

Thư mục này chứa toàn bộ Scripts khởi tạo CSDL và tài liệu cấu trúc dữ liệu cho dự án **BLUSH AI Gaming Platform**.

---

## 📂 Danh mục File:

- 📄 **`script_database.sql`**: Script T-SQL khởi tạo Database `BlushDb` đầy đủ 6 Modules (Roles, VipPackages, Users, Games, Zones, UserGameProfiles, IceBreakerQuestions, ChatRooms, Messages, Quests, UserQuests, AiLogs, Reports, Transactions) kèm dữ liệu mẫu khởi tạo (Seed Data).

---

## 🛠️ Hướng dẫn Khởi tạo CSDL (SQL Server):

1. Mở phần mềm **SQL Server Management Studio (SSMS)** hoặc **Azure Data Studio**.
2. Kết nối tới SQL Server Database Engine của bạn.
3. Mở file `script_database.sql` (hoặc copy toàn bộ nội dung dán vào cửa sổ New Query).
4. Nhấn **Execute (F5)** để chạy script.
5. CSDL `BlushDb` sẽ được khởi tạo kèm các tài khoản mẫu:
   - ⚙️ **Super Admin:** `admin@blush.vn` | Mật khẩu: `123456`
   - 🛡️ **Staff:** `staff@blush.vn` | Mật khẩu: `123456`
   - 🎮 **Gamer:** `gamer@blush.vn` | Mật khẩu: `123456`
