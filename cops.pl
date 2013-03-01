#!/usr/bin/perl 
#
#  # This is a common method of declaring package scoped variables before the
#  # 'our' keyword was introduced.  You should pick one form or the other, but
#  # generally speaking, the our $var is preferred in new code.
#
#  #use vars qw($VERSION %IRSSI);
#
#  use Irssi;
#
#  our $VERSION = '1.00';
#  our %IRSSI = (
#      authors     => 'Author Name(s)',
#      contact     => 'author_email@example.com another_author@example.com',
#      name        => 'Script Title',
#      description => 'Longer script description, '
#                  .  'maybe on multiple lines',
#      license     => 'Public Domain',
#  );
#
#
use Data::Dumper;
use WWW::Mechanize;
use Storable;
use DBI;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use LWP::Simple;
use Geo::Google;

my $dsn    = "DBI:mysql:database=cops;server=localhost;port=3306";
my $dbuser = "XXX";
my $dbpass = "XXX";
my %months = (
    "January", '1',  "February", '2',  "March",     '3',
    "April",   '4',  "May",      '5',  "June",      '6',
    "July",    '7',  "August",   '8',  "September", '9',
    "October", '10', "November", '11', "December",  '12'
);
my $addrsuffix  = " FAYETTEVILLE, AR 72703";
my $lastgeotime = time - 16;

my $y   = WWW::Mechanize->new();
my $url = "http://dispatch.accessfayetteville.org/";
$y->get($url);
my $loghtml = $y->content;
my @log = split( "\n", $loghtml );
my %loghash;

#if (-e "./loghash") {my $lh = retrieve("./loghash"); %loghash = %$lh;}
until ( $log[0] =~ /You are viewing all calls for:/ ) {
    if ( $log[0] =~ m/no calls for/ ) { exit }
    shift @log;
}
my $todaysdate = shift @log;
$todaysdate =~ s/.*?nbsp;(.*?\d{4})&nbsp.*/$1/;
@today = split( / /, $todaysdate );
shift @today;
$today[0] = $months{ $today[0] };
$today[1] =~ s/,//g;
our $convdate =
    $today[2] . "-"
  . sprintf( "%02d", $today[0] ) . "-"
  . sprintf( "%02d", $today[1] );

print;
until ( $log[-1] =~ /<!-- end content -->/ ) {
    pop @log;
}
until ( $log[0] =~ /<!-- end content -->/ ) {
    if ( $log[0] =~ "<td class=\"time\">" ) {
        shift @log;
        my $itemtime = shift @log;
        $itemtime =~ s/\s//g;
        shift @log;
        my $itemdesc = &htstrip( shift @log );
        my $address  = &htstrip( shift @log );
        if ( $address =~ m/ AND / ) {
            $address =~ s/ [NESW] / /g;
            $address =~ s/^[NESW] //g;
        }

#	print $convdate." ".$itemtime." | " .sprintf("%-40s",$itemdesc)." | " .sprintf("%-40s",$address)."\n";
        $loghash{$convdate}{$itemtime}{$address}{$itemdesc} = 1
          unless (
            exists( $loghash{$convdate}{$itemtime}{$address}{$itemdesc} ) );
    }

    shift @log;

}
print;

sub dump {
    foreach my $date ( keys %loghash ) {
        foreach my $time ( keys %{ $loghash{$date} } ) {
            foreach my $add ( keys %{ $loghash{$date}{$time} } ) {
                foreach my $desc ( keys %{ $loghash{$date}{$time}{$add} } ) {
                    my $ts = $date . " " . $time;
                    my $md5 = md5_hex( $ts, $add, $desc );
                    my $tst =
                      $dbic->do("select * from incidents where md5 = '$md5'");
                    unless ( $tst == 1 ) {
                        my ( $sitela, $sitelo ) = &geoloc($add);
                        my $exec = $dbic->do(
"insert into incidents values ('$md5','$ts','$add','$desc','$sitela','$sitelo',false)"
                        );
                    }
                }
            }
        }
    }
}

our $dbic = DBI->connect( $dsn, $dbuser, $dbpass );
&dump;
$dbic->disconnect();

sub htstrip {
    my $out = shift;
    $out =~ s/&nbsp;//g;
    $out =~ s|<.+?>||g;
    $out =~ s/^\s*//g;
    $out =~ s/\s*$//g;
    $out =~ s/and/ AND /g;
    $out =~ s/\r//g;
    return $out;
}

sub geoloc {
    my $queryaddr = shift;
    $queryaddr .= ", " . $addrsuffix;
    sleep 17;
    my $d = get("http://rpc.geocoder.us/service/rest?address=$queryaddr");
    $d =~ /geo:long>([^< ]*).*?geo:lat>([^< ]*)/is;
    return ( $2, $1 );
}

