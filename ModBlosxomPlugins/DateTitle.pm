# Blosxom Plugin: date_title
# Author(s): Kyo Nagashima <kyo@hail2u.net>
# Version: 1.0
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

package ModBlosxom::plugin::DateTitle;

use strict;

sub new { bless {}, shift; }

sub start {
	my ($self,$blosxom) = @_;

	if(! $blosxom->settings('path_info_yr') ){
		return 0;
	}

	return 1;
}

sub head{
	my ($self, $blosxom, $currentdir, $head_ref) = @_;
	my ($title_sep, $date_sep)
	    = $blosxom->settings([qw/date_title_title_sep date_title_date_sep/]);
	my ($path_info_yr, $path_info_mo_num, $path_info_da)
	    = $blosxom->settings([qw/path_info_yr path_info_mo_num path_info_da/]);
	my $title;

	$title  = "$title_sep$path_info_yr";
	$title .= "$date_sep$path_info_mo_num" if($path_info_mo_num);
	$title .= "$date_sep$path_info_da"     if($path_info_da);

	$blosxom->param('date_title::title' => $title);

	return 1;
}

1;
