# 📱 AI Glasses App

A full-stack mobile productivity app built with **Flutter**, **Node.js/Express**, and **PostgreSQL**. Users register, log in, select a personal goal, and unlock premium nutrition tracking via a monthly subscription.

---

## 🏗️ Project Structure

```
my-app/
├── backend/           # Node.js + Express REST API
└── flutter_app/       # Flutter mobile app
```

---

## ✨ Features

### Auth
- ✅ Register & login with JWT
- ✅ Password hashing with bcrypt
- ✅ Show/hide password toggle
- ✅ Forgot password with 6-digit email code (Resend)

### App
- ✅ Goal selection (Focus, Consumption, Activity, Social, Explore)
- ✅ Daily summary time picker (24h / military time)
- ✅ Dashboard with animated spheres and daily quest
- ✅ Progress page with radar chart
- ✅ Glasses page with sneak mode
- ✅ Profile & settings page

### Nutrition (Premium - 15 RON/month)
- ✅ Stripe subscription with real card payments
- ✅ Daily food log (add, delete meals)
- ✅ Calorie tracking
- ✅ Meal suggestions based on user goal
- ✅ Recipe viewer with ingredients and steps
- ✅ "Add to log" from recipe screen

---

## 🗂️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| Backend API | Node.js + Express |
| Database | PostgreSQL |
| Authentication | JWT |
| Password Security | bcryptjs |
| Email | Resend |
| Payments | Stripe |
| Server | Ubuntu VPS (Hostinger) |
| Process Manager | PM2 |

---

## ⚙️ Backend Setup

### Prerequisites
- Node.js v20+
- PostgreSQL 16+

### 1. Install dependencies

```bash
cd backend
npm install
```

### 2. Create `.env` file

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=productivity_app
DB_USER=postgres
DB_PASSWORD=your_postgres_password
JWT_SECRET=your_super_secret_key
JWT_EXPIRES_IN=7d
RESEND_API_KEY=re_your_resend_key
FROM_EMAIL=onboarding@resend.dev
STRIPE_SECRET_KEY=sk_test_your_stripe_secret
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable
STRIPE_PRICE_ID=price_your_price_id
```

> ⚠️ Never commit your `.env` file. It is already in `.gitignore`.

### 3. Set up the database

```sql
CREATE DATABASE productivity_app;

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

CREATE TABLE subscriptions (
    id                     SERIAL PRIMARY KEY,
    user_id                INTEGER NOT NULL REFERENCES users(id),
    stripe_customer_id     VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    status                 VARCHAR(50) DEFAULT 'inactive',
    current_period_end     TIMESTAMP,
    created_at             TIMESTAMP DEFAULT NOW(),
    updated_at             TIMESTAMP DEFAULT NOW()
);

CREATE TABLE food_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id),
    meal_name   VARCHAR(255) NOT NULL,
    calories    INTEGER,
    meal_type   VARCHAR(50),
    logged_at   TIMESTAMP DEFAULT NOW()
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
| POST | `/api/auth/register` | Register |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/forgot-password` | Send reset code |
| POST | `/api/auth/reset-password` | Reset password |

### Goals (🔒 Auth required)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/goals` | Save/update goal |
| GET | `/api/goals` | Get current goal |

### Subscription (🔒 Auth required)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/subscription/create-payment-sheet` | Start Stripe flow |
| POST | `/api/subscription/confirm` | Confirm subscription |
| GET | `/api/subscription/status` | Check if subscribed |

### Food Log (🔒 Auth required)
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/food` | Add meal |
| GET | `/api/food/today` | Get today's meals |
| DELETE | `/api/food/:id` | Delete meal |

All protected routes require:
```
Authorization: Bearer <your_jwt_token>
```

---

## 📱 Flutter App Setup

### Prerequisites
- Flutter SDK 3.x
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device (Android 5.0+)

### 1. Install dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Configure server URL

Open `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Local Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Physical phone (your computer's local IP):
  // static const String baseUrl = 'http://192.168.x.x:3000/api';

  // Production:
  static const String baseUrl = 'http://187.124.25.127:3000/api';
}
```

### 3. Android requirement for Stripe

In `android/app/src/main/kotlin/.../MainActivity.kt`:
```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity()
```

In `android/app/build.gradle.kts`:
```kotlin
minSdk = 21
```

### 4. Run the app

```bash
flutter run
```

---

## 🚀 Production Server (Ubuntu VPS)

### Deploy backend

```bash
scp -r backend root@your-server-ip:/root/
cd /root/backend
npm install
pm2 start src/index.js --name "productivity-api"
pm2 startup
pm2 save
sudo ufw allow 3000
```

### Useful PM2 commands

```bash
pm2 status
pm2 logs productivity-api
pm2 restart productivity-api
pm2 flush
```

---

## 💳 Stripe Test Cards

| Card | Number |
|---|---|
| Success | 4242 4242 4242 4242 |
| Declined | 4000 0000 0000 0002 |

Use any future expiry, any 3-digit CVC, any ZIP.

---

## 🔒 Security Notes

- Passwords never stored in plain text — bcrypt hashed
- JWT tokens expire after 7 days
- Reset codes expire after 15 minutes, single use
- `.env` is gitignored — never share it
- Stripe secret key only lives on the server

---

## 👤 Author

Rita — [@lorinczdorakinga](https://github.com/lorinczdorakinga)
