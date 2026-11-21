# 🏠 RentKhata — Hostel / PG & Flat Rent Manager

> **Hyperlocal B2B Property, Rent & Utility Automation Tool for Independent Landlords in India.**  
> Built with **Flutter (Mobile)** + **Supabase (PostgreSQL 15+)** + **Meta WhatsApp Cloud API** + **NPCI Dynamic UPI Links**.

---

## 🌟 The Core Problem & Solution

In India's student and IT hubs (Kota, Delhi, Pune, Bangalore, Indore, Patna), over 90% of PG, hostel, and flat owners manage rent on paper diaries (*bahi-khata*) or messy WhatsApp chats. 

### Why Landlords Love RentKhata:
1. **Zero-Dispute Electricity Sub-Meter Math:** Enter the current meter reading $\rightarrow$ units consumed and bill amount are calculated automatically $\rightarrow$ math and meter dial photo are sent directly to the tenant's WhatsApp.
2. **Automated WhatsApp Reminders:** No more awkward calls (*"Bhaiya rent bhej do"*). Personalized bills with direct UPI buttons arrive automatically on the 1st of every month.
3. **1-Tap Direct UPI Settlement:** Uses native NPCI UPI deep-linking (`upi://pay`) directly into the owner's bank account with **0% gateway transaction fees**.
4. **Instant Digital PDF Receipts:** Generates official branded PDF rent receipts upon payment and dispatches them straight to WhatsApp in seconds.
5. **"Tenant-Zero-App" Model:** Landlord gets a simple 2-tap app. **Tenants do NOT download any app**—they interact purely via WhatsApp and a lightweight web view.

---

## 📚 Complete Project Documentation (`docs/`)

All architecture, database schemas, API specs, and implementation blueprints are located in the [`docs/`](docs/) directory:

| Document | Description |
| :--- | :--- |
| **[00. Master Index](docs/00_MASTER_INDEX.md)** | Master roadmap, blueprint, and directory overview. |
| **[01. Vision & Strategy](docs/01_Executive_Summary_and_Vision.md)** | Market analysis, student hubs, and core value propositions. |
| **[02. Full PRD](docs/02_Product_Requirements_Document_PRD.md)** | Complete Product Requirements Document & User Stories. |
| **[03. System Architecture](docs/03_System_Architecture_and_Tech_Stack.md)** | Flutter, Supabase PostgreSQL, Edge functions, and API topology. |
| **[04. Database Schema](docs/04_Database_Schema_and_Data_Models.md)** | Production-ready PostgreSQL DDL script with RLS & Triggers. |
| **[05. WhatsApp & UPI Engine](docs/05_WhatsApp_Automation_and_UPI_Flows.md)** | Meta Cloud API templates, NPCI dynamic UPI URI, and webhook flow. |
| **[06. UI/UX & Wireframes](docs/06_UI_UX_Design_System_and_Wireframes.md)** | Landlord 2-tap UI, 4-color Room Matrix, and numeric keypad flows. |
| **[07. Business & GTM Strategy](docs/07_Business_Model_Monetization_and_GTM.md)** | Monetization tiers (Free, ₹199/mo, ₹499/mo) and direct-sales playbook. |
| **[08. Roadmap & Budget](docs/08_Development_Roadmap_and_Cost_Estimation.md)** | 30-day MVP sprint plan, launch checklist, and cost analysis. |
| **[09. Step-by-Step Implementation & Audit Plan](docs/09_Step_by_Step_Implementation_and_Audit_Plan.md)** | 12-step implementation plan with mandatory verification at each step. |

---

## 🛠️ Tech Stack & Key Technologies

* **Frontend:** Flutter 3.x / Dart 3.x (Clean Architecture, Feature-First)
* **State Management:** Riverpod (`flutter_riverpod`)
* **Local Offline Database:** SQLite / Drift (Offline-first for basement meter rooms)
* **Cloud Database:** Supabase (PostgreSQL 15+ with Row-Level Security)
* **Messaging:** Meta WhatsApp Cloud API v20.0+ (with direct intent fallback for free tier)
* **Payments:** NPCI Standard Dynamic UPI URI (`upi://pay`) & QR Codes
* **Document Engine:** High-performance vector PDF generator (`pdf` / `printing`)

---

## 🚀 Repository & Contribution Guidelines
* Every feature follows the **Code $\rightarrow$ Audit $\rightarrow$ Test $\rightarrow$ Verify** protocol.
* Run `flutter analyze` and `flutter test` before committing any code changes.
