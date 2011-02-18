use strict;
use warnings;
use Test::Base;
use lib 't/lib';
use Test::Behaviour::Spec;
use DBIx::Hakobe;

plan tests => 25;

@Table::Mock::ISA = qw(DBIx::Hakobe);
Table::Mock->table('mock');
Table::Mock->columns('id', 'name', 'title');
Table::Mock->primary_key('id');

{
    describe 'Table::Mock';
        my $class = 'Table::Mock';

    it 'should provide find.';

        ok $class->can('find'), spec;

    it 'should provide count.';

        ok $class->can('count'), spec;

    it 'should provide save.';

        ok $class->can('save'), spec;

    it 'should provide insert.';

        ok $class->can('insert'), spec;

    it 'should provide update.';

        ok $class->can('update'), spec;

    it 'should connect datasource.';

        is 'DBI::db', ref($class->connect('DBI:Mock:', '', '')), spec;

    it 'should provide database handle.';

        ok $class->can('dbh'), spec;

    it 'should get database handle.';

        is 'DBI::db', ref($class->dbh), spec;

    it 'should get DBIx::Hakobe::Query.';

        ok $class->sql->isa('DBIx::Hakobe::Query'), spec;

    it 'should find with Query.';

        my($stmt) = $class->sql->select_from(
            [$class->columns], $class->table,
        )->filter('id =', 1)->statement;
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['id', 'name', 'title'],
                [1, 'one', 'number 1'],
            ],
        };
        $class->dbh->{mock_clear_history} = 1;

        my $rows = $class->find(sub{ $_->filter('id =', 1) });

        my $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            rows => $rows,
            row_class => ref $rows->[0],
        }, {
            stmt => [$stmt],
            params => [[1]],
            rows => [{id => 1, name => 'one', title => 'number 1'}],
            row_class => $class,
        }, spec;

    it 'should find with HASH.';

        ($stmt) = $class->sql->select_from(
            [$class->columns], $class->table,
        )->filter('id =', 1)->statement;
        $class->dbh->{mock_rs} = undef;
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['id', 'name', 'title'],
                [1, 'one', 'number 1'],
            ],
        };
        $class->dbh->{mock_clear_history} = 1;

        $rows = $class->find({'id' => 1});

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            rows => $rows,
            row_class => ref $rows->[0],
        }, {
            stmt => [$stmt],
            params => [[1]],
            rows => [{id => 1, name => 'one', title => 'number 1'}],
            row_class => $class,
        }, spec;

    it 'should find from its instance values.';

        ($stmt) = $class->sql->select_from(
            [$class->columns], $class->table,
        )->filter('id =', 1)->statement;
        $class->dbh->{mock_rs} = undef;
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['id', 'name', 'title'],
                [1, 'one', 'number 1'],
            ],
        };
        $class->dbh->{mock_clear_history} = 1;

        $rows = $class->new({'id' => 1})->find;

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            rows => $rows,
            row_class => ref $rows->[0],
        }, {
            stmt => [$stmt],
            params => [[1]],
            rows => [{id => 1, name => 'one', title => 'number 1'}],
            row_class => $class,
        }, spec;

    it 'should count with Query.';

        ($stmt) = $class->sql->select_from(
            ['COUNT(*)'], $class->table,
        )->filter('id =', 2)->statement;
        $class->dbh->{mock_rs} = undef;
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['COUNT(*)'],
                [1],
            ],
        };
        $class->dbh->{mock_clear_history} = 1;

        my(@answer) = $class->count(sub{ $_->filter('id =', 2) });

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            answer => [@answer],
        }, {
            stmt => [$stmt],
            params => [[2]],
            answer => [1],
        }, spec;

    it 'should count with HASH.';

        ($stmt) = $class->sql->select_from(
            ['COUNT(*)'], $class->table,
        )->filter('id =', 2)->statement;
        $class->dbh->{mock_rs} = undef;
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['COUNT(*)'],
                [1],
            ],
        };
        $class->dbh->{mock_clear_history} = 1;

        (@answer) = $class->count({'id' => 2});

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            answer => [@answer],
        }, {
            stmt => [$stmt],
            params => [[2]],
            answer => [1],
        }, spec;

    it 'should count from its instance values.';

        ($stmt) = $class->sql->select_from(
            ['COUNT(*)'], $class->table,
        )->filter('id =', 2)->statement;
        $class->dbh->{mock_rs} = undef;
        $class->dbh->{mock_add_resultset} = {
            sql => $stmt,
            results => [
                ['COUNT(*)'],
                [1],
            ],
        };
        $class->dbh->{mock_clear_history} = 1;

        (@answer) = $class->new({'id' => 2})->count;

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            answer => [@answer],
        }, {
            stmt => [$stmt],
            params => [[2]],
            answer => [1],
        }, spec;

    it 'should save.';

        ($stmt) = $class->sql->insert_into('-replace', $class->table)
            ->set('id', 3)->set('name', 'foo')->set('title', 'Foo')
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->new({id => 3, name => 'foo', title => 'Foo'})->save;

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => ['BEGIN WORK', $stmt, 'COMMIT'],
            params => [[], [3, 'foo', 'Foo'], []],
        }, spec;

    it 'should save and set primary_key.';

        ($stmt) = $class->sql->insert_into('-replace', $class->table)
            ->set('name', 'foo')->set('title', 'Foo')
            ->statement;
        # see DBD::Mock comment: 'we start at one minus the start id'
        $class->dbh->{mock_start_insert_id} = 23 + 1;
        $class->dbh->{mock_clear_history} = 1;

        my $row = $class->new({name => 'foo', title => 'Foo'})->save;

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
            id => $row->id,
        }, {
            stmt => ['BEGIN WORK', $stmt, 'COMMIT'],
            params => [[], ['foo', 'Foo'], []],
            id => 23,
        }, spec;

    it 'should insert a row.';

        ($stmt) = $class->sql->insert_into($class->table)
            ->set('id', 3)->set('name', 'foo')->set('title', 'Foo')
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->new({id => 3, name => 'foo', title => 'Foo'})->insert;

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => ['BEGIN WORK', $stmt, 'COMMIT'],
            params => [[], [3, 'foo', 'Foo'], []],
        }, spec;

    it 'should insert or replace a row.';

        ($stmt) = $class->sql->insert_into('-replace', $class->table)
            ->set('id', 3)->set('name', 'foo')->set('title', 'Foo')
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->new({id => 3, name => 'foo', title => 'Foo'})
            ->insert('-replace');

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => ['BEGIN WORK', $stmt, 'COMMIT'],
            params => [[], [3, 'foo', 'Foo'], []],
        }, spec;

    it 'should insert or ignore a row.';

        ($stmt) = $class->sql->insert_into('-ignore', $class->table)
            ->set('id', 3)->set('name', 'foo')->set('title', 'Foo')
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->new({id => 3, name => 'foo', title => 'Foo'})->insert('-ignore');

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => ['BEGIN WORK', $stmt, 'COMMIT'],
            params => [[], [3, 'foo', 'Foo'], []],
        }, spec;

    it 'should insert or abort a row.';

        ($stmt) = $class->sql->insert_into('-abort', $class->table)
            ->set('id', 3)->set('name', 'foo')->set('title', 'Foo')
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->new({id => 3, name => 'foo', title => 'Foo'})->insert('-abort');

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => ['BEGIN WORK', $stmt, 'COMMIT'],
            params => [[], [3, 'foo', 'Foo'], []],
        }, spec;

    it 'should insert or fail a row.';

        ($stmt) = $class->sql->insert_into('-fail', $class->table)
            ->set('id', 3)->set('name', 'foo')->set('title', 'Foo')
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->new({id => 3, name => 'foo', title => 'Foo'})->insert('-fail');

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => ['BEGIN WORK', $stmt, 'COMMIT'],
            params => [[], [3, 'foo', 'Foo'], []],
        }, spec;

    it 'should insert or rollback a row.';

        ($stmt) = $class->sql->insert_into('-rollback', $class->table)
            ->set('id', 3)->set('name', 'foo')->set('title', 'Foo')
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->new({id => 3, name => 'foo', title => 'Foo'})
            ->insert('-rollback');

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => ['BEGIN WORK', $stmt, 'COMMIT'],
            params => [[], [3, 'foo', 'Foo'], []],
        }, spec;

    it 'shoule update.';

        ($stmt) = $class->sql->update($class->table)
            ->set('name =', 'foo')->set('title =', 'Foo')
            ->filter('id =', 3)
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->update(sub{
            $_->set('name =', 'foo')->set('title =', 'Foo');
            $_->filter('id =', 3);
        });

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => [$stmt],
            params => [['foo', 'Foo', 3]],
        }, spec;

    it 'should reject.';

        ($stmt) = $class->sql->delete_from($class->table)
            ->filter('name =', 'foo')->filter('title =', 'Foo')
            ->statement;
        $class->dbh->{mock_clear_history} = 1;

        $class->reject(sub{
            $_->filter('name =', 'foo')->filter('title =', 'Foo');
        });

        $history = $class->dbh->{mock_all_history};
        is_deeply {
            stmt => [map { $_->statement } @{$history}],
            params => [map { $_->bound_params } @{$history}],
        }, {
            stmt => [$stmt],
            params => [['foo', 'Foo']],
        }, spec;
}

