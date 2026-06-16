# BillBoy - AI-Powered Digital Bill & Warranty Manager

> **Never lose a bill. Never miss a warranty.**

## Architecture

```
billboy/
├── billboy_app/          # Flutter mobile app (Android + iOS)
│   ├── lib/
│   │   ├── core/         # Theme, constants, DI, router, services, utils
│   │   ├── data/         # Models, repositories, datasources (local + remote)
│   │   ├── domain/       # Entities, repository contracts
│   │   └── presentation/ # BLoCs, pages, widgets
│   └── test/             # Unit + widget + integration tests
│
├── billboy_backend/      # Node.js REST API
│   └── src/
│       ├── config/       # Database, Firebase, Redis
│       ├── controllers/  # Request handlers
│       ├── middleware/    # Auth, validation, error handling
│       ├── models/        # Sequelize ORM models
│       ├── routes/        # Express routers
│       ├── services/      # OCR, notifications, depreciation, export
│       └── jobs/          # Cron jobs (warranty reminders)
│
├── database/             # PostgreSQL schema
├── nginx/                # Reverse proxy config
├── docker-compose.yml    # Full stack deployment
└── .github/workflows/    # CI/CD pipeline
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x + Dart |
| State Management | flutter_bloc (BLoC pattern) |
| Navigation | go_router |
| Backend | Node.js + Express |
| Database | PostgreSQL + Sequelize ORM |
| Cache | Redis |
| Auth | Firebase Authentication |
| Storage | Firebase Storage |
| OCR | Google Cloud Vision + OpenAI GPT-4o |
| Push Notifications | Firebase Cloud Messaging |
| Email | Nodemailer |
| Deployment | Docker + Docker Compose + Nginx |
| CI/CD | GitHub Actions |

## Getting Started

### Flutter App

```bash
cd billboy_app
flutter pub get
flutter run
```

### Backend API

```bash
cd billboy_backend
cp .env.example .env
# Fill in your credentials

npm install
npm run dev
```

### Full Stack with Docker

```bash
cp .env.example .env
# Configure environment variables

docker compose up -d
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/bills | List all bills (paginated, filterable) |
| POST | /api/v1/bills | Create a new bill |
| GET | /api/v1/bills/:id | Get bill by ID |
| PUT | /api/v1/bills/:id | Update bill |
| DELETE | /api/v1/bills/:id | Soft delete bill |
| GET | /api/v1/bills/stats/dashboard | Dashboard statistics |
| GET | /api/v1/bills/export/csv | Export as CSV |
| GET | /api/v1/bills/export/pdf | Export as PDF |
| POST | /api/v1/ocr/extract | OCR from uploaded image/PDF |
| GET | /api/v1/analytics/spending-by-category | Category analytics |
| GET | /api/v1/analytics/monthly-spending | Monthly trends |
| GET | /api/v1/analytics/warranty-overview | Warranty status distribution |
| GET | /api/v1/analytics/depreciation-summary | Depreciation by category |
| GET | /api/v1/notifications | List notifications |
| PUT | /api/v1/notifications/read-all | Mark all as read |
| GET | /api/v1/categories | List categories |
| POST | /api/v1/categories | Create custom category |
| GET | /api/v1/users/preferences | Get user preferences |
| PUT | /api/v1/users/preferences | Update preferences |

## Features

- **AI OCR** — Automatically extracts bill details from photos and PDFs using Google Vision + GPT-4o
- **Warranty Tracking** — Auto-calculates warranty end dates and sends reminders at 90/60/30/15/7/1 days
- **Depreciation Engine** — Calculates current estimated value using configurable category-based rules
- **Smart Dashboard** — Statistics, spending trends, warranty alerts, category breakdown
- **Export** — Download all data as CSV or PDF
- **Dark/Light Theme** — Full theming support
- **Offline Mode** — Local cache for offline access
- **Security** — JWT via Firebase Auth, AES-256 encrypted storage, GDPR compliant

## Environment Setup

See `.env.example` for all required environment variables.

Required services:
- Firebase project with Authentication + Firestore + Storage
- PostgreSQL 15+
- Redis 7+
- Google Cloud Vision API key
- OpenAI API key (GPT-4o)
- SMTP server for email notifications
