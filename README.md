# herdr-config

My Herdr setup, versioned. The Herdr app home (`~/.config/herdr-app`) is a
deploy target: installers and the app itself write there constantly, so this
repo holds only the parts I author or want pinned, and `scripts/install.sh`
copies them in.

## Layout

`layouts/OBINNA.json` — the one layout I use.

```
sidebar          workspace-chrome / better-sidebar
work
  tabs-row       better-tabs + panel-toggle, buttons: Files · Changes · PRs · CI
  work-body
    main-column
      main       the terminal panes (header: better-changes)
      session-bar  28px git chips
    panel        better-sidebar panel-toggle, 368px
      panel-body (stack, active=changes)
                 files(better-files) · changes(better-changes) · prs(branch-pr) · ci(ci-dash)
  status         workspace-status
```

## Mods

Vendored under `mods/`, not fetched by ref: they came from earlier manual
installs, so no exact commit is recorded. `mods.list.json` names each
upstream and the version that upstream ships today.

| mod | upstream | here | what it does |
|---|---|---|---|
| `better-sidebar` | `munza/herdr-mods` 3.3.0 | 3.3.0 | sidebar lists + footer + panel toggle |
| `better-tabs` | `munza/herdr-mods` 3.0.0 | 3.0.0 | tab bar with the Files/Changes/PRs/CI buttons |
| `better-changes` | `munza/herdr-mods` 2.5.0 | 2.4.0 | changes panel and the pane header |
| `better-files` | `munza/herdr-mods` 1.5.1 | 1.4.0 | files panel |
| `branch-pr` | `munza/herdr-mods` 2.3.0 | 2.3.0 | pull-request panel |
| `ci-dash` | `cybertron288/herdr-mods` | `34e7c33` | GitHub Actions panel |
| `session-bar` | `cybertron288/herdr-mods` | `34e7c33` | 28px git chips under the terminals |

To update a `munza` mod: copy `<name>/mods/<name>/` from upstream over
`mods/<name>/`, then re-run `scripts/install.sh`. `better-changes` and
`better-files` are behind; the run above is the one that has been checked.

### Patches

`overrides/session-bar/main.js` rewires the ✎ and ⚠ chips from the `filetree`
mod (not installed) to `better-changes`. Everything else is upstream.

Shipped Herdr mods (`menu`, `new-menu`, `worktree`, `workspace-chrome`,
`workspace-status`, …) are restored by the app on every start and are not
vendored here.

## Install

```sh
./scripts/install.sh              # mods + layout
./scripts/install.sh --keys       # also deploy keys.json (overwrites live keys)
./scripts/install.sh --settings   # also deploy settings.json (see note)
./scripts/install.sh --dry-run
```

The script backs up anything it overwrites to
`$HERDR_APP_HOME/backups/herdr-config-<timestamp>/`, then runs
`herdr-app check` on every vendored mod and fails on `herdr-app status` errors.

**`settings.json` is not deployed by default.** The committed copy has no
`zoom` (the reset/default value); the live file keeps whatever zoom I set.
Pass `--settings` only when I actually mean to reset it.

## Deliberately absent

`shared.json`, `view.json`, `seen.json`, `window*.json`, `installed.json`,
`data/`, `frame/`, `icons/`, `lib/`, `core/`, `bin/`, `backups/`, `themes/`,
`layouts/.state/`, and every `mods/*/gpui-kit.d.ts` + `jsconfig.json` — all
either app state or files the app rewrites itself.

Other layouts and third-party mods that nothing in `OBINNA.json` references
were removed; see the commit that introduced this repo.

## Third-party installers

Not run from here. `shepherdr`, `flockbook` and `skillshare` each restore their
own mods and keys; if any comes back, it will re-add files this repo does not
track.
