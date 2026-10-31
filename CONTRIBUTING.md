# Contributing

Thanks for helping out!

1. Fork and create a branch from `main`.
2. `git config core.hooksPath .githooks` to enable the secret-scan pre-commit hook.
3. Make your change; keep it focused and match the surrounding style (see `.editorconfig`).
4. Run `swift build -c release` and try the app with `swift run ClaudeBuddy`.
5. Open a pull request describing what and why.

## Ground rules

- Never commit API keys, tokens, certificates, or personal paths/emails.
- Don't add network calls or new data collection without discussing it in an issue first.
- By contributing you agree your work is licensed under the project's [MIT license](LICENSE).
- Be kind: see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
