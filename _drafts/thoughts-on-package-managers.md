---
layout: neon-post
title: Thoughts on package managers
categories: thoughts design
tags: package management python java union filesystem design analysis thoughts
---
These days we deal with many package managers - the system package manager (eg. pacman, dpkg & apt, rpm & yum), and various language specific package managers (eg. pip, npm, maven, gem). Each of them has its own quirks, tradeoffs, and design choices. Many of them have loads of hacks layerd on top to overcome these package managers' limitations. Recently, I had some ideas how all this mess could be avoided.

I don't exactly know how package management is done in node.js and Ruby, so I'll use Python as my example of hacky package management.

Python's package manager is pip, and the most prominent hack on top of pip is virtualenv. There's a nice [blog post][venv-rant] about why virtualenv is a hack and should be only used in developement environment, never for production. I recommend you read it, if you haven't yet, although it won't be necessary for understanding what I'm trying to say here.

### A typical "let's start working on a Python project"

So, let's say we wanna start working on some python project we've just found on github.

```sh
git clone ....someproject.git
cd someproject
pip install -r requirements.txt
```

But wait, that's not gonna work! pip will try to install stuff in `/usr/lib/python3.6/site-packages`, for which you don't have permissions (if you do, you should go see a doctor). This is where system-wide python libraries live, most likely under control of your system package manager, and you probably want to keep them there and keep them separate from your developement stuff, because various distributions often include system utilities written in python which depend on these libraries.

So, you want to install some dependencies somewhere in your home directory, instead of installing them system-wide. The most popular way to do this in the Python land is to create a virtualenv

```sh
virtualenv ~/myVenv
. ~/myVenv/bin/activate
```

Now I could rant about how sourcing the `activate` script is non-Unixish and how it should be a subshell, [this gist][venv-activate-rant] explains it well enough.

Anyway, now you've created yourself a kinda-chroot-but-only-with-python in your home and can proceed installing your dependencies.

`pip install -r requirements.txt`

Even if some of them is already installed in your system-wide site packages, they'll be downloaded and installed again in the virtualenv, because "isolation" and what not. And by the way, this is not real isolation, as explained by the [virtualenv rant I've mentioned before][venv-rant]. But even if it did, why does it have to waste bandwidth for downloading everything again, and disk space for storing it twice?

Now, you might think, it's not that bad - if I just have one venv and use it for everything, I'll end up with at most two copies of every library. Well, no, this won't work.

The thing is, different projects may require different, incompatible versions of the same library, or different implementations of the same python package. (And before you shout "[SemVer] to the rescue!" - good luck getting all the developers to retroactively follow semver to the letter. It's like herding cats.) So, we have version conflicts, and we have to deal with them. The most popular way to do it in the Python land is - you guessed it - more virtualenvs. In the worst case, where everything conflicts with everything else, we end up with one venv per project. And if you want that "isolation" stuff, you probably want one venv per project anyway, to make sure no project is using libraries not listed in its dependencies (in `requirements.txt` or `setup.py`).

But if we have one venv per project anyway, can't we automate the whole process of cloning a repo, creating a venv, entering it and installing dependencies, into one script? Well, what if you have two projects, A and B, in separate repos with A depending on B, and you wanna test if this new experimental change you made in B allows you to do that cool thing you wanted to do in A, without actually pushing it to pypi or something? You'll probably need to put them in a common venv. So, you end up managing venvs by hand anyway.

To sum up virtualenv tries to:
 - allow installing packages in a non-system-wide unpriviledged way
 - prevent libraries not listed as dependencies from being available
 - help in avoiding version conflicts

And creates the following problems:
 - duplication of packages, one copy per project
 - additional manual setup required for each project

### So, how do we fix it?

First, let's notice that every package manager is managing some namespace. In case of system package managers, it's the filesystem namespace, and in case of language-specific package managers - the language's namespace (the namespace of module names in Python, the namespace of fully-qualified class names in Java, etc).

Now, we want any package to be able to put its content anywhere in that namespace. In other words, the final namespace is a union of namespaces of all packages. Which btw. means [`/package`][slashpackage] is no good.

#### Why union the namespaces?

Ok, let's say we decided that packages won't be able to put their stuff all over the namespace, and instead the package manager will enforce that each package is confined to its own subtree. Now, let's say there's a particular API `foo` that has multiple implementations, `fooA` and `fancyFoo`, each done by a different library in a separate package. Then let's say `bar` depends on `foo` API, and was build with `fooA` in mind. Therefore, there are refenrences to the part of namespace that belongs to `fooA` all over its code. Now, you want to install `fancyFoo` instead, as it's made to be a drop-in replacement. Well, `fancyFoo` can't use the same part of the namespace as `fooA`, because it's a different package. And by the way, you might want to have them both installed, and use one or another depending on context. You might say `./configure` should solve this by allowing you to point to the correct location of `foo` implementation. But if we're talking about Python, Java, or similar high-level languages, they don't have `./configure`, and the reference to `foo`'s namespace is all over the code, so it'd be inconvenient (at least) to find/replace all those at install time.
Oh, and if you believe this example is fake, take a look at [SLF4J][slf4j]'s logging bridges. With `/package`-style package management, it wouldn't be possible.

#### How to union?

So we know we want our namespace to be the union of all packages. Well, most existing package managers do exactly that. The thing is, they extract the package contents to the filesystem, and the filesystem (or part of it, eg. the `site-packages` directory) is the single backend for the namespace they're managing. This means, you can't have two packages with colliding namespaces, eg. two implementations of the same python module. This leads to all the duplication I mentioned earlier when complaining about virtualenv.

The other way to do it is to make the union at runtime, and store each package's contents separately. This means, whenever a namespace lookup happens, the runtime will search the requested path in all packages on some list, and the first match wins. This is essentially what a [union mount][union-mount] does for a filesystem (we've had in in Plan9, and we have it in Linux by means of `overlayfs`).

Oh, and the list should be per-process or something, so that you can run different programs in different namespaces.

#### What to union?

One more question we need to answer is: where do we put all those packages that we wanna union?

Well, you could put them anywhere. But you probably want some system-wide location to store ones that are required by system-wide-installed programs. And you probably want some cache of them in your home directory, for all your developement needs.

By the way, you should have some convention of naming those packages - it should involve the package name, the exact version, possibly the author name, and anything it takes to make sure that package names are unique. Ideally, if two packages have the same name, they should be bit-to-bit identical. To be hones, using cryptographic hash of the package content as the name wouldn't be that bad of an idea, provided that no human ever has to look through these packages manually.

What's important is that whatever naming convention you chose, it's orthogonal to what the package puts in the namespace.

### How does this solve our problems?

Let's look again at the problems I've mentioned `virtualenv` tries to solve.

The first one was about installing packages as an unpriviledged user. Well, you just download them into your cache in your home directory, put them on the list of packages for the programs you run, and done - every program you run sees them, and other users' programs are unaffected.

The second one was "isolation", i.e. preventing non-listed libraries from appearing in the namespace. Well, if you have per-process list of packages to include in the namespace, you can put in there only packages listed as dependencies, and no other package will sneak in just by means of laying somewhere on disk.

The third thing was avoiding version conflicts. Provided that you can store the conflicting packages separately (they should have different filenames, and even if they don't, you can put them indifferent directories or something...), you can put either of them on the to-include-in-namespace list depending on what you're trying to run. It's not a problem to have multiple versions of the same library stored on disk, and using different versions in different projects.

So we've solved all the problems virtualenv tries to solve, but what about the issues it introduces?

Package duplication? We don't have any. You can have some packages in your system-wide area, other ones in your home directory, and even some in the project directory, and you can gather them up in one nice list of things to put in the namespace. No need to copy them all into a single location. And with sane cache and naming convention, you'll be able to reuse packages that you've already downloaded for some other project.

And what about the manual setup? Well, instead of this:
```sh
git clone ....someproject.git
cd someproject
virtualenv ~/myVenv
. ~/myVent/bin/activate
python setup.py test
```

You could just do this:
```sh
git clone ....someproject.git
cd someproject
python setup.py test
```

And `setup.py` would find the package cache in your home directory (eg. something like`~/.python-package-cache`), see if the required packages are already there, download ones that are missing, put them on the namespaces-to-union list, and proceed launching the tests.

### How Java and Maven have been doing this for ages

Sigh... yeah. This is nothing new.

Java has `CLASSPATH`, which is its list of packages to put in the union namespace, and maven does exactly what I said `setup.py` should do - you run `mvn test` or whatever, and it checks if all deps are in `~/.m2/repository`, downloads the missing ones, puts them all on `CLASSPATH`, and proceeds running the tests or whatever you asked it to do. And you could probably easily adapt it to also look for packages in `/usr/share/java/m2/` or whatever. And its cache has the naming convention of `$groupId/$artifactId/$version/%groupId-$artifactId-$version.jar`, which might be a bit overkill, but nicely separates different versions/forks/implementations of the same package.

Honestly, people, you could look around at how others have solved their problems before inventing your own hacky solutions.

### Eggs, and how Python apparently can do it too

Python has `sys.path` which does pretty much what `CLASSPATH` does in Java. Except that nobody uses `sys.path`. Or maybe...?

Remember how I suggested this series of commands:
```sh
git clone ....someproject.git
cd someproject
python setup.py test
```
should just work? Well, I've seen it happen. `setup.py` (or whatever it is that it's calling) downloaded some libraries I had in `requirements.txt` but not in my venv, put them as eggs in some `.something` subdirectory in the project directory, and added them to `sys.path` before running the tests.

Each egg is a directory or zip named after the package name and version. It contains stuff the package would want to be put in site-packages, i.e. in the python namespace. This is essentially how JARs work in Java, and how I've just described package management should work.

If this is the case, then why the heck are we still using virtualenv? I hope some Python guru will come to me and explain it, because honestly, I have no idea.

### How to do this with system package manager

I've had this idea in mind for quite a while.

1. When building a package, package the contents into a squashfs instead of a tar.
2. Put the packages on some writable partition, mounted eg. in `/pkgs` or `/var/pkgs`.
3. Make the initramfs union-mount all the required packages as the new root, using overlayfs.
4. Use mount namespaces to be able to have different packages installed on a per-user or per-process basis.

Funny thing is, when I came up with this, I had no idea about the theory explained earlier in this post. I didn't realise how it's similar to Maven, or how it solves package management problems. I came up with it because I didn't like how the `.tar.xz`'s in package cache are all signed and can be easily verified, but it's a bit harder to verify if the extracted content on disk is the same as in the packages. So I came up with this idea that each package would be squashfs with dm-verity, the verity roothash would be in metadata, and the metadata would be signed and verified at package-mount-time.

Now, I know this particular `overlayfs` approach for system packages has some issues. I have answers for some of them, others need more research, but this is a topic for another blog post.

[venv-rant]: https://pythonrants.wordpress.com/2013/12/06/why-i-hate-virtualenv-and-pip/
[venv-activate-rant]: https://gist.github.com/datagrok/2199506
[semver]: http://semver.org/
[slashpackage]: https://cr.yp.to/slashpackage.html
[slf4j]: https://www.slf4j.org/legacy.html
[union-mount]: https://en.wikipedia.org/wiki/Union_mount
