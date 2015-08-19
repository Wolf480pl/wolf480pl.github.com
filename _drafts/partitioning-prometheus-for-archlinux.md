---
layout: neon-post
title: Partitioning Prometheus
categories: prometheus setup
tags: partition gpt lvm luks dm-crypt detached header
---
Now that I've [tamed SecureBoot][tamesb] and can boot Archiso on Prometheus, it's time to set up some partitions where I can install [Arch Linux][arch].

As I said before, the laptop came with Windows 8 preinstalled, and the following partition scheme:

`/dev/sda` - SSD, 62.5 GB, GPT partition table

* `/dev/sda1` - 500 MB - Windows recovery
* `/dev/sda2` - 100 MiB - EFI System Partition
* `/dev/sdb3` - 128 MiB - Windows reserved
* `/dev/sda4` - 1 GiB - "RPC_RP" (???, VFAT, looks like something related to Windows bootloader)
* `/dev/sda5` - 60.5 GB - `C:`

`/dev/sdb` - HDD, 1 TB, MBR partition table

* `/dev/sdb1` - 869 GiB - `D:` "Data" (empty NTFS)
* `/dev/sdb2` - 60.5 GiB - `E:` "Recovery" (NTFS with installers for all OEM-provided drivers and tools, images of some partitions on /dev/sda)

Now, for some reason, I don't feel like wiping Win8. Maybe it's because <del>I wanna try out Win10 once it's out,</del> or maybe I'm afraid one day I'll need to use some windows-only program for school/work/etc. Whatever the reason is, I'll go for dual-boot.

### Move over, you fat Windows!

First of all, on Windows I deleted/uninstalled any useless crap from `C:` that was taking significant amount of space, disabled hibernation (to get rid of the huge `hiberfile.sys`) and configured swap to only use `D:`. Then I shrank `C:` down to 32,9 GiB. There's still some free space on it, but unmovable files of a recovery point (which I'm hesitant to delete) prevent further shrinking. That leaves 24,9 GiB free SSD space for Linux, which is more than enough for my purposes. Then I shrank `D:` to 100 GiB. Unfortunately, Windows can only resize partitions by moving the end, which resulted in the fastest 100 GiB of the HDD occupied by a partiton meant for stuff like music and videos (at least that's my plan). I moved it later, but first...

### Step back MBR, and look at the power of GPT

... but first I decided to boot Archiso and convert the /dev/sdb's partition table to GPT. Because GPT is superior, and I might need more than 4 partitions, etc. (Later it turned out it was a great idea for one more reason.)

So I did a `gdisk /dev/sdb` as the [tutorial][gpttut] says, checked that there's no warnings, printed the in-memory partition table and made sure the partitions begin and end at the same sectors than in the original partition table (printed with `fdisk -l /dev/sdb`), and hit `w`rite. And it worked. The partiton table was GPT, and all the partitions were still visible both under Linux and under Windows.

Now to move the 100GiB NTFS partition...
Ok, so I created a new 100GiB partition (`/dev/sdb3`) with gdisk at the end of the disk, right before the 60,5GiB `/dev/sdb2`. It's partition type in GPT was gdisk's default - "Linux filesystem". Then I copied the old NTFS filesystem from `/dev/sdb1` to the new partition `/dev/sdb3` with `ddrescue`, putting the log on an USB stick (I don't think I really needed the log, but this way, in case of power loss, I could resume the copying instead of starting from scratch). IIRC the copying took like 30-40 minutes. Then I rebooted to Win8 and saw that it still recognizes `/dev/sdb1` as `D:`, and doesn't care about `/dev/sdb3`, most likely because of its type in GPT. Rebooted to Archiso, and changed partition types in GPT: `/dev/sdb1/`'s to "Linux filesystem" and `/dev/sdb3`'s to "Microsoft basic data" (note: they're actually GUIDs, but I reference them by the captions gdisk uses to represent them). Then I rebooted to Win8, and - as expected - it now recognized `/dev/sdb3` as `D:`, and all the files I had put there were still there, and swap seemed to work ok. Finally, I deleted `/dev/sdb1` Dunno if it would've gone this smoothly, if it had been still on MBR partition table.

At that point I had all the space I needed on /dev/sdb for Linux partitions.
On the SSD `/dev/sda` I created a single `/dev/sda6` "Linux filesystem" partition out of all the remaining free space. On the HDD I created a 16 GiB `/dev/sdb1` type "Linux swap" at the beginning of the disk, then 1 GiB `/dev/sdb4` "Linux Reserved" right after swap (why? You'll see later) and then `/dev/sdb5` "Linux filesystem" covering all the free space in the middle. Then I sorted the partition table with gdisk, so that the partition numbers reflect the on-disk order. `sdb4` became `sdb2` ("Linux reserved"), `sdb5` became `sdb3` ("Linux filesystem"), `sdb3` became `sdb4` (windows' `D:`), and `sdb2` became `sdb5` (windows' `E:`). Rebooted to Win8, made sure it still correctly assigns partitions to disk letters, and then rebooted back to Archiso.

I zeroed `sdb2` and `sdb3` with `dd if=/dev/zero of=/dev/sdbX bs=4096` (yeah, my HDD has physical sectors of 4096 bytes, so IO is faster if you read/write a multiple of 4096 bytes). `sdb4` was over 700 GiB, so it took ~2 hours. But I don't wanna risk someone suspecting my free disk space of being some encrypted hidden volume. And what I just said makes sense, because the next thing I did was shrinking `sdb3` to 25 GiB and `sdb2` to 2 MiB. (Actually, for each of them, I had to delete the partition and re-create it with new size, because neither fdisk/gdisk nor the recent versions of parted support a 'rezise' operation.)

### But Wolf, what is your plan?

The plan was to have a LUKS-encrypted root partition on `/dev/sda6` (SSD), and then `/var` and `/home` on LVM on plain dm-crypt on the HDD. But since you can't reliably delete anything from an SSD (because [Flash Translation Layer][ssd-ftl] likes to [hide stuff from you<sup>(section 5.19)</sup>][ssd-issues]), I decided to use a detached LUKS header on the HDD. That's what the 2 MiB `sdb2` is for. Now, I didn't like the idea of offsetting everything by 2 MiB just because LUKS - things look much better when aligned to 1 GiB - so I left a 1022 MiB of unallocated space between `sdb2` and `sdb3`. For `/home` and `/var` I anticipate a need for about 10 GiB and 15 GiB respectively (the latter due to [Docker]), which means a total 25 GiB for the LVM container (yeah, I know I didn't take the LVM metadata into account). I can later expand the container to the free space following it, and allocate the extra extents to whichever logical volume (`/home` or `/var`) needs it.

Oh, and the existing `sda2` EFI System Partition will serve as `/boot`, it has about 74 MiB free, which should be enough for a bootloader and even 2 sets of kernel,initramfs,initramfs-fallback (where initramfs-fallback is an initramfs with all the kernel modules, just in case).

### The step I forgot

I should have filled `sda6` and `sdb3` with random data (eg. by mounting plain dm-crypt with random key on them and zeroing the mapped volume) before proceeding to the next step. This can reveal fs usage patterns. (Actually, it doesn't matter for `sda6` because I `--allow-discards`, and as for `sdb3`, I don't think it's that big of a deal.) I'll try to remember about it the next time I setup a dm-crypt (not too soon, I guess).

### dm-crypt, LVM, mkfs

I did a `cryptsetup benchmark`, and the results (for the ciphers) were:

```
# Algorithm   Key    Encryption [MiB/s]   Decryption [MiB/s]
    aes-cbc   128b        667,8               2928,4
serpent-cbc   128b         90,2                580,4
twofish-cbc   128b        189,0                369,7
    aes-cbc   256b        492,2               2178,7
serpent-cbc   256b         91,7                580,1
twofish-cbc   256b        190,3                369,5
    aes-xts   256b       2517,5               2505,3
serpent-xts   256b        580,3                563,9
twofish-xts   256b        358,7                364,5
    aes-xts   512b       1941,6               1936,3
serpent-xts   512b        582,1                563,9
twofish-xts   512b        359,5                364,1
```

As you can see, AES is much faster than the others on my hardware (probably because it has hardware acceleration on the CPU instruction set level), and XTS ciphers are about 5x faster at encryption than CBC (IIRC CBC can be parallelized only on decryption, not on encryption, so that migh be the reason). Moreover, XTS was [designed with][XTS-wiki] disk encryption in mind, so I decided to go with `aes-xts`. More precisely, `aes-xts-plain64` (apparently XTS [doesn't need ESSIV<sup>(section 5.15)</sup>][xts-no-essiv]). As for key size, XTS actually splits the key in half, cause it needs two keys, so a 512 bit XTS key has strength equivalent to 256 bit symmetric key in other situations. While the strength of 128 bits "practically unbreakable" sounds good, 256 bits "breaking would require all the energy in Solar System" sounds better. So I went with 2x256 = 512 bit XTS key.

First, LUKS header for `sda6`:
`cryptsetup luksFormat -c aes-xts-plain64 -s 512 --use-random --header /dev/sdb2 /dev/sda6`
Then open `sda6`:
`cryptsetup open --type luks --header /dev/sdb2 --allow-discards /dev/sda6 root`
which opens the container as `/dev/mapper/root`.

Why did I use `--allow-discards` ? Aren't discards [bad][discard-bad]? Well, I think disclosing filesystem write patterns on files which are rarely written (like stuff in /usr and /etc), mounted with `relatime` (atime updated only when mtime or friends are uptaded), isn't that big of a deal, and can be sacrifised in order to extend the life of SSD. AFAIK, in case of my rationale for using dm-crypt on `/`, which is making it harder to tamper with the filesystem and protecting plaintext keys (like sshd host keys  in `/etc`), it shouldn't make a difference.

Now, to proceed with `sdb3`, we need a place to store its key, so I made an ext4 fs on `/dev/mapper/root`:
`mkfs.ext4 -L arch-root /dev/mapper/root`
where `-L` sets the label to `arch-root`.

Then, after mounting `/dev/mapper/root` on `/mnt`, I made a random 512 byte key for `sdb3`:
`head -c 512 /dev/random > /mnt/bundle-dm.key`
wait, what? I made it 512 bytes instead of 512 bits? Whatever... it's hashed anyway.
It should've been `head -c 64`, but 512 bytes works too :P

And opened it:
`cryptsetup open --type plain -c aes-xts-plain64 -s 512 --key-file /bundle-dm.key /dev/sdb3 bundle`
and it should appear as `/dev/mapper/bundle`. (don't ask me why `bundle`, I had no other idea for a meaningful name)

Then I created an LVM volume group on it:
`vgcreate --clustered n -s 16M bundlevg /dev/mapper/bundle`
where:

* `--clustered n` explicitely tells LVM that no other computers in a cluster (there's no cluster) will access the same volume (dunno if I really need it)
* `-s 16M` sets the physical extent size to 16 MiB. The default is 4 MiB, and with LVM1 that would limit logical volume size to 256 GiB. LVM2 has no such limit, but the manpage says a large number of extents slows down the LVM tools (but not the IO performance). I thought setting the extent size to 16 MiB would be a good idea, because that would allow me to have 1 TiB in each logical volume even with LVM1, which means the number of extents won't get crazy high. I hope that makes sense.

Then `/var` (i.e. a 15 GiB `/dev/mapper/bundlevg-var` allocated from `bundlevg` volume group)
`lvcreate -L 15G -n var bundlevg`
and `/home` taking the remaining space:
`lvcreate -l 100%FREE -n home bundlevg`

and ext4 filesystems:
`mkfs.ext4 -L var /dev/mapper/bundlevg-var`
`mkfs.ext4 -L home /dev/mapper/bundlevg-home`

Finally, made mountpoints and mounted all the things:
```sh
mkdir /mnt/home
mkdir /mnt/var
mkdir /mnt/boot
mount /dev/mapper/bundlevg-home /mnt/home
mount /dev/mapper/bundlevg-var /mnt/var
mount /dev/sda2 /boot
```

At this point, the filesystems are ready for ArchLinux instllation.

[tamesb]: {{ '/prometheus/setup/2015/08/12/prometheus-secureboot/' | prepend: site.baseur }}
[arch]: https://www.archlinux.org/
[gpttut]: http://www.rodsbooks.com/gdisk/mbr2gpt.html
[ssd-ftl]: https://en.wikipedia.org/wiki/Flash_memory_controller#Flash_Translation_Layer_.28FTL.29_and_Mapping
[ssd-issues]: https://gitlab.com/cryptsetup/cryptsetup/wikis/FrequentlyAskedQuestions#5-security-aspects
[Docker]: https://www.docker.com/
[XTS-wiki]: https://en.wikipedia.org/wiki/Disk_encryption_theory
[xts-no-essiv]: https://gitlab.com/cryptsetup/cryptsetup/wikis/FrequentlyAskedQuestions#5-security-aspects
[discard-bad]: http://asalor.blogspot.de/2011/08/trim-dm-crypt-problems.html
