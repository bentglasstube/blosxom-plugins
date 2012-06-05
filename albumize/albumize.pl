#!/usr/bin/perl -w

# albumize.pl v0.000000 (magic photo album htmlizer)
#
# Copyright (C) 2004 Bruce Alderson
# License: Questionable

# TODO : globals, cleanup, etc.
# TODO : look for description files per dir
# TODO : Alternate types of indexes:
#           * bread-crumb style (current)
#           * all-in-one (no nav hierarchy)
#           * combo
# TODO : configuration
#           * index extension
#           * themes/templates
#           * thumnail size/names
#           * root (relative, url)
# TODO : gen per-image page (shtml?)
# TODO : gen special 'index' composite for title page

use strict;
use warnings;
use Text::MagicTemplate qw( -compile );

use constant {
    ERROR_INDEX => 0,
    IMAGE_INDEX => 1,
    DIR_INDEX   => 2,
    COMBO_INDEX => 3,
    BLANK_INDEX => 4,
# TODO - add special dir-index (one pic, useful for image-indexes)
# TODO - add root index
    NO_INDEX    => 10
};

# TODO : getopt (root, theme, etc.)
my ($root) = @ARGV;
$root = './Album' unless defined $root;


# List of files
#
#   Flat - note some benifits to flat (despite need to filter)
#       * allows pages to use info from 'other' pages, not that
#         the code does it yet
my @list;  


# main

# TODO : need a 'partial-rebuild' approach
# TODO : also partial-clean

clean();
find();
gen_indexes();

sub clean {
    # hackish mechanism to clean
    system "find Album/ -name index.html -exec rm \"{}\" \\;";
    system "find Album/ -name \"thumbnails*\" -exec rm -fr \"{}\" \\;";
}

#----------------------------------------------------------------------
sub find {
    # A hackish way to grab file paths
    @list = `find $root`;
    map {chomp; s/^\.$//;} sort @list;
}

#----------------------------------------------------------------------
sub gen_indexes {

    foreach my $path (@list) {

        if (-d $path) {
            my $type =  index_type($path);

            if ($type == DIR_INDEX) {
                
                print "Generating a directory index in '$path'\n";
                process_dir_index($path);

            } elsif ($type == IMAGE_INDEX) {
                print "Generating an image index in '$path'\n";
                process_image_index($path);

            } else {
                print "Ignored '$path' ($type)\n";
            }
        } 
    }
}
#----------------------------------------------------------------------
sub index_type {
    my $root = shift;

    # TODO : logic is broken (file_in_dir + states need rethinking)
    #           * requires clean between uses (thumbnails not 
    #             ignored

    my ($image, $directory, $unknown, $blank) = (0,0,0,0);
    foreach my $path (@list) {
       
       next unless file_in_dir($path, $root); # ignore non-cwd elements
        
        if (-d $path) {
            $directory = 1;
            $blank = 1 if $path =~ m/.*\.thumbnail.*/;
        } elsif (-f $path) {
            if ($path =~ m/(jpeg|jpg|png|gif)/) {
                $image = 1;
            } else {
                $unknown = 1;
            }
        }
    }        

    return ERROR_INDEX if $unknown;
    return BLANK_INDEX if $blank;
    return IMAGE_INDEX if $image and !$directory;
    return DIR_INDEX   if !$image and $directory;
    return COMBO_INDEX if $image and $directory;
    return NO_INDEX;
}

#----------------------------------------------------------------------
sub file_in_dir {
    my ($path, $root) = @_;
    
    # TODO : add filters (thumbs, htaccess, etc)
    return 1 if $path =~ m/$root\// and 
        (($path =~ tr/\///) - ($root =~ tr/\///) == 1);
    0;
}

#----------------------------------------------------------------------
sub process_dir_index {
    my $root = shift;

    # TODO add 'breadcrumbs' similar to title
    
    my %page = ();

    $page{title} = get_name($root);

    foreach my $path (@list) {
        next unless file_in_dir($path, $root);
       
        my $dir = get_path($path, $root);
        push @{$page{directories}}, {
            path        => $dir,
            filename    => 'index.html', # TODO : from globals/config
            name        => get_short_name($path),
            long_name   => get_name($path)    
        };
    }    

    write_index('Themes/Default/dir-index.html', "$root/index.html", \%page);
}

#----------------------------------------------------------------------
sub process_image_index {
     my $root = shift;

    # TODO add 'breadcrumbs' similar to title
    
    my %page = ();

    $page{title} = get_name($root);
    $page{root} = $root;

    foreach my $path (@list) {
        next unless file_in_dir($path, $root);
       
        my $dir = get_path($path, $root);
        my ($thumb_local, $thumb) = get_thumb_path($path, $dir);
        push @{$page{images}}, {
            path        => '.', 
            filename    => $dir,
            name        => get_short_name($path),
            long_name   => get_name($path),
            thumbnail   => $thumb
        };

        gen_thumbnail($path, $thumb_local) unless -f $thumb_local;
        
        # TODO : gen per picture html (with nav)
    }    

    write_index('Themes/Default/image-index.html', "$root/index.html", \%page);
    
}

#----------------------------------------------------------------------
sub gen_thumbnail {
    my ($source, $dest) = @_;

    my $dir = $dest;
    $dir =~ s/^(.*)\/.*/$1/;
    system "mkdir -p \"$dir\"" unless -d $dir;
    return warn "Unable to create $dir" unless -d $dir;
    system "touch \"$dir\/index.html\""; 
   
    my $size = "100x100!";  # '!' forces dimensions
    my $options = "-antialias";
    
    my $command_line =    
        "convert -size $size $options " . 
        "\"$source\" -resize $size +profile '*' \"$dest\"";
 
    system $command_line;

    1;
}


#----------------------------------------------------------------------
sub write_index {
    my ($template, $output, $vars) = @_;
    
    die "Couldn't find template '$template'" unless -f $template;
    open IDX, "> $output" or die "Error, unable to write '$output' : $!";

    my $mt = new Text::MagicTemplate
              lookups         => [ \%{$vars} ], # TODO: add global tags
              output_handlers => sub{ print IDX $_[1]; };
    $mt->print($template);
    close IDX;

    1;
}

#----------------------------------------------------------------------
# Data Helpers

sub get_name {
    my $name = shift; 
    $name =~ s/^\.\///; 
    $name =~ s/\//::/g; 
    return $name;
}
sub get_short_name {
    my $name = shift; 
    $name =~ s/^.*\///g; 
    $name =~ s/\..*$//g; 
    return $name;
}
sub get_path {
    my ($path, $root) = @_; 
    $path =~ s/$root\///g; 
    return $path;
}
sub get_thumb_path {
    my $path = shift;
    my $short_path = $path;
    $path =~ s/\.\/(.*)\/(.*)/$1\/thumbnails\/$2/;
    $short_path =~  s/\.\/(.*)\/(.*)/thumbnails\/$2/;
    return $path, $short_path;
}


