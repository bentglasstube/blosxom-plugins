package Text::Textile;

use strict;
use Exporter;
@Text::Textile::ISA = qw(Exporter);
use vars qw(@EXPORT_OK $debug);
@EXPORT_OK = qw(textile);
use File::Spec;

$debug = 0;

sub new {
    my $class = shift;
    my $self = bless {
        named_filters => {},
        text_filters => [],
        charset => 'iso-8859-1',
        char_encoding => '1',
        flavor => 'xhtml',
        line_open => '',
        line_close => '<br />',
        blockcode_open => '<pre><code>',
        blockcode_close => '</code></pre>',
    }, $class;
    $self->css_defaults();
    $self;
}

sub disable_html {
    my $self = shift;
    if (@_) {
        $self->{disable_html} = shift;
    }
    $self->{disable_html} || 0;
}

sub flavor {
    my $self = shift;
    if (@_) {
        my $flavor = shift;
        $self->{flavor} = $flavor;
        if ($flavor =~ m/^xhtml/) {
            if ($flavor =~ m/xhtml1(\.\d)/) {
	        $self->{line_open} = '';
	        $self->{line_close} = '<br />';
	        $self->{blockcode_open} = '<pre><code>';
	        $self->{blockcode_close} = '</code></pre>';
                $self->{css_mode} = 1;
            } elsif ($flavor eq 'xhtml2') {
	        $self->{line_open} = '<l>';
	        $self->{line_close} = '</l>';
	        $self->{blockcode_open} = '<blockcode>';
	        $self->{blockcode_close} = '</blockcode>';
                $self->{css_mode} = 1;
            }
        } elsif ($flavor eq 'html') {
            $self->{line_open} = '';
            $self->{line_close} = '<br>';
            $self->{css_mode} = $flavor =~ m/\/css/;
        }
        $self->css_defaults() if $self->{css_mode} && !exists $self->{css};
    }
    $self->{flavor};
}

sub css {
    my $self = shift;
    if (@_) {
        my $css = shift;
        if (ref $css eq 'HASH') {
            $self->{css} = $css;
            $self->{css_mode} = 1;
        } else {
            $self->{css_mode} = $css;
        }
    }
    $self->{css_classes};
}

sub css_defaults {
    my $self = shift;
    my %css_defaults = (
       class_align_right => 'right',
       class_align_left => 'left',
       class_align_center => 'center',
       class_align_top => 'top',
       class_align_bottom => 'bottom',
       class_align_middle => 'middle',
       class_align_justify => 'justify',
       class_caps => 'caps',
       class_footnote => 'footnote',
       id_footnote_prefix => 'fn',
    );
    $self->css(\%css_defaults);
}

sub charset {
    my $self = shift;
    if (@_) {
        $self->{charset} = shift;
        if ($self->{charset} eq 'utf-8') {
            $self->char_encoding(0);
        }
    }
    $self->{charset};
}

sub process {
    my $self = shift;
    $self->textile(@_);
}

sub docroot {
    my $self = shift;
    if (@_) {
        $self->{docroot} = shift;
    }
    $self->{docroot};
}

sub filter_param {
    my $self = shift;
    if (@_) {
        $self->{filter_param} = shift;
    }
    $self->{filter_param};
}

sub named_filters {
    my $self = shift;
    if (@_) {
        $self->{named_filters} = shift;
    }
    $self->{named_filters};
}

sub text_filters {
    my $self = shift;
    if (@_) {
        $self->{text_filters} = shift;
    }
    $self->{text_filters};
}

sub char_encoding {
    my $self = shift;
    if (@_) {
        $self->{char_encoding} = shift;
    }
    $self->{char_encoding};
}

# a URL discovery regex. This is from Mastering Regex from O'Reilly.
# Some modifications by Brad Choate <brad@bradchoate.com>
use vars qw($urlre $blocktags $clstyre $clstypadre $clstyfiltre $alignre $valignre $halignre $imgalignre $tblalignre $codere $punct);
$urlre = qr{
    # Must start out right...
    (?=[a-zA-Z0-9./])
    # Match the leading part (proto://hostname, or just hostname)
    (?:
        # ftp://, http://, or https:// leading part
        (?:ftp|https?|telnet|nntp)://(?:\w+(?::\w+)?@)?[-\w]+(?:\.\w[-\w]*)+
        |
        (?:mailto:)?[-\+\w]+\@[-\w]+(?:\.\w[-\w]*)+
        |
        # or, try to find a hostname with our more specific sub-expression
        (?i: [a-z0-9] (?:[-a-z0-9]*[a-z0-9])? \. )+ # sub domains
        # Now ending .com, etc. For these, require lowercase
        (?-i: com\b
            | edu\b
            | biz\b
            | gov\b
            | in(?:t|fo)\b # .int or .info
            | mil\b
            | net\b
            | org\b
            | museum\b
            | aero\b
            | coop\b
            | name\b
            | pro\b
            | [a-z][a-z]\b # two-letter country codes
        )
    )?

    # Allow an optional port number
    (?: : \d+ )?

    # The rest of the URL is optional, and begins with / . . .
    (?:
     /?
     # The rest are heuristics for what seems to work well
     [^.!,?;:"'<>()\[\]{}\s\x7F-\xFF]*
     (?:
        [.!,?;:]+  [^.!,?;:"'<>()\[\]{}\s\x7F-\xFF]+ #'"
     )*
    )?
}x;

$punct = qr{[\!"#\$%&'()\*\+,\-\./:;<=>\?@\[\\\]\^_`{\|}\~]};
$valignre = qr/[\-^~]/;
$tblalignre = qr/[<>=]/;
$halignre = qr/(?:<>|[<>=])/;
$alignre = qr/(?:$valignre|<>$valignre?|$valignre?<>|$valignre?$halignre?|$halignre?$valignre?)(?!\w)/;
$imgalignre = qr/(?:[<>]|$valignre){1,2}/;

$clstypadre = qr!
  (?:\([A-Za-z0-9\- \#]+\))
  |
  (?:{
      (?: \( [^)]+ \) | [^}] )+
     })
  |
  (?:\(+?)
  |
  (?:\)+?)
  |
  (?: \[ [a-zA-Z\-]+? \] )
!x;

$clstyre = qr!
  (?:\([A-Za-z0-9\- \#]+\))
  |
  (?:{
      (?: \( [^)]+ \) | [^}] )+
     })
  |
  (?: \[ [a-zA-Z\-]+? \] )
!x;

$clstyfiltre = qr!
  (?:\([A-Za-z0-9_\- \#]+\))
  |
  (?:{
      (?: \( [^)]+ \) | [^}] )+
     })
  |
  (?:\|[^\|]+\|)
  |
  (?:\(+)
  |
  (?:\)+)
  |
  (?: \[ [a-zA-Z]+? \] )
!x;

$codere = qr!
    (?:
      [\[{]
      @                           # opening
      (?:\|([A-Za-z0-9]+)\|)?     # $1: language id
      (.+?)                       # $2: code
      @                           # closing
      [\]}]
    )
    |
    (?:
      (?:^|(?<=[\s\(]))
      @                           # opening
      (?:\|([A-Za-z0-9]+)\|)?     # $3: language id
      (.+?)                       # $4: code itself
      @                           # closing
      (?:$|(?=$punct{1,2}|\s))
    )
!x;

$blocktags = qr{
    <
    (( /? ( h[1-6]
     | p
     | pre
     | div
     | table
     | t[rdh]
     | [ou]l
     | li
     | block(?:quote|code)
     | form
     | input
     | select
     | option
     | textarea
     )
    [ >]
    )
    | !--
    )
}x;

sub textile {
    my $str = shift;
    my $self = shift;

    # disable warnings for the sake of various regex that
    # have optional matches
    local $^W = 0;

    if ((ref $str) && ($str->isa('Text::Textile'))) {
        # oops -- OOP technique used so swap params...
        ($self, $str) = ($str, $self);
    } else {
        if (!$self) {
            $self = new Text::Textile;
        }
    }

    my %macros = ('bq' => 'blockquote');
    my @repl;

    # strip out extra newline characters. we're only matching for \n herein
    $str =~ tr!\r!!d;

    # preserve contents of the '==', 'pre', 'blockcode' sections
    $str =~ s!(^|\n\n)==(.+?)==($|\n\n)!$1."\n\n"._repl(\@repl, $2)."\n\n".$3!ges;

    unless ($self->{disable_html}) {
        $str =~ s!(<script(?:>| .+?>).*?</script>)!_repl(\@repl, $1)!ges;

        $str =~ s|(<!--.+?-->)|_repl(\@repl, $1)|ges;

        my $pre_start = scalar(@repl);
        $str =~ s|(<pre(?: [^>]*)?>)(.+?)(</pre>)|"\n\n"._repl(\@repl, $1.$self->encode_html($2, 1).$3)."\n\n"|ges;
        # fix code tags within pre blocks we just saved.
        for (my $i = $pre_start; $i < scalar(@repl); $i++) {
            $repl[$i] =~ s|(&lt;/?code.*?&gt;)|$self->decode_html($1)|ges;
        }

        $str =~ s|(<code(?: [^>]+)?>)(.+?)(</code>)|_repl(\@repl, $1.$self->encode_html($2, 1).$3)|ges;

        $str =~ s|(<blockcode(?: [^>]+)?>)(.+?)(</blockcode>)|"\n\n"._repl(\@repl, $1.$self->encode_html($2, 1).$3)."\n\n"|ges;

        # preserve PHPish, ASPish code
        $str =~ s!(<([\?\%]).*?(\2)>)!_repl(\@repl, $1)!ges;
    }

    my %links;
    ## John's method:
    ##$str =~ s{(?:\n|^) [ ]* \[\[ (\d+) \] \s* "(.+?)" [ ]* (?:"(.+?)")? [ ]*\] [ ]* (\n|$)}
    ##         {($links{$1} = {url => $2, title => $3}),"$4"}gemx;
    $str =~ s{(?:\n|^) [ ]* \[ ([^ ]+?) [ ]*? (?:\( (.+?) \) )?  \] ((?:(?:ftp|https?|telnet|nntp)://|/)[^ ]+?) [ ]* (\n|$)}
             {($links{$1} = {url => $3, title => $2}),"$4"}gemx;
    local $self->{links} = \%links;
    $str =~ s/^\n+//s;
    $str =~ s/\n+$//s;

    # split up text into paragraph blocks
    my @para = split /\n{2,}/, $str;
    my ($block, $bqlang, $filter, $class, $sticky, $cite, @lines, $style, $align, $tablebuff, $padleft, $padright, $lang, $clear);

    my $out = '';

    foreach my $para (@para) {
        my $id;
        $block = undef unless $sticky;
        $class = undef unless $sticky;
        $cite = undef unless $sticky;
        $style = '' unless $sticky;
        $lang = undef unless $sticky;
        $align = undef unless $sticky;
        $padleft = undef unless $sticky;
        $padright = undef unless $sticky;
        $sticky++ if $sticky;

        my @lines;
        my $buffer;
        if ($para =~ m/^(h[1-6]|p|bq|bc|fn\d+)($halignre)?($clstyfiltre*)($halignre)?(\.\.?)(:(\d+|$urlre))? /g) {
            if ($sticky) {
	        if ($block eq 'bc') {
	            # close our blockcode section
	            $out =~ s/\n\n$//;
	            $out .= $self->{blockcode_close}."\n\n";
	        } elsif ($block eq 'bq') {
	            $out =~ s/\n\n$//;
	            $out .= '</blockquote>'."\n\n";
	        } elsif ($block eq 'table') {
                    my $table_out = $self->format_table(text => $tablebuff);
                    $table_out = '' if !defined $table_out;
                    $out .= $table_out;
                    $tablebuff = undef;
                }
	        $sticky = 0;
            }
            # block macros: h[1-6](class)., bq(class)., bc(class)., p(class).
            $block = $1;
            if ($5 eq '..') {
                $sticky = 1;
            } else {
                $sticky = 0;
                $cite = undef;
                $class = undef;
                $bqlang = undef;
                $lang = undef;
                $style = '';
                $filter = undef;
            }
            my $params = $3;
            $align = $2 || $4;
            $cite = $6;
            if (defined $params) {
                if ($params =~ m/\|(.+)\|/) {
                    $filter = $1;
                    if ($block eq 'bc') {
                        $bqlang = $filter;
                        $filter = undef;
                    }
                }
                if ($params =~ m/{([^}]+)}/) {
                    $style = $1;
                    $style =~ s/\n/ /g;
                    $params =~ s/{[^}]+}//g;
                }
                if ($params =~ m/\(([A-Za-z0-9_\- ]+?)(?:\#(.+?))?\)/ ||
                    $params =~ m/\(([A-Za-z0-9_\- ]+?)?(?:\#(.+?))\)/) {
                    if ($1 || $2) {
                        $class = $1;
                        $id = $2;
                        if ($class) {
                            $params =~ s/\([A-Za-z0-9_\- ]+?(#.*?)?\)//g;
                        } elsif ($id) {
                            $params =~ s/\(#.+?\)//g;
                        }
                    }
                }
                if ($params =~ m/(\(+)/) {
                    $padleft = length($1);
                    $params =~ s/\(+//;
                }
                if ($params =~ m/(\)+)/) {
                    $padright = length($1);
                    $params =~ s/\)+//;
                }
                if ($params =~ m/\[(.+?)\]/) {
                    $lang = $1;
                    $params =~ s/\[.+?\]//;
                }
            }
            $cite =~ s/^:// if defined $cite;
            $para = substr($para, pos($para));
        } elsif ($para =~ m|^<textile#(\d+)>$|) {
            my $num = $1;
            #if ($repl[$num-1] =~ m/$blocktags/) {
	        $buffer = $repl[$num-1];
            #}
        } elsif ($para =~ m/^clear([<>]+)\.$/) {
            if ($1 eq '<') {
                $clear = 'left';
            } elsif ($1 eq '>') {
                $clear = 'right';
            } else {
                $clear = 'both';
            }
            next;
        } elsif ($sticky && (defined $block && $block eq 'table')) {
            $tablebuff .= "\n\n" . $para;
            next;
        } elsif ($para =~ m/^($halignre?)($clstypadre)*($halignre?)[\*\#]($halignre?)($clstypadre)*($halignre?) /) {
            # '*', '#' prefix means a list
            $buffer = $self->format_list(text => $para);
        } elsif ($para =~ m/^(?:table(?:$tblalignre?)(?:$clstypadre)*(?:$tblalignre?)(\.\.?)\s+)?(?:_|$alignre?)(?:$clstypadre)*(?:_|$alignre?)\|/) {
            # handle wiki-style tables
            if (defined $1 && ($1 eq '..')) {
                $block = 'table';
                $tablebuff = $para;
                $sticky = 1;
                next;
            } else {
                $buffer = $self->format_table(text => $para);
            }
        }
        if (defined $buffer) {
            $out .= $buffer;
            next;
        }
        @lines = split /\n/, $para;
        next unless @lines;

        $block ||= 'p';

        $buffer = '';
        my $pre = '';
        my $post = '';

        if ($block eq 'bc') {
            if ($sticky <= 1) {
	        $pre .= $self->{blockcode_open};
	        $pre =~ s/>$//s;
	        $pre .= qq{ language="$bqlang"} if $bqlang;
                if ($align) {
                    my $alignment = _halign($align);
                    if ($self->{css_mode}) {
                        if ($padleft || $padright) {
                            $style .= ';float:'.$alignment;
                        } else {
                            $style .= ';text-align:'.$alignment;
                        }
                        $class .= ' '.$self->{css}{"class_align_$alignment"} || $alignment;
                    } else {
                        $pre .= qq{ align="$alignment"};
                    }
                }
                $style .= qq{;padding-left:${padleft}em} if $padleft;
                $style .= qq{;padding-right:${padright}em} if $padright;
                $style .= qq{;clear:${clear}} if $clear;
                $class =~ s/^ // if $class;
	        $pre .= qq{ class="$class"} if $class;
	        $pre .= qq{ id="$id"} if $id;
                $style =~ s/^;// if $style;
                $pre .= qq{ style="$style"} if $style;
	        $pre .= qq{ lang="$lang"} if $lang;
	        #$pre .= qq{ cite="} . $self->format_url($cite) . '"' if defined $cite;
	        $pre .= '>';
                $lang = undef;
                $bqlang = undef;
                $clear = undef;
            }
            $para =~ s|==(?![\ '0-9A-Za-z\$:])(.+?)==|_repl(\@repl, $self->format_block(text => $1, inline => 1))|ges;
            $buffer .= $self->encode_html_basic($para, 1);
            $buffer =~ s/&lt;textile#(\d+)&gt;/<textile#$1>/g;
            if ($sticky == 0) {
	        $post .= $self->{blockcode_close}."\n\n";
            } else {
	        $post .= "\n\n";
            }
            $out .= $pre . $buffer . $post;
            next;
        } elsif ($block eq 'bq') {
            if ($sticky <= 1) {
	        $pre .= '<blockquote';
                if ($align) {
                    my $alignment = _halign($align);
                    if ($self->{css_mode}) {
                        if ($padleft || $padright) {
                            $style .= ';float:'.$alignment;
                        } else {
                            $style .= ';text-align:'.$alignment;
                        }
                        $class .= ' '.$self->{css}{"class_align_$alignment"} || $alignment;
                    } else {
                        $pre .= qq{ align="$alignment"};
                    }
                }
                $style .= qq{;padding-left:${padleft}em} if $padleft;
                $style .= qq{;padding-right:${padright}em} if $padright;
                $style .= qq{;clear:${clear}} if $clear;
                $class =~ s/^ // if $class;
	        $pre .= qq{ class="$class"} if defined $class;
	        $pre .= qq{ id="$id"} if defined $id;
                $style =~ s/^;// if $style;
                $pre .= qq{ style="$style"} if $style;
	        $pre .= qq{ lang="$lang"} if $lang;
	        $pre .= qq{ cite="} . $self->format_url(url => $cite) . '"' if defined $cite;
	        $pre .= '>';
                $clear = undef;
            }
            $pre .= '<p>';
        } elsif ($block =~ m/fn(\d+)/) {
            my $fnum = $1;
            $pre .= '<p';
            $class .= ' '.$self->{css}{class_footnote} if $self->{css}{class_footnote};
            if ($align) {
                my $alignment = _halign($align);
                if ($self->{css_mode}) {
                    if ($padleft || $padright) {
                        $style .= ';float:'.$alignment;
                    } else {
                        $style .= ';text-align:'.$alignment;
                    }
                    $class .= $self->{css}{"class_align_$alignment"} || $alignment;
                } else {
                    $pre .= qq{ align="$alignment"};
                }
            }
            $style .= qq{;padding-left:${padleft}em} if $padleft;
            $style .= qq{;padding-right:${padright}em} if $padright;
            $style .= qq{;clear:${clear}} if $clear;
            $class =~ s/^ // if $class;
            $pre .= qq{ class="$class"} if $class;
            $pre .= qq{ id="}.($self->{css}{id_footnote_prefix}||'fn').$fnum.'"';
            $style =~ s/^;// if $style;
            $pre .= qq{ style="$style"} if $style;
	    $pre .= qq{ lang="$lang"} if $lang;
            #$pre .= qq{ cite="} . $self->format_url(url => $cite) .'"' if defined $cite;
            $pre .= '>';
            $pre .= '<sup>'.$fnum.'</sup> ';
            # we can close like a regular paragraph tag now
            $block = 'p';
            $clear = undef;
        } else {
            $pre .= '<' . ($macros{$block} || $block);
            if ($align) {
                my $alignment = _halign($align);
                if ($self->{css_mode}) {
                    if ($padleft || $padright) {
                        $style .= ';float:'.$alignment;
                    } else {
                        $style .= ';text-align:'.$alignment;
                    }
                    $class .= ' '.$self->{css}{"class_align_$alignment"} || $alignment;
                } else {
                    $pre .= qq{ align="$alignment"};
                }
            }
            $style .= qq{;padding-left:${padleft}em} if $padleft;
            $style .= qq{;padding-right:${padright}em} if $padright;
            $style .= qq{;clear:${clear}} if $clear;
            $class =~ s/^ // if $class;
            $pre .= qq{ class="$class"} if $class;
            $pre .= qq{ id="$id"} if $id;
            $style =~ s/^;// if $style;
            $pre .= qq{ style="$style"} if $style;
	    $pre .= qq{ lang="$lang"} if $lang;
            $pre .= qq{ cite="} . $self->format_url(url => $cite) . '"' if defined $cite && $block eq 'bq';
            $pre .= '>';
            $clear = undef;
        }

        $buffer = $self->format_paragraph(text => $para);
        #if ($buffer !~ m/^[^<]/ && $buffer !~ m/>[^<]/) {
        #    $out .= $buffer . "\n\n";
        #    next;
        #}

        if ($block eq 'bq') {
            $post .= '</p>' if $buffer !~ m/<p[ >]/;
            if ($sticky == 0) {
	        $post .= '</blockquote>';
            }
        } else {
            $post .= '</' . $block . '>';
        }

        if ($buffer =~ m/$blocktags/) {
            $buffer =~ s/^\n\n//s;
            $out .= $buffer;
        } else {
            $buffer = $self->format_block(text => "|$filter|".$buffer, inline => 1) if defined $filter;
            $out .= $pre . $buffer . $post;
        }

        $out .= "\n\n";
    }

    $out =~ s/\n\n$//;

    if ($sticky) {
        if ($block eq 'bc') {
            # close our blockcode section
            $out .= $self->{blockcode_close} . "\n\n";
        } elsif ($block eq 'bq') {
            $out .= '</blockquote>' . "\n\n";
        } elsif (($block eq 'table') && ($tablebuff)) {
            my $table_out = $self->format_table(text => $tablebuff);
            $out .= $table_out if defined $table_out;
        }
    }

    # cleanup-- restore preserved blocks
    my $i = scalar(@repl);
    $out =~ s|<textile#$i>|$_|, $i-- while $_ = pop @repl;

    $out;
}

sub format_paragraph {
    my $self = shift;
    my (%args) = @_;
    my $buffer = exists $args{text} ? $args{text} : '';

    my @repl;
    $buffer =~ s|==(?![\ '0-9A-Za-z\$:])(.+?)==|_repl(\@repl, $self->format_block(text => $1, inline => 1))|ges;

    my $tokens;
    if ($buffer =~ m/</ && (!$self->{disable_html})) {  # optimization -- no point in tokenizing if we
                            # have no tags to tokenize
        $tokens = _tokenize($buffer);
    } else {
        $tokens = [['text', $buffer]];
    }
    my $result = '';
    foreach my $token (@$tokens) {
        my $text = $token->[1];
        if ($token->[0] eq 'tag') {
#            $text =~ s/&(?!amp;)/&amp;/g;
# modif BJR : ressemble une HTML entity
            $text =~ s/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w{1,8});)/&amp;/g;

            $result .= $text;
        } else {
            if ($text =~ m/[^a-z0-9\s\.:]/) {
	        $text = $self->format_inline(text => $text);
            }
            #if ($result !~ m/$blocktags/) {
	    #    if ($text =~ m/\n/) {
	    #        if ($self->{line_open}) {
            #            $text =~ s/^/$self->{line_open}/gm;
            #            $text =~ s/(\n|$)/$self->{line_close}$1/gs;
            #        } else {
            #            $text =~ s/(\n)/$self->{line_close}$1/gs;
            #        }
            #    }
            #}
            $result .= $text;
        }
    }

    # now, add line breaks for lines that contain plaintext
    my @lines = split /\n/, $result;
    $result = '';
    my $needs_closing = 0;
    foreach my $line (@lines) {
        if (($line !~ m/$blocktags/)
            && ($line =~ m/^[^<]/ || $line =~ />[^<]/)) {
            if ($self->{line_open}) {
                $result .= "\n" if $result ne '';
                $result .= $self->{line_open} . $line . $self->{line_close};
            } else {
                if ($needs_closing) {
                    $result .= $self->{line_close} ."\n";
                } else {
                    $needs_closing = 1;
                    $result .= "\n" if $result ne '';
                }
                $result .= $line;
            }
        } else {
            if ($needs_closing) {
                $result .= $self->{line_close} ."\n";
            } else {
                $result .= "\n" if $result ne '';
            }
            $result .= $line;
            $needs_closing = 0;
        }
    }
    $result =~ s/\r/\n/g;

    my $i = scalar(@repl);
    $result =~ s|<textile#$i>|$_|, $i-- while $_ = pop @repl;

    $result;
}

{
my @qtags = (['**', 'b',      '(?<!\*)\*\*(?!\*)', '\*'],
             ['__', 'i',      '(?<!_)__(?!_)', '_'],
             ['??', 'cite',   '\?\?(?!\?)', '\?'],
             ['*',  'strong', '(?<!\*)\*(?!\*)', '\*'],
             ['_',  'em',     '(?<!_)_(?!_)', '_'],
             ['-',  'del',    '(?<!\-)\-(?!\-)', '-'],
             ['+',  'ins',    '(?<!\+)\+(?!\+)', '\+'],
             ['~',  'sub',    '(?<!\~)\~(?![\\\/~])', '\~']);


sub format_inline {
    my $self = shift;
    my (%args) = @_;
    my $text = exists $args{text} ? $args{text} : '';

    my @repl;

    $text =~ s!$codere!_repl(\@repl, $self->format_code(text => $2.$4, lang => $1.$3))!gem;

    # images must be processed before encoding the text since they might
    # have the <, > alignment specifiers...

    # !blah (alt)! -> image
    $text =~ s!(?:^|(?<=[\s>])|([{[]))     # $1: open brace/bracket
               \!                          # opening
               ($imgalignre?)              # $2: optional alignment
               ($clstypadre*)              # $3: optional CSS class/id
               ($imgalignre?)              # $4: optional alignment
               (?:\s*)                     # optional space between alignment/css stuff
               ([^\s\(\!]+)                # $5: filename
               (\s*[^\(\!]*(?:\([^\)]+\))?[^\!]*) # $6: extra stuff (alt text, sizes, etc)
               \!                          # closing
               (?::(\d+|$urlre))?          # $7: optional URL
               (?:$|([\]}])|(?=$punct{1,2}|\s))# $8: closing brace/bracket
              !_repl(\@repl, $self->format_image(pre => $1, src => $5, align => $2||$4, extra => $6, url => $7, clsty => $3, post => $8))!gemx;

    $text =~ s!(?:^|(?<=[\s>])|([{[]))     # $1: open brace/bracket
               \%                          # opening
               ($halignre?)                # $2: optional alignment
               ($clstyre*)                 # $3: optional CSS class/id
               ($halignre?)                # $4: optional alignment
               (?:\s*)                     # spacing
               ([^\%]+?)                   # $5: text
               \%                          # closing
               (?::(\d+|$urlre))?          # $6: optional URL
               (?:$|([\]}])|(?=$punct{1,2}|\s))# $7: closing brace/bracket
              !_repl(\@repl, $self->format_span(pre => $1,text => $5,align => $2||$4, cite => $6, clsty => $3, post => $7))!gemx;

    $text = $self->encode_html($text);
    $text =~ s!&lt;textile#(\d+)&gt;!<textile#$1>!g;
    $text =~ s!&amp;quot;!&#34;!g;
    $text =~ s!&amp;(([a-z]+|#\d+);)!&$1!g;
    $text =~ s!&quot;!"!g; #"

    # These create markup with entities. Do first and 'save' result for later:
    # "text":url -> hyperlink
    # links with brackets surrounding
    my $parenre = qr/\( (?: [^()] )* \) /x;
    $text =~ s!(
               [{[]
               (?:
                   (?:"                    # quote character
                      ($clstyre*)?         # $2: optional CSS class/id
                      (.+?)                # $3: link text
                      (?:\( ( (?:[^()]|$parenre)*) \))?    # $4: optional link title
                      "                    # closing quote
                   )
                   |
                   (?:'                    # open single quote
                      ($clstyre*)?         # $5: optional CSS class/id
                      (.+?)                # $6: link text
                      (?:\( ( (?:[^()]|$parenre)*) \))?    # $7: optional link title
                      '                    # closing quote
                   )
               )
               :(\d+|$urlre)               # $8: URL suffix
               [\]}]
              )
              !_repl(\@repl, $self->format_link(text => $1,linktext => $3.$6, title => $self->encode_html_basic($4.$7), url => $8, clsty => $2.$5))!gemx;

    $text =~ s!((?:^|(?<=[\s>\(]))         # $1: open brace/bracket
               (?: (?:"                    # quote character
                      ($clstyre*)?         # $2: optional CSS class/id
                      ([^"]+?)             # $3: link text
                      (?:\( ( (?:[^()]|$parenre)*) \))?    # $4: optional link title
                      "                    # closing quote
                   )
                   |
                   (?:'                    # open single quote
                      ($clstyre*)?         # $5: optional CSS class/id
                      ([^']+?)             # $6: link text
                      (?:\( ( (?:[^()]|$parenre)*) \))?    # $7: optional link title
                      '                    # closing quote
                   )
               )
               :(\d+|$urlre)               # $8: URL suffix
               (?:$|(?=$punct{1,2}|\s)))# $9: closing brace/bracket
              !_repl(\@repl, $self->format_link(text => $1, linktext => $3.$6, title => $self->encode_html_basic($4.$7), url => $8, clsty => $2.$5))!gemx;

    if ($self->{flavor} eq 'xhtml2') {
        # citation with cite link
        $text =~ s!(?:^|(?<=[\s>'"\(])|([{[])) # $1: open brace/bracket
                   \?\?                        # opening '??'
                   ([^\?]+?)                   # $2: characters (can't contain '?')
                   \?\?                        # closing '??'
                   :(\d+|$urlre)               # $3: optional citation URL
                   (?:$|([\]}])|(?=$punct{1,2}|\s))# $4: closing brace/bracket
                  !_repl(\@repl, $self->format_cite(pre => $1,text => $2,cite => $3,post => $4))!gemx;
    }

    # footnotes
    if ($text =~ m/[^ ]\[\d+\]/) {
        my $fntag = '<sup';
        $fntag .= ' class="'.$self->{css}{class_footnote}.'"' if $self->{css}{class_footnote};
        $fntag .= '><a href="#'.($self->{css}{id_footnote_prefix}||'fn');
        $text =~ s|([^ ])\[(\d+)\]|$1$fntag$2">$2</a></sup>|g;
    }

    # (tm) -> &trade;
    $text =~ s|[\(\[]TM[\)\]]|&trade;|gi;
    # (c) -> &copy;
    $text =~ s|[\(\[]C[\)\]]|&copy;|gi;
    # (r) -> &reg;
    $text =~ s|[\(\[]R[\)\]]|<sup>&reg;</sup>|gi;

    my $redo = $text =~ m/[\*_\?\-\+\^\~]/;
    my $last = $text;
    while ($redo) {
        # simple replacements...
        $redo = 0;
        foreach my $tag (@qtags) {
            my ($f, $r, $qf, $cls) = @$tag;
            if ($text =~ s/(?:^|(?<=[\s>'"])|([{[])) # "' $1 - pre
                           $qf                       #
                           (?:($clstyre*))?          # $2 - attributes
                           ([^$cls\s].*?)                 # $3 - content
                           (?<=\S)$qf                #
                           (?:$|([\]}])|(?=$punct{1,2}|\s)) # $4 - post
                          /$self->format_tag(tag => $r, marker => $f, pre => $1, text => $3, clsty => $2, post => $4)/gemx) {
	        $redo = $last ne $text;
	        $last = $text;
            }
        }
    }

    # superscript is an even simpler replacement...
    $text =~ s/(?<!\^)\^(?!\^)(.+?)(?<!\^)\^(?!\^)/<sup>$1<\/sup>/g;

    # ABC(Aye Bee Cee) -> acronym
    $text =~ s|\b([A-Z][A-Z0-9]+?)\b(?:[(]([^)]*)[)])|_repl(\@repl,qq{<acronym title="}.$self->encode_html_basic($2).qq{">$1</acronym>})|ge;

    # ABC -> 'capped' span
    if (my $caps = $self->{css}{class_caps}) {
        $text =~ s/(^|[^"][>\s])
                   ([A-Z](?:[A-Z0-9\.,' ]|\&amp;){2,})
                   (?=[^a-z0-9]|$)
                  /$1._repl(\@repl, qq{<span class="$caps">$2<\/span>})/gemx;
    }

    # nxn -> n&times;n
    $text =~ s|(\d+['"]?) ?x ?(\d)|$1&times;$2|g; #"'

    #$text =~ s!<(ins|del)>\[(\d{1,2}/\d{1,2}/\d{2,4}( \d{1,2}:\d\d(:\d\d)?)?)\]!$self->format_datetime($1, $2, $3, $4)!ges;

    # translate these encodings to the Unicode equivalents:
    $text =~ s/&#133;/&#8230;/g;
    $text =~ s/&#145;/&#8216;/g;
    $text =~ s/&#146;/&#8217;/g;
    $text =~ s/&#147;/&#8220;/g;
    $text =~ s/&#148;/&#8221;/g;
    $text =~ s/&#150;/&#8211;/g;
    $text =~ s/&#151;/&#8212;/g;

    $text = $self->apply_text_filters(text => $text) if @{$self->{text_filters}};

    # Restore replacements done earlier:
    my $i = scalar(@repl);
    $text =~ s|<textile#$i>|$_|, $i-- while $_ = pop @repl;

    $text;
}
}

sub _halign {
    my ($align) = @_;

    study $align;
    if ($align =~ m/<>/) {
        return "justify";
    } elsif ($align =~ m/</) {
        return "left";
    } elsif ($align =~ m/>/) {
        return "right";
    } elsif ($align =~ m/=/) {
        return "center";
    }
    return '';
}

sub _valign {
    my ($align) = @_;

    study $align;
    if ($align =~ m/\^/) {
        return "top";
    } elsif ($align =~ m/~/) {
        return "bottom";
    } elsif ($align =~ m/-/) {
        return "middle";
    }
    return '';
}

sub _imgalign {
    my ($align) = @_;

    $align =~ s/(<>|=)//g;
    return _valign($align) || _halign($align);
}

sub _strip_borders {
    my ($pre, $post) = @_;
    if ($$post && $$pre && ((my $open = substr($$pre, 0, 1)) =~ m/[{[]/)) {
        my $close = substr($$post, 0, 1);
        if ((($open eq '{') && ($close eq '}')) ||
            (($open eq '[') && ($close eq ']'))) {
            $$pre = substr($$pre, 1);
            $$post = substr($$post, 1);
        } else {
            $close = substr($$post, -1, 1) if $close !~ m/[}\]]/;
            if ((($open eq '{') && ($close eq '}')) ||
                (($open eq '[') && ($close eq ']'))) {
                $$pre = substr($$pre, 1);
                $$post = substr($$post, 0, length($$post) - 1);
            }
        }
    }
}

sub format_cite {
    my $self = shift;
    my (%args) = @_;
    my $pre = exists $args{pre} ? $args{pre} : '';
    my $text = exists $args{text} ? $args{text} : '';
    my $cite = $args{cite};
    my $post = exists $args{post} ? $args{post} : '';
    print "<!-- pre = $pre; text = $text; cite = $cite; post = $post; -->\n" if $debug;
    _strip_borders(\$pre, \$post);
    my $tag = $pre.'<cite';
    if (($self->{flavor} eq 'xhtml2') && defined $cite && $cite) {
      $cite = $self->format_url(url => $cite);
      $tag .= qq{ cite="$cite"};
    } else {
      $post .= ':';
    }
    $tag .= '>';
    $tag . $self->format_inline(text => $text) . '</cite>'.$post;
}

sub format_code {
    my $self = shift;
    my (%args) = @_;
    my $code = exists $args{text} ? $args{text} : '';
    my $lang = $args{lang};
    $code = $self->encode_html($code, 1);
    $code =~ s/&lt;textile#(\d+)&gt;/<textile#$1>/g;
    my $tag = '<code';
    $tag .= " language=\"$lang\"" if $lang;
    $tag . '>' . $code . '</code>';
}

#sub format_datetime {
#    my $self = shift;
#    my ($tag, $date, $hourmin, $sec) = @_;
#
#    my $tag = '<' . $tag;
#    if (defined $date) {
#    }
#    if (defined $hourmin) {
#        if (defined $sec) {
#        }
#    }
#    $tag . '>';
#}

sub format_classstyle {
    my $self = shift;
    my ($clsty, $class, $style) = @_;

    $class =~ s/^ //;

    my ($lang, $padleft, $padright, $id);
    if ($clsty && ($clsty =~ m/{([^}]+)}/)) {
        my $_style = $1;
        $_style =~ s/\n/ /g;
        $style .= ';'.$_style;
        $clsty =~ s/{[^}]+}//g;
    }
    if ($clsty && ($clsty =~ m/\(([A-Za-z0-9_\- ]+?)(?:#(.+?))?\)/ ||
                   $clsty =~ m/\(([A-Za-z0-9_\- ]+?)?(?:#(.+?))\)/)) {
        if ($1 || $2) {
            if ($class) {
                $class = $1 . ' ' . $class;
            } else {
                $class = $1;
            }
            $id = $2;
            if ($class) {
                $clsty =~ s/\([A-Za-z0-9_\- ]+?(#.*?)?\)//g;
            }
            if ($id) {
                $clsty =~ s/\(#.+?\)//g;
            }
        }
    }
    if ($clsty && ($clsty =~ m/(\(+)/)) {
        $padleft = length($1);
        $clsty =~ s/\(+//;
    }
    if ($clsty && ($clsty =~ m/(\)+)/)) {
        $padright = length($1);
        $clsty =~ s/\)+//;
    }
    if ($clsty && ($clsty =~ m/\[(.+?)\]/)) {
        $lang = $1;
        $clsty =~ s/\[.+?\]//g;
    }
    my $attrs = '';
    $style .= qq{;padding-left:${padleft}em} if $padleft;
    $style .= qq{;padding-right:${padright}em} if $padright;
    $style =~ s/^;//;
    $class =~ s/^ //;
    $class =~ s/ $//;
    $attrs .= qq{ class="$class"} if $class;
    $attrs .= qq{ id="$id"} if $id;
    $attrs .= qq{ style="$style"} if $style;
    $attrs .= qq{ lang="$lang"} if $lang;
    $attrs =~ s/^ //;
    $attrs;
}

sub apply_text_filters {
    my $self = shift;
    my (%args) = @_;
    my $text = $args{text};
    return '' unless defined $text;
    my $filters = $self->text_filters;
    return $text unless (ref $filters) eq 'ARRAY';

    my $param = $self->filter_param;
    foreach my $filter (@$filters) {
        if ((ref $filter) eq 'CODE') {
            $text = $filter->($text, $param);
        }
    }
    $text;
}

sub apply_named_filters {
    my $self = shift;
    my (%args) = @_;
    my $text = $args{text};
    return '' unless defined $text;
    my $list = $args{filters};
    my $filters = $self->named_filters;
    return $text unless (ref $filters) eq 'HASH';

    my $param = $self->filter_param;
    foreach my $filter (@$list) {
        next unless exists $filters->{$filter};
        if ((ref $filters->{$filter}) eq 'CODE') {
            $text = $filters->{$filter}->($text, $param);
        }
    }
    $text;
}

sub format_tag {
    my $self = shift;
    my (%args) = @_;
    my $tagname = $args{tag};
    my $text = exists $args{text} ? $args{text} : '';
    my $pre = exists $args{pre} ? $args{pre} : '';
    my $post = exists $args{post} ? $args{post} : '';
    my $clsty = exists $args{clsty} ? $args{clsty} : '';
    ##my ($tagname, $marker, $pre, $text, $clsty, $post) = @_;
    print "<!-- tag = $tagname; clsty = $clsty; pre = $pre; post = $post -->\n" if $debug;
    _strip_borders(\$pre, \$post);
    my $tag = "<$tagname";
    my $attr = $self->format_classstyle($clsty);
    $tag .= qq{ $attr} if $attr;
    $tag .= qq{>$text</$tagname>};
    $pre.$tag.$post;
}

{
    my $Have_Entities = eval 'use HTML::Entities; 1' ? 1 : 0;

    sub encode_html {
        my $self = shift;
        my($html, $can_double_encode) = @_;
        return '' unless defined $html;
        return $html unless $html =~ m/[^\w\s]/;
        if ($Have_Entities && $self->{char_encoding}) {
            $html = HTML::Entities::encode_entities($html);
        } else {
            $html = $self->encode_html_basic($html, $can_double_encode);
        }
        $html;
    }

    sub decode_html {
        my $self = shift;
        my ($html) = @_;
        $html =~ s!&quot;!"!g;
        $html =~ s!&amp;!&!g;
        $html =~ s!&lt;!<!g;
        $html =~ s!&gt;!>!g;
        $html;
    }

    sub encode_html_basic {
        my $self = shift;
        my($html, $can_double_encode) = @_;
        return '' unless defined $html;
        return $html unless $html =~ m/[^\w\s]/;
        if ($can_double_encode) {
            $html =~ s!&!&amp;!g;
        } else {
            ## Encode any & not followed by something that looks like
            ## an entity, numeric or otherwise.
            $html =~ s/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w{1,8});)/&amp;/g;
        }
        $html =~ s!"!&quot;!g;
        $html =~ s!<!&lt;!g;
        $html =~ s!>!&gt;!g;
        $html;
    }

}

{
    my $Have_ImageSize = eval 'use Image::Size; 1' ? 1 : 0;

    sub image_size {
        my $self = shift;
        my ($file) = @_;
        if ($Have_ImageSize) {
            if (-f $file) {
                return Image::Size::imgsize($file);
            } else {
                if (my $docroot = $self->docroot) {
                    my $fullpath = File::Spec->catfile($docroot, $file);
                    if (-f $fullpath) {
                        return Image::Size::imgsize($fullpath);
                    }
                }
            }
        }
        undef;
    }
}

sub format_list {
    my $self = shift;
    my (%args) = @_;
    my $str = exists $args{text} ? $args{text} : '';

    my %list_tags = ('*' => 'ul', '#' => 'ol');

    my @lines = split /\n/, $str;

    my @stack;
    my $last_depth = 0;
    my $item = '';
    my $out = '';
    foreach my $line (@lines) {
        if ($line =~ m/^($halignre)?($clstypadre*)($halignre)?([\#\*]+)($halignre)?($clstypadre*)($halignre)? (.+)$/) {
            if ($item ne '') {
                if ($item =~ m/\n/) {
                    if ($self->{line_open}) {
                        $item =~ s/(<li[^>]*>|^)/$1$self->{line_open}/gm;
                        $item =~ s/(\n|$)/$self->{line_close}$1/gs;
                    } else {
                        $item =~ s/(\n)/$self->{line_close}$1/gs;
                    }
                }
                $out .= $item;
                $item = '';
            }
            my $type = substr($4, 0, 1);
            my $depth = length($4);
            my $blockalign = $1 || $3;
            my $itemalign = $5 || $7;
            my ($blockstyle, $blockid);
            my ($itemattr, $itemstyle, $itemclass, $itemid, $itemlang, $itempadl, $itempadr);
            my $blockclass = $2;
            my $itemclsty = $6;
            $line = $8;

            if ((defined $blockclass) &&
                ($blockclass =~ m/{([^}]+)}/)) {
                $blockstyle = $1;
                $blockclass =~ s/{[^}]+}//;
            }
            if ((defined $blockclass) &&
                ($blockclass =~ m/\(([A-Za-z0-9_\- ]+?)?(?:#(.*))?\)/)) {
                $blockclass = $1;
                $blockid = $2;
            }
            $itemattr = $self->format_classstyle($itemclsty) if $itemclsty;
            if ($depth > $last_depth) {
                for (my $j = $last_depth; $j < $depth; $j++) {
                    $out .= "\n<$list_tags{$type}";
                    push @stack, $type;
                    if ($blockclass) {
                        $out .= " class=\"$blockclass\"";
                        undef $blockclass;
                    }
                    if ($blockid) {
                        $out .= " id=\"$blockid\"";
                        undef $blockid;
                    }
                    if ($blockstyle) {
                        $out .= " style=\"$blockstyle\"";
                        undef $blockstyle;
                    }
                    $out .= ">\n<li";
                    $out .= qq{ $itemattr} if $itemattr;
                    $out .= ">";
                }
            } elsif ($depth < $last_depth) {
                for (my $j = $depth; $j < $last_depth; $j++) {
                    $out .= "</li>\n" if $j == $depth;
                    my $type = pop @stack;
                    $out .= "</$list_tags{$type}>\n";
                    $out .= "</li>\n";
                }
                if ($depth) {
                    $out .= '<li';
                    $out .= qq{ $itemattr} if $itemattr;
                    $out .= ">";
                }
            } else {
                $out .= "</li>\n<li";
                $out .= qq{ $itemattr} if $itemattr;
                $out .= ">";
            }
            $last_depth = $depth;
        }
        $item .= "\n" if $item ne '';
        $item .= $self->format_paragraph(text => $line);
    }

    if ($item =~ m/\n/) {
        if ($self->{line_open}) {
            $item =~ s/(<li[^>]*>|^)/$1$self->{line_open}/gm;
            $item =~ s/(\n|$)/$self->{line_close}$1/gs;
        } else {
            $item =~ s/(\n)/$self->{line_close}$1/gs;
        }
    }
    $out .= $item;

    for (my $j = 1; $j <= $last_depth; $j++) {
        $out .= '</li>' if $j == 1;
        my $type = pop @stack;
        $out .= "\n".'</'.$list_tags{$type}.'>'."\n";
        $out .= '</li>' if $j != $last_depth;
    }

    $out."\n";
}

sub format_block {
    my $self = shift;
    my (%args) = @_;
    my $str = exists $args{text} ? $args{text} : '';
    my $inline = $args{inline};
    my ($filters) = $str =~ m/^(\|(?:(?:[a-z0-9_\-]+)\|)+)/;
    if ($filters) {
        my $filtreg = quotemeta($filters);
        $str =~ s/^$filtreg//;
        $filters =~ s/^\|//;
        $filters =~ s/\|$//;
        my @filters = split /\|/, $filters;
        $str = $self->apply_named_filters(text => $str, filters => \@filters);
        my $count = scalar(@filters);
        if ($str =~ s!(<p>){$count}!$1!gs) {
            $str =~ s!(</p>){$count}!$1!gs;
            $str =~ s!(<br( /)?>){$count}!$1!gs;
        }
    }
    if ($inline) {
        # strip off opening para, closing para, since we're
        # operating within an inline block
        $str =~ s/^\s*<p[^>]*>//;
        $str =~ s/<\/p>\s*$//;
    }
    $str;
}

sub format_link {
    my $self = shift;
    my (%args) = @_;
    my $text = exists $args{text} ? $args{text} : '';
    my $linktext = exists $args{linktext} ? $args{linktext} : '';
    my $title = $args{title};
    my $url = $args{url};
    my $clsty = $args{clsty};

    #print "<!-- pre = $pre; text = $text; title = $title; class = $clsty; post = $post -->\n" if $debug;
    if (!defined $url || $url eq '') {
        return $text;
    }
    if (exists $self->{links} && exists $self->{links}{$url}) {
        $title ||= $self->{links}{$url}{title};
        $url = $self->{links}{$url}{url};
    }
    $linktext =~ s/ +$//;
    $linktext = $self->format_paragraph(text => $linktext);
    $url = $self->format_url(url => $url);
    my $tag = qq{<a href="$url"};
    my $attr = $self->format_classstyle($clsty);
    $tag .= qq{ $attr} if $attr;
    if (defined $title) {
        $title =~ s/^\s+//;
        $tag .= qq{ title="$title"} if length($title);
    }
    $tag .= qq{>$linktext</a>};
    $tag;
}

sub format_url {
    my $self = shift;
    my (%args) = @_;
    my $url = defined $args{url} ? $args{url} : '';
    if ($url =~ m/^(mailto:)?([-\+\w]+\@[-\w]+(\.\w[-\w]*)+)$/) {
        $url = 'mailto:'.$self->mail_encode($2);
    }
    if ($url !~ m!^(/|\./|\.\./)!) {
        $url = "http://$url" if $url !~ m!^(https?|ftp|mailto|nntp|telnet)!;
    }
    $url =~ s/&(?!amp;)/&amp;/g;
    $url;
}

sub mail_encode {
    my $self = shift;
    my ($addr) = @_;
    # granted, this is simple, but it gives off warm fuzzies
    $addr =~ s/([^\$])/uc sprintf("%%%02x",ord($1))/eg;
    $addr;
}

sub format_span {
    my $self = shift;
    my (%args) = @_;
    my $text = exists $args{text} ? $args{text} : '';
    my $pre = exists $args{pre} ? $args{pre} : '';
    my $post = exists $args{post} ? $args{post} : '';
    my $align = $args{align};
    my $cite = exists $args{cite} ? $args{cite} : '';
    my $clsty = $args{clsty};
    _strip_borders(\$pre, \$post);
    my ($class, $style);
    my $tag  = qq{<span};
    $style = '';
    if (defined $align) {
        if ($self->{css_mode}) {
            my $alignment = _halign($align);
            $style .= qq{;float:$alignment} if $alignment;
            $class .= ' '.$self->{css}{"class_align_$alignment"} if $alignment;
        } else {
            my $alignment = _halign($align) || _valign($align);
            $tag .= qq{ align="$alignment"};
        }
    }
    my $attr = $self->format_classstyle($clsty, $class, $style);
    $tag .= qq{ $attr} if $attr;
    if (defined $cite) {
        $cite =~ s/^://;
        $cite = $self->format_url(url => $cite);
        $tag .= qq{ cite="$cite"};
    }
    $pre.$tag.'>'.$self->format_paragraph(text => $text).'</span>'.$post;
}

sub format_image {
    my $self = shift;
    my (%args) = @_;
    my $src = exists $args{src} ? $args{src} : '';
    my $extra = $args{extra};
    my $align = $args{align};
    my $pre = exists $args{pre} ? $args{pre} : '';
    my $post = exists $args{post} ? $args{post} : '';
    my $link = $args{url};
    my $clsty = $args{clsty};
    print "<!-- image - pre = $pre; src = $src; extra = $extra; link = $link; clsty = $clsty; post = $post -->\n" if $debug;
    _strip_borders(\$pre, \$post);
    return $pre.'!!'.$post if length($src) == 0;
    my $tag;
    if ($self->{flavor} =~ m/^xhtml2/) {
        my $type; # poor man's mime typing. need to extend this externally
        if ($src =~ /(?:\.jpeg|\.jpg)$/) {
            $type = 'image/jpeg';
        } elsif ($src =~ /\.gif$/) {
            $type = 'image/gif';
        } elsif ($src =~ /\.png$/) {
            $type = 'image/png';
        } elsif ($src =~ /\.tiff$/) {
            $type = 'image/tiff';
        }
        $tag = qq{<object};
        $tag .= qq{ type="$type"} if $type;
        $tag .= qq{ data="$src"};
    } else {
        $tag = qq{<img src="$src"};
    }
    my ($class, $style);
    if (defined $align) {
        if ($self->{css_mode}) {
            my $alignment = _halign($align);
            $style .= qq{;float:$alignment} if $alignment;
            $class .= ' '.$alignment if $alignment;
            $alignment = _valign($align);
            if ($alignment) {
                my $imgvalign = ($alignment =~ m/(top|bottom)/ ? 'text-' . $alignment : $alignment);
                $style .= qq{;vertical-align:$imgvalign} if $imgvalign;
                $class .= ' '.$self->{css}{"class_align_$alignment"} if $alignment;
            }
        } else {
            my $alignment = _halign($align) || _valign($align);
            $tag .= qq{ align="$alignment"};
        }
    }
    my $attr = $self->format_classstyle($clsty, $class, $style);
    $tag .= qq{ $attr} if $attr;
    my ($pctw, $pcth, $w, $h, $alt);
    if (defined $extra) {
        ($alt) = $extra =~ m/\(([^\)]+)\)/;
        $extra =~ s/\([^\)]+\)//;
        my ($pct) = ($extra =~ m/(^|\s)(\d+)%(\s|$)/)[1];
        if (!$pct) {
            ($pctw, $pcth) = ($extra =~ m/(^|\s)(\d+)%x(\d+)%(\s|$)/)[1,2];
        } else {
            $pctw = $pcth = $pct;
        }
        if (!$pctw && !$pcth) {
            ($w,$h) = ($extra =~ m/(^|\s)(\d+|\*)x(\d+|\*)(\s|$)/)[1,2];
            $w = '' if $w eq '*';
            $h = '' if $h eq '*';
            if (!$w) {
                ($w) = ($extra =~ m/(^|[,\s])(\d+)w([\s,]|$)/)[1];
            }
            if (!$h) {
                ($h) = ($extra =~ m/(^|[,\s])(\d+)h([\s,]|$)/)[1];
            }
        }
    }
    $alt = '' unless defined $alt;
    if ($self->{flavor} !~ m/^xhtml2/) {
        $tag .= ' alt="' . $self->encode_html_basic($alt) . '"';
    }
    if ($w && $h) {
        $tag .= qq{ height="$h" width="$w"};
    } else {
        my ($image_w, $image_h) = $self->image_size($src);
        if (($image_w && $image_h) && ($w || $h)) {
            # image size determined, but only width or height specified
            if ($w && !$h) {
                # width defined, scale down height proportionately
                $h = int($image_h * ($w / $image_w));
            } elsif ($h && !$w) {
                $w = int($image_w * ($h / $image_h));
            }
        } else {
            $w = $image_w;
            $h = $image_h;
        }
        if ($w && $h) {
            if ($pctw || $pcth) {
                $w = int($w * $pctw / 100);
                $h = int($h * $pcth / 100);
            }
            $tag .= qq{ height="$h" width="$w"};
        }
    }
    if ($self->{flavor} =~ m/^xhtml2/) {
        $tag .= '>' . $self->encode_html_basic($alt) . '</object>';
    } elsif ($self->{flavor} =~ m/^xhtml/) {
        $tag .= ' />';
    } else {
        $tag .= '>';
    }
    if (defined $link) {
        $link =~ s/^://;
        $link = $self->format_url(url => $link);
        $tag = '<a href="'.$link.'">'.$tag.'</a>';
    }
    $pre.$tag.$post;
}

sub format_table {
    my $self = shift;
    my (%args) = @_;
    my $str = exists $args{text} ? $args{text} : '';

    my @lines = split /\n/, $str;
    my @rows;
    my $line_count = scalar(@lines);
    for (my $i = 0; $i < $line_count; $i++) {
       if ($lines[$i] !~ m/\|\s*$/) {
           if ($i + 1 < $line_count) {
               $lines[$i+1] = $lines[$i] . "\n" . $lines[$i+1] if $i+1 <= $#lines;
           } else {
               push @rows, $lines[$i];
           }
       } else {
           push @rows, $lines[$i];
       }
    }
    my ($tableid, $tablepadl, $tablepadr, $tablelang);
    my $tableclass = '';
    my $tablestyle = '';
    my $tablealign = '';
    if ($rows[0] =~ m/^table[^\.]/) {
        my $row = $rows[0];
        $row =~ s/^table//;
        my $params = 1;
        while ($params) {
            if ($row =~ m/^($tblalignre)/) {
                $tablealign .= $1;
                $row = substr($row, length($1)) if $1;
                redo if $1;
            }
            if ($row =~ m/^($clstypadre)/) {
                my $clsty = $1;
                $row = substr($row, length($clsty)) if $clsty;
                if ($clsty =~ m/{([^}]+)}/) {
                    $tablestyle = $1;
                    $clsty =~ s/{([^}]+)}//;
                    redo if $tablestyle;
                }
                if ($clsty =~ m/\(([A-Za-z0-9_\- ]+?)(?:#(.+?))?\)/ ||
                    $clsty =~ m/\(([A-Za-z0-9_\- ]+?)?(?:#(.+?))\)/) {
                    if ($1 || $2) {
                        $tableclass = $1;
                        $tableid = $2;
                        redo;
                    }
                }
                if ($clsty =~ m/(\(+)/) {
                    $tablepadl = length($1);
                }
                if ($clsty =~ m/(\)+)/) {
                    $tablepadr = length($1);
                }
                if ($clsty =~ m/\[(.+?)\]/) {
                    $tablelang = $1;
                }
                redo if $clsty;
            }
            $params = 0;
        }
        $row =~ s/\.\s+//;
        $rows[0] = $row;
    }
    my $out = '';
    my @cols = split /\|/, $rows[0].' ';
    my (@colalign, @rowspans);
    foreach my $row (@rows) {
        my @cols = split /\|/, $row.' ';
        my $colcount = $#cols;
        pop @cols;
        my $colspan = 0;
        my $row_out = '';
        my ($rowclass, $rowid, $rowalign, $rowstyle, $rowheader);
        $cols[0] = '' if !defined $cols[0];
        if ($cols[0] =~ m/_/) {
            $cols[0] =~ s/_//g;
            $rowheader = 1;
        }
        if ($cols[0] =~ m/{([^}]+)}/) {
            $rowstyle = $1;
            $cols[0] =~ s/{[^}]+}//g;
        }
        if ($cols[0] =~ m/\(([^\#]+?)?(#(.+))?\)/) {
            $rowclass = $1;
            $rowid = $3;
            $cols[0] =~ s/\([^\)]+\)//g;
        }
        if ($cols[0] =~ m/($alignre)/) {
            $rowalign = $1;
        }
        for (my $c = $colcount - 1; $c > 0; $c--) {
            if ($rowspans[$c]) {
                $rowspans[$c]--;
                next if $rowspans[$c] > 1;
            }
            my ($colclass, $colid, $header, $colparams, $colpadl, $colpadr, $collang);
            my $colstyle = '';
            my $colalign = $colalign[$c];
            my $col = pop @cols;
            $col ||= '';
            my $attrs = '';
            if ($col =~ m/^(((_|[\/\\]\d+|$alignre|$clstypadre)+)\. )/) {
                my $colparams = $2;
                $col = substr($col, length($1));
                my $params = 1;
                while ($params) {
                    if ($colparams =~ m/^(_|$alignre)/g) {
                        $attrs .= $1;
                        $colparams = substr($colparams, pos($colparams)) if $1;
                        redo if $1;
                    }
                    if ($colparams =~ m/^($clstypadre)/g) {
                        my $clsty = $1;
                        $colparams = substr($colparams, pos($colparams)) if $clsty;
                        if ($clsty =~ m/{([^}]+)}/) {
                            $colstyle = $1;
                            $clsty =~ s/{([^}]+)}//;
                        }
                        if ($clsty =~ m/\(([A-Za-z0-9_\- ]+?)(?:#(.+?))?\)/ ||
                            $clsty =~ m/\(([A-Za-z0-9_\- ]+?)?(?:#(.+?))\)/) {
                            if ($1 || $2) {
                                $colclass = $1;
                                $colid = $2;
                                if ($colclass) {
                                    $clsty =~ s/\([A-Za-z0-9_\- ]+?(#.*?)?\)//g;
                                } elsif ($colid) {
                                    $clsty =~ s/\(#.+?\)//g;
                                }
                            }
                        }
                        if ($clsty =~ m/(\(+)/) {
                            $colpadl = length($1);
                            $clsty =~ s/\(+//;
                        }
                        if ($clsty =~ m/(\)+)/) {
                            $colpadr = length($1);
                            $clsty =~ s/\)+//;
                        }
                        if ($clsty =~ m/\[(.+?)\]/) {
                            $collang = $1;
                            $clsty =~ s/\[.+?\]//;
                        }
                        redo if $clsty;
                    }
                    if ($colparams =~ m/^\\(\d+)/) {
                        $colspan = $1;
                        $colparams = substr($colparams, length($1)+1);
                        redo if $1;
                    }
                    if ($colparams =~ m/\/(\d+)/) {
                        $rowspans[$c] = $1 if $1;
                        $colparams = substr($colparams, length($1)+1);
                        redo if $1;
                    }
                    $params = 0;
                }
            }
            if (length($attrs)) {
                $header = 1 if $attrs =~ m/_/;
                $colalign = '' if $attrs =~ m/($alignre)/ && length($1);
                if ($attrs =~ m/<>/) {
                    $colalign .= '<>';
                } elsif ($attrs =~ m/</) {
                    $colalign .= '<';
                } elsif ($attrs =~ m/=/) {
                    $colalign = '=';
                } elsif ($attrs =~ m/>/) {
                    $colalign = '>';
                }
                if ($attrs =~ m/\^/) {
                    $colalign .= '^';
                } elsif ($attrs =~ m/~/) {
                    $colalign .= '~';
                } elsif ($attrs =~ m/-/) {
                    $colalign .= '-';
                }
            }
            $header = 1 if $rowheader;
            $colalign[$c] = $colalign if $header;
            $col =~ s/^ +//; $col =~ s/ +$//;
            if (length($col)) {
                my $rowspan = $rowspans[$c] || 0;
                my $col_out;
                if ($header) {
                    $col_out = q{<th};
                } else {
                    $col_out = q{<td};
                }
                if (defined $colalign) {
                    my $halign = _halign($colalign);
                    $col_out .= qq{ align="$halign"} if $halign;
                    my $valign = _valign($colalign);
                    $col_out .= qq{ valign="$valign"} if $valign;
                }
                $colstyle .= qq{;padding-left:${colpadl}em} if $colpadl;
                $colstyle .= qq{;padding-right:${colpadr}em} if $colpadr;
                $col_out .= qq{ class="$colclass"} if $colclass;
                $col_out .= qq{ id="$colid"} if $colid;
                $colstyle =~ s/^;// if $colstyle;
                $col_out .= qq{ style="$colstyle"} if $colstyle;
                $col_out .= qq{ lang="$collang"} if $collang;
                $col_out .= qq{ colspan="$colspan"} if $colspan > 0;
                $col_out .= qq{ rowspan="$rowspan"} if ($rowspan||0) > 0;
                $col_out .= '>';
                if (($col =~ m/\n\n/) || ($col =~ m/^($halignre?)($clstypadre)*($halignre?)[\*\#]($halignre?)($clstypadre)*($halignre?) /)) {
                    $col_out .= $self->textile($col);
                } else {
                    $col_out .= $self->format_paragraph(text => $col);
                }
                if ($header) {
                    $col_out .= '</th>';
                } else {
                    $col_out .= '</td>';
                }
                $row_out = $col_out . $row_out;
                $colspan = 0 if $colspan;
            } else {
                $colspan = 1 if $colspan == 0;
                $colspan++;
            }
        }
        if ($colspan > 1) {
            $colspan--;
            $row_out = qq{<td} 
                     . ($colspan>1 ? qq{ colspan="$colspan"} : '')
                     . qq{></td>$row_out};
        }
        $out .= qq{<tr};
        if ($rowalign) {
            my $valign = _valign($rowalign);
            $out .= qq{ valign="$valign"} if $valign;
        }
        $out .= qq{ class="$rowclass"} if $rowclass;
        $out .= qq{ id="$rowid"} if $rowid;
        $out .= qq{ style="$rowstyle"} if $rowstyle;
        $out .= qq{>$row_out</tr>};
    }

    my $table = '';
    $table .= qq{<table};
    if ($tablealign) {
        if ($self->{css_mode}) {
            my $alignment = _halign($tablealign);
            if ($tablealign eq '=') {
                $tablestyle .= ';margin-left:auto;margin-right:auto';
            } else {
                $tablestyle .= ';float:'.$alignment if $alignment;
            }
            $tableclass .= ' '.$alignment if $alignment;
        } else {
            my $alignment = _halign($tablealign);
            $table .= qq{ align="$alignment"} if $alignment;
        }
    }
    $tablestyle .= qq{;padding-left:${tablepadl}em} if $tablepadl;
    $tablestyle .= qq{;padding-right:${tablepadr}em} if $tablepadr;
    $tableclass =~ s/^ // if $tableclass;
    $table .= qq{ class="$tableclass"} if $tableclass;
    $table .= qq{ id="$tableid"} if $tableid;
    $tablestyle =~ s/^;// if $tablestyle;
    $table .= qq{ style="$tablestyle"} if $tablestyle;
    $table .= qq{ lang="$tablelang"} if $tablelang;
    $table .= qq{ cellspacing="0"} if $tableclass || $tableid || $tablestyle;
    $table .= qq{>$out</table>};

    if ($table =~ m|<tr></tr>|) {
        # exception -- something isn't right so return fail case
        return undef;
    }

    $table;
}

sub _repl {
    push @{$_[0]}, $_[1];
    '<textile#'.(scalar(@{$_[0]})).'>';
}

sub _tokenize {
    my $str = shift;
    my $pos = 0;
    my $len = length $str;
    my @tokens;

    my $depth = 6;
    my $nested_tags = join('|', ('(?:</?[A-Za-z0-9:]+ \s? (?:[^<>]') x $depth)
        . (')*>)' x $depth);
    my $match = qr/(?s: <! ( -- .*? -- \s* )+ > )|  # comment
                   (?s: <\? .*? \?> )|              # processing instruction
                   (?s: <\% .*? \%> )|              # ASP-like
                   (?:$nested_tags)|
                   (?:$codere)/x;                  # nested tags

    while ($str =~ m/($match)/g) {
        my $whole_tag = $1;
        my $sec_start = pos $str;
        my $tag_start = $sec_start - length $whole_tag;
        if ($pos < $tag_start) {
            push @tokens, ['text', substr($str, $pos, $tag_start - $pos)];
        }
        if ($whole_tag =~ m/^[[{]?\@/) {
            push @tokens, ['text', $whole_tag];
        } else {
            # this clever hack allows us to preserve \n within tags.
            # this is restored at the end of the format_paragraph method
            $whole_tag =~ s/\n/\r/g;
            push @tokens, ['tag', $whole_tag];
        }
        $pos = pos $str;
    }
    push @tokens, ['text', substr($str, $pos, $len - $pos)] if $pos < $len;
    \@tokens;
}

1;
__END__

=head1 NAME

Text::Textile

=head1 SYNOPSIS

  use Text::Textile qw(textile);
  my $text = <<EOT;
  h1. Heading

  A _simple_ demonstration of Textile markup.

  * One
  * Two
  * Three

  "More information":http://www.textism.com/tools/textile is available.
  EOT

  # procedural usage
  my $html = textile($text);
  print $html;

  # OOP usage
  my $textile = new Text::Textile;
  $html = $textile->process($text);
  print $html;

=head1 ABSTRACT

Text::Textile is a Perl-based implementation of Dean Allen's Textile
syntax. Textile is shorthand for doing common formatting tasks.

=head1 METHODS

=over 4

=item * new

Instantiates a new Text::Textile object.

=item * process( $str )

Alternative method for invoking textile().

=item * flavor( $flavor )

Assigns the HTML flavor of output from Text::Textile. Currently
these are the valid choices: html, xhtml (behaves like 'xhtml1'),
xhtml1, xhtml2.

=item * charset( $charset )

Assigns the character set targetted for publication.
At this time, Text::Textile only changes it's behavior
if the 'utf-8' character set is assigned.

=item * docroot( $path )

Physical file path to root of document files. This path
is utilized when images are referenced and size calculations
are needed (the Image::Size module is used to read the image
dimensions).

=item char_encoding( $encode )

Assigns the character encoding logical flag. If character
encoding is enabled, the HTML::Entities package is used to
encode special characters. If character encoding is disabled,
only <, >, " and & are encoded to HTML entities.

=item * filter_param( $data )

Stores a parameter that may be passed to any filter.

=item * named_filters( \%filters )

Optional %filters parameter assigns the list of named filters
to make available for Text::Textile to use. Returns a hash
reference of the currently assigned filters.

=item * text_filters( \@filters )

Optional @filters parameter assigns the textual filters for
Text::Textile to use. Returns an array reference of the
currently assigned text filters.

=item * textile( $str )

Can be called either procedurally or as a method. Transforms
$str using Textile markup rules.

=item * format_paragraph( $str )

Processes a single paragraph.

=item * format_inline( $str )

Processes an inline element (plaintext) for Textile syntax.

=item * apply_text_filters( $str )

Applies all the textual filters to $str.

=item * apply_named_filters( $str, \@list )

Applies all the filters identified in @list to $str.

=item * format_tag( $tag, $pre, $text, @rest )

Returns a constructed tag using the pieces given.

=item * format_list( $str )

Takes a Textile formatted list (numeric or bulleted) and
returns the markup for it.

=item * format_cite( $text, $link )

Formats a citation with a link.

=item * format_code( $code, $lang )

Processes '@...@' type blocks (code snippets).

=item * format_block( $str )

Processes '==xxxxx==' type blocks for filters.

=item * format_link( $text, $title, $url )

Takes the Textile link attributes and transforms them into
a hyperlink.

=item * format_url( $url )

Takes the given $url and transforms it appropriately.

=item * mail_encode( $email )

Encodes the email address in $email for 'mailto:' links.

=item * format_image( $src, $align, $extra, $url, $class )

Returns markup for the given image. $src is the location of
the image, $extra contains the optional height/width and/or
alt text. $url is an optional hyperlink for the image. $class
holds the optional CSS class attribute.

=item * image_size( $src )

Returns the size for the image identified in $src.

=item * format_table( $str )

Takes a Wiki-ish string of data and transforms it into a full
table.

=item * _repl( \@arr, $str )

An internal routine that takes a string and appends it to an array.
It returns a marker that is used later to restore the preserved
string.

=item * _tokenize( $str )

An internal routine responsible for breaking up a string into
individual tag and plaintext elements.

=back

=head1 SYNTAX



=head1 LICENSE

Please see the file LICENSE that was included with this module.

=head1 AUTHOR & COPYRIGHT

Text::Textile was written by Brad Choate, brad@bradchoate.com.
It is an adaptation of Textile, developed by Dean Allen of Textism.com.

=cut
