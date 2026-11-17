# Claude Multi-Account untuk Windows

Jalanin 2 (atau lebih) aplikasi **Claude desktop** sekaligus di satu PC Windows, masing-masing login pakai akun yang beda.

Tiap akun tambahan dapet:

- **Data terpisah**: login, chat, dan setting nggak nyampur sama Claude yang biasa
- **Icon Claude berwarna lain** (hijau, biru, ungu, dst.) biar gampang dibedain
- **Tombol taskbar sendiri**: nggak digabung sama Claude yang biasa
- **Perintah `claude2` buat Claude Code CLI**, juga dengan login dan config terpisah

> Ini proyek komunitas, bukan dari Anthropic. Cuma pakai fitur bawaan Windows dan opsi `--user-data-dir` dari aplikasi Claude. File aplikasi Claude-nya nggak diubah sama sekali.

## Syarat

- Windows 10 atau 11
- Aplikasi [Claude desktop](https://claude.ai/download) udah terpasang, baik versi Microsoft Store maupun installer biasa
- Opsional: [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) kalau mau pakai `claude2` di terminal

## Cara install

1. Download repo ini: klik **Code → Download ZIP**, terus extract.
2. Double-click **`install.cmd`**.
3. Buka **Claude 2** dari Desktop atau Start Menu, terus login pakai akun kedua.

Mau akun ketiga atau warna lain? Buka PowerShell di folder repo, terus jalanin:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1 -Number 3 -Color blue
```

Pilihan warna: `green` (default), `blue`, `purple`, `pink`, `teal`, `yellow`, `red`.

Kalau nggak butuh bagian CLI, tambahin `-NoCli`.

## Yang dipasang

| Apa | Lokasi |
|---|---|
| Shortcut **Claude N** | Desktop dan Start Menu |
| Shortcut **Claude Code N** (terminal) | Desktop |
| Launcher dan icon | `%LOCALAPPDATA%\ClaudeMultiAccount\akunN\` |
| Data aplikasi desktop akun N | `%USERPROFILE%\.claude-desktop-akunN\` |
| Perintah `claudeN` | `%USERPROFILE%\.local\bin\claudeN.cmd` |
| Config Claude Code CLI akun N | `%USERPROFILE%\.claude-akunN\` |

## Cara kerjanya

1. **Akun terpisah.** Aplikasi Claude dibuka pakai `--user-data-dir`, jadi semua datanya (cookie login, chat, setting) disimpan di folder sendiri. Windows nganggep itu aplikasi yang beda, jadi bisa jalan barengan.
2. **Taskbar terpisah.** Taskbar Windows ngegabungin jendela yang punya *AppUserModelID* sama. Launcher kecil `ClaudeN.exe` (di-compile di PC kamu pakai `csc.exe` bawaan .NET Framework) ngasih jendela akun N ID sendiri dan icon berwarna. Launcher ini jalan di background selama Claude N kebuka, lalu otomatis berhenti.
3. **Icon.** Icon resmi dari aplikasi Claude yang terpasang di PC kamu diambil, terus warnanya diputer (hue shift). Repo ini nggak nyimpen file icon atau logo apa pun.
4. **CLI.** `claudeN.cmd` cuma ngeset `CLAUDE_CONFIG_DIR` ke folder lain sebelum jalanin `claude`.

## Tips

- **Selalu buka lewat shortcut berwarna.** Kalau Claude akun N dibuka dengan cara lain, jendelanya bakal gabung lagi sama Claude yang biasa di taskbar.
- **Pin ke taskbar** dari shortcut di Desktop (klik kanan → *Pin to taskbar*), jangan dari jendela yang lagi kebuka.
- Kalau aplikasi Claude update, nggak perlu install ulang. Jalanin `install.ps1` lagi cuma kalau icon atau launcher-nya bermasalah.
- Tab **Code** di aplikasi desktop kemungkinan tetap baca config `~/.claude` yang sama buat semua akun. Kalau mau Claude Code kepisah total, pakai `claudeN` di terminal.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1 -Number 2
```

Ini ngehapus shortcut, launcher, dan perintah `claude2`. Data login dan chat tetap disimpan. Tambahin `-RemoveData` kalau mau ikut hapus datanya juga (nggak bisa dibalikin).

---

### English

Run multiple Claude desktop apps side by side on Windows, each signed in to a different account, with a recolored icon and its own taskbar button. Double-click `install.cmd`, or run `install.ps1 -Number 3 -Color blue` for more accounts. Remove with `uninstall.ps1 -Number N` (add `-RemoveData` to also delete that account's data). Not affiliated with Anthropic.
