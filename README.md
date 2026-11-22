# Student Wallet AI

A Flutter starter project for a global student spending companion.

## Current starter features
- Dashboard with available balance, income, expenses and budget progress
- Add income or expense manually
- Transaction history
- Local persistence on the device using SharedPreferences
- Currency symbol selected in the starter settings (USD default)

## Important
This is a starter prototype. It does not yet include cloud accounts, AI, voice entry,
roommate splitting, subscriptions, or production-grade financial data synchronization.
Do not store real sensitive financial records in this prototype.

## Run locally
1. Install Flutter SDK and Android Studio.
2. Extract this project.
3. Open a terminal in this folder.
4. Run:
   ```bash
   flutter pub get
   flutter analyze
   flutter run
   ```

## Next development milestones
1. Supabase authentication and secure per-user database (RLS).
2. Cloud transaction sync and backup.
3. Server-side AI parsing with confirmation before saving.
4. Speech-to-text voice entry.
5. Budget and savings goal modules.
6. Device testing and store release preparation.

## GitHub
Create a new repository named `student-wallet-ai`, then upload the contents of this folder
(the files inside the folder, not the ZIP itself).
