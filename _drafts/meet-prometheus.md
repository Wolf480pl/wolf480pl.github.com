---
layout: neon-post
title: Meet Prometheus
categories: prometheus
---
A couple months ago I bought myself a <b>Medion Erazer X7827 laptop</b> (btw. it's a huge beast). I'm gonna call it <b>Prometheus</b>. It's pretty powerful - Core i7 4710MQ Haswell unaffected by [EU power limitation][ecodesign] (no 'U' suffix), 16 GiB RAM, both SSD and 1TB HDD. It came with Win8 installed out of the box.

![erazer back][erazer-back]

As for external IO, it has 3x USB 3.0, 2x USB 2.0, SD card slot, 4 audio jacks, Ethernet, HDMI, VGA, Mini DisplayPort, and obviously a power jack. No ExpressCard, FireWire, or other connectors that are useful only for [DMA attacks][dma-attack].

![erazer connectors back][sockets-b]
![erazer connectors left][sockets-l]
![erazer connectors right][sockets-r]

It has German keyboard layout (QWERTZ), and it came with a set of stickers for converting the keyboard to regular QWERTY. The thing is, the keyboard backlight shines through the captions on the keys, and when you put a sticker on a key, the light can't get through anymore. The differences between the layouts are not too big, though, and I barely look at the captions anyway, so I decided not to use the stickers. I made a few exceptions though:

* delete and insert have very similar names in German, so I put a sticker on the delete key to be able to tell which one is which one
* the tilde key (not a tilda at all in QWERTZ) had a lot of empty space next to the caption, so I managed to put a sticker there without covering the caption
* the plus and minus keys (again, in QWERTZ they're sth totally different) are next to each other and I don't remember which is which, so I put a sticker on the minus key, and managed not to cover the original caption, like with the tilde

The most annoying thing, though, is that there was no space for a nav block, and instead of putting it somewhere near the arrows (like on my netbook) they put it all the way above the numpad:

![erazer keyboard][erazer-kb]

Other than that, it had some problems with optical drive, and I was thinking of getting it fixed on warranty, so I decided to wait before installing Linux on it. I just set the hostname to *prometheus* and the wallpaper to [one depicting the Prometheus ship][wallpaper] from [Stargate], randomly found on Google. Oh, and I made Windows [keep RTC clock in UTC][win-hwclock-utc] <small>(and [disabled Windows Time Service][win-ntp-off] cause I've heard it likes to mess things up)</small>.

### Optical drive issues

The laptop had a BlueRay/DVD-RW combo drive. BlueRay drives usually can read CDs and DVDs, too. This one did... sort of. It couldn't read ones recorded with high speeds, i.e. most of the discs I burned myself. Had no problems with factory-recorded discs, though. It also couldn't burn DVDs or CDs - it'd fail with IO Error before even starting.

It has a 1 year warranty, so I thought maybe I'd send it back to the shop so that they fix the drive and then send the laptop back, but... shipping takes a long time. Called them, and they said I can replace the drive myself w/o voiding the warranty, and there's just one screw holding it, which isn't sealed. <small>(There's just one warranty seal on a screw which holds the motherboard, so that the user is free to open the cover and eg. remove dust from the fan, etc.)</small> I went to a local computer store, bought a laptop DVD burner, and got the old drive replaced with the new one. It works great so far, and I don't mind it not being a BlueRay drive, because I don't have any BlueRay discs anyway.

### What's next

Now that I know I'm not gonna be sending Prometheus for any warranty repairs soon, it's time to install some Linux distro on it. But that requires taming SecureBoot, which the next post is gonna be about.

![erazer front][erazer-front]

### Full spec

```
Medion Erazer X7827
CPU: Intel Core i7-4710MQ @ 4 x 2.5-3.5 GHz Hyper-Threading
RAM: 16 GiB (4 x 4 GiB)
integrated GPU: Intel HD Graphics 4600
discrete GPU: NVidia GeForce GTX 870M (GK104), 3 GiB GDDR5
Display: ~17 inch, 1600x900
Storage: 60 GB SSD + 1 TB HDD, both connected via 6Gb/s SATA
Soundcard: Realtek ALC892 a.k.a. Intel HD Audio
Ethernet: Qualcomm Atheros Killer E220x Gigabit Ethernet Controller
Webcam: some Acer integrated webcam - USB ID: 5986:055c
802.11 ac/a/b/g/n, Bluetooth 4.0
```

<small>NOTE: If the photos looks like they travelled in time, then, well, they did... kinda... it just took me a long time (2 months) to write and publish this post, and the photos are a later addition, ok?</small>

[ecodesign]: http://www.eceee.org/ecodesign/products/personal_computers/
[dma-attack]: https://en.wikipedia.org/wiki/DMA_attack
[wallpaper]: http://images.forwallpaper.com/files/images/5/5938/5938029b/703563/wallpaper-space-stargate-atlantis-desktop-wallfreak-wallpapers-television-sandbox-prometheus-images-shows.jpg
[Stargate]: https://en.wikipedia.org/wiki/Stargate
[win-hwclock-utc]: https://wiki.archlinux.org/index.php/Time#UTC_in_Windows
[win-ntp-off]: http://superuser.com/questions/494432/force-windows-8-to-use-utc-when-dealing-with-bios-clock/552275#552275
[erazer-back]: {{ "/assets/att/erazer/back-0-512.jpg" |prepend: site.baseurl }}
[sockets-b]: {{ "/assets/att/erazer/sockets-b-0-512.jpg" |prepend: site.baseurl }}
[sockets-l]: {{ "/assets/att/erazer/sockets-l-0-512.jpg" |prepend: site.baseurl }}
[sockets-r]: {{ "/assets/att/erazer/sockets-r-0-512.jpg" |prepend: site.baseurl }}
[erazer-kb]: {{ "/assets/att/erazer/keyboard-hl-512.jpg" |prepend: site.baseurl }}
[erazer-front]: {{ "/assets/att/erazer/front-0-512.jpg" |prepend: site.baseurl }}
