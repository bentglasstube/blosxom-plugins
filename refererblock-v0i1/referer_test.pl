#!/usr/bin/perl -w
# Simple script to send a referer string to a website
# for testing referer blacklisting

use LWP::UserAgent;
use HTTP::Request;

if ($#ARGV != 1) {
    print "usage: referer_test.pl hostURI refererURI\n";
    print "i.e. referer_test.pl http://example.com http://yet-another-viagra-spammer.com\n";
    exit;
}

$|=1;# flush
my $ua = LWP::UserAgent->new();
$ua->agent("referer_test");
my $req = HTTP::Request->new(GET => $ARGV[0]);
$req->referer($ARGV[1]);
my $response = $ua->simple_request($req);
print $response->status_line . "\n";

