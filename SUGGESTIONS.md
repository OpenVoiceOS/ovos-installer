Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Keep compatibility report permission tests portable.

# Follow-up

The compatibility pin deliberately preserves older Mac targets and therefore needs selected fixes maintained separately. Align the wizard’s Mac choices with a reviewed upstream support matrix when the project is ready, then retire this backport. Impact: fewer independent installer paths to test. See [supported systems](docs/supported-systems.md).

Use Python permission inspection in future report fixtures to avoid GNU/BSD stat flag differences; the [report regression](tests/bats/error_report.bats) demonstrates private and non-private cases.
