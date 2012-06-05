#!/usr/bin/perl

# -------------
# Pollxn.cgi - Discussion/comments engine for Blosxom and other blog systems
#
# Version: 1.0b2 (beta)
#
# Author: Scott Wichmann <pollxn@nukekiller.net>
# Home: http://www.nukekiller.net/pollxn
# Copyright 2003 Scott Wichmann
# Creative Commons license applies
#   See: http://creativecommons.org/licenses/by-sa/1.0
# ---------------

# --------------
# CONFIGURATION
# --------------

# File system path to your main blog docs folder?
# For example, take this URL: http://myserver/tv/simpsons/homer
# On my system '/tv/simpsons/homer' is under /www/blog/docs
#   (i.e., /www/blog/docs/tv/simpsons/homer)
# So my $datadir is: /www/blog/docs
$datadir = "/www/blog/docs";

# File system path to Pollxn's templates folder?
# Example: /www/blog/pollxn_templates
$pollxntemplatefolder = "/www/blog/pollxn_templates";

# Your email address?
$myemail='you@something.com';

# Title of blog?
$blogtitle="My Blog";

# Maximum comments shown per page?
$maxperpage=0;   # 0=Show All

# Your time zone
$timezone="PST";

# What file extension do your blog entry files use? 
# i.e., .txt, .blog, etc.
$fileextension=".txt";

# Require visitors to enter their names?  Email addresses? 
$reqname=0;     # 0=No, 1=Yes
$reqemail=0;

# Maximum comment posts allowed for a blog story?
# (When this number is reached, the comments will
# automatically be archived, disallowing further posts).
$maxpostsallowed=100; # 0=unlimited

# Security - set these to random values:
$delim=5; # number between 5 and 10
$key=123; # between 2 and 1000
$maxmult=345; # between 5 and 10000


# --------
# PROGRAM
# --------

use CGI qw/:standard :netscape/;
print "Content-type: text/html\n\n";

# GET POLLXN FLAVOR, CALCULATE PATHS, AND SANITY-CHECK STORY PATH
$flav=param('flav'); if (!$flav) {$flav="pollxn";}
if ($fileextension !~ /^\..*/) {$fileextension=".$fileextension";}
$storypath=param('storypath'); 
if ($datadir =~ /(.*)\/$/) {$datadir=$1;}
if ($storypath !~ /^\/.*/) {$storypath="/$storypath";}
$story=$storypath; $abspath=$story;
$story=~/^.*\/(.*)$/g; $story=$1;
$abspath =~ /(.*\/).*$/g; $abspath="$datadir$1";
if ($story =~ /(.*)\..*$/) {$story="$1$fileextension"; } else {$story="$story$fileextension";}
if ( (-d "$abspath$story")||($abspath=~/\.\./)||(! -f "$abspath$story")) {diemsg("The story you referenced wasn't found.",0);}

# NEW POST? SAVE IT
$newpost=param('newpost'); $eof="__endpollxn";
if ($newpost) {
 if (!verifykey($newpost)) {diemsg("Try reloading the previous page, then submitting your comments again.",0);}
 $email=cleanhtml(param('email'));  if ($email !~ /.*@.*\..{1,}/) {$email=''} 
 $name=cleanhtml(param('name')); 
 if (!$name && $reqname) {diemsg("Your name is required.",1);}
 if ($email eq '' && $reqemail) {diemsg("A proper email address is required.",1);}
 if (!$name) {$name="anonymous"}
 $comments=cleanhtml(param('comments')); if (length($comments)<2) {diemsg("Please enter some comments before submitting.",0);}
 $newfile="$abspath$story.pollxn$newpost";
 if (! -e $newfile) {
  if (! open(fh,"> $newfile") ) {diemsg("Permission settings in <b>$abspath</b> won't allow your comments to be saved.",0);}
  print fh time()."\n$name\n$email\n".localtime()."\n$comments$eof"; close(fh);
 }
}

# GET STORY TITLE AND DATE
if(!open (fh,"$abspath$story")) {diemsg("The story you want can't be opened.",0); }
$storytitle=<fh>; close(fh); chomp $storytitle;
if (!$storytitle) {$storytitle="This Story";}
$storytime=scalar localtime((stat "$abspath$story")[9] ); 

# FILL COMMENT TEMPLATE WITH COMMENTS
if ($pollxntemplatefolder =~ /(.*)\/$/) {$pollxntemplatefolder=$1;}
$ctemp=gettemplate("$pollxntemplatefolder/$flav"."_comment.html");
if (! opendir(dir,$abspath)) {diemsg("The comment files are unavailable right now.",0);}; 
@files= grep{/$story.pollxn.{2,}/} readdir(dir); closedir dir;

if (scalar(@files)==1 && $files[0]=~/_archive$/) {
 ## this is an archive
 &makethisanarchive;
 $file=$files[0];
 open (fh,"$abspath/$file");
  @glob=<fh>; close(fh);
  @files=split($eof,join('',@glob));
  foreach $file(@files) {
	@glob=split("\n",$file);
	$thecomment=join('',@glob[4...($#glob)]);
	&formatcomment;
  }
} 
else {
 ## not an archive
 $postform=gettemplate("$pollxntemplatefolder/$flav"."_form.html");
 foreach $file (@files) {
  if (open (fh,"$abspath/$file")) {
   @glob=<fh>; close(fh); $thecomment=join('',@glob[4...($#glob)]); 
   if ($thecomment =~ /$eof/) { &formatcomment; }
  }
 }
 if ( ((scalar @files) >= $maxpostsallowed) && ($maxpostsallowed>0) ) { &makethisanarchive; }
}

if ($count) {
 if ($count!=1) {$suf="s";}
 $count="$count comment$suf";
 $count .= ($archive) ? " [archive]" : "";
} else {
 $count = "There are no comments for this story";
 $count .= ($archive) ? "." : " yet.";
}

# CHRONO-SORT & NUMBER/COLOR COMMENTS, THEN PRINT & EXIT
$newkey=&genkey;
sub by_posted {$posted[$b] <=> $posted[$a];}
@sorted=@comments[sort (by_posted (0..$#posted))];
if ($maxperpage==0) { $commentsbody=join('',@sorted[0..$#posted]); $number=$#posted; } 
else { 
 $myurl=$0; $myurl=~/(.*)\/(.*\.cgi)/; $myurl=$2;
 $start=param('start'); 
 if (!$start) {$start=0;}
 $commentsbody=join('',@sorted[$start..($start+$maxperpage-1)]);
 $number=$#posted-$start;
 $nextstart=($start+$maxperpage);
 if ($nextstart>$maxperpage) {
	$back=$start-$maxperpage;
 	$backlink="<a href=\"" . "$myurl?storypath=$storypath&start=$back&flav=$flav" . "\">&lt; back</a>";
 }
 if ($nextstart<$#posted) {
	$nextlink="<a href=\"" . "$myurl?storypath=$storypath&start=$nextstart&flav=$flav" . "\">next &gt;</a>";
 }
} 
while($commentsbody=~/\$number/){$commentsbody=~s/\$number/$number/;$number--}
while ($commentsbody=~/\$altcolor/){
 $color=($color*-1)+1; $altcolor = $color ? "color1" : "color2"; $commentsbody=~s/\$altcolor/$altcolor/;
}
print filltemplate(gettemplate("$pollxntemplatefolder/$flav"."_template.html"),postform,nextlink,backlink,blogtitle,storytitle,storytime,count,commentsbody,storypath,newkey,flav);
exit;


# ---------------
# ROUTINES
# ---------------

# TURN PAGE INTO ARCHIVE
sub makethisanarchive {
 $archive++;
 $maxperpage=0;
 $postform='';
}
# FORMAT A POST 
sub formatcomment {
 $thecomment=~s/\n/<br>/g;
 $thecomment=~s/$eof//g;
 $count++;
 @posted[$count]=@glob[0];
 $name=@glob[1];
 $email=$glob[2]; chomp $email;
 $when=@glob[3]." $timezone";
 @comments[$count]=filltemplate($ctemp,thecomment,name,email,when,timezone);
}
# ERROR MSG AND EXIT
sub diemsg {
 $error=shift; $tryagain=shift; $when=localtime()." ".$timezone; $buf=''; $ferr="$pollxntemplatefolder/$flav"."_error.html"; 
 $tryagain = ($tryagain!=1 ) ? '' : "Click your browser's Back button to try again.";
 if (open(fh,"< $ferr")) {$buf=join('',<fh>); close(fh); }
 if ($buf ne '') {print filltemplate($buf,blogtitle,error,tryagain,myemail,when);}
 else {
  print "<html><head><title>$blogtitle</title></head><body bgcolor=white>$error<p>$tryagain</body></html>";
 }
 exit; 
}
# RANDOM NUMBER
sub rnd {
 my $min=shift; my $max=shift;  
 return int(rand( $max-$min+1 ) ) + $min;
}
# RANDOM NUMBER OF LENGTH N
sub rndlen {
 my $l=shift; my $r='';
 while (length($r)<$l) {$tmp=rnd(1,9); $r.="$tmp";}
 return $r;
}
# VERIFY INCOMING POST KEY
sub verifykey {
 my $k=shift;
 $k =~ /(.*)-(.{$delim})(.*)/; $k=$3;
 $k=($k-$key)/$key;
 $k= (!$k || $k=~/\./ || $k<1 || $k>$maxmult) ? 0 : 1;
 return $k;
}
# GENERATE POST KEY
sub genkey {
 return rnd(1,100000) . "-" . rndlen($delim) . (($key * rnd(1,$maxmult))+$key);
}
# STRIP <HTML> EXCEPT HREF TAGS
sub cleanhtml {
 my $k=shift;
 $k =~ s/<a/qwerty9/sig; $k =~ s/\/a>/qwerty8/sig;
 $k =~ s/<(.*?)>//gi;
 $k =~ s/qwerty9/<a/sig; $k =~ s/qwerty8/\/a>/sig;
 return $k;
}
# READ IN TEMPLATE FILE
sub gettemplate {
 my $f=shift; my $buf='';
 if (!open (fh,"< $f")) {diemsg("Unable to open template $f.");}
 $buf=join('',<fh>); close(fh);
 return $buf;
}
# REPLACE TEMPLATE $VARS WITH VALUES
sub filltemplate {
 my $buf=shift;
 while ($v=shift){$buf=~s/\$$v/$$v/g;}  
 return $buf;
}


