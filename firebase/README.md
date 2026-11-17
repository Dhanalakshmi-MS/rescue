# RescueLens XR – Firebase Cloud Setup Guide

This guide explains how Member 3 (or the team lead) sets up the **Firebase Realtime Database** and **Firebase Authentication** for RescueLens XR.

---

## 1. Create a Firebase Project

1. Navigate to the [Firebase Console](https://console.firebase.google.com/) and sign in with your Google account.
2. Click **Add project** and enter the project name: `rescuelens-xr`.
3. Disable Google Analytics (optional, not required for this prototype) and click **Create project**.

---

## 2. Set Up Realtime Database

1. In the left sidebar of the Firebase Console, navigate to **Build** ➔ **Realtime Database**.
2. Click **Create Database**.
3. Choose a database location (e.g., `us-central1` or closest to your location) and click **Next**.
4. Select **Start in test mode** for initial development, then click **Enable**.
5. Note your **Database URL**, which looks like:
   ```text
   https://rescuelens-xr-default-rtdb.firebaseio.com/
   ```

---

## 3. Import Database Structure

1. In the Realtime Database **Data** tab, click the three vertical dots (⋮) in the top-right corner.
2. Click **Import JSON**.
3. Browse and select the file:
   `c:\Users\hemam\OneDrive\Desktop\rescue\firebase\database_structure.json`
4. Click **Import**. Your database will immediately populate with all 8 rooms, baseline sensor telemetry, sample routes, and user role records.

---

## 4. Apply Database Security Rules

1. In the Realtime Database, click the **Rules** tab.
2. Open the file [firebase/database.rules.json](file:///c:/Users/hemam/OneDrive/Desktop/rescue/firebase/database.rules.json).
3. Copy its entire content, paste it into the Firebase Rules editor, and click **Publish**.
4. These rules ensure:
   - All authenticated users can read telemetry and routes in real time.
   - Temperature, humidity, and smoke values are strictly validated within physical limits.
   - Only admin accounts or authorized backend credentials can modify building safety states.

---

## 5. Enable Firebase Authentication

1. In the left sidebar, navigate to **Build** ➔ **Authentication**.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, click **Email/Password**.
4. Toggle **Enable** on and click **Save**.
5. Go to the **Users** tab and click **Add user**:
   - **Admin Account**: `admin@rescuelens.org` | Password: `Password@123`
   - **User Account**: `student@college.edu` | Password: `Password@123`

---

## 6. Configure Service Account for Backend

1. Click the gear icon ⚙ next to **Project Overview** in the left sidebar and select **Project settings**.
2. Go to the **Service accounts** tab.
3. Select **Python** and click **Generate new private key**.
4. Save the downloaded JSON file as:
   `c:\Users\hemam\OneDrive\Desktop\rescue\firebase\serviceAccountKey.json`
   *(Note: This file is already git-ignored in `.gitignore` to prevent leaking credentials).*
5. Open your `.env` file (or set environment variables):
   ```env
   FIREBASE_DATABASE_URL=https://your-project-id-default-rtdb.firebaseio.com/
   FIREBASE_CREDENTIALS_PATH=./firebase/serviceAccountKey.json
   ```

---

## 7. Verify Sync

Run the backend test script to verify that local simulation and safety triggers continue to operate seamlessly with Firebase sync:
```powershell
cd c:\Users\hemam\OneDrive\Desktop\rescue\backend
.\venv\Scripts\python test_backend.py
```
