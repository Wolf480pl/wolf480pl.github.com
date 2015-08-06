---
layout: neon-post
title: Taming SecureBoot on Prometheus
categories: prometheus setup
---
As I said in the previous post, Prometheus came with Win8, which means it has UEFI with SecureBoot enabled by default. It means it will refuse to boot anything it doesn't trust, like a linux installation liveCD/liveUSB.

### Why SecureBoot is not evil

Many people would just shout "SecureBoot is evil, just turn it off ASAP" or something. I disagree.

SecureBoot is meant to allow booting only *trusted* things. And this is actually a good thing. It can (hopefully) prevent bootkits and evil maids from succesfully attacking you.

The problem is what it treats as *trusted*. You can change that by [replacing the SecureBoot keys][own-your-uefi], which I will do one day. I don't feel like doing it right now, so I'll just use Linux Foundation's [PreLoader]. It's an EFI executable that allows the user to *interactively* decide what executables he/she trusts, in addition to ones already trusted by UEFI. Linux Foundation [went through the process][preloader-sign-effort] of getting the PreLoader signed by Microsoft, which allows it to run on any Win8 SecureBoot PC.

### Booting with PreLoader

PreLoader is actually part of [`efitools`][efitools]. `efitools` contains many useful EFI executables, two of which got signed by Microsoft: `PreLoader.efi` and `HashTool.efi`. `HashTool` is used by `PreLoader` to *interactively* ask you to put a hash of an executable in the `MokList`. The `PreLoader` allows booting executables whose hash is in the `MokList` even if SecureBoot wouldn't normally allow it.

I downloaded the MS-signed `PreLoader` and `HashTool`, and grabbed the source of `efitools` from git in case I need any of the other tools. I thought `KeyTool` may be useful in the future (for [replacing the MS keys in UEFI][own-your-uefi]), so I built it. There are also some linux executables in `efitools`, I needed one of them: `hash-to-efi-sig-list`.

What's `hash-to-efi-sig-list`? UEFI, `PreLoader`, `HashTool`, etc. often need to calculate hashes of EFI executables. But they don't use a regular SHA256 of the whole file. They use SHA256, but skip some parts of the executable (notably the digital signatures area, so that they don't go in circles because hash needs to include signature which needs to include hash which...). The `hash-to-efi-sig-list` program can be used to hash any EFI file this way, and display the hash.

So I took an relatively empty, FAT partitioned USB stick, made an `/EFI/BOOT` directory on it, and put the `HashTool.efi` on it, and `PreLoader.efi` renamed to `bootx64.efi` (which is what UEFI expects when looking for a bootloader). PreLoader will try to execute `loader.efi` (and start `HashTool` if neither SecureBoot nor MokList trust `loader.efi`), so I need to put some executable with that name next to `PreLoader`. I decided to use `KeyTool` for that purpose, because it has an 'Execute Binary' menu option with a file picker dialog, which will allow me to choose anything I want to run.

I plugged the USB stick to Prometheus, powered it up, pressed F10 so that the boot selection menu shows up, and chose the USB stick. `PreLoader` failed to start `loader.efi`, so it launched `HashTool`. I chose `loader.efi` with `HashTool`, it showed me its hash and asked if I really want to add it to `MokList`. I hashed a copy of `KeyTool.efi` on my other PC with `hash-to-efi-sig-list`, made sure the two hashes match, and chose chose 'Yes'.

NOTE: `hash-to-efi-sig-list` also saves the hash in some EFI format in a file provided as the second argument. If you just want to see the hexadecimal value of the hash, and don't need the file, do something like `./hash-to-efi-sig-list SomeFile.efi /dev/null`.

Now I can execute any EFI executable I want, whith SecureBoot enabled, by enrolling its hash with `HashTool` and executing it with `KeyTool`'s 'Execute Binary' dialog. Yay!

### Wrong hash WTF?!?!!?!

I had problem with some binaries - the `HashTool` would show a completely different hash than `hash-to-efi-sig-list`. Was I under attack?

No.

Apparently, `efitools` before v1.5.2 had a bug in its EFI executable hashing routines, which would produce incorrect hashes if the binary wasn't aligned to 4096 byte blocks, or something like that. The `PreLoader.efi` and `HashTool.efi` signed by MS are from one of those old versions with the [bug] - they produce and expect incorrectly calculated hashes. Now when I was to compile the source, I checked out git tag of latest release, which was v1.5.3, so the `hash-to-efi-sig-list` used the fixed version of the hashing procedure. No surprise the hashes were different. So I checked out v1.5.1 (latest that still has the bug) in a separate working directory, built `hash-to-efi-sig-list` from it, and used it to calculate the hash. It matched with the one from `HashTool`, and everything worked ok.

### Booting Archiso

[ArchLinux] happens to be my distro of choice, so as soon as I downloaded, verified and burned the latest Arch installation ISO, I tried booting Prometheus from it. The live DVD has `PreLoader` and `HashTool` included, but it uses gummiboot as bootloader, so not only the `loader.efi`'s hash needs to be enrolled in `HashTool`, but also hashes of anything gumiboot launches, including Linux kernel image, and - in case you want to use it - EFI shell.

In my case, for some reason, HashTool only saw the /EFI directory of the Archiso live DVD and its subdirectories. I thought this was gonna be an issue, because on Archiso the kernels are in the /arch/boot directory, but fortunately, gummiboot copies them to the /EFI directory prior to executing... or something... I don't know how it exactly happens on a read-only medium, but that's what it looked like, IIRC. Oh, and some (maybe all) of these binaries on the live DVD trigger that hashing bug above.

Anyway, it works, Archiso is able to boot with SecureBoot enabled!

[own-your-uefi]: #
[PreLoader]: #
[preloader-sign-effort]: #
[efitools]: #
[bug]: #
[ArchLinux]: #
