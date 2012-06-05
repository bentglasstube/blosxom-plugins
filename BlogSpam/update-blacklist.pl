#!/usr/bin/perl -w
# update-blacklist.pl - update a local blacklist from the Comment Spam Clearinhouse
# Copyright 2004 Doug Alcorn <doug@lathi.net>

# You are free to use this software under the terms of the GNU Public
# License.

use strict;
use LWP::UserAgent;
use XML::RSS;
use Date::Manip;
use Digest::MD5 qw(md5_hex);

# Here are the configuration variables
my $blacklist = "/home/dalcorn/data/blosxom-plugins/blacklist.txt";
my $state_dir = "/home/dalcorn/data/blosxom-plugins/state/";
my $blacklist_cache = "$state_dir/blacklist-cache.txt";


# These shouldn't need to be changed
my $blacklist_rss = "http://www.jayallen.org/comment_spam/feeds/blacklist-changes.rdf";
my $blacklist_url = "http://www.jayallen.org/comment_spam/blacklist.txt";
my $version = "1.0";
my $debug = $ENV{RSS_DEBUG};
my $useragent = "Update-Blacklist v$version - http://www.lathi.net/twiki-bin/view/Main/BlogSpam/";

my %cache;
if (open CACHE, $blacklist_cache) {
    while (<CACHE>) {
        my ($field, $value) = split /\s*:\s*/, $_, 2;
        $cache{$field} = $value;
    }
    close CACHE;
}

my $res = get_feed ($blacklist_rss, \%cache);
exit unless $res;
my $rss = get_rss ($res);
die "Didn't get an RSS feed from '$blacklist_rss'\n"
    unless $rss;
my $rss_date = feed_date($rss);
die "Feed has no timestamp\n" unless $rss_date;
if (Date_Cmp($cache{date}, $rss_date) < 0) {
    $cache{date} = $rss_date;
    update_blacklist ($blacklist_url, $blacklist);
}

$cache{etag} = $res->header('Etag');

open CACHE, ">$blacklist_cache" or
    die "Can't write to '$blacklist_cache', $!\n";
foreach my $key (keys %cache) {
    print CACHE "$key:$cache{$key}\n";
}
close CACHE;

# actually download the rss feed if it has changed
sub get_feed {
    my $url = shift;
    my $cacheref = shift;
    my $ua = LWP::UserAgent->new;
    $ua->agent($useragent);
    $ua->timeout(30);
    my $req = HTTP::Request->new(GET => $url);
    my $date = $cacheref->{date} if (exists $cacheref->{date});
    $date = "";                 # i'm caching the date in Date::Manip format;
                                # i need to look at converting it to the right format for HTTP
    my $etag = $cacheref->{etag} if (exists $cacheref->{etag});
    $req->header('If-Modified-Since' => $date)  if ($date);
    $req->header('If-None-Match' => $etag) if ($etag);
    my $res = $ua->request($req);
    unless ($res->is_success) {
        # if code == 304 that means the request worked, but there was
        # nothing new to get
        unless ($res->code == 304) {
            my $code = $res->code;
            my $message = $res->message;
            warn "Error retrieving blacklist rss, $code - $message\n";
        } elsif ($debug) { print "\t - Not Changed\n"; }
        return "";
    }
    return $res;
}

# convert the http responce into a parsed rss object
sub get_rss {
    my $res = shift;
    my $rss = new XML::RSS;
    my $content = $res->content;
    $content =~ s/([\xC0-\xDF])([\x80-\xBF])/chr(ord($1)<<6&0xC0|ord($2)&0x3F)/eg;
    eval {$rss->parse($content);};
    if ($@) {
        warn "RSS Parsing: $@\n";
        return "";
    }
    return $rss;
}

sub feed_date {
    my $rss = shift;
    if (exists $rss->{channel}
        and exists $rss->{channel}->{dc}
        and exists $rss->{channel}->{dc}->{date}) {
        return ParseDate($rss->{channel}->{dc}->{date});
    }
}

sub update_blacklist {
    my $url = shift;
    my $file = shift;

    my $ua = LWP::UserAgent->new(agent => $useragent);
    my $res = $ua->get($url);
    my $msg = $res->message;
    die "Can't get new blacklist from '$url', $msg\n"
        unless ($res->is_success);

    open FILE, ">$file" or 
        die "Can't write to '$file', $!\n";
    print FILE $res->content;
    close FILE;
}
