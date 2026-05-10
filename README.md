# 📱 Productivity App

A full-stack mobile productivity app built with **Flutter**, **Node.js/Express**, and **PostgreSQL**. Users can register, log in, select a personal goal, and receive daily summaries at a time they choose.

---

## 🏗️ Project Structure

```
my-app/
├── backend/          # Node.js + Express REST API
└── flutter_app/      # Flutter mobile app
```

---

## ✨ Features

- ✅ User registration & login with JWT authentication
- ✅ Password hashing with bcrypt
- ✅ Forgot password with 6-digit email code (via Resend)
- ✅ Goal selection (Focus, Consumption, Activity, Social, Explore)
- ✅ Daily summary time picker (24-hour / military time)
- ✅ Show/hide password toggle
- ✅ Data persisted in PostgreSQL

---

## 🗂️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| Backend API | Node.js + Express |
| Database | PostgreSQL |
| Authentication | JWT (jsonwebtoken) |
| Password Security | bcryptjs |
| Email | Resend |

---

## ⚙️ Backend Setup

### Prerequisites
- Node.js v18+
- PostgreSQL 15+

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Create the `.env` file

Create a file called `.env` in the `backend/` folder:

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=productivity_app
DB_USER=postgres
DB_PASSWORD=your_postgres_password
JWT_SECRET=your_super_secret_key
JWT_EXPIRES_IN=7d
RESEND_API_KEY=re_your_resend_api_key
FROM_EMAIL=onboarding@resend.dev
```

> ⚠️ Never commit your `.env` file to Git. It is already in `.gitignore`.

### 3. Set up the database

Open **pgAdmin** or **psql** and run:

```sql
-- Create the database
CREATE DATABASE productivity_app;

-- Connect to it, then run:

CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    email       VARCHAR(255)  UNIQUE NOT NULL,
    password    VARCHAR(255)  NOT NULL,
    created_at  TIMESTAMP     DEFAULT NOW(),
    updated_at  TIMESTAMP     DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);

CREATE TABLE user_goals (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER NOT NULL REFERENCES users(id),
    goal          VARCHAR(50) NOT NULL,
    summary_time  VARCHAR(5)  NOT NULL,
    created_at    TIMESTAMP DEFAULT NOW(),
    updated_at    TIMESTAMP DEFAULT NOW()
);

CREATE TABLE password_reset_codes (
    id         SERIAL PRIMARY KEY,
    email      VARCHAR(255) NOT NULL,
    code       VARCHAR(6)   NOT NULL,
    expires_at TIMESTAMP    NOT NULL,
    used       BOOLEAN      DEFAULT FALSE,
    created_at TIMESTAMP    DEFAULT NOW()
);
```

### 4. Start the server

```bash
npm run dev
```

You should see:
```
🚀 Server running on http://localhost:3000
✅ PostgreSQL connected
```

---

## 📡 API Endpoints

### Auth

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register` | Register a new user |
| POST | `/api/auth/login` | Login and get token |
| POST | `/api/auth/forgot-password` | Send 6-digit reset code |
| POST | `/api/auth/reset-password` | Verify code and set new password |

### Goals (requires Authorization header)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/goals` | Save or update user goal |
| GET | `/api/goals` | Get current user goal |

All protected routes require:
```
Authorization: Bearer <your_jwt_token>
```

---

## 📱 Flutter App Setup

### Prerequisites
- Flutter SDK 3.x
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device

### 1. Install dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Configure the server URL

Open `lib/config/api_config.dart` and set the correct URL:

```dart
class ApiConfig {
  // Android emulator:
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Physical Android phone (use your computer's local IP):
  // static const String baseUrl = 'http://192.168.1.x:3000/api';

  // Production:
  // static const String baseUrl = 'https://your-production-api.com/api';
}
```

> To find your local IP on Windows: run `ipconfig` and look for **IPv4 Address** under Wi-Fi.

### 3. Run the app

```bash
flutter run
```

---

## 🚀 Going to Production

### Backend
Deploy to **Railway**, **Render**, or any VPS. Point the `.env` to a cloud PostgreSQL (Supabase, Neon, or Railway Postgres).

### Flutter
Change the one line in `api_config.dart` to your production URL, then build:

```bash
flutter build apk          # Android
flutter build ios          # iOS
```

---

## 🔒 Security Notes

- Passwords are **never stored in plain text** — bcrypt hashes them before saving
- JWT tokens expire after **7 days**
- Password reset codes expire after **15 minutes** and can only be used once
- The `.env` file is gitignored — never share it

---

## 📦 Dependencies

### Backend
```json
{
  "express": "^4.18.2",
  "pg": "^8.11.0",
  "bcryptjs": "^2.4.3",
  "jsonwebtoken": "^9.0.0",
  "cors": "^2.8.5",
  "dotenv": "^16.0.3",
  "resend": "latest"
}
```

### Flutter
```yaml
http: ^1.2.0
shared_preferences: ^2.2.2
provider: ^6.1.1
```

---

## 👤 Author

Rita — [@lorinczdorakinga](https://github.com/lorinczdorakinga)
