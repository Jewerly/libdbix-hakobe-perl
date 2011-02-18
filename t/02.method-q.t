use strict;
use warnings;
use Test::Base;
use Test::Exception;
use DBIx::Hakobe::Query;

plan tests => 13;

can_ok 'DBIx::Hakobe::Query', 'select_from';
can_ok 'DBIx::Hakobe::Query', 'insert_into';
can_ok 'DBIx::Hakobe::Query', 'replace_into';
can_ok 'DBIx::Hakobe::Query', 'update';
can_ok 'DBIx::Hakobe::Query', 'delete_from';
can_ok 'DBIx::Hakobe::Query', 'distinct';
can_ok 'DBIx::Hakobe::Query', 'filter';
can_ok 'DBIx::Hakobe::Query', 'having';
can_ok 'DBIx::Hakobe::Query', 'group';
can_ok 'DBIx::Hakobe::Query', 'set';
can_ok 'DBIx::Hakobe::Query', 'order';
can_ok 'DBIx::Hakobe::Query', 'limit';
can_ok 'DBIx::Hakobe::Query', 'statement';

