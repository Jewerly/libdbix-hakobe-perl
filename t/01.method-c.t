use strict;
use warnings;
use Test::Base;
use Test::Exception;
use DBIx::Hakobe;

plan tests => 24;

can_ok 'DBIx::Hakobe', 'connect';
can_ok 'DBIx::Hakobe', 'connect_cached';
can_ok 'DBIx::Hakobe', 'sql';
can_ok 'DBIx::Hakobe', 'table';
can_ok 'DBIx::Hakobe', 'columns';
can_ok 'DBIx::Hakobe', 'primary_key';
can_ok 'DBIx::Hakobe', 'blobs';
can_ok 'DBIx::Hakobe', 'make_table';
can_ok 'DBIx::Hakobe', 'make_table_view';
can_ok 'DBIx::Hakobe', 'make_class_accessor';
can_ok 'DBIx::Hakobe', 'make_accessor';
can_ok 'DBIx::Hakobe', 'new';
can_ok 'DBIx::Hakobe', 'collect_new';
can_ok 'DBIx::Hakobe', 'find';
can_ok 'DBIx::Hakobe', 'count';
can_ok 'DBIx::Hakobe', 'save';
can_ok 'DBIx::Hakobe', 'insert';
can_ok 'DBIx::Hakobe', 'update';
can_ok 'DBIx::Hakobe', 'reject';
can_ok 'DBIx::Hakobe', 'transaction';
can_ok 'DBIx::Hakobe', 'execute';
can_ok 'DBIx::Hakobe', 'selectrow_array';
can_ok 'DBIx::Hakobe', 'dbh';
can_ok 'DBIx::Hakobe', 'disconnect';

