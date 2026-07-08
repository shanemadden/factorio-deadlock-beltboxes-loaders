# Building the Factorio mod zip

Factorio mod archives should be named like this:

```text
deadlock-beltboxes-loaders_2.6.1.zip
```

The zip must contain a single top-level folder with the same name:

```text
deadlock-beltboxes-loaders_2.6.1/
```

## Windows / PowerShell

Run this from the repository root:

```powershell
.\package.ps1
```

It creates:

```text
dist/deadlock-beltboxes-loaders_2.6.1.zip
```

## Linux / macOS / Git Bash

Run this from the repository root:

```bash
chmod +x package.sh
./package.sh
```

It creates:

```text
dist/deadlock-beltboxes-loaders_2.6.1.zip
```

Copy the zip into your Factorio mods folder and start Factorio.
