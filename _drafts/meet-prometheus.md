---
layout: neon-post
title: Meet Prometheus
categories: prometheus
---
Last month I bought myself a [Medion Erazer X7827 laptop][spec] (btw. it's a huge beast). I'm gonna call it <b>Prometheus</b>. It's pretty powerful - Core i7 Haswell from before EU power limitation, 16 GiB RAM, both SSD and 1TB HDD. It came with Win8 installed out of the box.

As for external IO, it has 3x USB 3.0, 2x USB 2.0, SD card slot, 4 audio jacks, Ethernet, HDMI, VGA, Mini DisplayPort, and obviously a power jack. No ExpressCard, FireWire, or other connectors that are useful only for [DMA attacks][dma-attack].

It had some problems with optical drive, and I was thinking of getting it fixed on warranty, so I decided to wait before installing Linux on it. I just set the hostname to *prometheus* and the wallpaper to [one depicting the Prometheus ship][wallpaper] from [Stargate], randomly found on Google. Oh, and I made Windows [keep RTC clock in UTC][win-hwclock-utc].

### Optical drive issues

The laptop had a BlueRay/DVD-RW combo drive. BlueRay drives usually can read CDs and DVDs, too. This one did... sort of. It couldn't read ones recorded with high speeds, i.e. most of the discs I burned myself. Had no problems with factory-recorded discs, though. It also couldn't burn DVDs or CDs - it'd fail with IO Error before even starting.

It has a 1 year warranty, so I thought maybe I'd send it back to the shop so that they fix the drive and then send the laptop back, but... shipping takes a long time. Called them, and they said I can replace the drive myself w/o voiding the warranty, and there's just one screw holding it, which isn't sealed. <small>(There's just one warranty seal on a screw which holds the motherboard, so that the user is free to open the cover and eg. remove dust from the fan, etc.)</small> I went to a local computer store, bought a laptop DVD burner, and got the old drive replaced with the new one. It works great so far, and I don't mind it not being a BlueRay drive, because I don't have any BlueRay discs anyway.

### What's next

Now that I know I'm not gonna be sending Prometheus for any warranty repairs soon, it's time to install some Linux distro on it. But that requires taming SecureBoot, which the next post is gonna be about.

[spec]: #
[dma-attack]: #
[wallpaper]: #
[Stargate]: #
[win-hwclock-utc]: #
