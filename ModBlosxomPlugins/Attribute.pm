package ModBlosxom::plugin::Attribute;

# This is test version.
#  by makamaka[at]donzoko.ent

#use warnings;
use strict;

sub new { bless {}, shift; }

sub start{
	my ($self,$blosxom) = @_;

	$self->{extension} = $blosxom->settings('attribute_extension') || 'txt';
	$self->{attr_dir}  = $blosxom->settings('attribute_dir');
	$self->{handles}   = $blosxom->settings('attribute_handles')
#	                   || [ sub{} ];
	                   || [
		sub{
			my ($blosxom,$attr,$path,$fn,$storyref,$titleref,$bodyref) = @_;
			return unless(defined $attr);

			while( my($k,$v) = each %$attr ){
				$$bodyref .= "<em>$k = $v</em><br />\n";
			}
		}
	];

	1;
}

sub story {
	my ($self, $blosxom, $path, $fn, @refs) = @_;
	my $id = "$path/$fn." . $self->{extension};

	no strict qw(refs);
	local *ModBlosxom::AccessDB::get_attr = $self->_get_attr();

	my $attr = $blosxom->access_db()->get_attr({
		datadir => $self->{attr_dir},
		id      => $id,
	});

	# @refs ... $story_ref, $title_ref, $body_ref
	for my $sub ( @{$self->{handles}} ){
		$sub->($blosxom, $attr, $path, $fn, @refs);
	}

	return 1;
}

#
# ModBlosxom::AccessDB's method
#

sub _get_attr {
	sub {
		my $self    = shift;
		my $hashref = shift;
		my $fh      = $self->{fh};

		my $datadir = $hashref->{datadir};
		my $file    = $hashref->{id};
		my $attr    = {};

		$fh->open("$datadir$file") or return undef;

		while(my $line = <$fh>){
			chomp($line);
			my ($key, $value) = split(/\s*=\s*/,$line,2);
			$attr->{$key} = $value if(defined $key and defined $value);
		}

		$fh->close();

		return $attr;
	};
}


1;

