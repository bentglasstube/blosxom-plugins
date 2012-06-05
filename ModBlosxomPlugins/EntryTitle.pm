# Blosxom Plugin: entry_title
# Author(s): Kyo Nagashima <kyo@hail2u.net>
# Version: 1.0
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

# 2004-09-13 for ModBlosxom v.0.17

package ModBlosxom::plugin::EntryTitle;

use strict;

sub new { bless {}, shift; }

sub start { return 1; }

sub head {
	my ($self, $blosxom, $dir, $headref) = @_;
	my ($title_sep, $datadir)
	    = $blosxom->settings([qw/entry_title_title_sep datadir/]);

	if ($dir =~ m!(.*?)/?([\w-]+)\.([\w-]+)$! and $2 ne 'index') {
		my $id  = join('/', '', $1, "$2.txt");
		my $entry = $blosxom->access_db->get_entry({datadir => $datadir, id => $id});
		if( my $title = $entry->title ){
			$blosxom->param('entry_title::title' => "$title_sep$title");
		}
	}

	return 1;
}

1;
