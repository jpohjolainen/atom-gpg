# atom-gpg package

GPG Encryption for Atom. Encrypts, decrypts and signs selected text.

## Install

### Dependencies

  - gpg

```bash
$ apm install atom-gpg
```

Or install trough Atom Packages.

## Settings

  - **Gpg Executable**

    Path to GPG binary. Defaults to 'gpg'

  - **Gpg Home Dir**

    Path to GPG key directory.

  - **Gpg Recipients**

    Recipient User IDs seperated by comma (,). Add your own User ID here so you can decrypt text.

  - **Gpg Recipients File**

    File of recipient User IDs that are appended to Gpg Recipients. If only filename is given, it's searched from project workdir or same directory as text buffer file is in.

## Usage

Select text and press ```alt-shift-e``` to encrypt, ```alt-shift-d``` to decrypt and ```alt-shift-s``` to sign.
If no text is selected, operations are done on whole buffer.
Note: keymap changed on 0.7.0 from ctrl-shift to alt-shift.

Optionally you can also use context menu with right mouse button and select either _GPG Encrypt_,
_GPG Decrypt_ or _GPG Sign_. Same options can be found under menu __Packages__ -> __GPG__.

You can encrypt, decrypt and sign multiple selections.

NOTE: If Atom fails to find GPG in the PATH, you can set the path to the binary in Settings page!

### Recipients

You need to specify recipients to encryption. You can either specify them in Settings `Gpg recipients` or have `gpg.recipients` (name of the file can be changed in the settings) file in the same directory or in root of Git repo. User IDs in the file will be appended to recipients define in the Settings.

## YAML files

When encrypting secrets in YAML files, atom-gpg will add '|' character and indent the following lines:

![yaml](./yaml-example.png)
