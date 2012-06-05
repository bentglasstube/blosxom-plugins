Textile Text Formatter
Plugin for Blosxom

Release 0+1i, March 8 2003
Based on mttextile 1.1

This is Brad Choate's Textile plugin for Movable Type, genericised, with a
Blosxom interface added.

files:
  license.txt           -- the original license, covers this too (although all
                           changes are (C) Todd Larason)
  mtmanual_textile.html -- the original manual; the formatting language is
                           unchanged, but the MT-type specific parts apply
                           only when using Movable Type 
  readme.txt            -- the original readme.txt file
  textile               -- the blosxom plugin
  textile.pl            -- the MT plugin, modified to use the genericised
                           textile.pm; completely untested
  testile.pl-original   -- the original MT plugin
  textile.pm            -- the actual formatting engine, genericised
  textile.pm-original   -- the original formatting engine

Blosxom Installation
1.  Create a 'lib/bradchoate' directory under your Blosxom plugin directory
2.  Copy 'textile.pm' to $plugin_dir/lib/bradchoate
3.  Copy 'textile' to $plugin_dir.  You may wish to name it something like
   '50textile', and rename other plugins with other numbers, to get them
    loaded in the right order.  "The right order" is still somewhat unknown,
    but I'd suggest using textile before SmartPants but after most other
    body-modifying plugins (such as macro packages).
4.  Install Rael's meta plugin if you don't already have it installed.
5.  Create a test post; mark it as Textile by using "meta-markup: textile" on
    the line after the title.  See the meta documentation for more information
    on meta variables.

Report any problems (or success reports!) to jtl-blosxom-plugins@molehill.org.
