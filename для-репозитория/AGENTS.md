# Правила для AI-агентов (регламент Trest-SZMA)

Файл читают Codex, Cursor, GitHub Copilot, Gemini CLI и другие агенты, поддерживающие `AGENTS.md`.
Claude Code читает его через строку `@AGENTS.md` в `CLAUDE.md`. Регламент целиком:
https://github.com/Trest-SZMA/.github/blob/main/CONTRIBUTING.md

- Ветки: `main` и `Development` — только владелец. Работа — в ветке задачи `<№ issue>-<кратко>` от `Development`.
- Не делать: push в `main`/`Development`, force-push, `--no-verify`, rebase и reset общих веток, слияние PR, удаление веток на GitHub.
- Перед работой: `git fetch`; если `Development` ушёл вперёд — `git merge origin/Development` в ветку задачи.
- Перед PR: пройти `ПРОВЕРКА.md`, таблицу «пункт — результат — число» вставить в PR; PR — в `Development`, `Closes #N`.
- `.pbix` не добавлять (только PBIP); `.xlsx` — только если в issue стоит бронь этого файла.
- Ветки на GitHub удаляет человек кнопкой на сайте; агент только напоминает об этом.
- Push отклонён хуком `pre-push` — не обходить, а сообщить человеку, что именно нужно сделать.
