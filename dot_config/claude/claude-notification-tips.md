If you are like me running sandboxed(bwrap) claude inside tmux, you might have
noticed that Claude Code's built-in desktop notifications don't work. Here's how
to get Ghostty notifications working so you know when Claude needs your attention.

## What you need

- **Ghostty** as your local terminal (it supports OSC 777 notifications, which
  carry a separate title + body; OSC 9 also works but is body-only)
- **tmux 3.3+** on the remote VM

## Setup

### 1. Enable tmux passthrough

Add to your `~/.tmux.conf` on the remote VM:

```
set -g allow-passthrough on
```

Reload: `tmux source ~/.tmux.conf`

### 2. Create the notification script

Save this as `~/.config/claude/tmux-notify.sh` and `chmod +x` it:

```bash
#!/bin/bash
[ -z "$TMUX" ] && exit 0
read -r input
message=$(echo "$input" | jq -r '.message // "Claude Code"')
pane_tty=$(tmux display-message -p '#{pane_tty}')
# OSC 777: ESC ] 777 ; notify ; <title> ; <body> BEL — title "Claude Code" + body.
tmux run-shell "printf '\\033Ptmux;\\033\\033]777;notify;Claude Code;${message}\\007\\033\\\\' > $pane_tty"
```

Why `tmux run-shell` instead of a simple `printf > /dev/tty`? On some VMs, Claude
runs inside a bwrap sandbox that blocks writes to terminal devices (`/dev/tty`,
`/dev/pts/*`). `tmux run-shell` executes in the tmux server's context — outside
the sandbox — so it can write to the PTY just fine.

### 3. Register the hook in Claude Code settings

Add to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/home/YOUR_USERNAME/.config/claude/tmux-notify.sh"
          }
        ]
      }
    ]
  }
}
```

### 4. [DEPRECATED] Grant sandbox access to PTY devices

**You do NOT need this step.** It's kept here only to explain a dead end.

The theory was that you had to add `/dev/pts` to `allowWrite` in
`~/.claude/apple/sandbox/bwrap.json` so the hook could touch the pane TTY:

```json
{
  "allowWrite": [
    "/dev/pts"
  ]
}
```

**Why it's unnecessary:** bwrap's `allowWrite` only governs *filesystem* paths —
it does not grant character-device node I/O. Verified empirically: even *with*
`/dev/pts` in `allowWrite`, a direct write to the pane PTY from inside the
sandbox still returns `Permission denied`. And nothing in the working setup ever
writes the device from inside the sandbox anyway: `tmux display-message -p
'#{pane_tty}'` only reads a path *string*, and the actual write is done by
`tmux run-shell`, which runs in the (unsandboxed) tmux server. So the grant was
inert. Notifications work with it removed — leave it out.

## When do notifications fire?

The hook has no `matcher`, so it fires on **every** Claude Code notification —
whatever Claude Code decides is worth notifying about. Common triggers include
Claude needing you to approve a tool use, Claude waiting on your input after
being idle, and a subagent needing input or finishing. You don't need to
enumerate or filter the types; they all pass through to your desktop.

## Verify it works

1. Open Claude Code in a tmux pane (over SSH to the VM, as usual).
2. Ask Claude to prompt you for something — e.g. tell it to use its "ask"
   tool to ask you a question, or kick off any action that needs your approval.
3. **Immediately switch window focus to another app.** The OS only raises a
   desktop notification when Ghostty is *unfocused* — if Ghostty stays focused,
   nothing pops up even though the escape sequence fired correctly.

You should see a "Claude Code" desktop notification appear.

## Troubleshooting

- No notification? Add `echo "fired: $?" >> /tmp/claude-notify-trace.txt` to the
  end of the script and check the log.
- `jq` not found? Install it or replace the jq line with:
  `message=$(echo "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','Claude Code'))")`
- Not using Ghostty? Any terminal that supports OSC 777 will work (or OSC 9 for
  a body-only notification — swap `777;notify;Claude Code;${message}` for
  `9;${message}`). Without tmux, a simple
  `printf '\033]777;notify;Claude Code;%s\007' "$message" > /dev/tty` is enough.
