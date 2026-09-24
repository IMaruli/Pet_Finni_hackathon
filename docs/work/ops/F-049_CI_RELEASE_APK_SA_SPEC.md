# CI/CD: сборка релизного APK в GitHub Actions — системная спецификация (SA)

| Поле | Значение |
|------|----------|
| **ID** | F-049 |
| **Назначение** | Каждый пуш в `main` / `Egor_DevStand` и каждый PR проверяется (analyze + test) и собирает release APK; тег `v*` публикует APK в GitHub Releases |
| **Репозиторий** | `Pet_Finni_hackathon` |
| **Источник** | Запрос Егора 2026-09-24: «настроить CI/CD в GitHub, чтобы сборка релизной APK была там» |
| **Статус** | Реализовано 2026-09-24 |

---

## 1. Workflow `.github/workflows/android-apk.yml`

| Шаг | Что делает |
|-----|------------|
| Триггеры | `push` в `main`, `Egor_DevStand`; `pull_request` в `main`; теги `v*`; ручной запуск (`workflow_dispatch`) |
| Окружение | `ubuntu-latest`, Java 17 (Temurin), Flutter 3.47.5 stable с кешем |
| Проверки | `flutter pub get` → `flutter analyze` → `flutter test` |
| Сборка | `flutter build apk --release --build-number=<номер запуска>` |
| Артефакт | `finni-<версия>-<sha>.apk` в артефактах запуска (хранится 30 дней) |
| Релиз | На тег `v*` — GitHub Release с APK |

## 2. Подпись

По умолчанию — debug-ключ (как локально): APK ставится вручную для демо. Если в секретах репозитория есть `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, workflow создаёт `android/key.properties`, и Gradle подписывает релизным ключом. Ключ и пароли создаёт и добавляет в секреты владелец репозитория; в код они не попадают (`key.properties`, `*.jks` — в `.gitignore`).

## 3. Как пользоваться

- Скачать APK: GitHub → Actions → запуск → Artifacts → `finni-apk`.
- Выпустить релиз: `git tag v1.0.0 && git push origin v1.0.0` → GitHub → Releases.

## 9. Проверка

Первый запуск после пуша — зелёный: analyze без замечаний, 161+ тест, APK в артефактах.
