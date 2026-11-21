# Well-Being Application

A mobile well-being companion: hydration, sleep and stress tracking, activity screens,
and an AI **well-being coach** chatbot powered by an open LLM on Hugging Face.

| Component | Folder | Tech | Port |
|---|---|---|---|
| Mobile app | `mobileapp/` | Flutter (Android, iOS, web, desktop) | – |
| AI service (chatbot, image captioning, Q&A) | `back-end/` | Spring Boot 4, Java 21, Hugging Face Inference Providers | 8081 |
| Tracking service (users, hydration, sleep, stress) | `waterIntake/` | Spring Boot 4, Java 21, MongoDB | 8082 |
| Database | – | MongoDB 8 | 27017 |

```
Flutter app ──► waterIntake (8082) ──► MongoDB
     │
     └──────► AI service (8081) ──► router.huggingface.co (chat model, e.g. Llama 3.1 8B Instruct)
```

The chatbot sends the conversation plus today's water intake and goal to the AI service,
which adds a well-being coach system prompt and calls a chat model through the
OpenAI-compatible Hugging Face router.

## Prerequisites

- **Docker** with Docker Compose (to run the back-end), or Java 21 + Maven + MongoDB.
- **Flutter** 3.38.4 or newer (tested with Flutter 3.50 / Dart 3.14) and Android Studio
  with an Android emulator.
- A **Hugging Face token** with the *Make calls to Inference Providers* permission:
  <https://huggingface.co/settings/tokens>. The default model
  `meta-llama/Llama-3.1-8B-Instruct` is gated: accept its licence on its Hugging Face page
  with the same account, or pick another chat model with `HF_CHAT_MODEL`.

## Quick start

1. Configure the back-end:

   ```bash
   cp .env.example .env
   ```

   Then edit `.env` and set `HF_TOKEN=hf_...`. Never commit `.env`.

2. Start MongoDB and both services:

   ```bash
   docker compose up --build
   ```

   Check they are up: <http://localhost:8082/actuator/health> and
   <http://localhost:8081/actuator/health>.

3. Run the app on the Android emulator:

   ```bash
   cd mobileapp
   flutter pub get
   flutter run
   ```

   On the emulator the app reaches your computer at `10.0.2.2`, which is the default.

### Other targets

- **Chrome:** `flutter run -d chrome` (uses `localhost`).
- **Physical phone** on the same Wi-Fi as your computer:

  ```bash
  flutter run --dart-define=API_HOST=192.168.1.20
  ```

  Replace the IP with your computer's, and add it to
  `mobileapp/android/app/src/main/res/xml/network_security_config.xml`, since Android
  blocks plain HTTP to other hosts.
- Full URLs can also be set with `--dart-define=HYDRATION_API_URL=...` and
  `--dart-define=AI_API_URL=...` (see `mobileapp/lib/config/api_config.dart`).

## Configuration

AI service (`back-end/src/main/resources/application.properties`):

| Variable | Default | Purpose |
|---|---|---|
| `HF_TOKEN` | *(empty)* | Hugging Face token. Without it the chat answers HTTP 503 with an explanation. |
| `HF_CHAT_MODEL` | `meta-llama/Llama-3.1-8B-Instruct` | Any chat model served by Inference Providers. |
| `HF_CAPTION_MODEL` | `Salesforce/blip-image-captioning-large` | Model for `/api/image-caption`. |
| `HF_QA_MODEL` | `deepset/roberta-base-squad2` | Model for `/api/ask`. |
| `HF_MAX_TOKENS` | `512` | Maximum length of a chat answer. |
| `CORS_ALLOWED_ORIGINS` | `*` | Browser origins allowed (Flutter web). |

Tracking service (`waterIntake/src/main/resources/application.properties`):

| Variable | Default | Purpose |
|---|---|---|
| `MONGODB_URI` | `mongodb://rootuser:rootpass@localhost:27017/waterintake?authSource=admin` | MongoDB connection. |
| `DEMO_USER_ID` | `66036b08fe2d6569e5efbb5c` | User created on startup and used by the app (there is no login back-end yet). |
| `DEMO_USER_NAME` | `Demo User` | Name shown on the home screen, used only when the demo user is first created. |

## API

AI service:

- `POST /api/chat`. Body: `{"messages":[{"role":"user","content":"..."}], "context":"optional facts"}`.
  Returns `{"reply":"...","model":"..."}`. Roles are `user` or `assistant`, and the last
  message must be from the user. Errors use RFC 9457 problem details (`{"detail": "..."}`).
- `POST /api/image-caption` with multipart `file`.
- `POST /api/ask` with body `{"question":"...","context":"..."}`.

Tracking service, users and hydration (amounts in litres, days in UTC):

- `GET /users/{userId}` and `GET /users/{userId}/daily-goal`
- `POST /users/add`
- `POST /waterIntake/logIntake` with body `{"userId":"...","amount":0.25}`
- `GET /waterIntake/daily/{userId}?date=YYYY-MM-DD` (date defaults to today)
- `GET /waterIntake/weeklySummary/{userId}` (Monday to Sunday, 0 for empty days)
- `GET /waterIntake/range/{userId}?startDate=...&endDate=...` (ISO date-times)
- `POST /waterIntake/updateGoal/{userId}` with body `{"newGoal":2.5}`

Tracking service, sleep and stress (the user's local dates and times; one entry per day,
logging again for the same day replaces it; ranges are inclusive and at most 366 days):

- `POST /sleep/log` with body
  `{"userId":"...","bedTime":"2026-11-20T23:15:00","wakeTime":"2026-11-21T07:00:00"}`.
  The night is stored under the wake-up date with its duration in minutes (10 min to 24 h).
- `GET /sleep/{userId}?from=YYYY-MM-DD&to=YYYY-MM-DD`
- `POST /stress/log` with body `{"userId":"...","date":"2026-11-21","level":3,"note":"optional"}`.
  Levels go from 1 (very low) to 5 (very high).
- `GET /stress/{userId}?from=YYYY-MM-DD&to=YYYY-MM-DD`

Errors from the tracking service are RFC 9457 problem details (`{"detail": "..."}`).

## Running without Docker

```bash
cd waterIntake && ./mvnw spring-boot:run
```

```bash
cd back-end && HF_TOKEN=hf_... ./mvnw spring-boot:run
```

The hydration service needs a MongoDB reachable at `MONGODB_URI`.

## Tests

```bash
cd back-end && ./mvnw test
```

```bash
cd waterIntake && ./mvnw test
```

```bash
cd mobileapp && flutter test
```

The `waterIntake` integration test starts MongoDB with Testcontainers and is skipped
when Docker is not available.

## Demos

Screen recordings are in `demos/` and screenshots in `New folder/`.
