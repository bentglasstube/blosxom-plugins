# Blosxom Plugin: mp3player    -*- perl -*-
# Author(s): Steve Sergeant < stevesgt@effable.com >
# Version: 0+3i
# Blosxom Home/Docs/Licensing: http://www.blosxom.com
#
# Requires the player.swf from the package available from 1pixelout:
# http://www.1pixelout.net/code/audio-player-wordpress-plugin/

package mp3player;

use LWP::Simple;
use File::Basename;

#-----REQUIRED CONFIGURATION OPTIONS

# Location of the "player.swf" file
$player_url = "http://your.domain.tld/directory/player.swf" ;

# include all flavours to which you want to add players
@flavours = ('html');

#-----ADVANCED CONFIGURATION OPTIONS

# Modify the player width in pixels
# The height is fixed to 24px, setting the width narrower than 250px will
# revert to 250px.
$player_width = "290";

# Modify the settings of the player.
%player_params = (
	animation => "yes", # If "no", player is always open
# Color values should be in standard HTML hexidecimal form: RRGGBB
# Leaving a color field blank results in default neutral grays
	bg => "", # scroll area background colour
	leftbg => "", # Speaker icon/Volume control background colour
	lefticon => "", # Speaker icon colour
	rightbg => "", # Right background colour
	rightbghover => "", # Right background colour (hover)
	righticon => "", # Right icon colour
	righticonhover => "", # Right icon colour (hover)
	text => "", # Text colour
	loader => "", # Loader bar colour
	track => "", # Progress track background colour
	tracker => "", # Progress track colour
	border => "", # Progress track border colour
	voltrack => "", # Volume track colour
	volslider => "", # Volume slider colour
	skip => "" # Previous/Next skip button colours
) ;

#-----DEVELOPER TESTING OPTIONS

my $DataFile = $blosxom::plugin_state_dir.'/'."mp3player.dat";
$debug_level = 5 unless defined $debug_level;

#-----END CONFIGURATION OPTIONS

# Initialize configuration values
$mp3player = '';
$player_width = 250 if ($player_width < 250) ;
my @param_list = ();
foreach $param (keys(%player_params)) {
	$player_params{$param} =~ s!^([0-9a-fA-F]{6})$!0x$1! ;
	unless ($player_params{$param} eq "") { push (@param_list, $param."=".$player_params{$param}) } ;
}

$debug_output = '';

sub debug {
    my ($level, @msg) = @_;
    if ($debug_level >= $level) {
	print STDERR "$package debug $level: @msg\n";
    }
    1;
}


sub load_cache {
    debug (1, "In load cache");
    $info = {};
    #open data file
    local *FH;
    if( -e "$DataFile") {
	open FH, "$DataFile" or return $info;
    }
    flock(FH, 2);
    debug (1, "Opening cache at $DataFile");
    while (<FH>) {
	chomp ($_);
	my ($url, $size, $type) = split (/ /, $_);
	$info->{$url}->{length} = $size;
	$info->{$url}->{type} = $type;
	debug (1, "found $url length=" .$info->{$url}->{length} ." and type=". $info->{$url}->{type});
    }
    close (FH);
    return $info;
}

#sub head {
#

#}

sub start {
    load_cache();
    1;
}

sub story {
	$debug_output .= "<!-- test -->";
    my($pkg, $path, $filename, $story_ref, $title_ref, $body_ref) = @_;
    if (grep { $_ eq $blosxom::flavour}  @flavours) {
	$mp3player = "";
	@anchors = ( $$body_ref =~ m#<a([^>]*href\s*=\s*[^>]*)>#gis ); 
	foreach $anchor (@anchors) {
		$debug_output .= $anchor;
		if ($anchor =~ m#enclosure\s*=\s*"?true"?#is) {
			if ($anchor =~ m#href\s*=\s*"([^"]+)"#is) {
				$file = $1;
			} elsif ($anchor =~ m#href\s*=\s*([^\s]+)#is) {
				$file = $1;
			}
			if (! $info->{$file}) {
			    get_info($file);
			}
			$type = $info->{$file}->{type};
			$length = $info->{$file}->{length};
			if ($type == "mp3") {
#  Create the object tag for the player
				$mp3player .= '
<object type="application/x-shockwave-flash" data="'.$player_url.'" height="24" width="'.$player_width.'">
<param name="movie" value="'.$player_url.'">
<param name="FlashVars" value="soundFile='.$file.'&amp;titles='.$$title_ref.'&amp;'.join("&amp;",@param_list).'">
<param name="quality" value="high">
<param name="menu" value="false">
<param name="wmode" value="transparent">
</object>
' ;
			}
		}
	}
    }
}

sub get_info {
    my $url = shift;
    my ($content_type, $size, undef, undef, undef) = head($url);
    $info->{$url}->{length} = $size;
    $info->{$url}->{type} = $content_type;
    save_cache();
    return ($content_type, $size); 
}

sub save_cache {
    local *FH;
    open FH, ">$DataFile" or return 0;
    flock(FH, 2);
    debug(1, "writing to $DataFile at ".localtime()."\n");
    foreach $url (keys (%{$info})) { 
	debug (1, $url." ".$info->{$url}->{length} ." ". $info->{$url}->{type}."\n"); 
	print FH $url." ".$info->{$url}->{length} ." ". $info->{$url}->{type}."\n"; 
    }
    close FH;
    return 1;
}


1;

__END__

=pod

=head1 Name

Blosxom Plug-In: B<mp3player>

=head1 Synopsis

The mp3player plugin embeds a shockwave MP3 audio player applet/widget into articles containing links to mp3 files.  It uses the player.swf, part of the WordPress Audio Player package by Martin Laine of 1pixelout: L<http://www.1pixelout.net/code/audio-player-wordpress-plugin/>

=head2 Quick Start

1. Upload the provided C<player.swf> into a location within your web server's C<DocumentRoot>.

2. Edit the following configuration variables at the top of the B<mp3plater> plugin script:

=over

=item C<$player_url>

Set to the full absolute URL of your B<player.swf> file.  This must be in a location that your browser can access.

=item C<@flavours>

C<html> is a reasonable default.  If you need to embed the player into additional Blosxom flavors, indicate them here in a comma-separated and quoted list.

=back

3. Upload this plugin to your $plugin_dir.

4. Edit your C<story.html> templates to include the C<$mp3player::mp3player> variable.

5. Within a story, place a link to an mp3 file, and add the enclosure parameter:

C<<a href="http://www.myhost.tld/audiofile.mp3" enclosure="true">>

That should be it.  When you re-load your Blosxom page, you should see player widgets appear in your stories.

=head2 Advanced Configuration

=head3 Player Configuration

You can customize the colors, size, and animation behavior of the Shockwave player.  The default colors are various shades of gray that should look good in any layout.

=head3 Animation

When C<$player_params{animation}> is set to C<yes>, the default, the player appears as a small rounded rectagle containing a speaker icon and a right-pointing triangle (the PLAY button).  When the play button is pressed, the player widens to reveal a progress bar and a text line indicating the title of the file.

When  C<$player_params{animation}> is set to C<no>, the player remains at it's active width even when at idle.

=head3 Size

The height of the player is fixed at 24 pixels.  The width is dynamic.

When animation is enabled and the player is idle, the visible width is approximately 75 pixels.  When the player is active, it expands to the width set in the C<$player_width>, or 250 pixels, whichever is greater.  When the player is collapsed, it still occupies the full width set by this parameter.

When animation is disabled, the player remains at the width set by  C<$player_width> at all times.

=head3 Colors

Color values should be in standard HTML hexidecimal form: C<RRGGBB>  Do not precede the value with the usual pound sign (#) you would use in HTML or CSS.

See L<http://www.1pixelout.net/code/audio-player-wordpress-plugin/#colours> for a graphical description of these parameters.

=over

=item bg

Scroll area background colour.

=item leftbg

Speaker icon/Volume control background colour.

=item lefticon

Speaker icon colour.

=item rightbg

Right background colour.

=item rightbghover

Right background colour (hover).

=item righticon

Right icon colour.

=item righticonhover

Right icon colour (hover).

=item text

Text colour.

=item loader

Loader bar colour.

=item track

Progress track background colour.

=item tracker

Progress track colour.

=item border

Progress track border colour.

=item voltrack

Volume track colour.

=item volslider

Volume slider colour.

=item skip

Previous/Next skip button colours.  (Not supported in this version of this plug-in.)

=back

=head1 Current Version

0.3

=head2 Version History

=head3 0.3 of April 13, 2007

Revised to support version 2.0 of Martin Laine's Audio Player.

=head3 0.2 of April 12, 2007

Added configuration for player location, default audio file, and player color settings.

=head3 0.1 of April 7, 2007

First working version.  Everything hard-coded.  No configuration variables.

=head2 Planned Features

This current version looks for the C<enclosure> parameter in an anchor tag.  Strictly speaking, this is broken HTML and espeically bad XML.  A future version should allow the option to look for all of the anchor tags which link to MP3 files and give the option to deploy a player at each one.  If the I<enclosure_tags> parameter is set, then enclosure parameters would not be necessary, nor would editing of the story template be required.

I'd like to find a way to define player colors within the HTML or CSS, rather than as parameters within the plugin's script.

=head1 Author

Steve Sergeant  (stevesgt@effable.com)

=head1 Acknowledgements

Thanks to Martin Laine of 1pixelout for supporting my efforts and providing the player.swf code.  See:

L<http://www.1pixelout.net/code/audio-player-wordpress-plugin/>

The bulk of the code in this plugin was re-worked from the enclosure plug-in by Dave Slusher and Keith Irwin. See:

L<http://www.asyserver.com/~kirwin/enclosures_readme.txt>

L<http://www.asyserver.com/~kirwin/enclosures2.zip>

And in homage to the original code:

L<http://www.evilgeniuschronicles.org/wordpress/2004/08/22/get_enclosurespl/>

=head1 See Also

Blosxom Home/Docs/Licensing: L<http://www.blosxom.com/>

Blosxom Plugin Docs: L<http://www.blosxom.com/documentation/users/plugins.html>

=head1 Bugs

Not tested, but if a link to the same audio file appears more than once on the same page, strange things might happen.

Not tested at all with static rendering, probably won't work.

=head1 License

This Blosxom Plug-in Copyright 2007, Steve Sergeant for Effable Communications

(This license is the same as Blosxom's)
Permission is hereby granted, free of charge, to any person obtaining a copy 
of this software and associated documentation files (the "Software"), to deal 
in the Software without restriction, including without limitation the rights 
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
copies of the Software, and to permit persons to whom the Software is furnished 
to do so, subject to the following conditions:


The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
