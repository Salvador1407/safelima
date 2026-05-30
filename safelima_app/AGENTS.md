# Repository Guidelines

## Project Structure & Module Organization

This is a Python FastAPI backend for the SeaBot API. The entry point is `app/main.py`, which creates database tables and registers routers. Code is organized by responsibility:

- `app/controllers/`: FastAPI routers and endpoint definitions.
- `app/services/`: business logic and integrations, including email, GCS, and message handling.
- `app/repositories/`: database access functions.
- `app/models/`: SQLAlchemy ORM models.
- `app/schemas/`: Pydantic request and response schemas.
- `app/database/`: engine, session, and base database setup.
- `app/security/`: authentication and password/JWT utilities.

Root-level files include `requirements.txt`, `Dockerfile`, and `pruebaBot.py` for manual bot testing.

## Build, Test, and Development Commands

Create and activate a virtual environment before installing dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Run the API locally:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

Build and run the Docker image:

```powershell
docker build -t seabot-backend .
docker run -p 8080:8080 --env-file .env seabot-backend
```

No automated test command is currently defined. Add tests under `tests/` and run with `pytest` once the dependency is added.

## Coding Style & Naming Conventions

Use Python 3.11-compatible code, 4-space indentation, and type hints for new public functions where practical. Keep the existing layered pattern: controllers call services, services call repositories, and repositories own SQLAlchemy queries. Name files by domain and layer, for example `student_controller.py`, `student_service.py`, and `student_repository.py`. Prefer Pydantic schemas for API payloads.

## Testing Guidelines

When adding tests, mirror the app layout under `tests/`, such as `tests/services/test_student_service.py` or `tests/controllers/test_user_controller.py`. Use FastAPI's `TestClient` for endpoint tests and isolate database state with fixtures. Cover repository queries, service rules, and authentication-sensitive routes before changing production behavior.

## Commit & Pull Request Guidelines

Recent history uses short Spanish or English summaries such as `Actualizacion del backend SeaBot` and `Update README.md`. Keep commit subjects concise and imperative, and mention the affected area when useful, for example `Actualiza recuperacion de usuario`.

Pull requests should include a brief description, affected endpoints or modules, test evidence, and required environment variables. For API changes, include example request/response payloads or note backward-incompatible behavior.

## Security & Configuration Tips

Keep secrets and environment-specific values in `.env` or deployment configuration. Review `app/core/config.py` before adding new settings, and document required variables such as database credentials, Google Cloud Storage settings, OpenAI keys, and support email configuration. Do not commit `__pycache__/` files or virtual environments.
