package ModBlosxom::plugin::Categories2;

use strict;

sub new { bless {}, shift; }

sub start {
	my ($self, $blosxom) = @_;

	$self->report_dir($blosxom);

	$blosxom->settings( 'categories_aliases'
	                         => $self->alais_for_categories_plugin() );

	1;
}


sub report_dir {
	my ($self, $blosxom) = @_;
	my $basedir = $blosxom->settings('basedir');
	my $file    = 'category';

	$self->{category}   = do "$basedir/$file";
	$self->{report}     = [];
	$self->{parent}     = [];
	$self->{categories} = [];

	if   ($!){ warn $! }
	elsif($@){ warn $@ }

	my $hash = $self->{category} || return;

	$self->_report($blosxom,$self->{category}->{children});
}


sub _report {
	my ($self, $blosxom, $categories) = @_;

	while( my($name, $value) = each %{ $categories } ){

		push @{ $self->{current} }, $name;

		if($value->{children}){
			$self->_report($blosxom,$value->{children});
			$self->{report}->[0] = join('/',@{ $self->{current} });
		}
		else{
			$self->{report}->[0] = join('/',@{ $self->{current} });
		}

		$self->{report}->[2] = scalar(@{ $self->{current} }); # indent
		$self->{report}->[1]
		  = ($value->{alias} ne '') ? $value->{alias} : $name;

		if($self->{report}->[0] eq $self->{edit_target}->{name}){
			$self->{edit_target}->{alias} = $self->{report}->[1];
		}

		my $target = $self->{edit_target}->{name};
		if( $self->{report}->[0] =~ /^$target\// ){
			$self->{edit_target}->{has} = 1;
		}

		push @{ $self->{categories} }, [ @{ $self->{report} } ];

		$self->{report} = undef;

		pop @{ $self->{current} };
	}
}



sub alais_for_categories_plugin {
	my $self = shift;
	my $hash = {};

	for my $category (@{ $self->{categories} }){
		my ($name, $alias) = ($category->[0], $category->[1]);
		($name) = $name =~ /([^\/]+)$/;
		$hash->{$name} = $alias if($name);
	}

	return $hash;
}

1;
