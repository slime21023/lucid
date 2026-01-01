# Testing & Coverage

## Run Tests

```bash
crystal spec
```

## Generate Coverage Report (Reachability Proxy)

This project uses `crystal tool unreachable` as a method-level reachability report (a coverage proxy).

Linux/macOS (bash):

```bash
bash scripts/coverage.sh
```

Windows (PowerShell):

```powershell
powershell -File scripts/coverage.ps1
```

Outputs in `coverage/`:

- `coverage/coverage.json` (codecov format)
- `coverage/unreachable.csv` (method hit counts)
- `coverage/summary.txt` (summary)

## CI

GitHub Actions generates and uploads `coverage/` as an artifact via `.github/workflows/ci.yml`.
