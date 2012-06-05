# Blosxom Plugin: wikieditish
# Author(s): Rael Dornfest <rael@oreilly.com>
# Version: 2003-05-29
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html


package ModBlosxom::plugin::WikiEditish;

use strict;


sub new { bless {}, shift; }

sub start {
	my ($self,$blosxom) = @_;
	my $result          = $self->_init($blosxom);

	$blosxom->param(
		'wikieditish::title'    => $self->{title},
		'wikieditish::body'     => $self->{body},
		'wikieditish::response' => $self->{response},
	);

	return $result;
}

sub _init {
	my ($self,$blosxom) = @_;
	my $cgi             = $blosxom->{CGI};

	my ($datadir, $path_info, $flavour)
	  = $blosxom->settings([qw/datadir path_info flavour/]);

	my ($preserve_lastmodified, $require_password, $blog_password, $restrict_by_ip,
	 $ips, $file_extension, $tb_charset) 
	    = $blosxom->settings([qw/
		    wikieditish_preserve_lastmodified
		    wikieditish_require_password
		    wikieditish_blog_password
		    wikieditish_restrict_by_ip
		    wikieditish_ips
		    wikieditish_file_extension
		    wikieditish_tb_charset
	    /]);

	$file_extension =~ s!^\.!!;

	$self->{response} = 'Ready to edit this entry.';

	# Only spring into action if POSTing to the wikieditish  plug-in
	return 1 unless( $cgi->request_method() eq 'POST'
	                and $cgi->param('plugin') eq 'wikieditish' );

	my($path,$fn) = $path_info =~ m!^(?:(.*)/)?(.*)\.$flavour!;
	$path =~ m!^/! or $path = "/$path";

	$self->{title} = $cgi->param('title');
	$self->{body}  = $cgi->param('body');

	$self->{body} =~ s/\r\n/\n/g;

	# Something's fishy with the path
	$path =~ /[^\/\w\-]/
	  and warn "blosxom : wikieditish plugin : something's fishy with the path, $path\n"
	  and $self->{response} = "$path seems to be strange; this entry has not been saved."
	  and return 1;

	# password required, but not set
	$require_password and !$blog_password
	  # and warn "blosxom : wikieditish plugin : password required but is not yet set; trying to > $datadir$path/$fn.file_extension\n"
	  and $self->{response} = "A password is required to edit this page but one has not yet been set; this entry has not been saved."
	  and return 1;

	# password required, set, but not correctly supplied
	$require_password and (! $cgi->param('password') or ( $cgi->param('password') and $cgi->param('password') ne $blog_password))
	  # and warn "blosxom : wikieditish plugin : incorrect password supplied for > $datadir$path/$fn.$file_extension\n"
	  and $self->{response} = "Incorrect password; this entry has not been saved."
	  and return 1;

	# restricted by ip
	$restrict_by_ip and !grep(/^\Q$ENV{'REMOTE_ADDR'}\E$/, @$ips)
	  and warn "blosxom : wikieditish plugin : incorrect IP address > $datadir$path/$fn.file_extension\n"
	  and $self->{response} = "Incorrect IP address; this entry has not been saved."
	  and return 1;

	# blosxom's $datadir is not writeable
	!-w  $datadir
	  and warn "blosxom : wikieditish plugin > \$datadir, $datadir, is not writable.\n"
	  and $self->{response} = "\$datadir is not writable; this entry has not been saved."
	  and return 1;

	# the destination directory for this blog entry does not yet exist
	unless ( -d "$datadir$path" and -w "$datadir$path" ) {
	  warn "blosxom : wikieditish plugin : mkdir $datadir$path\n";
	  foreach ( ('', split /\//, $path) ) {
	    my $p .= "/$_"; $p =~ s!^/!!;
	    -d "$datadir/$p" or mkdir "$datadir/$p", 0755
	      or ( warn "blosxom : wikieditish plugin : couldn't mkdir $datadir/$p." and return 1 );
	    chmod 0777, "$datadir/$p";
	  }
	}

	# If file already exists, memorize the lastmodified date/time
	my $mtime = (stat "$datadir$path/$fn.$file_extension")[9];
	$mtime = time if !$mtime;

	no strict qw(refs);
	local *ModBlosxom::AccessDB::make_entry = $self->make_entry();

	my $result = $blosxom->access_db()->make_entry({
		id      => "$datadir$path/$fn.$file_extension",
		title   => $self->{title},
		body    => $self->{body},
	});

	# If file is writeable
	if($result){
		$self->{response} = "This entry has been saved successfully.";
		# reset lastmodified date/time to memorized value (if possible)
		$preserve_lastmodified
		  and utime(time, $mtime, "$datadir$path/$fn.$file_extension")
		    ? $self->{response} .= "  Preserved last modified date/time."
		    : warn "blosxom : wikieditish plugin : couldn't reset lastmodified time on $datadir$path/$fn.$file_extension.";
	}
	else{
		warn "couldn't > $datadir$path/$fn.$file_extension";
		$self->{response}
		 = "There was a problem saving this entry; this entry has not been saved.";
	}

	# send trackback pings
	# @pings = split /\r?\n/, $cgi->param('ping_url');
	$self->{pings} = [ split /\r?\n/, $cgi->param('ping_url') ];
	$self->{title} = escape($self->{title});
	$self->{body}  = escape($self->{body});

	1;
}


sub story {
	my $self    = shift;
	my $blosxom = shift;
	my($path, $filename, $story_ref, $title_ref, $body_ref) = @_;
	my $cgi = $blosxom->{CGI};

	unless ( $cgi->param('plugin') eq 'wikieditish' ) {
		my ($title,$body,@body);
		($title, $body) = (split /\n/, $blosxom->settings('raw'), 2);
		$title = escape($title);
		$body  = escape($body);

		$blosxom->param(
			'wikieditish::title'    => $title,
			'wikieditish::body'     => $body,
		);
	}

	my $plain_body = &strip_html($$body_ref);

	$blosxom->param( 'wikieditish::plain_body' => $plain_body );

	if( $blosxom->settings('wikieditish_send_pings') and $self->{pings}){

		if(my @pings = @{ $self->{pings} }){ # real pinging is done here
			$self->{tb_ch} = $blosxom->settings('wikieditish_tb_charset');
			$self->send_pings(
			    $blosxom, $title_ref, $plain_body, $path, $filename, @pings
			);
		}

	}

	1;
}


sub escape {
  local $_ = shift;

  my %escape = ('<'=>'&lt;', '>'=>'&gt;', '&'=>'&amp;', '"'=>'&quot;');
  my $escape_re = join '|' => keys %escape;
  s/($escape_re)/$escape{$1}/g;

  $_;
}


sub send_pings {
	my($self, $blosxom, $title_ref, $plain_body, $path, $fn, @ping_urls) = @_;

	require LWP::UserAgent;
	require HTTP::Request::Common;

	my $blog_name  = strip_html( $blosxom->settings('blog_title') );
	my $url        = $blosxom->settings('url') . "$path/$fn.htm";
	my $title      = strip_html($$title_ref);
	my $excerpt    = $blosxom->cgi->param('excerpt') || $plain_body;
	my $tb_charset = $blosxom->settings('wikieditish_tb_charset');

	my $ua = LWP::UserAgent->new(
		agent   => "ModBlosxom/v" . $blosxom->VERSION,
		timeout => 30,
	);

	for my $ping_url (@ping_urls) {
		next unless $ping_url;
		warn "pinging $ping_url";
		my $req = HTTP::Request::Common::POST(
		  $ping_url, [
		    blog_name => $blog_name,
		    url       => $url,
		    title     => $title,
		    excerpt   => $excerpt,
		    charset   => $tb_charset,
		  ]
		);
		my $res = $ua->request($req);
	}

}


sub strip_html {
	my $str = shift;
	$str =~ s!\x0D|\x0A!!g;
	$str =~ s!<.*?>!!gs;
	return $str;
}


#
# ModBlosxom::AccessDB's method
#

sub make_entry {
	sub {
		my $self    = shift;
		my $hashref = shift;
		my $fh      = $self->{fh};

		my $file  = $hashref->{id};
		my $title = $hashref->{title};
		my $body  = $hashref->{body};

		$fh->open("> $file") or return 0;
		print $fh $title . "\n" . $body;
		$fh->close();
		return 1;
	};
}


1;

__END__

=head1 NAME

Blosxom Plug-in: wikieditish

=head1 SYNOPSIS

Edit a Blosxom blog wiki-style, from right in the browser.

=head2 QUICK START

Drop this wikieditish plug-in file into your plug-ins directory
(whatever you set as $plugin_dir in blosxom.cgi).

Wikieditish, being a well-behaved plug-in, won't do anything until you
either set a password or turn off the password requirement
(set $require_password = 0).

Move the contents of the flavours folder included in this distribution
into your Blosxom data directory (whatever you set as $datadir in blosxom.cgi).
Don't move the folder itself, only the files it contains!  If you don't
have the the sample flavours handy, you can download them from:

http://www.raelity.org/apps/blosxom/downloads/plugins/wikieditish.zip

Point your browser at one of your Blosxom entries, specifying the wikieditish
flavour (e.g. http://localhost/cgi-bin/blosxom.cgi/path/to/a/post.wikieditish)

Edit the entry, supply your password (if required -- the default), and hit the
Save button to save your changes.

You can just as easily create a new blog entry by pointing your browser at a
non-existent filename, potentially on a non-existent path
(e.g. http://localhost/cgi-bin/blosxom.cgi/foo/bar.wikieditish).  Give the entry
a title and body, supply your password (again, if required), and hit the Save
button.  The wikieditish plug-in will create a new blog entry for you on
your specified path, creating the supplied path's directory structure for you
on the fly if necessary.

Enjoy!

=back

=head2 SAMPLE FLAVOUR TEMPLATES

I've made sample flavour templates available to you to help with any
learning curve this plug-in might require.

Take a gander at the source HTML for:

=item * head.wikieditish, a basic head template -- nothing special.

=item * story.wikieditish, a basic story template -- nothing special.

=item * foot.wikieditish, a basic foot template just about like any other.
The big difference is the "edit this blog" form for editing the current
blog entry or creating a fresh one.

NOTE: The wikieditish plug-in requires the presence of a "plugin" form
variable with the value set to "wikieditish"; this tells the plug-in
that it should handle the incoming POSTing data rather than leaving it
for another plug-in.

=back

=head2 FLAVOURING WIKIEDITISH

While there's not much in the way of template variables and the sample
foot.wikieditish provides about everything you'll need, here's a list of
variables and their purposes for your reference:

=item * $wikieditish::title and $wikieditish::body prepopulate the form with the values from the existing blog entry file.

=item * $wikieditish::password is prepopulated with the password you just entered into and submitted in the "edit this blog" form or preferences stored in a 'wikieditish' cookie, if you've the cookie plug-in installed and enabled.

=back

=head2 INVITING CONTRIBUTIONS

The wikieditish plug-in serves dual purposes: as a browser-based editor for
your Blosxom blog and as a wiki-style community blog, allowing contributions
by a particular group of bloggers (using a shared password) or passers-by
(without need of a password -- true Wiki-style).

If you'd like to invite contribution, you can assocate  an "edit" button with
each entry like so:

<a href="$url$path/$fn.wikieditish">edit this blog</a>

HERE

=head1 INSTALLATION

Drop wikieditish into your plug-ins directory ($blosxom::plugin_dir).

=head1 CONFIGURATION

=head2 PRESERVING LAST MODIFIED DATE/TIME ON EDITED ENTRY

The wikieditish plug-in can attempt to maintain the last modified date/time
stamp on any blog entry you're editing.  Otherwise, editing an entry will
cause it to rise to the top of your blog like so much cream.

I say "attempt" since this doesn't work on every operating system
(it doesn't do any harm, though).

To turn this feature on -- it's off by default -- set the
$preserve_lastmodified variable to 1.

=head2 RESTRICTING BY PASSWORD

By default, the wikieditish plug-in requires a password.  You'll need to
set one before being able to edit anything.  Set the $blog_password
configuration variable to anything you wish
(e.g.  my $blog_password = 'abc123';).  Just be
sure to use something you'll remember and other's won't guess.

You can disable password-protection if you wish, allowing passers-by to
contribute to your blog, Wiki-style.  Be sure this is something you want to
do.  It has some possible security implications, anyone being able to write
to your server's hard drive, post to your public-facing blog, and edit
(read: alter, spindle, contort) any blog postings.  Those warning's out of
the way, to turn off password-protection, set $require_password to 0.

=head2 RESTRICTING BY IP

You can alternatively decide to restrict editing to a particular IP address
or addresses -- those in your office, for example, or the machine actually
running Blosxom (127.0.0.1).

To do so, set $restrict_by_ip to 1 (it's off, or 0, by default), and
populate the @ips array with a list of approved IP addresses.  By default,
this is set to "this machine", the machine running Blosxom; shorthand for
"this machine" in IP-speak is 127.0.0.1.  The following example restricts
editing to those coming from three IPs, including 127.0.0.1:

  # Should editing this blog be restricted to a particular set of IPs?
  # 0 = no (default), 1 = yes
  $restrict_by_ip = 1;

  # To what IPs should editing this blog be restricted?
  @ips = qw/ 127.0.0.1 10.0.0.3 140.101.22.10/;

Of course, you can use a combination of password-protection and IP
restriction if you so wish.

=head1 VERSION

2003-05-29

Version number is the date on which this version of the plug-in was created.

=head1 AUTHOR

Rael Dornfest  <rael@oreilly.com>, http://www.raelity.org/

=head1 SEE ALSO

The wikieditish plug-in plays nicely with the wikiwordish plug-in
[http://www.raelity.org/apps/blosxom/plugins/text/wikiwordish.individual]
for wiki-style linking action.  And for wiki-style markup, be sure to try the
textile [http://www.raelity.org/apps/blosxom/plugins/text/textile.individual]
or tiki [http://www.raelity.org/apps/blosxom/plugins/text/tiki.individual]
plug-ins.

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
