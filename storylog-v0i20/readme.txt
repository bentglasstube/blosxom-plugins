Installation: Simply copy into the plugins directory.

Use: The plugin logs keyword links and category views, and creates a list of most popular clicks, which can be
included in a story or template.

$storylog::keywords - most popular keywords
$storylog::categories - most popular categories
$storylog::combined - combined categories and keywords
Select which lists are produced (and the display style) by changing the $logkeywords, $logcategories and
$logcombined variables.

To display the most-clicked categories or keywords, use:
$storylog::keywords,  $storylog::categories or $storylog::combined
$display = maximum number of links to display
$showcount = 1 if you want the number of clicks to be displayed
$ignore holds a regular expression for any categories you don't want displaying.
