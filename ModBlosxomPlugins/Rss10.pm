# Blosxom Plugin: rss10
# Author(s): Rael Dornfest <rael@oreilly.com>
# Version: 2.0b4
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

package ModBlosxom::plugin::Rss10;

my $template_placeholder = "{{{items}}}";

sub new { bless {}, shift; }

sub start {
	my ($self, $blosxom) = @_;
	my $version = '2.0';  #  $blosxom->VERSION;

	@{ $self }{qw/items title description content_encoded generatorAgent T colon/}
	  = ('', '', '', '', "http://www.blosxom.com/?v=$version", 'T', ':');

	$blosxom->param('rss10::generatorAgent' => $self->{generatorAgent});

	1;
}

sub head {
	$_[0]->{items} = '';
}

sub story {
	my($self, $blosxom, $path, $filename, $story_ref, $title_ref, $body_ref) = @_;
	my $url = $blosxom->settings('url');

	my ($creato,$email,$tz_offset)
	  = $blosxom->settings([qw/rss10_creator rss10_email $rss10_tz_offset/]);

	$self->{title}       = &strip_html($$title_ref);
	$self->{description} = &strip_html($$body_ref);
	$self->{items}
	 .= qq{\t\t\t\t<rdf:li rdf:resource="$url$path/$filename.html"/>\n};

	$blosxom->param(
		'rss10::title'       => $self->{title},
		'rss10::description' => $self->{description},
		'rss10::items'       => $self->{items},
	);

	1;
}

sub foot {
	my($self, $blosxom, $pkg, $currentdir, $foot_ref) = @_;
	my $items = $self->{items};

	chomp($items);
	$items = <<"ITEMS";
		<items>
			<rdf:Seq>
$items
			</rdf:Seq>
		</items>
ITEMS

	chomp($items);
	$blosxom->{rendered}->{head} =~ s/$template_placeholder/$items/m;
	return 1;
}

sub strip_html {
  my $str = shift;

  $str =~ s!\x0D|\x0A!!g;
  $str =~ s!<.*?>!!g;

  return $str;
}

1;

__END__

=head1 NAME

Blosxom Plug-in: rss10

=head1 SYNOPSIS

Purpose: Provides the extra bit of programming needed to produce a valid
RSS 1.0 [http://www.purl.org/rss/1.0/] feed for syndication.  Works
in concert with the associated {head,story,foot,content_type,date}.rss10
flavour files.

=head1 VERSION

2.0b1

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
