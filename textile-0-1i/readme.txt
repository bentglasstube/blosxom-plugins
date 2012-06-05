Textile Text Formatter
A Plugin for Movable Type

Release 1.1
February 16, 2003


From Brad Choate
http://www.bradchoate.com/
Copyright (c) 2003, Brad Choate


===========================================================================

INSTALLATION

To install, place the 'textile.pl' file in your Movable Type "plugins"
directory. The 'textile.pm' file should be placed in a 'bradchoate'
subdirectory underneath your Movable Type "extlib" directory. Your
installation should look like this:

  * (mt home)/plugins/textile.pl
  * (mt home)/extlib/bradchoate/textile.pm

Refer to the Movable Type documentation for more information regarding
plugins.


===========================================================================

DESCRIPTION

This plugin adds an additional 'Text Formatter' to Movable Type. Once
installed, 'Textile' will appear as a new option in the 'Text Formatting'
drop-down list you see on the edit entry form and within the blog
configuration.

Textile greatly simplifies the task of writing, eliminating most of the
HTML tags. For detailed information on the rules that Textile uses, please
refer to the online documentation available from the '?' help link (which
appears ot the right of the 'Text Formatting' label) you'll find on the
entry edit screen.

Tags made available through this plugin:

  <MTTextileHeadOffset> - Used to change the head tags to match the
  context of where they will be placed.

  <MTTextileAutoEncode> - Used to control whether high-bit and special
  characters are encoded to HTML entities or not.


===========================================================================

<MTTextileHeadOffset>

This tag allows you to define what the '<h1>' tag is really supposed to be
when Textile encounters it. Ideally, your entries should use 'h1' for the
first heading, 'h2' for the second, etc. But when your entry is output to
your template, it may look funny to have an 'h1' tag where it should
really be an 'h4' for example. To counter this, you can specify the number
you wish for your headings to start with. This will number any 'h1' tags
to the number you specify, then 'h2' tags will be renumbered to the
starting number plus one, etc.

Note that if you use a 'start' value of '2', 'h6' tags will be left as-is
since there is no 'h7' tag.

  * start
    The number to be used for 'h1' header tags. 'h2' tags will be
    renumbered as start+1 and so forth.

Usage examples:

  <MTTextileHeadOffset start="4">
  This will cause the 'h1' tags (or markers) you place within your entry
  to actually be 'h4' tags.


===========================================================================

<MTTextileAutoEncode>

This tag allows you to control whether high-bit and special characters
are automatically encoded into HTML entities or not. This will affect
any textual portions of your entry.

  * disable
    If set to '1', this will disable automatic encoding.

Usage examples:

  <MTTextileAutoEncode disable="1">
  This will disable the HTML entity encoding Textile normally applies.


===========================================================================

LICENSE

Released under the MIT license. Please see
    http://www.opensource.org/licenses/mit-license.php
for details.


===========================================================================

SUPPORT

If you have any questions or need assistance with this plugin, please
visit this page on my site:

  http://www.bradchoate.com/past/mttextile.php


Brad Choate
February 12, 2003


===========================================================================

CHANGELOG

1.1 - A number of regex updates.

- If emphasis, strong, etc. shorthand appears at the start of the line,
they are now handled properly.

- Hand-entered HTML entities are preserved for non-'pre' blocks (meaning
text that isn't in a 'pre' tag). This is different from 1.0, so please
take note. Standalone '&' characters will still be escaped.

- Addition of MTTextileAutoEncode tag. This allows you to define
whether you want Textile to escape high-bit characters or not.

- Additional TLDs were added to the URL regex.

- A paragraph tag is now used for the content of the 'bq.' marker.

- Nesting emphasis and strong formats should work better now.

- Added CSS class support for images.

- Added link support for images.

- Added image dimension support for images.

- Fixed a bug that was causing one of those 'internal server errors'.

1.0 - Initial release
