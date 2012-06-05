# Blosxom Plugin: entries_index
# Author(s): Rael Dornfest <rael@oreilly.com>
# Version: 2003-03-23
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

package ModBlosxom::plugin::EntriesIndex;

use File::stat;
use File::Find;
use Data::Dumper;

sub new{ bless {}, shift; }

sub start { 1; }

sub entries {
	my $self    = shift;
	my $blosxom = shift;

	return sub {
		my $self     = shift; # blosxom object
		my $datafile = $self->settings('entries_index_datafile');
		my ($datadir,$depth,$file_extension,$show_future_entries)
		 = @{ $self->{settings} }{qw/datadir depth file_extension show_future_entries/};
		my(%files, %indexes, $VAR1);

		if ( open ENTRIES, "$datafile" ) {
			my $index = join '', <ENTRIES>;
			close ENTRIES;
			$index =~ /\$VAR1 = \{/ and eval($index) and !$@ and %files = %$VAR1;
		}

		my $reindex = 0;
		for my $file (keys %files) {
			-f $file or do { $reindex++; delete $files{$file} };
		}

		find(sub {
			my $d;
			my $curr_depth = $File::Find::dir =~ tr[/][];
			if ( $depth and $curr_depth > $depth ) {
			  $files{$File::Find::name} and delete $files{$File::Find::name};
			  return;
			}

			$File::Find::name =~ m!^$datadir/(?:(.*)/)?(.+)\.$file_extension$!
			  and $2 ne 'index' and $2 !~ /^\./ and (-r $File::Find::name)
			    # to show or not to show future entries
			    and (
			      $show_future_entries
			      or stat($File::Find::name)->mtime <= time
			    )
			      and ( $files{$File::Find::name} || ++$reindex )
			      and ( $files{$File::Find::name} = $files{$File::Find::name} || stat($File::Find::name)->mtime )
			      and $indexes{$1} = 1
			      and $d = join('/', ($self->nice_date($files{$File::Find::name}))[5,2,3])
			      and $indexes{$d} = $d
		}, $datadir);

		if( $reindex ){
		  if( open ENTRIES, "> $datafile" ){
		    print ENTRIES Dumper \%files;
		    close ENTRIES;
		  }
		  else{
		    warn "couldn't > $datafile: $!\n";
		  }
		}

		return (\%files, \%indexes);
	}
}

1;

__END__

=head1 NAME

Blosxom Plug-in: entries_index

=head1 SYNOPSIS

Purpose: Preserves original creation timestamp on weblog entries,
allowing for editing of entries without altering the original
creation time.

Maintains an index ($blosxom::plugin_state_dir/.entries_index.index) of
filenames and their creation times.  Adds new entries to the index
the first time Blosxom encounters them (read: is run after their
creation).

Replaces the default $blosxom::entries subroutine

=head1 VERSION

2003-03-23

Version number coincides with the version of Blosxom with which the
current version was first bundled.

=head1 AUTHOR

Rael Dornfest  <rael@oreilly.com>, http://www.raelity.org/

=head1 SEE ALSO

Blosxom Home/Docs/Licensing: http://www.raelity.org/apps/blosxom/

Blosxom Plugin Docs: http://www.raelity.org/apps/blosxom/plugin.shtml

=head1 BUGS

Address bug reports and comments to the Blosxom mailing list
[http://www.yahoogroups.com/group/blosxom].

=head1 LICENSE

Blosxom and this Blosxom Plug-in
Copyright 2003, Rael Dornfest

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
