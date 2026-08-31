#!/bin/sh
# UserPromptSubmit hook. Re-injects the unslop Core rules as developer context on every
# turn, because a rule stated once at session start loses to the model's own defensive
# output accumulating in context. Plain stdout becomes developer context; stdin is the
# event JSON and is deliberately ignored.
#
# Single source of truth: the Core section is extracted from the skill, so /unslop and
# this injection can never drift apart.

cat >/dev/null

SKILL="${CODEX_HOME:-$HOME/.codex}/skills/unslop/SKILL.md"
[ -r "$SKILL" ] || exit 0

printf 'Apply the following style contract once when composing the human-facing prose in the final response of this turn:\n'
awk '/^## Core$/{f=1;next} f&&/^## /{exit} f' "$SKILL"
