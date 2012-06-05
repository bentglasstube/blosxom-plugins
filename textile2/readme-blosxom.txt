Textile Text Formatter
Plugin for Blosxom



Blosxom Installation
1.  Create a 'lib/Text' directory under your Blosxom plugin directory
2.  Copy 'textile.pm' to $plugin_dir/lib/Text
3.  Copy 'textile2' to $plugin_dir.  You may wish to name it something like
   '50textile2', and rename other plugins with other numbers, to get them
    loaded in the right order.  "The right order" is still somewhat unknown,
    but I'd suggest using textile before SmartPants but after most other
    body-modifying plugins (such as macro packages).
4.  Install Rael's meta plugin if you don't already have it installed.
5.  Create a test post; mark it as Textile by using "meta-markup: textile2"
    on the line after the title.  See the meta documentation for more
    information on meta variables. You can also set
    $meta::markup = "textile2" in your config file or your storyprefs file
    if you use the config or the prefs plugin.

You may probably replace the Textile.pm file with the latest one for
MovableType which you can find at 
<http://bradchoate.com/mt-plugins/textile>. 