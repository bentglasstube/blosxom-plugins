# Blosxom Plugin: breadcrumbs
# Author(s): Rael Dornfest <rael@oreilly.com> 
# Version: 2003-12-29
# Documentation: See the bottom of this file or type: perldoc readme

# 2004-09-07
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

package ModBlosxom::plugin::Breadcrumbs;

use strict;


sub new { bless {}, shift; }

sub start {
	my ($self,$blosxom) = @_;
	$self->{home}    = $blosxom->settings('breadcrumbs_home')    || 'home';
	$self->{divider} = $blosxom->settings('breadcrumbs_divider') || '::';
	return 1;
}

sub head {
	my ($self, $blosxom, $path, $head_ref) = @_;
	my ($flavour, $url)  = $blosxom->settings([qw/flavour url/]);
	my ($home, $divider) = @{$self}{qw/home divider/};

	$path or return 0;
	$path =~ s/\.$flavour$//;

	my(@p, $p);
	$home and push @p, qq{<a href="$url/index.$flavour">$home</a>};

	foreach ( split /\//, $path ) {
		$p .= "/$_";
		push @p, 
		  $p ne "/$path"
		  ? qq{<a href="$url$p/index.$flavour">$_</a>}
		  : qq{$_};
	}

	$blosxom->param('breadcrumbs::breadcrumbs' => join $divider, @p);

	return 1;
}

1;

__END__

=head1 NAME

Blosxom Plug-in: breadcrumbs

=head1 SYNOPSIS

Populates $breadcrumbs::breadcrumbs with a clickable trail to
your current path in the weblog hierarchy (a la Yahoo!).

e.g. a/path/to/somewhere becomes 
<a href="/a">a</a> :: <a href="/a/path">path</a> :: ...

Optionally prepends the path with a link back to home.  Alter $home
as you please, leaving it blank to turn off the link to home.

=head1 VERSION

2003-12-29

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
