# Blosxom Plugin: google
# Author(s): Kyo Nagashima <kyo@hail2u.net>
# Version: 1.0
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

package ModBlosxom::plugin::Google;

use strict;

sub new { bless {}, shift; }

sub start {
	my ($self, $blosxom) = @_;
	$blosxom->param(
		'google::path' => $blosxom->settings('google_cgi_path'),
		'google::key'  => $blosxom->settings('google_keyword'),
	);
	return 1;
}

1;
