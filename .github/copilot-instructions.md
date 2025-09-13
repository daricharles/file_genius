# FileGenius – AI agent working notes

Purpose: Give AI coding agents the minimal but specific context to work productively in this repo. Keep advice grounded in what’s here today, not aspirational.

## Big picture
- Flutter app (web/desktop/mobile) backed by Firebase Auth, Firestore, and Storage. UI centers on `FileGeniusSidebar` → `MainPane` (+ `FileViewer`) with an optional `DashboardScreen` and `UserProfileScreen`.
- Documents (PDF/DOCX/PPTX/XLSX) are uploaded to Firebase Storage; metadata lives in Firestore under the signed‑in user. An Express proxy (`gemini-proxy.js`) handles Google Generative AI and server‑side text extraction endpoints.
- Learning analytics and gamification are first‑class: user metrics are tracked in `users/{uid}` and mirrored/summarized in `dashboards/{uid}`.

## Data model and Firestore layout
- Folders: `users/{uid}/folders/{folderId}` with fields `{ name, createdAt }`.
- Files (top level): `users/{uid}/files/{fileId}`; Files in folder: `users/{uid}/folders/{folderId}/files/{fileId}`.
- Typical file doc fields: see `lib/models.dart::FileMeta` (`name,size,type,url,uploadedAt,folderId` + optional `extractedText,summary,followUpQuestions,isAnalyzing`). When reading numbers, handle `int` vs `num` per `FileMeta.fromDoc`.
- Dashboard snapshot: `dashboards/{uid}` aggregates counters and analytics (e.g., `filesUploaded, aiChatInteractions, dailyActivity, studyTimeBySubject, weeklyPerformance, totalStudyTime`). Keep these in sync when changing counters.

## Key modules and patterns
- App entry: `lib/main.dart` wires Providers:
  - `FileContentExtractor`, `AIService`, `QuestionSuggestionsService`, and `FileAnalysisOrchestrator` via `Provider/ProxyProvider`.
  - For web: `WebViewPlatform.instance = WebWebViewPlatform()`.
- UI flow: `FileGeniusSidebar` controls navigation; `MainPane` renders list + AI chat; `FileViewer` shows PDFs (Syncfusion) or Office via Google Docs viewer. AI chat is via `widgets/enhanced_ai_chat_widget.dart`.
- Uploading: `_pickFiles()` then `_uploadOne()` writes to Storage and Firestore. After first successful upload, `_startAutoAnalysis()` triggers orchestrated analysis and forces an AI chat rebuild.
- Moving files: there’s no “rename” in Firebase Storage; copy to new path, write a new Firestore doc, delete the old doc + old storage object (see `_moveFile`).
- Realtime updates: listeners on `users/{uid}/folders` and nested `files` keep UI state live; avoid manual list edits except transient cache updates.

## Analytics, achievements, and safety guards
- Analytics counters are incremented in `HomeScreen` handlers: `_onFileUploadSuccess`, `onAIInteractionSuccess`, `onQuizAnswerSubmitted` followed by `_saveUserData()` and `_syncDashboardToFirestore()`; dashboard refresh uses `dashboardKey.currentState?.refreshDashboard()` after a short delay.
- First load guard: don’t write zeros before load completes. Check `_hasLoadedUserData` before saving or syncing.
- Always check `mounted` after `await` before `setState()`; existing code follows this—preserve it.
- Use the helper `_safeSet(ref, data)` for Firestore writes that should log failures.

## Server proxy and extraction
- Node entry: `gemini-proxy.js` (Express on `http://localhost:3000`). Requires `.env` with `GEMINI_API_KEY` in the project root. Endpoints include:
  - `POST /gemini` → forwards to Google Generative Language API.
  - `POST /extract-pdf-text`, `/extract-docx-text`, `/extract-pptx-text`, `/extract-xlsx-text` → fetch file via URL, parse with `officeparser` (and friends), return text.
- Client uses `FileContentExtractor.extractContent(fileUrl, fileType, fileName)` and `extractFromBytes(...)`. If you add a type, update extractor logic and server endpoints accordingly.

## Build, run, and test workflows
- Install Flutter deps and Node deps once; a convenience script runs both:
  - `npm start` → runs `node gemini-proxy.js` and `flutter run -d chrome` concurrently.
- Standalone:
  - Flutter web: `flutter run -d chrome`
  - Proxy: `node gemini-proxy.js` (ensure `.env` with `GEMINI_API_KEY`).
- Tests: Flutter tests live under `test/`. Example present: `test/login_page_test.dart`. Run: `flutter test`.

## Conventions when extending
- New file types:
  - Update `FileContentExtractor.supportsAIAnalysis`, `MainPane` detection, and `FileViewer` render path. For Office‑like formats, prefer web viewer fallback and server extraction.
  - Ensure Storage path + Firestore doc fields match `FileMeta` shape. Avoid breaking streams.
- New counters/analytics:
  - Add fields to `users/{uid}` and ensure `_saveUserData()` and `_syncDashboardToFirestore()` write them. Mirror reads in `DashboardScreen._applyDashboardData` and cache in SharedPreferences.
- AI interactions:
  - Wire `onInteractionSuccess` from `EnhancedAIChatWidget` to `HomeScreen.onAIInteractionSuccess` so points and streaks update consistently.

## Notable settings and assets
- Env: Flutter loads `assets/.env` via `flutter_dotenv`; Node proxy loads `.env` in repo root. Never hardcode secrets in Dart.
- Branding/colors: see `lib/constants.dart` (`kBrand`, `kHover`, text colors) and keep Material 3 theme usage.

If anything here seems off or you’re adding a cross‑cutting feature (e.g., new analysis pipeline), update this file with the concrete path(s), data shapes, and example call sites you touched.