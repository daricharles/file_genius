# FileGenius

Flutter + Firebase learning assistant with file upload, AI chat, analytics, and gamified progress.

## Overview

- Flutter web/desktop/mobile app backed by Firebase Auth, Firestore, and Storage.
- Node proxy (`gemini-proxy.js`) for Google Generative AI and server-side file text extraction, plus SMTP email sending.
- Real-time analytics and achievements; local notifications and optional email digests.

## Prerequisites

- Flutter SDK installed
- Node.js 18+
- Firebase project configured (see `lib/firebase_options.dart` and platform-specific configs)

## Setup

1. Install Flutter dependencies:

```powershell
flutter pub get
```

1. Install Node dependencies:

```powershell
npm install
```

1. Create `.env` in the project root with your API keys and SMTP (for emails):

```ini
GEMINI_API_KEY=your_google_api_key
# SMTP settings (optional, for emails)
SMTP_HOST=smtp.yourprovider.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_smtp_username
SMTP_PASS=your_smtp_password
FROM_EMAIL=no-reply@yourdomain.com
```

## Run

Start both the proxy and the Flutter app:

```powershell
npm start
```

This runs `node gemini-proxy.js` and `flutter run -d chrome` concurrently.

## Features

- Upload and preview PDFs and Office files; AI chat about your content.
- Auto-analysis pipeline and quiz/flashcards generation with XP rewards.
- Dashboard with learning analytics (daily activity, weekly performance, subjects, totals).
- Achievements and streaks with balanced XP awards.
- Local notifications and optional emails.

### Notifications & Emails

Local notifications are handled via `flutter_local_notifications` and can be toggled under Profile → Notifications & Emails:

- Study reminders (inactivity nudge)
- Achievement alerts (on unlock)
- Weekly summary reminder (periodic)
- Daily inspirational quote (new)

Email sending (optional) uses the Node proxy `/send-email` endpoint and SMTP credentials:

- Achievement emails (on unlock)
- Weekly summary email (sent at most once per week when the app is used)

To enable emails, set SMTP variables in `.env` (see Setup) and turn on the email toggles in the profile screen.

### Daily Inspirational Quotes

- A short curated quote is delivered once per day as a local notification.
- Quote content rotates daily and is rescheduled at midnight.
- Toggle: Profile → Notifications & Emails → "Daily inspirational quote (local notification)".

## Troubleshooting

- Proxy errors: ensure `.env` has `GEMINI_API_KEY` and correct SMTP settings.
- Emails not arriving: verify SMTP credentials and `FROM_EMAIL`; some providers require app passwords.
- Notifications not showing: check OS/browser notification permissions and ensure related toggles are enabled.
- Node deps: run `npm install`; optional `npm audit fix` to address advisories.

## Scripts

- `npm start` – runs proxy and Flutter app together

## License

This project is for educational purposes. See repository for license details.
