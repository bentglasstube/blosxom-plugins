# Blosxom Plugin: archives
# Author: Brian Akins <bakins@web.turner.com>
# Version: 0+5i
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

package ModBlosxom::plugin::Archives;

# --------------------------------------

sub new { bless {}, shift; }

sub start { return 1; }

sub filter {
	my $self     = shift;
	my $blosxom  = shift;
	my $files    = shift;
	my %archive;

	my ($reverse,$indent,$url) = $blosxom->settings([qw/reverse indent url/]);
	my @monthname              = @{ $blosxom->settings('archives_monthname') };

	foreach (keys %{$files}) {
		my @date = localtime($files->{$_});
		my $month = $date[4];
		my $year  = $date[5] + 1900;

		$archive{$year}{'count'}++;
		$archive{$year}{$month}{'count'}++;
	}

	my $results = qq{<ul class="archives">\n};

	foreach my $year(sort { $reverse ? $b <=> $a : $a <=> $b } keys(%archive)) {
	  $results .= qq{$indent<li><a href="$url/$year/">$year</a> ($archive{$year}{'count'})\n$indent$indent<ul>\n};
	  delete $archive{$year}{'count'};

	  # loop for each month found; one LI per month.
	  foreach my $month(sort {$reverse?$b<=>$a:$a<=>$b} keys(%{$archive{$year}})) {
	     my $mnum = sprintf("%02d", $month+1);
	     $results .= qq{$indent$indent$indent<li><a href="$url/$year/$mnum/">$monthname[$month]</a> ($archive{$year}{$month}{'count'})</li>\n};
	  }

	  $results .= "$indent$indent</ul>\n$indent</li>\n";
	}

	$results .= "</ul>\n";

	$blosxom->param('archives::archives' => $results);

	1;
}

1;
