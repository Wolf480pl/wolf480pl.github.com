---
layout: neon-post
title: Configuring Arch's initramfs for detached LUKS header
categories: prometheus setup
tags: arch linux initramfs luks detached header
---
After [setting up encrypted partitions][partitioning] and [installing][arch-install] [Arch Linux][arch], I relized that Arch's initramfs with the default `encrypt` hook can't mount an encrypted root filesystem with detached LUKS header. I had to modify it for that to work.

First, I looked at the [detached header instructions][wiki-detach] on Arch Wiki - they made a modified version of the `encrypt` mkinitcpio hook that expected the detached header in a file inside initramfs. That didn't work for me, because I have the detached header on a separate partition. (Their solution was meant for carrying a boot partition with initramfs and LUKS header on an USB stick.)

But from there, I could easily adapt the hook to do what I needed to do. It was just a matter of adding a kernel commandline option for specifying the header's location. Here's a diff between the original `encrypt` hook and my adapted `encrypt2`:

```diff
--- /lib/initcpio/hooks/encrypt	2015-06-18 00:58:22.000000000 +0200
+++ /etc/initcpio/hooks/encrypt2	2015-07-11 11:06:37.649509904 +0200
@@ -49,11 +49,18 @@
         echo "Use 'cryptdevice=${root}:root root=/dev/mapper/root' instead."
     }
 
+    local headerFlag=false
     for cryptopt in ${cryptoptions//,/ }; do
         case ${cryptopt} in
             allow-discards)
                 cryptargs="${cryptargs} --allow-discards"
                 ;;
+            header.*)
+                cryptargs="${cryptargs} --header ${cryptopt#header.*}"
+                headerFlag=true
+                ;;
             *)
                 echo "Encryption option '${cryptopt}' not known, ignoring." >&2
                 ;;
@@ -61,7 +68,7 @@
     done
 
     if resolved=$(resolve_device "${cryptdev}" ${rootdelay}); then
-        if cryptsetup isLuks ${resolved} >/dev/null 2>&1; then
+        if $headerFlag || cryptsetup isLuks ${resolved} >/dev/null 2>&1; then
             [ ${DEPRECATED_CRYPT} -eq 1 ] && warn_deprecated
             dopassphrase=1
             # If keyfile exists, try to use that
```

There's also `/etc/initcpio/install/encrypt2`, but it's identical to `/lib/initcpio/install/encrypt`.

To use this hook, enable it  in [mkinitcpio.conf][mkinitcpio] (and disable the old `encrypt` hook in case it was enabled), and add `header./path/to/header` to your cryptsetup options in kernel commandline.

Eg. if - like me -  without detached header you'd have:
`root=/dev/mapper/root rw cryptdevice=/dev/sda6:root:allow-discards`
and you have the detached LUKS header on `/dev/sdb2`, change it to:
`root=/dev/mapper/root rw cryptdevice=/dev/sda6:root:allow-discards,header./dev/sdb2`

My setup is identical, except I used `/dev/disk/by-partuuid/...` instead `/dev/sdXY`, so that it recognizes partitons by their GUID in GPT, and the configuration doesn't become invalid when the disks switch places, or something... not that it's likely to happen on a laptop, but still...

[partitioning]: {{ "http://localhost:4000/prometheus/setup/2015/08/19/partitioning-prometheus-for-archlinux/" | prepend: site.baseurl }}
[arch-install]: https://wiki.archlinux.org/index.php/Installation_guide
[arch]: https://www.archlinux.org/
[wiki-detach]: https://wiki.archlinux.org/index.php/Dm-crypt/Specialties#Modifying_encrypt_hook
[mkinitcpio]: https://wiki.archlinux.org/index.php/Mkinitcpio
