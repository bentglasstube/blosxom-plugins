package LJPost;

use strict;
use warnings;
use RPC::XML::Client;

#fix livejournal username and password below. password must be md5 sum
#of your real password :P

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    # set the version for version checking
    $VERSION     = 1.00;
    @ISA         = qw(Exporter);
    @EXPORT      = qw(&makepost &send2lj &writedat);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ]
    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw();
}

our @EXPORT_OK;


sub makepost() {

my $user=shift;
my $pass=shift;
my $event=shift;
my $subject=shift;
my $year=shift;
my $mon=shift;
my $day=shift;
my $hour=shift;
my $min=shift;

my $cli = RPC::XML::Client->new('http://www.livejournal.com/interface/xmlrpc/');

$event=~s/\n/ /g;
$event.="\n";
$event=~s!<br/?>!\n!g;
$event=~s!<p/?>!\n\n!g;

my %h=(
    username => $user,
    hpassword => $pass,
    event => $event,
    lineendings=> "\n",
    subject => $subject,
    year => $year,
    mon => $mon,
    day => $day,
    hour => $hour,
    min => $min,
    props => {opt_backdated=>1},
    );

my $resp = $cli->send_request('LJ.XMLRPC.postevent', \%h);

if(!$resp) {
    return "500 Response error\n";
    }
   
if($resp->value->{'faultString'}) {
    return '500 ' . $resp->value->{'faultString'};
    }

return "200 OK";

} #sub makepost


sub send2lj()   {

my $file=shift;
my $user=shift;
my $pass=shift;
my $event;
my $h=1;
my $sub;
my $retval;

open (EV,"<$file") || return "$!";
while(my $foo=<EV>) {
    if($h==1) {
        $h=0;
        $sub=$foo;
        chomp($sub);
        next;
        }
    $event.=$foo;
    }
close(EV);

$event.=qq[\nCloned from <a href="http://www.thesatya.com/blosxom/">Satya's website</a>\n];

my @time=localtime(((stat($file))[9]));
$time[5]+=1900;
$time[4]++;

$retval=&makepost($user,$pass,$event,$sub,$time[5], $time[4], $time[3], 
$time[2],$time[1]);

if($retval=~/^200/) {
    print (($sub ne ''?$sub:$file), " posted\n");
    }
else {
    print "$retval\n";
    }

return;
} #send2lj

sub writedat() {

my $datfile=shift;
my $file;
my $s=shift;
my %sums=%{$s};

open(I,">$datfile") || die "$datfile: $!";
foreach $file (sort(keys(%sums))) {
    print I $file . ' ' ;
    print I $sums{$file} . "\n";
    }

close(I);

}#sub writedat


1;

__END__
