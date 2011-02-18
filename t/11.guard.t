use strict;
use warnings;
use Test::Base;
use Test::Exception;
use DBIx::Hakobe::Query;

plan tests => 2;

throws_ok(sub{
    my $query = DBIx::Hakobe::Query->select_from(['bar'], 'foo');
    $query->filter('bobby; tables =', 'bar');
    my($stmt) = $query->statement;
}, qr/(?-x)Possible SQL injection attempt/msx, 'injection on unquoted column');

lives_ok(sub{
    my $query = DBIx::Hakobe::Query->select_from(['bar'], 'foo');
    $query->filter(q{"foo" = 'bobby; ''tables''' OR `foo.bar` = 'a''b'});
    my($stmt) = $query->statement;
}, 'safe quoted');

