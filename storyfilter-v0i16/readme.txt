Blosxom plugin: storyfilter
===========================

Filters stories according to a keyword provided on the URL.

Current version: 0.16 (17/07/2005)

Installation:
=============

Copy to the plugins directory. Requires the 'meta' plugin.

Usage:
======
copy into the plugins directory. install the meta plugin if it isn't
already there.
add $storyfilter::keywordlinks to the story.html flavour file
(and any other flavours you require).
Add 'meta-keywords: keyword1,keyword2' to the blog entries.
As stories are viewed, the keywords will be added to the known list
and will be available for filtering stories.

Configuration:
==============

$categoryiskeyword = 1
	If the category/directory to be viewed is only one level deep
	i.e. no subdirectories, then the directory name will be taken
	as the keyword, eg. blosxom.cgi/coventry will be the same as
	blosxom.cgi?keyword=coventry. This requires '$autokeywords=1'
	to preserve the normal category view.

$autokeywords = 1
	The plugin will take the path to the story and add the categories
	to the keywords, eg. 'blosxom.cgi/days_out/beach' will cause
	'days_out' and 'beach' to be added to the keywords for the stories
	in that directory.

$refresh = 1
	Every time a story is viewed, the keywords are written to the cache file.
$refresh = 0
	Only writes the keywords to the file when the file is first viewed. If the
	keywords are changed in the story, the changes will not be saved.


Notes:
======

The filter gathers keyword information from the stories and allows the user
to selectively view stories according to keyword. The keywords are defined
by adding
	meta-keywords: comma separated keyword list
The 'storyfilter' plugin uses the 'meta' plugin to convert the list into
a variable which it can access.
To view stories according to keyword, append keyword=theword to the URL,
	e.g blosxom.cgi?keyword=coventry
will view only stories which use the keyword coventry. (note, keywords are
case sensitive).

The $categoryiskeyword should be treated as experimental. It hasn't been
fully implemented or tested and may have some strange behaviour or effect
on other filters.

