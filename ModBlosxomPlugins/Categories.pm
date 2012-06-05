# Blosxom Plugin: categories
# Author: Todd Larason <jtl@molehill.org>
# Version: 0+1i
# Blosxom Home/Docs/Licensing: http://www.raelity.org/blosxom

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

package ModBlosxom::plugin::Categories;

use strict;

sub new { bless {}, shift; }

sub start { return 1; }

sub filter {
	my ($self,$blosxom,$files) = @_;
	my ($datadir, $path_info)
	  = $blosxom->settings([qw/datadir path_info/]);
	my ($story_count_commulative)
	 = $blosxom->settings([qw/categories_story_count_commulative/]);

	$self->{stories}  = {};
	$self->{children} = {};
	$self->{seen}     = {};

	$self->{datadir}       = $datadir;
	$self->{output_format} = $blosxom->settings('categories_output_format') || 'ul';
	$self->{root_name}     = $blosxom->settings('categories_root_name') || 'all';
	$self->{aliases}       = $blosxom->settings('categories_aliases')   || {};
	$self->{url}           = $blosxom->settings('url');
	$self->{prune_dirs}    = $blosxom->settings('categories_prune_dirs') || [];

	foreach (keys %{$files}) {
	  my ($dir, $file) = m:(.*)/(.*):;
	  my $child;
	  $self->{stories}->{$dir}++;

	  while ($dir ne $datadir) {
	    ($dir, $child) = ($dir =~ m:(.*)/(.*):);
	    $self->{stories}->{$dir}++ if $story_count_commulative;
	    if (!$self->{seen}->{"$dir/$child"}++) {
	      push @{$self->{children}->{$dir}}, $child;
	    }
	  }
	}

	my $categories = $self->report_root();

	$blosxom->param('categories::categories' => $categories);
}

sub story {
	my $self    = shift;
	my $blosxom = shift;
	my($path, $fn, $story_ref, $title_ref, $body_ref) = @_;
	my $sep = $blosxom->settings('categories_sep');

	if(!defined $sep){ $sep = ''; }

	my $alias = '';
	my @path = split(/\//, $path);

	foreach (@path) {
		next if !$_;
		$_ = $self->{aliases}->{$_} if $self->{aliases}->{$_};
		$alias .= qq!$sep$_!;
	}

	$alias =~ s!^$sep!!;
	$alias = "n/a" if (!$alias);

	$blosxom->param('categories::alias' => $alias);

	return 1;
}

sub report_root {
	my $self      = shift;
	my $datadir   = $self->{datadir};
	my $root_name = $self->{root_name};
	my $results;

	$results  = $self->report_categories_start();
	$results .= $self->report_dir_start(
		'/', $root_name, $self->{stories}->{$datadir}
	);

	$self->{children}->{$datadir} ||= [];
	foreach (sort @{$self->{children}->{$datadir}}) {
		$results .= $self->report_dir('/', $_);
	}

	$results .= report_dir_end();
	$results .= report_categories_end();

	return $results;
}

sub report_categories_start {
	my $output_format = $_[0]->{output_format};
	return qq!<ul class="categories">\n! if $output_format eq 'ul';
	return qq!categories_start\n!        if $output_format eq 'm4';
	warn "Unrecognized output format: $output_format";
	return '';
}


sub report_dir_start {
	my $self = shift;
	my ($fulldir, $thisdir, $numstories) = @_;
	my $output_format = $self->{output_format};
	my $url           = $self->{url};

	$numstories ||= 0;
	$thisdir = $self->{aliases}->{$thisdir} if $self->{aliases}->{$thisdir};

	return qq!<li><a href="$url${fulldir}">$thisdir</a>! . qq! ($numstories)\n<ul>\n! if $output_format eq 'ul';
	return qq!dir_start([[$fulldir]],[[$thisdir]],[[$numstories]])\n! if $output_format eq 'm4';
	return '';
}

sub report_dir {
	my $self = shift;
	my ($parent, $dir) = @_;
	my $results;
	local $_;

	my $datadir   = $self->{datadir};

	if (!defined($self->{children}->{"$datadir$parent$dir"}) || $self->is_prune_dir("$parent$dir")) {
		$results = $self->report_dir_leaf("$parent$dir/", "$dir", $self->{stories}->{"$datadir$parent$dir"});
	}
	else{
		$results = $self->report_dir_start("$parent$dir/", "$dir", $self->{stories}->{"$datadir$parent$dir"});
		foreach (sort @{$self->{children}->{"$datadir$parent$dir"}}) {
			$results .= $self->report_dir("$parent$dir/", $_);
		}
		$results .= $self->report_dir_end();
	}

	return $results;
}


sub report_dir_leaf {
	my $self = shift;
	my ($fulldir, $thisdir, $numstories) = @_;
	my $output_format = $self->{output_format};
	my $url           = $self->{url};

	$numstories ||= 0;
	$thisdir = $self->{aliases}->{$thisdir} if $self->{aliases}->{$thisdir};

	return qq!<li><a href="$url${fulldir}">$thisdir</a>! . qq! ($numstories)</li>\n! if $output_format eq 'ul';
	return qq!dir_leaf([[$fulldir]],[[$thisdir]],[[$numstories]])\n! if $output_format eq 'm4';
	return '';
}

sub report_dir_end {
	my $output_format = $_[0]->{output_format};
	return qq!</ul>\n</li>\n! if $output_format eq 'ul';
	return qq!dir_end\n!      if $output_format eq 'm4';
	return '';
}

sub report_categories_end {
	my $output_format = $_[0]->{output_format};
	return qq!</ul>\n!          if $output_format eq 'ul';
	return qq!categories_end\n! if $output_format eq 'm4';
	return '';
}

sub is_prune_dir {
	my $self  = shift;
	my ($dir) = @_;

	foreach (@{ $self->{prune_dirs} }) {
		return 1 if $dir eq $_;
	}

	return 0;
}

1;
