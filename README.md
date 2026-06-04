# Git-Flip (gflip)

**Git-Flip (gflip)** is a simple utility that allows you to easily set and switch between multiple Git profiles, just like `git config`, but managed centrally. 

## 🎯 Problem It Solves

If you work with multiple identities (e.g., personal, work, open-source) and keep accidentally committing with the wrong email, **Git-Flip** provides a simple CLI to manage and switch between them effortlessly.

## ✨ Features

- **Central Profile Database**: Store unlimited Git identities centrally in `~/.gflip/profiles.json`.
- **Instant Switching**: `gflip use <profile> [--local]` applies configs globally or locally.
- **Smart Status Check**: `gflip status` auto-detects your current active profile.
- **Interactive Editing**: `gflip add` and `gflip update` with validation and fallbacks.
- **Tab Completion**: Built-in bash tab completion for profiles and commands.

## 🛠️ Installation

Git-Flip comes with an automated installation script. 

1. Clone or download this repository.
2. Run the `install.sh` script:

```bash
chmod +x install.sh
./install.sh
```

The installer will:
- Create a `~/.gflip` directory.
- Copy `gflip.sh` to `~/.gflip/gflip.sh`.
- Set up bash tab-completion.
- Add the `gflip` alias to your `~/.bashrc`.

3. After installation, reload your bash profile to activate:

```bash
source ~/.bashrc
```

## 🚀 Quick Start & Usage

Once installed, you can use the `gflip` command.

| Command | Description | Example |
| :-- | :-- | :-- |
| `gflip add` or `-a` | Add a new profile interactively | `gflip add` |
| `gflip list` or `-l` | List all saved profiles | `gflip list` |
| `gflip <profile-name>` | View specific profile details | `gflip work` |
| `gflip update <name>` or `-u <name>`| Update an existing profile | `gflip update work` |
| `gflip delete <name>` or `-d <name>`| Remove a profile | `gflip delete oldjob` |
| `gflip use <name> [--local]` | Switch identity (global by default) | `gflip use work --local` |
| `gflip status` or `-s` | Check which profile is active | `gflip status` |
| `gflip uninstall` or `-un` | Uninstall Git-Flip | `gflip uninstall` |
| `gflip help` or `-h` | Show help menu | `gflip help` |

### Examples

**1. Add a Profile**
```bash
gflip add
# Prompts for profile name -> 
# Git User Name -> 
# Git Email -> 
```

**2. List Profiles**
```bash
gflip list
```

**3. Switch Profile Globally**
```bash
gflip use work
```

**4. Switch Profile Locally (Current Repo)**
```bash
gflip use personal --local
```

**5. Check Active Profile**
```bash
gflip status
```

## 🤝 Contributing

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## 📄 License

MIT License
