---
layout: neon-post
title: Adventures with installing firefox sync
categories: faris server
tags: firefox sync linux server readonly virtualenv python
---
Yesterday, I decided it's time to finally install [Firefox Sync][fxsync] server on my new VPS, as I got fed up with being unable to send browser tabs across devices. On the old VPS, it used to be just be running from a git checkout under `/home/fxsync/`, the way the [official guide][mozguide] recommends. It's not hard to guess that the daemon was running as the `fxsync` user, the same user that owned (and had write permission to) all the Sync server's files. Not the cleanest solution ever, not to mention security concerns.

### So, this time I decided to do it the right way.

The official way of installing Sync server is to install a few dependencies, clone the repo, and run `make build` in it. `make build` sets up a python virtualenv in the `./local` directory, and does `setup.py develop`, which half-builds the package and egg-links it into site-packages inside the virtualenv. Then to start the server, you run gunicorn from within the virtualenv, and give it the `syncserver.ini` file laying in the main directory of the repo.

I wanted to put the whole virtualenv and the syncserver code in some `root:root` owned, `og-w` place. The right place for things that are contained in a single directory, and contain mixed platform-dependend and platform-independent files, is `/opt`. I also didn't want all the stuff like `MANIFEST.in`, `setup.py`, `README.md` and `.git` to go in there, as it's useless at runtime. To achieve this, I applied made a patch to `Makefile` that looks like this:

```diff
diff --git a/Makefile b/Makefile
index 2efa163..5c87283 100644
--- a/Makefile
+++ b/Makefile
@@ -1,6 +1,6 @@
 SYSTEMPYTHON = `which python2 python | head -n 1`
 VIRTUALENV = virtualenv --python=$(SYSTEMPYTHON)
-ENV = ./local
+ENV = /opt/fxsync
 TOOLS := $(addprefix $(ENV)/bin/,flake8 nosetests)
 
 # Hackety-hack around OSX system python bustage.
@@ -18,10 +18,10 @@ all: build
 
 .PHONY: build
 build: | $(ENV)/COMPLETE
-$(ENV)/COMPLETE: requirements.txt
+$(ENV)/COMPLETE: requirements.txt syncserver/*.py
 	$(VIRTUALENV) --no-site-packages $(ENV)
 	$(INSTALL) -r requirements.txt
-	$(ENV)/bin/python ./setup.py develop
+	$(ENV)/bin/python ./setup.py install
 	touch $(ENV)/COMPLETE
 
 .PHONY: test
```

It does two major changes.

First, it changes `setup.py develop` to `setup.py install`, so that the syncserver's code gets installed into the virtualenv's site-packages instead of being just egg-linked there. This makes it necessary to rerun the build in case one of the source files changes, so I added them to the make target's dependencies.

With that change, the whole webapp is contained within the virtualenv, except for the single `syncserver.ini` file. Now, the second modification changes the virtualenv path to `/opt/fxsync`. This way, `make build` creates the virtualenv in a place we want the syncserver to be installed, and once it's installed, it doesn't depend on the source in the git repo being present.

This has a drawback that the `make build` must be ran as root. Ideally, I'd build the virtualenv as a regular user, and then copy it to the destination, but it has it's location hardcoded in shebangs of all the executable python scripts inside it, and in some other places. Once it's build, moving it into a different location requires `sed`ding through all the files and replacing the path, which I'm too lazy to do at the moment. Alternatively, I could `chown root:root` the whole virtualenv after the fact... maybe I'll do it this way in the future.

### But what about the `syncserver.ini`...?

Well, it's actually a config file. While it has some things like package name of the webapp to run, which it doesn't make sense to change while configuring the Sync server, most of the entries in it are regular config options. Therefore, it belongs in `/etc`. I copied it to `/etc/fxsync.ini`, and then to start the server I run `/opt/fxsync/bin/gunicorn --paste /etc/fxsync.ini` from the systemd unit.

### ...and the mutable state?

I also set the database path to `sqlite:////var/lib/fxsync/syncserver.db`. The `/var/lib/fxsync` directory is owned by `fxsync:fxsync`. By the way, <a rel="friend" href="https://ijestfajnie.pl">Michcioperz</a>, who is running about a dozen of webapps, told me recently that he moved everything to PostgreSQL, so he doesn't have lose sqlite files laying around. I might do the same in the future, would be pretty cool.

All this stuff was scripted with [Ansible], and the role files will soon end up in my [ansible-playbooks] repo. This will be useful in case I have to change VPS providers again, or have to reinstall the VPS for some other reason.

[fxsync]: https://en.wikipedia.org/wiki/Firefox_Sync
[mozguide]: https://docs.services.mozilla.com/howtos/run-sync-1.5.html
[Ansible]: https://www.ansible.com/
[ansible-playbooks]: https://github.com/Wolf480pl/ansible-playbooks/
