# Blosxom Plugin: css
# Author(s): Kyo Nagashima <kyo@hail2u.net>
# Version: 1.0
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-08-31
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

package ModBlosxom::plugin::Css;

use strict;

sub new { bless {}, shift; }

sub start {
	my $self    = shift;
	my $blosxom = shift;

	my @paths = @{ $blosxom->settings('css_paths') };

	my $i = int(rand(int(@paths)));

	$blosxom->param( 'css::path' => $paths[$i] );

	return 1;
}

1;
