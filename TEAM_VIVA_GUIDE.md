# 📖 Team Viva Guide: Field Survey Framework

Share this with all team members to prepare for the final presentation.

---

### 1. The Elevator Pitch (Use this to start)
"Our project is a Distributed Framework for Offline-First Data Collection. It allows field workers to collect data in zero-internet zones without data loss, using a local-to-cloud synchronization model with visual evidence (Photos) and geographic verification (GPS)."

---

### 2. The "Big Three" Technical Pillars
*   **Offline-First Architecture**: We use an internal **SQLite** database. We save data locally first. This ensures **0% data loss**.
*   **Real-Time Synchronization**: We use **Firebase Cloud Firestore**. Data from one phone appears on another phone's dashboard instantly.
*   **Geographic Verification**: Every survey captures silent GPS coordinates and **Photo Proofs**. This prevents "fake data" and proves the surveyor was physically present.

---

### 3. Tech Stack Breakdown
*   **Frontend**: **Flutter (Dart)** – Compiled as a **PWA (Progressive Web App)** for universal access.
*   **Cloud Backend**: **Firebase Authentication** (Identity), **Firestore** (Real-time DB), and **Firebase Storage** (Photos).
*   **Local Storage**: **SQLite** – Handles the background "Auto-Save Drafts" and "Offline Queue."
*   **Data Warehouse**: **Node.js + MySQL** – For long-term storage and advanced reporting.
*   **Visualization**: **fl_chart** – For interactive data trend analysis.

---

### 4. Key Feature Highlights
*   **The Builder**: Drag-and-Drop interface. Supports 7 data types (Photos, Ratings, Numbers, etc.).
*   **The Scanner**: Smart QR reader. Recognizes surveys and provides a one-tap shortcut to open them.
*   **The Analytics**: Interactive Donut Charts. Tapping a slice shows specific counts. Master CSV export for Excel analysis.
*   **The Map**: Google Maps integration with "Tap-to-See" pins. Managers can verify the site data directly from the map.

---

### 5. Professional "Senior" Features (Extra Marks!)
1.  **Debouncing**: 300ms delay on search bars to save battery and prevent UI lag.
2.  **Throttling**: Sync button disables itself after one click to prevent duplicate submissions.
3.  **Data Validation**: Strict enforcement of required fields and numeric types.
4.  **Security**: Hardened .gitignore and API key restrictions to prevent cloud hacking.

---

### 6. Viva "Power Answers" (Cheat Sheet)

**Q: Why did you use both SQLite and Firestore?**
*   *Answer*: "SQLite provides **Offline Persistence** for the field worker, while Firestore provides **Global Convergence** for the manager. Together, they create a robust distributed system."

**Q: What happens if the phone crashes while filling a survey?**
*   *Answer*: "The app uses an **Auto-Save Draft Engine**. Every input is saved to SQLite in the background. When the app reopens, it restores the exact state of the form."

**Q: How do you verify the data is real?**
*   *Answer*: "We use **Dual-Verification**: Visual proof via the **Photo question type** and Geographic proof via automatic **GPS capture**."

**Q: Why build a PWA instead of a normal Android app?**
*   *Answer*: "PWAs allow **Instant Distribution**. We can share a survey via a QR code, and someone can fill it without downloading anything from the Play Store."

---
© 2024 Field Survey Team
