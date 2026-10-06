# Datasphere Automation

Config driven bash scripts wrapping the SAP Datasphere CLI. Same scripts run
against any tenant (trial, dev, qa, prod) by swapping the config file.

## Design principles

1. **Configuration driven**: no tenant, space, or threshold hardcoded in scripts.
   All in `config/<env>.yaml`.
2. **Environment agnostic**: same script binary, different config per env.
3. **Structured output**: JSON to a samples folder, log to stderr.
4. **Standard exit codes**: 0 clean, 1 warn threshold, 2 crit threshold or CLI
   error. Suitable for cron and CI/CD.
5. **Read only by default**: no script writes to Datasphere without an explicit
   flag.
6. **Idempotent**: safe to rerun; every run writes a timestamped output.
7. **Discovery over enumeration** where possible: script asks the CLI for the
   list, config filters. Trial has 4 spaces, real env may have 30; scripts do
   not care.

## Prerequisites

```
# On WSL Ubuntu (trial) or any Linux/Mac
sudo apt install jq
sudo snap install yq
npm install -g @sap/datasphere-cli
```

Verify:
```
datasphere --version
jq --version
yq --version
```

## First run: login

Interactive OAuth (opens browser once, session cached):
```
cd automation
datasphere config host set --tenant-url https://sapmtds-7.eu10.hcs.cloud.sap
datasphere login -B chrome
```

WSL note: `-B chrome` opens the browser on Windows side. Copy the callback URL
back into the terminal.

## Run space snapshot

```
cd automation
CONFIG=config/trial.yaml ./scripts/ds_space_snapshot.sh
```

Output:
- File: `samples/space_snapshot_trial_<timestamp>.json`
- Stdout: one line summary (env, tenant, space count, total object count)
- Stderr: progress log

## Run task chain status

```
cd automation
CONFIG=config/trial.yaml ./scripts/ds_taskchain_status.sh
```

Output:
- File: `samples/taskchain_status_trial_<timestamp>.json`
- Stdout: one line summary
- Stderr: per space, per window log

Exit code drives cron alert:
```
CONFIG=config/trial.yaml ./scripts/ds_taskchain_status.sh || \
  mail -s "DS task chain alert" ops@example.com < samples/taskchain_status_trial_*.json
```

## Adding a new environment

1. Copy `config/trial.yaml` to `config/dev.yaml`
2. Edit `tenant.host` and `spaces:` list
3. Run: `CONFIG=config/dev.yaml ./scripts/ds_space_snapshot.sh`

No script changes needed.

## Dry run

Set `DRY_RUN=1` to print CLI commands without executing:
```
DRY_RUN=1 CONFIG=config/trial.yaml ./scripts/ds_space_snapshot.sh
```

## Repo layout

```
automation/
  config/
    trial.yaml
  lib/
    common.sh            # config loader, logger, CLI wrapper, exit codes
  scripts/
    ds_space_snapshot.sh
    ds_taskchain_status.sh
  samples/               # timestamped JSON outputs (git ignored)
  README.md
  .gitignore
```

## Known caveats

- **Task chain command name** may vary across CLI versions. If
  `datasphere tasks logs list` fails, run `datasphere tasks --help` and adjust
  the command inside `ds_taskchain_status.sh`.
- **SAC bundled tenants** (like the trial `sapmtds-7`) route API calls through
  the SAC AppRouter and reject direct DWaaS API tokens. CLI works because it
  uses Interactive OAuth. On real environments with standalone Datasphere
  service instances, Technical User OAuth also works; set
  `tenant.auth_mode: technical_user` in the config and export
  `DS_CLIENT_ID`, `DS_CLIENT_SECRET` env vars (secrets never in config file).
- **Secrets**: never commit real credentials. `.gitignore` excludes anything
  matching `*.secret.yaml` and `samples/`.

## Roadmap

Future scripts (same pattern):
- `ds_content_export.sh` weekly backup of all objects per space
- `ds_replication_flow_health.sh` last run status per flow
- `ds_dac_audit.sh` orphan and unmapped user report
