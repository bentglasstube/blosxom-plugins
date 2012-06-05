# my_cript.pl

###################### for dynamic password
sub my_encript{
  my ($en_data) = @_;
  $en_data =  &my_cript($en_data,1);
  $en_data =~ tr/0123456789./qwertyuiops/; # qwertyuiops
  return $en_data;
}

sub my_decript{
  my ($de_data) = @_;
  $de_data =~ tr/qwertyuiops/0123456789./; # qwertyuiops
  $de_data =  &my_cript($de_data,0);
  return $de_data;
}

sub my_cript{ # $cript = 1 for encript, 0 for decript
  my ($data, $cript) = @_; my @data; 
  my $key = 4.1234567; # my password: 1.1234567-4.1234567, You can change this variable.
  if($cript){
    @data = reverse split //,$data;
    unshift @data,'1';
    $data = join '',@data;
    $data = $key * log($data);
  }else{
    $data =int(exp($data/$key)+0.001);
    @data = split //,$data;
    shift @data;
    $data = join '',reverse @data;
  }
  return $data;
}
######################

1;