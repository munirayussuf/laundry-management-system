# Laundry Service Management System

A Flutter and FastAPI/PostgreSQL laundry management platform developed for Kenya, supporting both formal laundry businesses and informal **Mama Fua / Jua Kali** laundry service providers.

The system provides customers with a digital platform to discover laundry providers, view available services, place and track orders, and manage their profiles. Laundry providers can manage their services and orders, while administrators can manage users, providers, orders, and support requests.

> **Project Status:** Working academic prototype. The core Flutter application and FastAPI/PostgreSQL backend are implemented. USSD, SMS, and M-Pesa payment integrations are included as planned components but are **not currently operational** in the submitted prototype and require further external configuration and integration.

---

## Contents

1. [Project Overview](#project-overview)
2. [Key Features](#key-features)
3. [Screenshots](#screenshots)
4. [Technology Stack](#technology-stack)
5. [System Architecture](#system-architecture)
6. [User Roles](#user-roles)
7. [Database Design](#database-design)
8. [Project Structure](#project-structure)
9. [Installation](#installation)
10. [Running the Application](#running-the-application)
11. [APK](#apk)
12. [USSD, SMS and M-Pesa Status](#ussd-sms-and-m-pesa-status)
13. [Security](#security)
14. [Testing](#testing)
15. [Project Limitations](#project-limitations)
16. [Academic Project](#academic-project)

---

## Project Overview

The **Laundry Service Management System** is designed to improve access to laundry services by connecting customers with formal laundry businesses and informal **Mama Fua / Jua Kali** service providers through a single digital platform.

The system consists of:

- A Flutter Android application for customers and laundry providers
- A provider management interface
- An administrator dashboard
- A FastAPI backend
- A PostgreSQL database
- Planned USSD, SMS, and M-Pesa integration

The application is designed to support customers who use smartphones while providing a foundation for future USSD-based access for users with limited internet or smartphone access.

---

## Key Features

### 👤 Customer

- User registration and login
- Password recovery
- Customer dashboard
- Browse available laundry providers
- Search and filter providers
- View nearby providers using location
- View provider profiles
- View available laundry services and prices
- Place laundry orders
- Calculate order totals
- Provide pickup and delivery locations
- Track order status
- Cancel orders where applicable
- Submit reviews and ratings
- Edit customer profile
- Upload profile photo
- Submit support/help requests

### 🧺 Laundry Provider

The provider interface supports both formal laundry businesses and **Mama Fua / Jua Kali** providers.

- Provider registration
- Provider profile management
- Specify provider type
- Set washing and ironing methods
- Add service prices
- Set turnaround time
- Set daily service capacity
- Manage availability
- Create laundry services
- Edit services
- Delete services
- View incoming orders
- Accept or reject orders
- Update order status
- View completed orders
- Provider dashboard with order statistics

### 👨‍💼 Administrator

- Admin dashboard
- View platform statistics
- Manage customers
- Activate/deactivate users
- Manage laundry providers
- Verify providers
- Activate/deactivate providers
- Manage orders
- View support messages
- Manage submitted support requests

---

## Screenshots

The application uses a **light rose/pink visual design** with white cards, rounded components, pink action buttons, and deep plum text.

### Customer App

![Login](screenshots/login.png)

![Customer Home](screenshots/customer-home.png)

![Provider Discovery](screenshots/provider-discovery.png)

![Provider Profile](screenshots/provider-profile.png)

![Booking](screenshots/booking.png)

![Order Tracking](screenshots/order-tracking.png)

### Provider App

![Provider Dashboard](screenshots/provider-dashboard.png)

![Provider Orders](screenshots/provider-orders.png)

### Admin

![Admin Dashboard](screenshots/admin-dashboard.png)

> Replace the screenshot filenames above with the exact filenames you upload to the `screenshots` folder in the repository.

---

## Technology Stack

| Layer | Technology |
|---|---|
| Mobile Application | Flutter |
| Programming Language | Dart |
| State Management | Riverpod |
| Routing | go_router |
| Backend | FastAPI |
| Backend Language | Python |
| Database | PostgreSQL |
| ORM | SQLAlchemy |
| Authentication | JWT |
| API Communication | REST API |
| Platform | Android |
| Version Control | Git & GitHub |

---

## System Architecture

```text
              Flutter Android Application
                         │
                         │ REST API
                         ▼
                  FastAPI Backend
                         │
                         │
                         ▼
                   PostgreSQL
                    Database
```

The Flutter application communicates with the FastAPI backend through REST APIs.

The backend manages authentication, business logic, orders, providers, services, reviews, notifications, support messages, and database operations.

---

## User Roles

| User | Main Functions |
|---|---|
| Customer | Find providers, view services, place orders, track orders and submit reviews |
| Provider | Manage services, receive orders and update order status |
| Admin | Manage users, providers, orders and support requests |

---

## Database Design

The system uses PostgreSQL for persistent data storage.

### Main entities

**Users**

Stores customer, provider and administrator account information.

**Providers**

Stores laundry provider information including provider type, services, pricing, location, availability and verification status.

**Services**

Stores individual laundry services offered by providers.

**Orders**

Stores customer orders, selected services, pickup/delivery information, order status and total amount.

**Payments**

Stores payment-related information associated with orders.

**Notifications**

Stores notifications generated for users.

**Reviews**

Stores customer ratings and reviews for laundry providers.

**Support Messages**

Stores customer support and help requests.

**USSD Sessions**

Provides the database structure required for future USSD session management.

---

## Project Structure

```text
laundry_service_app/
│
├── android/
│
├── assets/
│
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── repositories/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── theme/
│   │   └── widgets/
│   │
│   ├── features/
│   │   ├── auth/
│   │   ├── customer/
│   │   ├── provider/
│   │   ├── admin/
│   │   ├── notifications/
│   │   └── profile/
│   │
│   └── main.dart
│
├── backend/
│   └── app/
│
├── screenshots/
│
├── legacy_firebase_functions/
│
├── firestore/
│
├── tools/
│
├── pubspec.yaml
│
├── docker-compose.yml
│
└── README.md
```

The `legacy_firebase_functions` directory contains an earlier Firebase implementation. The current application uses **FastAPI and PostgreSQL**.

---

## Installation

### Requirements

- Flutter SDK
- Dart SDK
- Android Studio
- Python
- PostgreSQL
- Git

### Clone the repository

```bash
git clone <your-repository-url>
cd laundry_service_app
```

### Install Flutter dependencies

```bash
flutter pub get
```

### Run Flutter

```bash
flutter run
```

### Backend

The backend is built using FastAPI and communicates with PostgreSQL.

Install the required Python dependencies and configure the PostgreSQL database according to the backend environment configuration.

Example:

```bash
uvicorn app.main:app --reload
```

---

## Running the Application

The application consists of two main parts:

### Flutter Frontend

The Flutter application provides the user interface for:

- Customers
- Laundry providers
- Administrators

### FastAPI Backend

The FastAPI backend handles:

- Authentication
- User management
- Provider management
- Services
- Orders
- Reviews
- Notifications
- Support requests
- Database operations

The Flutter application communicates with the backend through the configured API URL.

---

## 📱 APK

An Android APK is included for demonstration and academic evaluation.

### Download

**[Download Laundry Management System APK](laundry-management-system.apk)**

The APK can be installed on an Android device for testing the application interface and implemented functionality.

### Generate a new APK

For a release build:

```bash
flutter build apk --release
```

The generated APK can be found at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## USSD, SMS and M-Pesa Status

The project was designed with future integration of USSD, SMS communication, and M-Pesa payments.

However, these external services are **not currently operational in the submitted prototype**.

### USSD

The project contains the backend structure for USSD functionality, but the USSD service is not currently connected to a working telecom/USSD provider.

Therefore:

> **USSD: Not currently operational.**

### SMS

The project contains backend preparation for SMS integration, but SMS communication has not been successfully connected and tested with a live SMS gateway.

Therefore:

> **SMS: Not currently operational.**

### M-Pesa Payment

The project contains payment-related backend structures, but the M-Pesa/Daraja payment integration is not currently working in the submitted prototype.

Therefore:

> **M-Pesa payments: Not currently operational.**

These components can be completed in future development by configuring the required third-party accounts, credentials, callback URLs, and service-provider integration.

The core application does **not depend on these integrations to demonstrate the main customer, provider, and administrator workflows**.

---

## Security

The backend uses JWT-based authentication for protected API routes.

The system also separates functionality according to user roles:

- Customer
- Provider
- Administrator

Sensitive backend credentials should be stored in environment variables and should not be committed to GitHub.

---

## Testing

The implemented application was tested through the Flutter Android application and backend environment.

### Core functionality tested

- User registration
- User login
- Role-based access
- Provider registration
- Provider discovery
- Provider profile viewing
- Service management
- Laundry booking
- Order creation
- Order tracking
- Order status updates
- Order cancellation
- Provider management
- Customer profile management
- Reviews and ratings
- Support message submission
- Administrator management functions

### External integrations

| Feature | Status |
|---|---|
| Flutter Android application | ✅ Implemented |
| FastAPI backend | ✅ Implemented |
| PostgreSQL database | ✅ Implemented |
| Customer functionality | ✅ Implemented |
| Provider functionality | ✅ Implemented |
| Admin functionality | ✅ Implemented |
| USSD | ⚠️ Not operational |
| SMS | ⚠️ Not operational |
| M-Pesa | ⚠️ Not operational |

---

## Project Limitations

The current prototype has several limitations:

- USSD integration is not currently operational.
- SMS integration is not currently operational.
- M-Pesa payment integration is not currently operational.
- Third-party service credentials and production configurations are not included in the repository.
- The application is currently focused on Android.
- Some external integrations require additional provider approval and configuration before they can be used in production.

These limitations provide areas for future development and deployment.

---

## Future Improvements

Future versions of the system can include:

- Fully operational USSD access
- SMS notifications
- M-Pesa payment integration
- Provider/customer communication
- Push notifications
- Advanced analytics and reporting
- Production cloud storage for profile images
- Android and iOS support
- Improved offline functionality
- More extensive automated testing

---

## Academic Project

This project was developed as a **Bachelor of Science in Information Technology final-year academic project** at **Umma University, Kenya**.

### Project Focus

**Laundry Service Management System: An Inclusive Digital Platform for Formal and Informal (Mama Fua/Jua Kali) Laundry Service Delivery**

The project focuses on using digital technology to improve access to laundry services while providing formal and informal laundry service providers with tools for managing their services and customer orders.

---

## Developer

**Munira Yussuf Suraw**

Bachelor of Science in Information Technology  
Umma University, Kenya

---

## License

This project was developed for academic purposes.
