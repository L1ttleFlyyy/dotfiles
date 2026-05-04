; xfce4-terminal GtkAccelMap rc-file         -*- scheme -*-
; iTerm2-style keybindings (Cmd via VNC → mod4, bypass GTK virtual modifier)
;
; === Copy / Paste ===
(gtk_accel_path "<Actions>/terminal-window/copy" "<Super>c")
(gtk_accel_path "<Actions>/terminal-window/paste" "<Super>v")
(gtk_accel_path "<Actions>/terminal-window/select-all" "<Super>a")

; === Tab Management ===
(gtk_accel_path "<Actions>/terminal-window/new-tab" "<Super>t")
(gtk_accel_path "<Actions>/terminal-window/close-tab" "<Super>w")
(gtk_accel_path "<Actions>/terminal-window/next-tab" "<Super><Shift>bracketright")
(gtk_accel_path "<Actions>/terminal-window/prev-tab" "<Super><Shift>bracketleft")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-1" "<Super>1")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-2" "<Super>2")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-3" "<Super>3")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-4" "<Super>4")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-5" "<Super>5")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-6" "<Super>6")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-7" "<Super>7")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-8" "<Super>8")
(gtk_accel_path "<Actions>/terminal-window/goto-tab-9" "<Super>9")

; === Window Management ===
(gtk_accel_path "<Actions>/terminal-window/new-window" "<Super>n")
(gtk_accel_path "<Actions>/terminal-window/close-window" "<Super>q")

; === Zoom ===
(gtk_accel_path "<Actions>/terminal-window/zoom-in" "<Super>equal")
(gtk_accel_path "<Actions>/terminal-window/zoom-out" "<Super>minus")
(gtk_accel_path "<Actions>/terminal-window/zoom-reset" "<Super>0")

; === Search ===
(gtk_accel_path "<Actions>/terminal-window/search" "<Super>f")

; === Misc ===
(gtk_accel_path "<Actions>/terminal-window/fullscreen" "F11")
(gtk_accel_path "<Actions>/terminal-window/toggle-menubar" "F10")
