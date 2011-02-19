use strict;
use warnings;
use Test::Base;
use lib 't/lib';
use Test::Behaviour::Spec;
use DBIx::Hakobe;

plan tests => 20;

{
    describe 'DBIx::Hakobe';
        my $class = 'DBIx::Hakobe';

    it 'should provide connect.';

        ok $class->can('connect'), spec;

    it 'should connect datasource.';

        is 'DBI::db', ref($class->connect('DBI:Mock:', '', '')), spec;

    it 'should provide database handle.';

        ok $class->can('dbh'), spec;

    it 'should get database handle.';

        is 'DBI::db', ref($class->dbh), spec;

    it 'should provide disconnect.';

        ok $class->can('disconnect'), spec;

    it 'should disconnect.';

        $class->disconnect;
        ok ! defined $class->dbh, spec;
        $class->connect('DBI:Mock:', '', '');

    it 'should provide execute.';

        ok $class->can('execute'), spec;

    it 'should execute sql string.';

        $class->dbh->{mock_clear_history} = 1;
        my $stmt = q{DELETE FROM planet WHERE name = 'earth'};
        $class->execute($stmt);
        my $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [$stmt],
            params => [[]],
        }, {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, spec;

    it 'should execute sql string with a parameter.';

        $class->dbh->{mock_clear_history} = 1;
        $stmt = 'INSERT INTO computer VALUES (?, ?)';
        $class->execute($stmt, 42, 'Deep Thought');
        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [$stmt],
            params => [[42, 'Deep Thought']],
        }, {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, spec;

    it 'should execute sth.';

        $class->dbh->{mock_clear_history} = 1;
        $stmt = q{DELETE FROM planet WHERE name = 'earth'};
        my $sth = $class->dbh->prepare($stmt);
        $class->execute($sth);
        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [$stmt],
            params => [[]],
        }, {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, spec;

    it 'should execute sth with a parameter.';

        $class->dbh->{mock_clear_history} = 1;
        $stmt = 'INSERT INTO computer VALUES (?, ?)';
        $sth = $class->dbh->prepare($stmt);
        $class->execute($sth, 42, 'Deep Thought');
        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [$stmt],
            params => [[42, 'Deep Thought']],
        }, {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, spec;

    it 'should return with fetchall_arrayref.';

        $stmt = 'SELECT * FROM planet';
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['name', 'description'],
                ['earth', 'mostly harmless'],
                ['magrathea', 'legendary'],
            ],
        };
        is_deeply [
            {name => 'earth', description => 'mostly harmless'},
            {name => 'magrathea', description => 'legendary'},
        ], $class->execute($stmt), spec;

    it 'should provide selectrow_array.';

        ok $class->can('selectrow_array'), spec;

    it 'should selectrow_array sql string.';

        $class->dbh->{mock_clear_history} = 1;
        $stmt = q{SELECT a, b FROM scrabble};
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['a', 'b'],
                [6, 9],
            ],
        };
        my @answer = $class->selectrow_array($stmt);
        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [$stmt],
            params => [[]],
            answer => [6, 9],
        }, {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            answer => [@answer],
        }, spec;

    it 'should selectrow_array sql string with a parameter.';

        $class->dbh->{mock_clear_history} = 1;
        $stmt = q{SELECT a, b FROM scrabble WHERE age = ?};
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['a', 'b'],
                [6, 9],
            ],
        };
        @answer = $class->selectrow_array($stmt, -2000000);
        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [$stmt],
            params => [[-2000000]],
            answer => [6, 9],
        }, {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            answer => [@answer],
        }, spec;

    it 'should selectrow_array sth.';

        $class->dbh->{mock_clear_history} = 1;
        $stmt = q{SELECT a, b FROM scrabble};
        $sth = $class->dbh->prepare($stmt);
        @answer = $class->selectrow_array($sth);
        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [$stmt],
            params => [[]],
            answer => [6, 9],
        }, {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            answer => [@answer],
        }, spec;

    it 'should selectrow_array sth with a parameter.';

        $class->dbh->{mock_clear_history} = 1;
        $stmt = q{SELECT a, b FROM scrabble WHERE age = ?};
        $sth = $class->dbh->prepare($stmt);
        @answer = $class->selectrow_array($sth, -2000000);
        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [$stmt],
            params => [[-2000000]],
            answer => [6, 9],
        }, {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            answer => [@answer],
        }, spec;

    it 'should provide transaction.';

        ok $class->can('transaction'), spec;

    it 'should commit.';

        $class->dbh->{mock_clear_history} = 1;
        $class->transaction(sub{
            $class->execute(q{INSERT INTO puzzle VALUES (42)});
        });
        is_deeply [
            'BEGIN WORK',
            'INSERT INTO puzzle VALUES (42)',
            'COMMIT',
        ], [
            map { $_->statement } @{$class->dbh->{mock_all_history}},
        ], spec;

    it 'should rollback on error.';

        $class->dbh->{mock_clear_history} = 1;
        eval {
            $class->transaction(sub{
                $class->execute(q{INSERT INTO puzzle VALUES (41)});
                die 'plunge into a star';
                $class->execute(q{INSERT INTO puzzle VALUES (42)});
            });
        };
        is_deeply [
            'BEGIN WORK',
            'INSERT INTO puzzle VALUES (41)',
            'ROLLBACK',
        ], [
            map { $_->statement } @{$class->dbh->{mock_all_history}},
        ], spec;
}

