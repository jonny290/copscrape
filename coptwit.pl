#!/usr/bin/perl 

#perl twitter script
#by 290
#v0.000000000401
#not really

use Net::Twitter;
use DBI;

my $dsn    = "DBI:mysql:database=cops;server=localhost;port=3306";
my $dbuser = "XXX";
my $dbpass = "XXX";
my $tweet  = "twitter test, lol";
my @tweeted;
my $twitterconsumer          = "XXX";
my $twitterconsumersecret    = "XXX";
my $twitteraccesstoken       = "XXX";
my $twitteraccesstokensecret = "XXX";

my $nt = Net::Twitter->new(
    traits          => [ 'API::REST', 'OAuth' ],
    consumer_key    => $twitterconsumer,
    consumer_secret => $twitterconsumersecret,
);
if ( $twitteraccesstoken && $twitteraccesstokensecret ) {
    $nt->access_token($twitteraccesstoken);
    $nt->access_token_secret($twitteraccesstokensecret);
}
unless ( $nt->authorized ) {
    exit;
}

our $dbic = DBI->connect( $dsn, $dbuser, $dbpass );
my $query =
  "select * from incidents where tweeted = false ORDER BY date LIMIT 0,30";
my $sth = $dbic->prepare($query);
$sth->execute();

while ( @row = $sth->fetchrow_array ) {
    my $timestamp = $row[1];
    $timestamp =~ s/.*\s//g;
    $tweet = "$timestamp $row[3] $row[2]";
    if ( $lat && $long ) {
        $nt->update(
            {
                status => $tweet,
                lat    => $row[4],
                long   => $row[5],
            }
        );
    }
    else {

        $nt->update(
            {
                status   => $tweet,
                place_id => "Fayetteville",
            }
        );
    }
    sleep(5);
    push( @tweeted, $row[0] );
}

foreach my $setflag (@tweeted) {
    my $rc =
      $dbic->do("UPDATE incidents SET tweeted = true WHERE md5 = '$setflag'");
}
