# 📋 Field Survey App

A **Mobile-Based Distributed Data Collection Framework** that enables field workers to collect survey data offline and sync it to a central data warehouse when connectivity is available.

> **Project Guide:** Dr. Praveen Goyal  
> **Tech Stack:** Flutter · Node.js · SQLite · MYSQL 
> **Domain:** Mobile App + Networks + Data Warehousing

---

## 📌 Table of Contents

- [Overview]
- [Features]
- [System Architecture]
- [Tech Stack]
- [Getting Started]
- [Project Structure]
- [API Endpoints]
- [Database Schema]
- [Screenshots]
- [Team]
- [License]

---

## 🧭 Overview

The Field Survey App solves a critical problem faced by field researchers, healthcare workers, and data collectors — **the inability to collect data in areas with poor or no internet connectivity.**

This app allows users to:
- Create and manage surveys from an admin panel
- Fill out survey forms in the field — **even without internet**
- Automatically sync collected data to a cloud database when connectivity is restored
- View and analyze collected data through a dashboard

---

## ✨ Features

### 👤 Field Worker
- Login with role-based access
- View assigned surveys
- Fill forms with text, images, GPS location, and dropdowns
- Store responses **locally (offline)** using SQLite
- **Auto-sync** to cloud when internet is detected
- View sync status for each submission

### 🛠️ Admin
- Create and manage surveys and questions
- Assign surveys to field workers
- View real-time response data
- Export data to CSV / Excel
- Monitor sync activity and field worker status

### 📊 Data Warehouse
- Centralized PostgreSQL database
- Timestamped records with device metadata
- Conflict resolution for duplicate submissions
- REST API for third-party integrations

---

## 🏗️ System Architecture

```
┌─────────────────────┐         ┌──────────────────────┐
│   Flutter Mobile App │◄───────►│   Node.js REST API   │
│  (Android / iOS)    │  HTTPS  │   (Express.js)       │
│                     │         └──────────┬───────────┘
│  ┌───────────────┐  │                    │
│  │  SQLite (Local│  │                    ▼
│  │  Offline DB)  │  │         ┌──────────────────────┐
│  └───────────────┘  │         │   MYSQL Database │
│                     │         │   (Data Warehouse)   │
└─────────────────────┘         └──────────────────────┘
```

**Data Flow:**
1. Admin creates surveys via web/app panel
2. Field worker downloads surveys to mobile app
3. Field worker fills forms (online or offline)
4. Responses stored in local SQLite DB
5. App detects internet → triggers background sync
6. Data pushed to MYSQL via REST API
7. Admin views results on dashboard

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Mobile App | Flutter (Dart) | Cross-platform UI (Android + iOS) |
| Local Storage | SQLite / Hive | Offline data storage |
| Backend | Node.js + Express | REST API server |
| Cloud Database | MYSQL | Central data warehouse |
| Authentication | JWT Tokens | Secure login |
| State Management | Provider / Riverpod | Flutter state |
| Network Detection | connectivity_plus | Detect online/offline |
| Maps & GPS | geolocator | Location tagging |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Node.js `>=18.x`
- 
- Android Studio / VS Code

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/field-survey-app.git
cd field-survey-app
```

### 2. Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Fill in your database credentials in .env
npm run migrate    # Run DB migrations
npm start          # Start the server on port 3000
```

### 3. Flutter App Setup

```bash
cd mobile
flutter pub get
# Update lib/config/api_config.dart with your backend URL
flutter run
```

### 4. Environment Variables (`.env`)

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=field_survey_db
DB_USER=your_db_user
DB_PASSWORD=your_db_password
JWT_SECRET=your_jwt_secret_key
```

---

## 📁 Project Structure

```
field-survey-app/
│
├── mobile/                     # Flutter App
│   ├── lib/
│   │   ├── config/             # API config, constants
│   │   ├── models/             # Data models
│   │   ├── screens/            # UI screens
│   │   │   ├── auth/           # Login screen
│   │   │   ├── surveys/        # Survey list & form
│   │   │   └── dashboard/      # Admin dashboard
│   │   ├── services/           # API & sync services
│   │   ├── database/           # SQLite local DB
│   │   └── main.dart
│   └── pubspec.yaml
│
├── backend/                    # Node.js Server
│   ├── routes/                 # API routes
│   ├── controllers/            # Route handlers
│   ├── models/                 # DB models
│   ├── middleware/             # Auth middleware
│   ├── migrations/             # DB migrations
│   └── server.js
│
└── README.md
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | User login |
| GET | `/api/surveys` | Get all surveys |
| GET | `/api/surveys/:id` | Get survey by ID |
| POST | `/api/surveys` | Create new survey |
| POST | `/api/responses` | Submit survey response |
| GET | `/api/responses` | Get all responses (admin) |
| GET | `/api/responses/export` | Export responses to CSV |

---

## 🗄️ Database Schema

### Users
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(100) UNIQUE,
  password_hash TEXT,
  role VARCHAR(20),   -- 'admin' or 'field_worker'
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Surveys
```sql
CREATE TABLE surveys (
  id SERIAL PRIMARY KEY,
  title VARCHAR(200),
  description TEXT,
  created_by INT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Responses
```sql
CREATE TABLE responses (
  id SERIAL PRIMARY KEY,
  survey_id INT REFERENCES surveys(id),
  user_id INT REFERENCES users(id),
  answers JSONB,
  latitude DECIMAL,
  longitude DECIMAL,
  synced_at TIMESTAMP,
  device_id VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 📸 Screenshots

> *(Add screenshots of the app here after development)*

| Login Screen | Survey List | Form Filling | Sync Status |
|---|---|---|---|
| ![login](#) | ![surveys](#) | ![form](#) | ![sync](#) |

---

## 👥 Team

| Name | Roll No |  
|------|---------|
| Aditi Nigam | PU02324EUGBTCS011 | 
| Abhisar Sharma | PU02324EUGBTCS008 | 
| Adeesh Jain | PU02324EUGBTCS009 | 
| Divyanshu Dave | PU02324EUGBTCS040 |

**Project Guide:** Dr. Praveen Goyal

---

## 📄 License

This project is developed as part of an academic internship/project under **Symbiosis university of applied science**.  
For educational use only.

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---
