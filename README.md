# Bài kiểm tra đầu giờ — Đóng gói và chạy Campus Hub với Docker

> **Dự án:** Campus Hub Base  
> **Thời gian:** 45 phút | **Hình thức:** Cá nhân, thực hành trên máy  
> **Bài nộp:** Liên kết GitHub repository của sinh viên

---

## 👤 Thông tin sinh viên

- **Họ và tên:** Vũ Đức Huy Hoàng
- **Lớp / Nhóm:** HNCNTT-2
- **GitHub Repository:** https://github.com/Hoang2006-creater/  PTIT_CNTT2_IT209_VuDucHuyHoang_Session13_Kiemtra

---

## 🚀 Hướng dẫn chạy và kiểm tra hệ thống

### 1. Phần 1 — Kiểm thử và Đóng gói Backend thành Docker Image

#### Bước 1.1: Chạy kiểm thử backend bằng Gradle
```bash
# Di chuyển vào thư mục backend
cd backend

# Chạy test trên Linux / macOS:
./gradlew test

# Hoặc trên Windows PowerShell / CMD:
./gradlew.bat test
```

#### Bước 1.2: Build Docker Image cho backend
Dockerfile sử dụng **Multi-stage build** với **Eclipse Temurin JDK 21** và **JRE 21** tối ưu dung lượng, phân quyền non-root user và tự động xử lý ký tự xuống dòng Windows (CRLF).

```bash
# Cách 1: Build từ thư mục backend
cd backend
docker build -t campus-hub-backend .

# Cách 2: Hoặc build trực tiếp từ thư mục gốc dự án
docker build -t campus-hub-backend .
```

#### Bước 1.3: Kiểm tra Docker Image vừa tạo
```bash
docker images | grep campus-hub-backend
# Hoặc trên Windows PowerShell:
docker images
```

---

### 2. Phần 2 — Khởi chạy Backend và MySQL bằng Docker Compose

Hệ thống được cấu hình qua file `compose.yml` (và `docker-compose.yml`) gồm 2 services:
- **`mysql`**: MySQL 8.0, cấu hình database `campus_hub`, volume lưu trữ `mysql_data` và healthcheck tự động ping database.
- **`backend`**: Nhận biến môi trường `DB_URL` kết nối tới `jdbc:mysql://mysql:3306/campus_hub...` thông qua tên service `mysql`, có `depends_on` với điều kiện `service_healthy`.
- **`campus-network`**: Bridge network riêng biệt kết nối giữa 2 container.

#### Bước 2.1: Kiểm tra tính hợp lệ của file Compose
```bash
docker compose config
```

#### Bước 2.2: Khởi động hệ thống ở chế độ nền (Detached)
```bash
docker compose up -d
```

#### Bước 2.3: Kiểm tra trạng thái các container
```bash
docker compose ps
```
> Cả 2 service `campus-hub-mysql` (healthy) và `campus-hub-backend` (running) phải duy trì trạng thái hoạt động.

#### Bước 2.4: Kiểm tra kết nối và trạng thái ứng dụng qua Actuator Health
- **Cổng công khai backend:** `8080`
- **URL kiểm tra:** `http://localhost:8080/actuator/health`

Thực hiện kiểm tra bằng lệnh:
```bash
curl http://localhost:8080/actuator/health
```

**Kết quả mong đợi:**
```json
{"status":"UP","components":{"db":{"status":"UP","details":{"database":"MySQL","validationQuery":"isValid()"}},"diskSpace":{"status":"UP"},"ping":{"status":"UP"}}}
```

#### Bước 2.5: Dừng hệ thống khi kết thúc
```bash
docker compose down
# Hoặc nếu muốn xóa luôn volume database:
docker compose down -v
```

---

## 📸 Minh chứng kết quả thực hiện

### 1. Minh chứng 1: Docker Image đã build thành công
> Thể hiện kết quả lệnh `./gradlew test`, `docker build -t campus-hub-backend .` và danh sách `docker images`.

![Docker Image Build](screenshots/1_docker_images.png)

---

### 2. Minh chứng 2: Trạng thái các service sau khi chạy Compose
> Thể hiện kết quả chạy `docker compose up -d` và `docker compose ps` (các container đều running và healthy).

![Docker Compose Status](screenshots/2_docker_compose_ps.png)

---

### 3. Minh chứng 3: Kết quả gọi endpoint `/actuator/health`
> Thể hiện kết quả `curl http://localhost:8080/actuator/health` trả về HTTP 200 và trạng thái `"status":"UP"`.

![Actuator Health Check](screenshots/3_actuator_health.png)

---

# Tài liệu gốc dự án: Campus Hub Base

Campus Hub là dự án nền cho Mini Project Session 13. Ứng dụng cung cấp một không gian chung để sinh viên đăng sự kiện, tìm đồ thất lạc, hỏi đáp, trao đổi đồ dùng và tìm nhóm.

Dự án được giữ ở mức nhỏ để dễ đọc và sửa đổi, nhưng đã có đủ luồng giao diện, API, xác thực, migration và kiểm thử.

## Chức năng có sẵn

- Xem, tìm kiếm và lọc bài đăng.
- Đăng ký, đăng nhập bằng HTTP Basic.
- Tạo bài đăng theo chuyên mục.
- Bình luận và bày tỏ quan tâm.
- Chủ bài đăng có thể đánh dấu bài đã hoàn tất.
- Quản trị viên có quyền quản lý trạng thái bài đăng qua API.
- Health check tại `/actuator/health`.

Tài khoản mẫu được tạo khi ứng dụng khởi động lần đầu:

| Vai trò | Tên đăng nhập | Mật khẩu |
|---|---|---|
| Sinh viên | `student` | `student123` |
| Quản trị viên | `admin` | `admin123` |

Các tài khoản này chỉ dùng để trình diễn. Nhóm cần thay đổi hoặc loại bỏ trước khi sử dụng trong bối cảnh thực tế.

## Kiến trúc

```text
React frontend
    │ /api
    ▼
Spring Boot monolith
    │ JDBC
    ▼
MySQL
```

Backend gồm năm bảng chính: `users`, `categories`, `posts`, `comments` và `reactions`. Frontend không sử dụng thư viện giao diện hay thư viện quản lý trạng thái để sinh viên dễ đọc mã nguồn.

## Chạy khi phát triển

Tạo database MySQL tên `campus_hub`, sau đó đặt các biến môi trường nếu thông tin kết nối khác giá trị mặc định:

```powershell
$env:DB_URL = "jdbc:mysql://localhost:3306/campus_hub"
$env:DB_USERNAME = "root"
$env:DB_PASSWORD = "your-password"
```

Chạy backend:

```powershell
cd backend
./gradlew.bat bootRun
```

Mở terminal khác để chạy frontend:

```powershell
cd frontend
npm install
npm run dev
```

Frontend phát triển chạy tại `http://localhost:5173` và chuyển tiếp `/api` tới backend tại cổng `8080`.

## API chính

| Phương thức | Đường dẫn | Mục đích | Xác thực |
|---|---|---|---|
| `POST` | `/api/auth/register` | Tạo tài khoản | Không |
| `GET` | `/api/auth/me` | Lấy người dùng hiện tại | Có |
| `GET` | `/api/categories` | Danh sách chuyên mục | Không |
| `GET` | `/api/posts` | Tìm và lọc bài đăng | Không |
| `GET` | `/api/posts/{id}` | Chi tiết bài đăng | Không |
| `POST` | `/api/posts` | Tạo bài đăng | Có |
| `PUT` | `/api/posts/{id}` | Sửa bài của mình | Có |
| `PATCH` | `/api/posts/{id}/status` | Đổi trạng thái | Có |
| `DELETE` | `/api/posts/{id}` | Xóa bài của mình | Có |
| `POST` | `/api/posts/{id}/comments` | Thêm bình luận | Có |
| `POST` | `/api/posts/{id}/reaction` | Bật hoặc tắt quan tâm | Có |

Các API cần xác thực sử dụng header HTTP Basic. Trong môi trường công khai, hệ thống phải được đặt sau HTTPS.

## Kiểm tra trước khi bàn giao

```powershell
cd backend
./gradlew.bat test

cd ../frontend
npm ci
npm run lint
npm run build
```
