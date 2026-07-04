## Git Commit

- Before every commit, in addition to using the `commit-message-convention` skill, inspect `git status --short`, `git diff --staged --name-only`, and patch-level diffs when needed. Confirm that the commit contains only changes related to the current task.
- Do not commit unrelated files, temporary files, accidental formatting-only output, build artifacts, or untracked directories by default. If multiple intents exist, split them into separate commits.
- Continue using Conventional Commits. Default to Chinese for commit messages unless the user explicitly asks for English. The subject must state the primary purpose clearly and must not use vague text such as `update`, `fix issue`, or `misc`.
- Prefer concise commit messages by default. Use `subject` only for small or single-purpose changes; add a `body` only when the reason, constraints, risks, or affected scope would otherwise be unclear.
- When a commit body is needed, keep it short and scannable with concrete bullets only. Prefer 1-3 bullets, avoid repeating obvious diff details, and do not include long narratives, process descriptions, or padded explanation.
- Run validation commands that match the scope of the change before committing. At minimum, type checks, tests, or builds affected by the change must be reasonably accounted for in the current context.
- If the repository provides a commit message lint script, run it before `git commit`.
