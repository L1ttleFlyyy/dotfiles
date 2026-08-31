---
name: unslop
description: Rewrite prose once to remove empty language, unsupported rhetoric, vague attribution, and chatbot language while preserving meaning.
disable-model-invocation: true
---

Rewrite the last message, or the message about to be sent, once. Apply these rules only to prose a human will read.

## Core

- Preserve meaning, including facts, conclusions, uncertainty, attribution, and the user's requested tone and format.
- Delete a word, phrase, or sentence when removing it changes no fact, evidence, source, scope, conclusion, or required action.
- Name the source of attributed claims. Mark an inference as an inference. Delete a claim when neither a source nor reasoning supports it.
- Do not invent a foil for `not X but Y`. Use a contrast only when X is already established and rejecting it is necessary.
- Use the number of items the material contains. Use `from X to Y` only when X and Y belong to a meaningful scale or progression.
- Prefer plain words when the replacement preserves technical precision. Keep standard technical terms.
- Delete generic praise, reassurance, greetings, offers to continue, and sign-offs. Delete conclusions that add no concrete result or action. Do not claim information is unavailable unless the missing information limits the answer.
