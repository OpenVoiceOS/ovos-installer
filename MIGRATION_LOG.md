# OVOS Installer Migration Log

## Plan (stored before migration)

0) **Pre-step: Remove deprecated GUI (ovos-gui)**
- Set `ovos_installer_feature_gui` default **false**.
- Remove GUI options from the TUI.
- Remove GUI tasks/templates/services/requirements and GUI docker compose files.
- Remove GUI blocks from `mycroft.conf.j2`.
- Keep telemetry field but report **false**.
- Update README.
- **Context dump** in this log.

1) **Prep & logging**
- Keep this file updated with guardrails and milestones.
- **Context dump** after creation.

2) **Phase 1 – Low-coupling splits**
- Extract: `ovos_timezone`, `ovos_telemetry`, `ovos_storage_tuning`.
- Update wrapper `ovos_installer`.
- Run `ansible-lint` + idempotence check.
- **Context dump**.

3) **Phase 2 – Services & sound foundation**
- Extract: `ovos_services` (systemd/handlers), `ovos_sound`, `ovos_audio_tuning`.
- Update wrapper ordering.
- Test + **context dump**.

4) **Phase 3 – Core runtime**
- Extract: `ovos_python`, `ovos_config`.
- Test + **context dump**.

5) **Phase 4 – Performance & network**
- Extract: `ovos_performance_tuning`, `ovos_network_tuning`.
- Test + **context dump**.

6) **Phase 5 – Cleanup & polish**
- Tighten wrapper variable mapping.
- Add tags per role.
- Update docs with final role map.
- Test + **context dump**.

7) **Phase 6 – Mark1/Mark2 modernization (no legacy)**
- Update mark1/mark2 to depend on new roles directly.
- Replace legacy vars with canonical ones.
- Validate + **context dump**.

**Standards enforced in every phase**
- Modular roles (single responsibility).
- Ansible best practices (modules over shell, idempotence, handlers, safe defaults).
- CodeRabbit-friendly patterns (guarded vars, clear `changed_when/failed_when`, consistent naming).

---

## Phase 0 progress (deprecated GUI removal)

**Status:** completed

**Changes applied**
- Set `ovos_installer_feature_gui` default to `false`; TUI forces `FEATURE_GUI=false`.
- Removed GUI from TUI options/locales and scenario feature parsing.
- Removed GUI tasks/templates/services/requirements in both virtualenv and docker flows.
- Deleted GUI scenario files and removed `gui:` from remaining scenarios.
- Removed GUI blocks from `mycroft.conf.j2` and GUI references in README.
- Kept telemetry schema field `gui_feature` but it now reports `false` by default.

**Notes**
- Telemetry behavior left intact (no functional change beyond `gui_feature` default).
- No remaining `ovos-gui` references outside this log and telemetry schema.

---

## Phase 1 progress (low-coupling splits)

**Status:** completed

**Changes applied**
- Created new roles:
  - `ovos_timezone` (timezone detection + system timezone).
  - `ovos_telemetry` (telemetry submission + template).
  - `ovos_storage_tuning` (fstab/log2ram/tmpfs/Mycroft state tmpfs).
- Updated `ovos_installer` wrapper:
  - `tasks/main.yml` now imports `ovos_timezone` and `ovos_telemetry`.
  - `tasks/tuning/main.yml` now imports `ovos_storage_tuning`.
- Moved `telemetry.json.j2` into `ovos_telemetry/templates` and updated docs link.

**Notes**
- Handlers moved in Phase 2 to `ovos_services` to keep role-scoped ownership.

---

## Phase 2 progress (services & sound foundation)

**Status:** completed

**Changes applied**
- Created new roles:
  - `ovos_services` (systemd unit management + all handlers).
  - `ovos_sound` (sound server detection/installation).
  - `ovos_audio_tuning` (audio tuning tasks).
- Updated `ovos_installer` wrapper:
  - `tasks/main.yml` now imports `ovos_sound` and `ovos_services` (virtualenv/cleaning only).
  - `tasks/tuning/main.yml` now imports `ovos_audio_tuning`.
- Moved `virtualenv/systemd.yml` into `ovos_services` and removed old include.
- Moved handlers (`handlers/main.yml`, `handlers/block-sound.yml`) into `ovos_services`.
- Moved systemd unit templates + wrapper into `ovos_services/templates/virtualenv`.

**Notes**
- Handler names preserved for compatibility across roles.

---

## Phase 3 progress (core runtime)

**Status:** completed

**Changes applied**
- Created new roles:
  - `ovos_python` (mimalloc + Python optimization tuning).
  - `ovos_config` (config/geoip defaults + mycroft.conf generation).
- Updated `ovos_installer` wrapper:
  - `tasks/main.yml` now imports `ovos_config`.
  - `tasks/tuning/main.yml` now imports `ovos_python`.
- Moved `mycroft.conf.j2` into `ovos_config/templates`.

**Notes**
- `ovos_installer_configuration` is still set by `ovos_config` and consumed by services.

---

## Phase 4 progress (performance & network)

**Status:** completed

**Changes applied**
- Created new roles:
  - `ovos_performance_tuning` (governor, I/O, zram, sysctl, numa, memory, limits).
  - `ovos_network_tuning` (wireless power + DNS caching).
- Updated `tuning/main.yml` to import these roles.
- Moved tuning assets:
  - `cpu-governor.service`, `zram-generator.conf` → `ovos_performance_tuning/files/tuning`.
  - `wlan0-power.service` → `ovos_network_tuning/files/tuning`.

---

## Phase 5 progress (cleanup & polish)

**Status:** completed

**Changes applied**
- Added role tags on wrapper imports for targeted runs.
- Added README role map for the modularized installer.

---

## Phase 6 progress (Mark1/Mark2 modernization)

**Status:** completed

**Changes applied**
- Mark1/Mark2 roles now use the canonical `ovos_installer_boot_directory` fact.
- Boot directory discovery aligns with the shared installer fact name (no role-specific boot vars).

**Notes**
- Hardware roles remain standalone and continue to run before `ovos_installer` in `ansible/site.yml`.

---

## Context dump (post-phase cleanup, uninstall split, tagging, lint)

**Status:** in progress (post-phase hygiene)

**What changed since Phase 6**
- **Uninstall split into dedicated files**:
  - Added `tasks/uninstall.yml` and moved uninstall blocks for:
    - `ovos_audio_tuning`, `ovos_storage_tuning`, `ovos_network_tuning`,
      `ovos_services`, `ovos_sound`, `ovos_python`, `ovos_config`,
      `ovos_performance_tuning`.
  - Each role now imports uninstall tasks from `tasks/main.yml` with:
    - `when: ovos_installer_cleaning | bool`
    - `tags: [uninstall]`
- **Performance tuning cleanup**:
  - Removed use of `ovos_installer_uninstall` inside tuning install tasks.
  - Install tasks always install/apply; uninstall tasks now remove packages,
    sysctls, services, and files explicitly.
  - `ovos_performance_tuning/tasks/uninstall.yml` now removes:
    cpupower packages, governor service, scheduler rules, kernel module
    persistence, dtparam/overclock entries, USB autosuspend override,
    limits, RT/Zero-Swap drop-ins, sysctl overrides (including BBR),
    THP tmpfiles, zram packages + sysctl + config, and flushes handlers.
- **Audio tuning fixes**:
  - Standardized role-prefixed facts for PipeWire/Bluetooth/ALSA detection.
  - Added `ovos_audio_tuning_capture_target` / `playback_target` defaults.
  - Wrapped long Jinja lines in vars blocks to satisfy lint.
  - Fixed `truthy` lint (`"on"` string for amixer).
- **Network tuning uninstall consolidated**:
  - DNS + wireless uninstall steps moved into a single `tasks/uninstall.yml`.
- **Role tagging**:
  - Added role-level tags in `ansible/site.yml` for:
    `ovos_hardware_mark1`, `ovos_hardware_mark2`, `hardware`, `ovos_installer`.
  - Existing role include tags remain in `ovos_installer`.
- **ansible-lint config**:
  - Removed invalid `.ansible-lint` (roles_path not supported in current schema).
  - Added `ansible.cfg` with `[defaults] roles_path = ansible/roles`.
  - `ansible-lint` now passes (warnings only).

**Lint status**
- `ansible-lint` passes with only upstream collection/deprecation warnings.

**Known TODOs**
1) **Split remaining `ovos_installer` tasks into roles**:
   - `ovos_facts`: move `tasks/tuning/facts.yml`.
   - `ovos_virtualenv`: move `tasks/virtualenv/*` (and uninstall).
   - `ovos_containers`: move `tasks/docker/*` (and uninstall).
   - `ovos_finalize`: move `tasks/finalize.yml`.
   - Keep `ovos_installer` as orchestration only.
2) **Add role-level tags for the new roles** once created
   (e.g., `ovos_virtualenv`, `ovos_containers`, `ovos_finalize`, `ovos_facts`).
3) **Update README role map** after the final split.

---

## Phase 7 progress (remaining ovos_installer split)

**Status:** completed

**Changes applied**
- Added new roles:
  - `ovos_facts`: extracted installer facts (boot dir, NetworkManager stat, systemd drop-in paths).
  - `ovos_virtualenv`: moved virtualenv packages/venv/bus tasks + uninstall.
  - `ovos_containers`: moved docker setup/common/composer tasks + uninstall.
  - `ovos_finalize`: moved finalize tasks.
- `ovos_installer/tasks/main.yml` now:
  - imports `ovos_facts` first and maps `ovos_installer_*` facts for shared roles.
  - imports `ovos_containers`, `ovos_virtualenv`, and `ovos_finalize` roles with tags.
- `ovos_installer/tasks/tuning/main.yml` no longer imports `tuning/facts.yml`.
- Moved templates:
  - `templates/virtualenv/*` → `ovos_virtualenv/templates/virtualenv/`
  - `templates/docker/*` → `ovos_containers/templates/docker/`
- Added uninstall files for new roles and removed inline uninstall blocks.
- Updated README role map to include new roles.

**Lint status**
- `ansible-lint` passes (warnings only for upstream collections/deprecations).
