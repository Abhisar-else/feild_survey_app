# Field Survey App

A **Mobile-Based Distributed Data Collection Framework** that enables field workers to collect survey data offline and sync it to a central data warehouse when connectivity is available.

> **Project Guide:** Dr. Praveen Goyal  
> **Tech Stack:** Flutter · Firebase · Node.js · SQLite · MySQL
> **Domain:** Mobile App + Networks + Data Warehousing
> **Status:** Deployment Ready · Audited · Optimized

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Quality Assurance & Testing](#quality-assurance--testing)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [API Endpoints](#api-endpoints)
- [Database Schema](#database-schema)
- [Team](#team)
- [License](#license)

---

## Overview

The Field Survey App solves a critical problem faced by field researchers, healthcare workers, and data collectors — **the inability to collect data in areas with poor or no internet connectivity.**

This app allows users to:
- Create and manage complex surveys with a drag-and-drop builder.
- Capture visual evidence via **Photo Proofs** and precise GPS coordinates.
- Fill out survey forms in the field — **even without internet** — with auto-save draft protection.
- Automatically sync collected data to a cloud database when connectivity is restored.
- View and analyze global reach through professional charts and interactive maps.
- Export data to professional CSV/Excel files for business analysis.

---

## Features

### Field Worker / Surveyor
- **Secure Identity**: Sign Up and Sign In via Firebase Authentication.
- **Visual Evidence**: Capture photos as "Proof of Work" (Firebase Storage).
- **Location Tagging**: Automatic GPS capture for every submission.
- **Offline Reliability**: Store responses locally using SQLite with **Auto-Save Drafts** to prevent data loss.
- **Auto-sync**: Data is pushed to the cloud automatically when internet is detected.

### Admin / Manager
- **Advanced Builder**: Create forms with 7 question types (Text, MCQ, Photo, etc.) and reorder them with drag-and-drop.
- **Template Editor**: Edit existing surveys without losing previous data.
- **Public Distribution**: Generate instant QR codes and public links for anyone to fill forms without logging in.
- **Data Management**: View all submissions in expandable cards or delete outdated surveys.
- **Data Export**: One-click download of individual or **Master Master CSV** files.

### Professional Analytics
- **Reach Dashboard**: Real-time counter of "Total Reach" vs "Total Forms."
- **Visual Trends**: Interactive Pie Charts (via `fl_chart`) showing survey distribution.
- **Transmission Status**: Visual progress bar showing % of data safely secured on the cloud.
- **Geographic Verification**: Interactive map with clickable pins showing data previews of physical submissions.

---

## System Architecture

```
┌─────────────────────┐         ┌──────────────────────┐
│   Flutter Mobile App │◄───────►│   Node.js REST API   │
│  (PWA / Android / iOS)│  HTTPS  │   (Express.js)       │
│                     │         └──────────┬───────────┘
│  ┌───────────────┐  │                    │
│  │  SQLite (Local│  │                    ▼
│  │  Offline DB)  │  │         ┌──────────────────────┐
│  └───────────────┘  │         │   MYSQL Database     │
│                     │         │   (Data Warehouse)   │
└─────────────────────┘         └──────────────────────┘
```

---

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter (Dart) | High-performance UI & PWA support |
| **Authentication** | Firebase Auth | Secure user management |
| **Cloud Storage** | Firebase Storage| Hosting field photo proofs |
| **Local Storage** | SQLite | Offline data, sync tracking, and drafts |
| **Backend** | Node.js + Express | REST API server |
| **Cloud Database** | MYSQL | Central data warehouse |
| **Charts & Maps** | fl_chart / Google Maps| Data visualization & Geographic hub |
| **Export Tool** | csv | Excel-compatible reporting |

---

## Quality Assurance & Testing

The application has passed a professional 6-stage testing audit:

1. **Functional Testing**: Verified registration, builder reordering, and submission logic.
2. **Performance Testing**: Optimized via Tree-Shaking. Initial load optimized for 4G speeds.
3. **Accessibility Testing**: Integrated WCAG-compliant contrast and semantic labels for Screen Readers.
4. **Compatibility Testing**: Verified on Chrome, Safari, and Edge across multiple screen sizes.
5. **Security Audit**: Secured API keys via domain restriction and excluded sensitive credentials from Git.
6. **Alpha/Beta Testing**: Simulated power/internet failure to verify SQLite draft restoration logic.

---

## Getting Started

### Prerequisites
- Flutter SDK `>=3.11`
- Node.js `>=18.x`
- Firebase Account

### 1. Clone & Setup
```bash
git clone https://github.com/Abhisar-else/feild_survey_app.git
cd feild_survey_app
flutter pub get
```

### 2. Backend Setup
```bash
cd backend
npm install
# Configure your .env based on .env.example
npm start
```

### 3. Deployment
Run the professional deployment script (Windows):
```bash
.\deploy-web.bat
```

---

## Project Structure

```
field-survey-app/
├── lib/
│   ├── models/             # Data structures (Survey, Response, User)
│   ├── screens/            # UI (Login, SignUp, Dashboard, Responses)
│   ├── services/           # Logic (Auth, Survey, Sync, Location, Downloads)
│   ├── fill_survey.dart    # Public form filling interface
│   ├── analytic.dart       # Professional reach dashboard
│   └── main.dart           # App entry and route configuration
├── backend/                # Node.js Server & MySQL integration
├── web/                    # PWA & Web configuration
├── .gitignore              # Professional security isolation
└── README.md
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | User login |
| GET | `/api/surveys` | Get all surveys |
| GET | `/api/surveys/:id` | Get survey by ID |
| POST | `/api/surveys` | Create new survey |
| POST | `/api/responses` | Submit survey response |
| GET | `/api/responses` | Get all responses (admin) |

---

## Database Schema

- **Users**: `id, name, email, password_hash, role, created_at`
- **Surveys**: `id, title, description, questions_json, created_at`
- **Responses**: `id, survey_id, answers_json, latitude, longitude, synced_at`

---

## Team

| Name | Roll No |  
|------|---------|
| **Abhisar Sharma** | PU02324EUGBTCS008 | 
| **Aditi Nigam** | PU02324EUGBTCS011 | 
| **Adeesh Jain** | PU02324EUGBTCS009 | 
| **Divyanshu Dave** | PU02324EUGBTCS040 |

**Project Guide:** Dr. Praveen Goyal

---

## License
Developed as part of an academic project under **Symbiosis University of Applied Science**.
© 2024 Field Survey Team. All rights reserved.
