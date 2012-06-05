# Blosxom Plugin: FlaboursDir
# Author(s): Makamaka <makamaka[at]donzoko.net> 
# Version: 2004-09-07

# 2004-09-19 modified for ModBlosxom 0.22

package ModBlosxom::plugin::FlavoursDir;

sub new { bless {}, shift; }

sub start {
	my ($self, $blosxom) = @_;

	$self->{templates} = {};

	1;
}

sub template {
	my ($self,$blosxom) = @_;

	sub {
		my $self = shift;
		my ($path, $chunk, $flavour) = map{ (defined $_ ? $_ : '') } @_;
		my %template  = %{ $self->{templates} };
		my $tmpl_dir  = $self->settings('templates_dir')
		             || $self->settings('datadir');
		my $def_dir   = $self->settings('default_tmpl_dir');

		do {
			return $self->{template}->{"$tmpl_dir/$path/$chunk.$flavour"}
			  if($self->{template}->{"$tmpl_dir/$path/$chunk.$flavour"});

			my $template
			 = $self->access_db()
			        ->get_template({datadir => $tmpl_dir, id =>"/$path/$chunk.$flavour"})
			 || $self->access_db()
			         ->get_template({datadir => $def_dir, id =>"/$path/$chunk.$flavour"});

			$self->{template}->{"$tmpl_dir/$path/$chunk.$flavour"} = $template;
			return $template if($template);

		} while ($path =~ s/(\/*[^\/]*)$// and $1);

		return join '', ($template{$flavour}{$chunk} || $template{error}{$chunk} || '');
	};
}

1;

