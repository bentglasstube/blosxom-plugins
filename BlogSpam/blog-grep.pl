#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Find;

# This script is for searching blosxom writeback entries.  It works
# similar to grep.  You give it a regexp to search for and it returns
# #the writeback entry that matches that pattern.  The optional
# 'delete' #switch will delete the option from the writeback file.

# each writeback entry consist of one or more lines separated by
# multiple '-'

my $usage = "Usage: $0 [--delete|-d] [--list|-l] <regexp> files...\n";

my $delete = 0;
my $list = 0;
my $ignore_case = 0;

my $result = GetOptions ("list|l" => \$list,
                         "delete|d" => \$delete,
                         "ignore|i" => \$ignore_case);
my $regexp = shift;
my @files = @ARGV;

die $usage unless $regexp;
die $usage unless $files[0];

foreach my $entity (@files) {
    if (-f $entity) {
        $File::Find::dir = ".";
        scanfile($entity);
    } elsif (-d $entity) {
        File::Find::find({ wanted => \&scanfile }, $entity);
      }
}

sub scanfile {
    my $file = $_;
    my $dir = $File::Find::dir;
    my $pattern = $regexp;      # global variable

    return if $file =~ /^\.{1,2}$/;
    return if (-d $file);

    open FILE, "$_" or do {
        warn "Can't read '$_', $!\n";
        return;
    };


    my @good;
    my @bad;
    my $entry = "";
    while (<FILE>) {
        if (/^-{4,}$/) {
            # this is an entry divider
            if (($ignore_case and $entry =~ /$regexp/i)
                or $entry =~ /$regexp/) {
                push @bad, $entry;
            } else {
                push @good, $entry;
            }
            $entry = "";
        } else {
            $entry .= $_;
        }
    }
    close FILE;
    if ($list) {
        print "$dir/$file\n";
    } elsif ($delete) {
        writeback($file, @good);
    } else {
        printhits($file, @bad);
    }
}

sub printhits {
    my $file = shift;
    my @entries =@_;
    my $tabstop = 4;
    my $width = ($ENV{COLUMNS} || 80) - $tabstop;

    foreach my $entry (@entries) {
        # print out the file and the entry that matches
        print "$file:\n";
        my @lines = split /\n/, $entry;
        foreach my $line (@lines) {
            # this loop offsets the entry by $tabstop
            if (length $line < $width) {
                print ' ' x $tabstop , $line, "\n";
            } else {
                for (my $i = 0; $i <= length $line; $i += $width) {
                    print ' ' x $tabstop, substr ($line, $i, $width), "\n";
                    if ($i > length($line) - $width
                        and $i < length($line)) {
                        print ' ' x $tabstop, substr($line, $i);
                    }
                }
            }
        }
    }
}

sub writeback {
    use File::Temp qw( tempfile );
    my $file = shift;
    my @entries = @_;

    unless (@entries) {
    	unlink $file or warn "Can't clean '$file', $!\n";
	return;
    }

    my $mode = (stat($file))[2];
    $mode = sprintf "%04o", $mode & 07777;

    my ($fh, $filename) = tempfile();
    print $fh join "-----\n", @entries;
    print $fh "-----";
    close $fh;
    return if (-z $filename);
    rename $filename, $file
        or warn "Can't rewrite '$file', $!\n";
    chmod oct($mode), $file;
}
