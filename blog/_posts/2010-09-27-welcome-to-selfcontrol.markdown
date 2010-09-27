---
layout: post
title: Welcome to SelfControl
---

Well, it has been a busy weekend... I almost have this blog thing figured out, maybe in a few more days.  It has been *way* hot the past few days, breaking 108°F (uggh).

* CLI tools rock!
* GUI tools are hard.
* Tests are good.
* Blogs are weird.
* SelfControl is on Ubuntu Software Center (but broken)
* I've mostly figured out Private APT Repositories
* It's *HOT*

I should be working on SelfControl v1.0.0, but instead I've been playing around with a v2.0.0 test.  It's a shame people don't like command line tools, the cli version is coming along nicely.

It uses YAML for configuration files so you can have something like:

    ---
    # test.yml
    duration: 1:30
    ---
    host: example.com
    ---
    duration: 2:00
    host: facebook.com

and then do:

    sc list --file test.yml    # shows what is in the file after applying
                               # inherited defaults from file and global
                               # entries.

    sc list --file test.yml --nodefaults  # skips the default applications.

    sc list                    # lists the currently active blocks
                               # with the amount of time remaining.

    sc --sudo apply test.yml   # applies the blocks for reals.

    sc test                    # does basic testing of setup.
    sc --sudo test             # and some more.
    sc --sudo test --realtest  # and actually applies an example block
                               # and waits for it to clear.

    sc help                    # gives some help.

Of course it's taken most of the weekend just pulling out my hair to figure out just a few more GUI tricks.  I figure it will be tons of code and work to get a good GUI around it.

It also seems that SelfControl automagically appeard on Ubuntu Software Center! I swear I didn't do anything to cause that to happen.  Sadly it seems there's something amiss in my packages to make it not work that way.  Something about not finding the right architecture package.  (SelfControl has no architecture parts, it's all _all.deb)  Oh well.  It actually works when I set up a Personal Repository and add it to APT. :)

----
zengargoyle
