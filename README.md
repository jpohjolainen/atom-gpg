# atom-gpg package

Package to encrypt/decrypt selections with GPG.

## Install

### Dependencies

  - gpg

```bash
$ apm install atom-gpg
```

Or install trough Atom Packages.

## Settings

If you get error message "Failed to spawn command gpg. Make sure gpg is installed and on your PATH" then you need to go to Settings page and set Gpg Executable path.

## Usage

Select text and press ```ctrl-alt-shift-e``` to encrypt or ```ctrl-alt-shift-d``` to decrypt.

Optionally you can also use context menu with right mouse button and select _GPG Encrypt_ or _GPG Decrypt_. Same options can be found under menu __Packages__ -> __GPG__.

Multiple selections are also working.

### Recipients

You need to specify recipients to encryption. You can either specify them on Settings `Gpg recipients` or have `gpg.recipients` file in the same directory or in root of Git repo. User IDs in the file will be appended to recipients
define in the Settings.
