# ---------------------------------------------------------------------------
# MT-Textile Text Formatter
# A Plugin for Movable Type
#
# Release 1.1
# February 14, 2003
#
# From Brad Choate
# http://www.bradchoate.com/
# ---------------------------------------------------------------------------
# This software is provided as-is.
# You may use it for commercial or personal use.
# If you distribute it, please keep this notice intact.
#
# Copyright (c) 2003 Brad Choate
# ---------------------------------------------------------------------------

package plugins::textile;

use vars qw($VERSION);
$VERSION = 1.1;

use strict;

use MT;
use MT::Template::Context;
use MT::Util qw(encode_html);

MT->add_text_filter('textile_1' => {
    label => 'Textile',
    on_format => sub {
        require bradchoate::textile;
	my $c = {
		 encode_html => \&encode_html,
		 smarty      => $MT::Template::Context::Global_filters{'smarty_pants'},
		 imagesize   => sub {
		     my ($file, $pctw, $pcth) = @_;
		     eval {require MT::Image;};
		     if (!$@) {
			 my $img = MT::Image->new(Filename => $file);
			 if ($img) {
			     my ($w, $h) = $img->get_dimensions;
			     if ($pctw || $pcth) {
				 $w = int($w * $pctw / 100);
				 $h = int($h * $pcth / 100);
			     }
			     return ($w, $h)
			 }
		     }
		     undef;
		 },
		 auto_encode => $ctx->stash('TextileDisableEncode') ? 0 : 1,
		 head_offset => $ctx->stash('TextileHeadOffsetStart'),
		 document_root => $ENV{DOCUMENT_ROOT},
		 site_path   => $ctx->stash('blog') ? $ctx->stash('blog')->site_path : undef,
		 
		}
        &bradchoate::textile::textile_1($_[0], $c);
    },
    docs => 'http://www.bradchoate.com/mt/docs/mtmanual_textile.html'
});

MT::Template::Context->add_tag(TextileHeadOffset => sub {
				   my ($ctx, $args, $cond) = @_;
				   my $start = $args->{start};
				   if ($start && $start =~ m/^\d+$/ && $start >= 1 && $start <= 6) {
				       $ctx->stash('TextileHeadOffsetStart', $start);
				   }
				   '';
			       });

MT::Template::Context->add_tag(TextileAutoEncode => sub {
				   my ($ctx, $args, $cond) = @_;
				   my $disable = $args->{disable};
				   if (defined $disable && $disable) {
				       $ctx->stash('TextileDisableEncode', 1);
				   }
				   '';
			       });

1;
