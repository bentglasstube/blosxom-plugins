# Blosxom Plugin: writeback
# Author(s): Rael Dornfest <rael@oreilly.com>
# Version: 2003-09-18
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/

# 2004-09-04
# modified for ModBlosxom.pm by Makamaka<makamaka[at]donzoko.net>
#
# Blosxom Home/Docs/Licensing: http://www.blosxom.com/license.html

# 2004-09-07 v.0.2  $writeback::form
# 2004-09-13 v.0.3
# 2004-09-19 v.0.4  modified for ModBlosxom for 0.22

package ModBlosxom::plugin::Writeback;


my $trackback_flavour = "trackback";

my $trackback_response = <<'TRACKBACK_RESPONSE';
<?xml version="1.0" encoding="iso-8859-1"?>
<response>
<error></error>
<message></message>
</response>
TRACKBACK_RESPONSE


sub new { bless {}, shift; }

sub start {
	my ($self,$blosxom) = @_;

	@{ $self }{qw/
		writeback_dir file_extension fields block_invalid_header_cm
		block_invalid_header_tb block_ascii_only conv_charset charset
		cookie_domain cookie_path cookie_expires notify_mail
	/}
	 = $blosxom->settings([qw/
		writeback_dir writeback_file_extension writeback_fields
		writeback_block_invalid_header_cm
		writeback_block_invalid_header_tb
		writeback_block_ascii_only
		writeback_conv_charset
		writeback_charset
		writeback_cookie_domain
		writeback_cookie_path
		writeback_cookie_expires
		writeback_notify_mail
	 /]);

	$blosxom->{templates}->{'trackback'} = {
		'content_type' => 'text/xml',
		'head'         => '$writeback::trackback_response',
		'date'         => ' ',
		'story'        => ' ',
		'foot'         => ' '
	};

	$self->{writeback_response} = 'Ready to post a comment.';
	$self->{trackback_response} = $trackback_response;

	my $result = $self->_init($blosxom);

	$blosxom->param(
		'writeback::writeback_response' => $self->{writeback_response},
		'writeback::trackback_response' => $self->{trackback_response},
		'writeback::trackback_flavour'  => $trackback_flavour,
	);

	return $result;
}

sub _init {
	my ($self,$blosxom) = @_;
	my $cgi             = $blosxom->cgi;
	my ($writeback_dir,$file_extension)
	 = @{$self}{qw/writeback_dir file_extension/};
	my ($flavour, $url) = $blosxom->settings([qw/flavour url/]);

	# Strip potentially confounding bits from user-configurable variables
	$writeback_dir =~ s!/$!!; $file_extension =~ s!^\.!!;

	# $writeback_dir must be set to activate writebacks
	unless ( $writeback_dir ) {
		warn "blosxom : writeback plugin > The \$writeback_dir configurable variable is not set; please set it to enable writebacks. Writebacks are disabled!\n";
		return 0;
	}

	# the $writeback_dir exists, but is not a directory
	if ( -e $writeback_dir and ( !-d $writeback_dir or !-w $writeback_dir ) ) {
		warn "blosxom : writeback plugin > The \$writeback_dir, $writeback_dir, must be a writeable directory; please move or remove it and Blosxom will create it properly for you.  Writebacks are disabled!\n";
		return 0;
	}

	# the $writeback_dir does not yet exist, so Blosxom will create it
	if ( !-e  $writeback_dir )  {
		my $mkdir_r = mkdir("$writeback_dir", 0755);
		warn $mkdir_r
		    ? "blosxom : writeback plugin > \$writeback_dir, $writeback_dir, created.\n"
		    : "blosxom : writeback plugin > There was a problem creating your \$writeback_dir, $writeback_dir. Writebacks are disabled!\n";
		$mkdir_r or return 0;

		my $chmod_r = chmod 0777, $writeback_dir;

		warn $chmod_r
		    ? "blosxom : writeback plugin > \$writeback_dir, $writeback_dir, set to 0777 permissions.\n"
		    : "blosxom : writeback plugin > There was a problem setting permissions on \$writeback_dir, $writeback_dir. Writebacks are disabled!\n";
		$chmod_r or return 0;

		warn "blosxom : writeback plugin > writebacks are enabled!\n";
	}

#	my $path_info  = $cgi->path_info();
	my $path_info  = $blosxom->settings('path_info');
	my ($path,$fn) = $path_info =~ m!^(?:(.*)/)?(.*)\.$flavour!;
	$path =~ m!^/! or $path = "/$path";
	$path =~ s!/$!!;

	# Only spring into action if POSTing to the writeback plug-in
	return 1
	  unless( $cgi->request_method() eq 'POST'
        and (
          $cgi->param('plugin') eq 'writeback' or $flavour eq $trackback_flavour
        )
      );

	if( $self->{block_invalid_header_cm} and $cgi->param('comment')
	    and ($ENV{'HTTP_REFERER'} !~ m!^$url$path/$fn.htm!) )
	{
	  warn "blosxom : writeback plugin > Someone post a Comment with invalid referer. Writebacks are disabled!\n";
	  $self->{trackback_response} =~ s!<error></error>!<error>1</error>!m;
	  $self->{trackback_response} =~ s!<message></message>!<message></message>!m;
	  $self->{writeback_response} = "There was a problem posting your writeback.";
	  return 1;
	}

	if( $self->{block_invalid_header_tb} and ($flavour eq $trackback_flavour) and
	  ($ENV{HTTP_REFERER} or ($ENV{HTTP_USER_AGENT}||'') =~ m!^Mozilla/!))
	{
		warn "blosxom : writeback plugin > Someone post a TrackBack with invalid headers. Writebacks are disabled!\n";
		$self->{trackback_response} =~ s!<error></error>!<error>1</error>!m;
		$self->{trackback_response} =~ s!<message></message>!<message>There was a problem posting your writeback.</message>!m;
		$self->{writeback_response} = "There was a problem posting your writeback.";
		return 1;
	}

	if( $self->{block_ascii_only}
	    and (($cgi->param('comment') . $cgi->param('excerpt')) =~ /^[\x00-\x7f]+$/) )
	{
		warn "blosxom : writeback plugin > Someone post an ASCII-only Comment/TrackBack. Writebacks are disabled!\n";
		$self->{trackback_response} =~ s!<error></error>!<error>1</error>!m;
		$self->{trackback_response} =~ s!<message></message>!<message>There was a problem posting your writeback.</message>!m;
		$self->{writeback_response} = "There was a problem posting your writeback.";
		return 1;
	}

	my $p;
	foreach ( ('', split /\//, $path) ) {
		$p .= "/$_";
		$p =~ s!^/!!;
		-d "$writeback_dir/$p" or mkdir "$writeback_dir/$p", 0755;
		chmod 0777, "$writeback_dir/$p";
	}

	my $temp = '';
	foreach ( @{ $blosxom->settings('writeback_fields') } ) {
		my $p = sanitize( $cgi->param($_) );
		$temp .= "$_:$p\n";
	}

	$temp .= "date:" . time . "\n";
	$temp .= "remote_addr:" . $ENV{'REMOTE_ADDR'} . "\n";
	$temp .= "remote_host:" . $ENV{'REMOTE_HOST'} . "\n";
	$temp .= "-----\n";

	if($self->{conv_charset}){
		require Jcode;
		unless($@){
			my $charset = $self->{charset};
			$temp = Jcode->new(\$temp)->$charset();
		}
		else{
			warn $@;
		}
	}

	no strict qw(refs);
	local *ModBlosxom::AccessDB::make_writeback = $self->make_writeback();

	my $result = $blosxom->access_db()->make_writeback({
		id   => "$writeback_dir$path/$fn.$file_extension",
		body => $temp,
	});
#print STDERR "$writeback_dir$path/$filename.$file_extension\n";
	if($result){
		$temp = "$url$path/$fn.htm\n-----\n$temp";
		$self->notify($blosxom, $temp) if($self->{notify_mail});

		# Make a note to save Name and URL/Email if save_preferences checked
		$self->{pref_name} = sanitize($cgi->param('name')) || '';
		$self->{pref_url}  = sanitize($cgi->param('url'))  || '';

		if( $cgi->param('save_preferences') ){
			$self->{cookie} = $cgi->cookie(
			  -name    => 'writeback',
			  -value   => {name => $self->{pref_name}, url => $self->{pref_url}},
			  -expires => $self->{cookie_expires},
			  -domain  => $self->{cookie_domain},
			  -path    => $self->{cookie_path},
			);
		}
		$self->{trackback_response} =~ s!<error></error>!<error>0</error>!m;
		$self->{trackback_response} =~ s!<message></message>\n!!s;
		$self->{writeback_response} = "Thanks for the writeback.";
	}
	else{
		warn "couldn't >> $writeback_dir$path/$fn.$file_extension\n";
		$self->{trackback_response} =~ s!<error></error>!<error>1</error>!m;
		$self->{trackback_response} =~ s!<message>trackback error</message>!!m;
		$self->{writeback_response} = "There was a problem posting your writeback.";
	}

	1;
}


sub story {
	my ($self,$blosxom, $path, $filename, $story_ref, $title_ref, $body_ref) = @_;
	my $cgi = $blosxom->{CGI};

	my ($writeback_dir,$file_extension) = @{$self}{qw/writeback_dir file_extension/};

	my ($flavour) = $blosxom->settings([qw/flavour/]);

	my ($writebacks, $count)  = ('', 0);
	my %param = ();

	$path =~ s!^/*!!; $path &&= "/$path";
	$self->{trackback_path_and_filename} = "$path/$filename";

	$blosxom->settings(
		'writeback::trackback_path_and_filename'
		        => $self->{trackback_path_and_filename},
	);

	if ( my %cookies = $cgi->cookie(-name => 'writeback')) {
		$self->{pref_name} ||= $cookies{'name'};
		$self->{pref_url}  ||= $cookies{'url'};
	}

	my $id = "$path/$filename.$file_extension";
	my $wb = $blosxom->access_db()
	                 ->get_entry({datadir => $writeback_dir, id => $id});
	if($wb->exists){
		my $writeback_tmpl
		 = $blosxom->get_template($path,'writeback',$flavour)
		 || '<p><em>Name/Blog:</em> $writeback::name<br /><em>URL:</em> $writeback::url<br /><em>Title:</em> $writeback::title<br /><em>Comment/Excerpt:</em> $writeback::comment$writeback::excerpt<br /><em>Date:</em> $writeback::date</p>';

		for my $line ( split(/\n/, join("\n",$wb->title,$wb->body) ) ){
			$line =~ /^(.+?):(.*)$/ and $param{$1} = $2;

			if ( $line =~ /^-----$/ ){
				my $writeback = $writeback_tmpl;

				if($param{'url'} =~ /[!-~]+\@[!-~]+\.[!-~]+/) {
					$param{'name'} = qq!<a href="mailto:$param{'url'}">$param{'name'}$param{'blog_name'}</a>!;
				}
				elsif($param{'url'}){
					$param{'name'} = qq!<a href="$param{'url'}">$param{'name'}$param{'blog_name'}</a>!;
				}

				$param{'date'} = format_time($param{'date'}) if $param{'date'};

				$writeback =~ s/\$writeback::(\w+)/$param{$1}/ge;
				$writebacks .= $writeback;

				$count++;
			}
		}
	}

	$blosxom->param(
		'writeback::count'      => $count,
		'writeback::writebacks' => $writebacks,
		'writeback::pref_name'  => $self->{pref_name},
		'writeback::pref_url'   => $self->{pref_url},
	);

	# added
	$self->make_form($blosxom);

	1;
}


sub foot {
	my ($self,$blosxom) = @_;
	$blosxom->add_cookie($self->{cookie}) if($self->{cookie});
#	$blosxom->{header}->{'-cookie'} = $self->{cookie} if($self->{cookie});
	1;
}

sub notify {
	my ($self, $blosxom, $body) = @_;
	my $subject     = $blosxom->settings('blog_title') . " - Comment";
	my $flavour     = $blosxom->settings('flavour');
	my ($to, $from) = $blosxom->settings([qw/writeback_to writeback_from/]);
	my $sendmail    = $blosxom->settings('writeback_sendmail');
	my $version     = $blosxom->VERSION;

	$subject =~ s/Comment/TrackBack/ if ($flavour eq $trackback_flavour);
	require Jcode;
	$subject = Jcode->new($subject, $charset)->mime_encode;
	$body    = Jcode->new($body, $charset)->jis;
	my $mail = <<"_MAIL_";
From: $from
To: $to
Subject: $subject
Content-Type: text/plain; charset=ISO-2022-JP
X-Mailer: blosxom	$version

$body
_MAIL_

	if (open(MAIL, "| $sendmail -t") or warn $!) {
		print MAIL $mail;
		close(MAIL) or warn $!;
	}
}

sub sanitize {
  my $str = shift;

  $str =~ s!<.*?>!!gs;
  $str =~ s!&amp;!&!g;
  $str =~ s!&!&amp;!g;
  $str =~ s!<!&lt;!g;
  $str =~ s!>!&gt;!g;
  $str =~ s!"!&quot;!g;
  $str =~ s!'!&#39;!g;
  $str =~ s!\x0D\x0A!<br />!g;
  $str =~ s!\x0D!<br />!g;
  $str =~ s!\x0A!<br />!g;

  return $str;
}

sub format_time {
	my $time = shift;

	my($ss, $nn, $hh, $dd, $mm, $yy, $ww) = localtime($time);
	$yy = $yy + 1900;
	$mm = sprintf "%02d", ++$mm;
	$dd = sprintf "%02d", $dd;
	$hh = sprintf "%02d", $hh;
	$nn = sprintf "%02d", $nn;
	$ss = sprintf "%02d", $ss;
	my @wdays = qw(Sun Mon Tue Wed Thu Fri Sat);
	$time = "$yy/$mm/$dd ($wdays[$ww]) $hh:$nn:$ss";

	return $time;
}


sub make_form {
	my ($self,$blosxom) = @_;
	my $form      = '';
	my $datadir   = $blosxom->settings('templates_dir');
	my $file      = '/writeback_form'; # conf?
	my $path_info = $blosxom->settings('path_info');

	if($path_info =~ /(?:.+)\.(?:.+)$/){
		my $tmpl = $blosxom->access_db()
		                   ->get_template({datadir => $datadir, id => $file});
		$form = $blosxom->interpolate($tmpl);
	}

	$blosxom->param('writeback::form' => $form);
}

#
# ModBlosxom::AccessDB's method
#

sub make_writeback {
	sub {
		my $self    = shift;
		my $hashref = shift;
		my $fh      = $self->{fh};

		my $file  = $hashref->{id};
		my $body  = $hashref->{body};

		$fh->open(">> $file") or return 0;
		print $fh $body;
		$fh->close();
		return 1;
	};
}


1;

__END__

=head1 NAME

Blosxom Plug-in: writeback

=head1 SYNOPSIS

Provides WriteBacks, a combination of comments and TrackBacks
[http://www.movabletype.org/trackback/].

All comments and TrackBack pings for a particular story are kept in
$writeback_dir/$path/$filename.cmt.

=head2 QUICK START

Drop this writeback plug-in file into your plug-ins directory
(whatever you set as $plugin_dir in blosxom.cgi).

Writeback, being a well-behaved plug-in, won't do anything until you set
$writeback_dir.

While you can use the same directory as your blosxom $datadir (WriteBacks
are saved as path/weblog_entry_name.wb), it's probably better to keep
them separate.

Once set, the next time you visit your site, the writeback plug-in will
perform some checks, creating the $writeback_dir and setting appropriate
permissions if it doesn't already exist.  (Check your error_log for details
of what's happening behind the scenes.)

Move the contents of the flavours folder included in this distribution
into your Blosxom data directory (whatever you set as $datadir in blosxom.cgi).
Don't move the folder itself, only the files it contains!  If you don't
have the the sample flavours handy, you can download them from:

http://www.raelity.org/apps/blosxom/downloads/plugins/writeback.zip

Point your browser at one of your Blosxom entries, specifying the writeback
flavour (e.g. http://localhost/cgi-bin/blosxom.cgi/path/to/a/post.writeback)

Enjoy!

=back

=head2 FLAVOUR TEMPLATE VARIABLES

Wherever you wish all the WriteBacks for a particular story to appear
in your flavour templates, use $writeback::writebacks.

A count of WriteBacks for each story may be embedded in your flavour
templates with $writeback::count.

If you'd like, you can embed a "Thanks for the writeback." or
"There was a problem posting your writeback." message after posting with
$writeback::writeback_response.

=head2 SAMPLE FLAVOUR TEMPLATES

I've made sample flavour templates available to you to help with any
learning curve this plug-in might require.

Take a gander at the source HTML/XML for:

=item * story.writeback, a basic example of a single-entry story
flavour with WriteBacks embedded.  You should not use this as your
default flavour since every story on the home page would have WriteBacks
right there with the story itself.

=item * foot.writeback provides a simple comment form for posting to the
WriteBack plug-in.  NOTE: The writeback plug-in requires the presence
of a "plugin" form variable with the value set to "writeback"; this tells
the plug-in that it should handle the incoming POSTing data rather than
leaving it for another plug-in.

=item * writeback.writeback is a sample flavour file for WriteBacks themselves.
Think of a WriteBacks flavour file as a story flavour file for individual
WriteBacks.

=back

=head2 FLAVOURING WRITEBACKS

While the default does a pretty good job, you can flavour your WriteBacks
in the writeback flavour file (e.g. writeback.writeback) using the following
variables:

=item * $writeback::name$writeback::blog_name - Name entered in comment form or weblog name used in TrackBack ping.

=item * $writeback::url - URL entered in comment form or that of writing citing your weblog entry via TrackBack ping.

=item * $writeback::title - Title entered into comment form or that of writing citing your weblog entry via TrackBack ping.

=item * $writeback::comment$writeback::excerpt - Comment entered into comment aorm or excerpt of writing citing your weblog entry via TrackBack ping.

=item * $writeback::pref_name and $writeback::pref_url are prepopulated with the values of the form you just submitted or preferences stored in a 'writeback' cookie, if you've the cookie plug-in installed an enabled.

=back

=head2 INVITING AND SUPPORTING TRACKBACKS

You should provide the TrackBack ping URL for each story so that those
wanting to TrackBack ping you manually know where to ping.
$writeback::trackback_path_and_filename, together with $url and
a TrackBack flavour will provide them all they need.

e.g. $url$writeback::trackback_path_and_filename.trackback

The writeback plugin provides an XML response to TrackBack pings in the form
of a baked-in trackback flavour.  If you alter the value of $trackback_flavour
(why would you?), you'll have to create a set of flavour templates by hand; all
should be blank save the content_type (text/xml) and head
($writeback::trackback_response).

=head1 INSTALLATION

Drop writeback into your plug-ins directory ($blosxom::plugin_dir).

=head1 CONFIGURATION

=head2 (REQUIRED) SPECIFYING A WRITEBACK DIRECTORY

Writeback, being a well-behaved plug-in, won't do anything until you set
$writeback_dir, create the directory, and make it write-able by Blosxom.

Create a directory to save WriteBacks to (e.g. $plugin_state_dir/writeback),
and set $writeback_dir to the path to that directory.

While you can use the same directory as your blosxom $datadir (WriteBacks
are saved as path/weblog_entry_name.wb), it's probably better to keep
them separate.

The writeback plug-in will create the appropriate paths to mimick your
$datadir hierarchy on-the-fly.  So, for a weblog entry in
$datadir/some/path/or/other/entry.txt, WriteBacks will be kept in
$writeback_dir/some/path/or/other/entry.wb.

=head2 (OPTIONAL) ALTERING THE TRACKBACK FLAVOUR

The $trackback_flavour sets the flavour the plug-in associates with incoming
TrackBack pings.  Unless this corresponds to the flavour associated with your
trackback URL, the writeback plug-in will ignore incoming pings.

=head2 (OPTIONAL) SPECIFYING AN EXTENSION FOR WRITEBACK FILES

The default extension for WriteBacks is wb.  You can change this if
you wish by altering the $file_extension value.

=head2 (OPTIONAL) SPECIFYING WHAT FIELDS YOU EXPECT IN YOUR COMMENTS FORM

The defaults are probably ok here, but you can specify that the writeback
plug-in should look for more fields in your comments form by adding to this
list.  You should keep at least the defaults in place so as not to break
anything.

my @fields = qw! name url title comment excerpt blog_name !;

=head1 VERSION

2003-09-18

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
