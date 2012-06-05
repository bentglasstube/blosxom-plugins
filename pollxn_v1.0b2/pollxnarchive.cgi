#!/usr/bin/perl

# -------------------------------
# pollxnarchive.cgi - Recursively archive old Pollxn comments
#
# Version 1.0b1 (beta)
#
# Author: Scott Wichmann <pollxn@nukekiller.net>
# Home: http://www.nukekiller.net/pollxn
# Copyright 2003 Scott Wichmann
# Creative Commons License applies.
#   See: http://creativecommons.org/licenses/by-sa/1.0
# 
# When a blog story reaches a certain age in days, this script
# can automatically archive the story's Pollxn comment files. Archiving
# consists of putting all the Pollxn comments for the story into
# a single "topic.pollxn_archive" file.  Once archived, the
# comments can still be read, but no new comments can be posted.
# Archiving from time to time is a good idea because it frees up 
# disk resources on your web server.
# -------------------------------

# -----------------------
# CONFIGURATION VARIABLES
# -----------------------

# What top-level folder should I begin searching for Pollxn files?
# (i.e., file system path to your blog's 'docs' folder)
# Example: /var/apache/htdocs/blog/docs
$datadir = "/www/blog/docs";

# How old should a blog story be before I archive its comments?
$archiveafter = 45; # days

# Which log file should I use?
$logfile = "/www/CGI-Executables/pollxnarchive.log";


# -------
# PROGRAM
# -------

use File::Find;
$storiesprocessed=0;
$commentsprocessed=0;
$dirssearched=0;
$dir;
$last;
$prefix;
$oneday=86400;
$maxtimetowait=$oneday * $archiveafter;
$err="ERROR:";

if (!-d $datadir) { die "Can't find folder $datadir";}
if ($datadir =~ /(.*)\/$/) {$datadir=$1;}

open(logout,">>$logfile") or die "Unable to open $logfile."; 
print logout "---------------------------------------------------------\n";
print logout "Petxl archive started at " . localtime() . "\n";
print logout "Starting in folder $datadir\n";
print logout "Only stories older than $archiveafter day(s) will have their comments archived\nStarting...\n";
find (\&search, "$datadir/");
$pl=($dirssearched==1)?"directory containing stories was":"directories containing stories were";
print logout "Archiving done. $dirssearched $pl scanned\n";
if($storiesprocessed==0){print logout "No comments need to be archived at this time.\n";}
else{
 $pl=($storiesprocessed==1)?"story was":"stories were";
 print logout "$commentsprocessed Petxl comment(s) for $storiesprocessed $pl archived\n";
}
print logout "Petxl archive job complete at " . localtime() . "\n";
close(logout);
exit;

# --------
# ROUTINES
# --------

# PERFORM ARCHIVE ON A SET OF COMMENTS
sub archive {
 my @a = @_;
 my @b = @_;
 my $buf='';
 my $temp;
 my $fi;
 my $count=0;
 $storytime=scalar ((stat "$dir/$last")[9] ); 
 if ( (time() - $storytime) < $maxtimetowait) {return;} 
 print logout "Comments found for $dir/$last\n";

 # Process a list of .txt.pollxn.n archive files
 while(@a) {
  $fi= $dir . "/" . pop(@a);
  if (-e $fi) {
	open(fh,"< $fi");
	$temp=join('',<fh>);
	close(fh);
	$count++;
	if ($temp =~ /__endpollxn/) {$buf.=$temp;}
	print logout "$fi\n";
  }
 }
 $commentsprocessed+=$count;
 if(!open (fh,"> $dir/$last.pollxn_archive")) {print logout "$err Unable to open $dir/$last.pollxn for writing\n";return;}
 print fh $buf; close(fh);

 # Delete old archive files
 while (@b) {
  $fi=$dir . "/" . pop(@b);  
  if(!unlink ($fi)) {print logout "$err Unable to delete $fi\n";return}
 }
 $storiesprocessed++;
}

# RECURSIVELY SEARCH DIRECTORIES FOR POLLXN FILES
sub search {
 my $filename = $_;
 $dir=$File::Find::dir;
 $t = $dir; $t=~s/\///g;
 if (!$f{$t}) {
  $f{$t}=1;
  if(-d $dir) { 

	# search this dir
	undef @files;	
	if (opendir(dir,$dir)){
		$dirssearched++;
		@files=sort( grep{/\.pollxn.{2,}/} readdir(dir) ); closedir dir; 
	} else {
		print logout "$err Unable to read $dir\n";
	}
	while(@files){
		$this=pop(@files);
		$prefix=$this;
		$prefix=~/(.*).pollxn/; $prefix=$1; #$prefix=~s/[.]//g;
		if ($prefix ne $last) {
			if (@biglist) { archive(@biglist); }
			undef @biglist;
		}		
		if ($this !~ /pollxn_archive/) {push(@biglist,$this);}
		$last=$prefix;
	}
	if (@biglist) { archive(@biglist); undef @biglist; }
   }
  }
}


