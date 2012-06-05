package ModBlosxom::plugin::NotFound;

use strict;

sub new { bless {}, shift; }

sub start { 1; }

sub last {
	my ($self, $blosxom) = @_;

	return 0 if(defined $blosxom->{rendered}->{story});

	my $flavour = $blosxom->settings('notfound_flavour') || '404';
	my $path    = $blosxom->settings('path');

	$blosxom->{header}->{'-status'}  = '404 Not Found';

	for my $type (qw/head story foot/){
		$blosxom->{rendered}->{$type}
		 = $blosxom->interpolate( $blosxom->get_template($path,$type,$flavour) );
	}

}

1;
