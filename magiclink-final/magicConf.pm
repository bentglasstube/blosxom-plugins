#!/bin/perl -w

#----------------------------------------------------------------------
# magicConf.pm  
#
# A simple configuration loader     
#
# Copyright (C) 2003 Bruce Alderson
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA 02111-1307, USA.
#
#----------------------------------------------------------------------


package magicConf;

use strict;
use warnings;

my $debug = 0; # set to 1 to debug config loading

sub load {
    my $filename = shift;
    
    return undef unless -f $filename;
    return undef unless open(CONF, "< $filename");

    my %conf = ();
    my $section;
    while (<CONF>) {
        chomp;
        s/^#.*//; # remove comments
        s/^\s+//; # remove leading space
        s/\s+$//; # remove trailing space
        next unless length;
    
        # grab section key from [] lines
        if (m/^\[(.*)\]/) {
            $section = $1; 
            next;
        }
        
        # grab key = value (trimming spaces)
        if (m/(\w+)\s*=\s*(.*)\s*$/) {
            my ($key, $value) = ($1, $2 || '');
            next unless defined $key and length $key;
            print "$section '$key' = '$value'\n" if $debug;
            $conf{$section}{$key} = $value;
        }
    }
    close(CONF);

    return \%conf;
}

1;
