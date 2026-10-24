# Файлы для общего репозитория

Копируются в корень каждого общего репозитория (регламент, разделы 1, 5, 6, 8):

| Файл | Зачем |
|---|---|
| `.github/workflows/pr-check.yml` | запускает общую проверку PR |
| `.github/CODEOWNERS` | владелец репозитория — рецензент каждого PR |
| `.gitattributes` | `.xlsx` и `.pbix` — двоичные, git не пытается их сливать |
| `AGENTS.md`, `CLAUDE.md` | правила для AI-агентов |
| `.githooks/pre-push` | не пускает push в `main`/`Development`, force-push, удаление веток; включить: `git config core.hooksPath .githooks` |
| `.claude/` | хук Claude Code |
| `ПРОВЕРКА.md` | шаблон — владелец заполняет пункты своего репозитория |
