# Blosxom Plugin: back_and_forth
# Author(s): Kyo Nagashima <k-n@muc.biglobe.ne.jp>
# Version: 1.2
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# This plugin is altenate version of "prevnextentry" plugin.
# "prevnextentry" plugin maybe found at:
# http://bulknews.net/lib/archives/prevnextentry-0.1

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

# 2004-09-13 for ModBlosxom v.0.17

package ModBlosxom::plugin::BackAndForth;

use strict;

sub new { bless {}, shift; }

sub start {
	my ($self, $blosxom) = @_;

	return ($blosxom->settings('path_info') =~ /\./) ? 1 : 0;
}


sub filter {
	my ($self, $blosxom, $files_ref) = @_;
	$self->{file_info}
	        = [ sort {$files_ref->{$b} <=> $files_ref->{$a}} keys %$files_ref ];
	return 1;
}

sub head {
	my ($self, $blosxom, $path, $head_ref) = @_;
	my ($datadir, $flavour, $file_extension, $url)
	    = $blosxom->settings([qw/datadir flavour file_extension url/]);

	my ($main, $prev, $next, $link_main, $link_prev, $link_next);
	my @file_info = @{ $self->{file_info} };

	$path =~ s/\.$flavour/\.$file_extension/;

	my %path2idx = map {$file_info[$_] => $_} 0..$#file_info;
	my $index    = $path2idx{"$datadir/$path"};

	if($index < $#file_info) {
		my ($prev_url, $prev_title) = $self->getinfo($blosxom, $index + 1, \@file_info);
		$link_prev = qq!<link rel="previous" href="$prev_url" />!;
		$prev = $blosxom->get_template($path, 'back_and_forth_prev', $flavour)
		     || '<p><a href="$back_and_forth::prev_url">&#171; $back_and_forth::prev_title</a></p>';
		$prev =~ s/\$back_and_forth::prev_url/$prev_url/ge;
		$prev =~ s/\$back_and_forth::prev_title/$prev_title/ge;
	}

	if($index > 0){
		my ($next_url, $next_title) = $self->getinfo($blosxom, $index - 1, \@file_info);
		$link_next = qq!<link rel="next" href="$next_url" />!;
		$next = $blosxom->get_template($path, 'back_and_forth_next', $flavour)
		     || '<p><a href="$back_and_forth::next_url">$back_and_forth::next_title &#187;</a></p>';
		$next =~ s/\$back_and_forth::next_url/$next_url/ge;
		$next =~ s/\$back_and_forth::next_title/$next_title/ge;
	}

	$main = $blosxom->get_template($path, 'back_and_forth_main', $flavour)
	      || '<a href="$blosxom::url">Main</a>';
	$main =~ s/\$blosxom::url/$url/ge;
	$link_main = qq!<link rel="top" href="$url" />!;

	$blosxom->param(
		'back_and_forth::link_main' => $link_main,
		'back_and_forth::link_prev' => $link_prev,
		'back_and_forth::link_next' => $link_next,
		'back_and_forth::main'      => $main,
		'back_and_forth::prev'      => $prev,
		'back_and_forth::next'      => $next,
	);

	return 1;
}

sub getinfo {
	my ($self, $blosxom, $ai, $pi) = @_;
	my ($datadir, $file_extension, $flavour, $url)
	    = $blosxom->settings([qw/datadir file_extension flavour url/]);
	my $file        = $pi->[$ai];
	my ($path, $fn) = $file =~ m!^$datadir/(?:(.*)/)?(.*)\.$file_extension!;

	my $id = "/$path/$fn.$file_extension";

	if($path){ $path = "/$path" }

	my $entry = $blosxom->access_db->get_entry({datadir => $datadir, id => $id});

	return("$url$path/$fn.$flavour", $entry->title);
}

1;
