#!/usr/bin/perl 

use Data::Dumper;
use Storable;
use DBI;
use Math::Trig qw(deg2rad pi great_circle_distance asin acos);

my $dsn      = "DBI:mysql:database=cops;server=localhost;port=3306";
my $dbuser   = "XXX";
my $dbpass   = "XXX";
my $homelat  = "36.0";
my $homelong = "-94.4";
my $dbic     = DBI->connect( $dsn, $dbuser, $dbpass );

my $query =
"SELECT `date`,`desc`,`add`,`lat`,`lon` from `incidents` where `date` > '2012-08-26 00:00:00' ORDER BY `date` desc LIMIT 0, 10";
my $sth = $dbic->prepare($query);
$sth->execute();
my $row;
while ( $row = $sth->fetchrow_hashref ) {
    my %hash = %{$row};
    my $dst = &Haversine( $homelat, $homelong, $hash{lat}, $hash{lon} );
    $hash{date} =~ s/^.*?\s//;
    if ( ( $dst ne "N/A" ) && ( $dst < 2 ) ) {
        print $hash{date} . " "
          . $hash{desc} . " | "
          . $hash{add} . " ("
          . $dst . " mi) ";
        print "\n\r";
        last;
    }
}

sub Haversine {
    my ( $lat1, $long1, $lat2, $long2 ) = @_;
    my $r = 3956;
    if ( ( $lat2 == 0 ) || ( $long2 == 0 ) ) { return "N/A" }

    $dlong = deg2rad($long1) - deg2rad($long2);
    $dlat  = deg2rad($lat1) - deg2rad($lat2);

    $a =
      sin( $dlat / 2 )**2 +
      cos( deg2rad($lat1) ) * cos( deg2rad($lat2) ) * sin( $dlong / 2 )**2;
    $c = 2 * ( asin( sqrt($a) ) );
    $dist = $r * $c;

    return sprintf( "%.2f", $dist );

}
