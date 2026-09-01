#Requires AutoHotkey v2.0
#SingleInstance Force

if A_Args.Length = 1 && A_Args[1] = "--check" {
    FileAppend "macos-shortcuts: ok`n", "*"
    ExitApp
}

; Left Alt is the macOS Command position. Right Alt remains an unmodified escape
; hatch for native Windows and application shortcuts such as NVIDIA Alt-Z.

#HotIf WinActive("ahk_exe wezterm-gui.exe")
<!c::Send "^+c"
<!v::Send "^+v"
<!t::Send "^+t"
<!+t::Send "^+t"
<!w::Send "^+w"
<!1::Send "^+1"
<!2::Send "^+2"
<!3::Send "^+3"
<!4::Send "^+4"
<!5::Send "^+5"
<!6::Send "^+6"
<!7::Send "^+7"
<!8::Send "^+8"
<!9::Send "{F17}"
<!Backspace::Send "^w"
<!Delete::Send "^{Delete}"
<!=::Send "^="
<!-::Send "^-"
<!0::Send "^0"
<!f::Send "^+f"
<!n::Send "^+n"
<!r::Send "^+r"
<!a::Send "^a"
<!q::Send "{F13}"
<!\::Send "{F14}"
<!+\::Send "{F15}"
<!+w::Send "{F16}"
<!+[::Send "{F18}"
<!+]::Send "{F19}"
<!h::Send "^+{Left}"
<!j::Send "^+{Down}"
<!k::Send "^+{Up}"
<!l::Send "^+{Right}"

; A terminal has no application-level undo stack. Passing Alt-Z through avoids
; turning it into Ctrl-Z, which suspends the foreground shell or TUI process.
#HotIf !WinActive("ahk_exe wezterm-gui.exe")
<!c::Send "^c"
<!v::Send "^v"
<!a::Send "^a"
<!k::Send "^k"
<!z::Send "^z"
<!+z::Send "^+z"
<!t::Send "^t"
<!+t::Send "^+t"
<!w::Send "^w"
<!q::Send "!{F4}"
<!1::Send "^1"
<!2::Send "^2"
<!3::Send "^3"
<!4::Send "^4"
<!5::Send "^5"
<!6::Send "^6"
<!7::Send "^7"
<!8::Send "^8"
<!9::Send "^9"
<!=::Send "^="
<!-::Send "^-"
<!0::Send "^0"
<!s::Send "^s"
<!r::Send "^r"
<!x::Send "^x"
<!f::Send "^f"
<!l::Send "^l"
<!n::Send "^n"
<!+n::Send "^+n"
<!o::Send "^o"
<!p::Send "^p"
<!+[::Send "^+{Tab}"
<!+]::Send "^{Tab}"

#HotIf

; Word movement replaces the Windows Ctrl-arrow convention, freeing physical
; Left Ctrl-arrow for macOS-style virtual desktop switching.
<!Left::Send "^{Left}"
<!Right::Send "^{Right}"
<!+Left::Send "^+{Left}"
<!+Right::Send "^+{Right}"

#HotIf !WinActive("ahk_exe wezterm-gui.exe")
<!Backspace::Send "^{Backspace}"
#HotIf

; These are deliberately exact Left Alt chords; no wildcard mapping should
; broaden them to NVIDIA's Alt-F1/Alt-R or another application's Alt namespace.
<!+3::SendAfterScreenshotChordReleased("3", "#{PrintScreen}")
<!+4::SendAfterScreenshotChordReleased("4", "#+s")
<!+5::RunAfterScreenshotChordReleased("5", "snippingtool.exe")

SendAfterScreenshotChordReleased(triggerKey, keys) {
    WaitForScreenshotChordRelease triggerKey
    Send keys
}

RunAfterScreenshotChordReleased(triggerKey, target) {
    WaitForScreenshotChordRelease triggerKey
    Run target
}

WaitForScreenshotChordRelease(triggerKey) {
    ; Sending Win while the source Alt-Shift chord is still held can form the
    ; Windows Office-key chord and open Microsoft 365.
    KeyWait "LAlt"
    KeyWait "LShift"
    KeyWait triggerKey
}

; Right Ctrl remains raw for applications that use Ctrl-Space or Ctrl-arrow.
$<^Space::Send "#{Space}"
$<^Left::Send "#^{Left}"
$<^Right::Send "#^{Right}"
