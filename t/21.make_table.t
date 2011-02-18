use strict;
use warnings;
use Test::Base;
use Test::Exception;
use lib 't/lib';
use Test::Behaviour::Spec;
use DBIx::Hakobe;

@Table::ISA = qw(DBIx::Hakobe);

plan tests => 50;

{
    describe 'Table';

    it 'should make table.';

        ok(Table->can('make_table'), spec);

    it 'should make table "user" as "Table::User".';

        Table->make_table(
            'user', [
                'id',
                'name',
            ],
            PRIMARY_KEY => 'id',
        );
        ok(Table::User->isa('Table'), spec);

     it 'should make table "role" as "Table::Role".';

        Table->make_table(
            'role', [
                'id',
                'name',
            ],
            PRIMARY_KEY => 'id',
        );
        ok(Table::Role->isa('Table'), spec);

     it 'should make table "permission" as "Table::Permission".';

        Table->make_table(
            'permission', [
                'user_id',
                'role_id',
            ],
        );
        ok(Table::Permission->isa('Table'), spec);

    it 'should make view.';

        ok(Table->can('make_table_view'), spec);

    it 'should make view "user_role" as "Table::UserRole".';

        Table->make_table_view(
            'user_role',
            'user' => [
                'id' => 'user_id',
                'name' => 'user_name',
            ],
            'role' => [
                'id' => 'role_id',
                'name' => 'role_name',
            ],
            'permission' => [
                'user_id' => 'user_id',
                'role_id' => 'role_id',
            ],
        );
        ok(Table::UserRole->isa('Table'), spec);
}

{
    describe 'Table::User class';

    it 'should provide table class accessor.';

        ok(Table::User->can('table'), spec);

    it 'should provide columns class accessor.';

        ok(Table::User->can('columns'), spec);

    it 'should provide primary_key class accessor.';

        ok(Table::User->can('primary_key'), spec);

    it 'should has table name "user".';

        is 'user', Table::User->table, spec;

    it 'should has column names ("id", "name").';

        is_deeply ['id', 'name'], [Table::User->columns], spec;

    it 'should has primary_key name "id".';

        is 'id', Table::User->primary_key, spec;
}

{
    describe 'Table::User instance';

        my $user = Table::User->new;

    it 'should provide column "id".';

        ok $user->can('id'), spec;

    it 'should provide column "name".';

        ok $user->can('name'), spec;
}

{
    describe 'Table::Role class';

    it 'should provide table class accessor.';

        ok(Table::Role->can('table'), spec);

    it 'should provide columns class accessor.';

        ok(Table::Role->can('columns'), spec);

    it 'should provide primary_key class accessor.';

        ok(Table::Role->can('primary_key'), spec);

    it 'should has table name "role".';

        is 'role', Table::Role->table, spec;

    it 'should has column names ("id", "name").';

        is_deeply ['id', 'name'], [Table::Role->columns], spec;

    it 'should has primary_key name "id".';

        is 'id', Table::Role->primary_key, spec;
}

{
    describe 'Table::Role instance';

        my $role = Table::Role->new;

    it 'should provide column "id".';

        ok $role->can('id'), spec;

    it 'should provide column "name".';

        ok $role->can('name'), spec;
}

{
    describe 'Table::Permission class';

    it 'should provide table class accessor.';

        ok(Table::Permission->can('table'), spec);

    it 'should provide columns class accessor.';

        ok(Table::Permission->can('columns'), spec);

    it 'should provide primary_key class accessor.';

        ok(Table::Permission->can('primary_key'), spec);

    it 'should has table name "permission".';

        is 'permission', Table::Permission->table, spec;

    it 'should has column names ("user_id", "role_id").';

        is_deeply ['user_id', 'role_id'], [Table::Permission->columns], spec;

    it 'should not has primary_key name.';

        ok ! defined Table::Permission->primary_key, spec;
}

{
    describe 'Table::Permission instance';

        my $permission = Table::Permission->new;

    it 'should provide column "user_id".';

        ok $permission->can('user_id'), spec;

    it 'should provide column "role_id".';

        ok $permission->can('role_id'), spec;
}

{
    describe 'Table::UserRole class';

    it 'should provide table class accessor.';

        ok(Table::UserRole->can('table'), spec);

    it 'should provide columns class accessor.';

        ok(Table::UserRole->can('columns'), spec);

    it 'should provide primary_key class accessor.';

        ok(Table::UserRole->can('primary_key'), spec);

    it 'should has table name "user_role".';

        is 'user_role', Table::UserRole->table, spec;

    it 'should has column names.';

        is_deeply [
            'user_id', 'user_name', 'role_id', 'role_name',
        ], [Table::UserRole->columns], spec;

    it 'should not has primary_key name.';

        ok ! defined Table::UserRole->primary_key, spec;
}

{
    describe 'Table::UserRole instance';

        my $user_role = Table::UserRole->new({
            user_id => 12345,
            user_name => 'deepsort',
            role_id => 67890,
            role_name => 'compute',
        });

    it 'should provide column "user_id".';

        ok $user_role->can('user_id'), spec;

    it 'should provide column "user_name".';

        ok $user_role->can('user_name'), spec;

    it 'should provide column "role_id".';

        ok $user_role->can('role_id'), spec;

    it 'should provide column "role_name".';

        ok $user_role->can('role_name'), spec;

    it 'should provide table "user".';

        ok $user_role->can('user'), spec;

    it 'should create Table::User instance.';

        ok $user_role->user->isa('Table::User'), spec;

    it 'should give column values to "user".';

        is_deeply [
            $user_role->user_id,
            $user_role->user_name,
        ], [
            @{$user_role->user}{$user_role->user->columns},
        ], spec;

    it 'should provide table "role".';

        ok $user_role->can('role'), spec;

    it 'should create Table::Role instance.';

        ok $user_role->role->isa('Table::Role'), spec;

    it 'should give column values to "role".';

        is_deeply [
            $user_role->role_id,
            $user_role->role_name,
        ], [
            @{$user_role->role}{$user_role->role->columns},
        ], spec;

    it 'should provide table "permission".';

        ok $user_role->can('permission'), spec;

    it 'should create Table::Permission instance.';

        ok $user_role->permission->isa('Table::Permission'), spec;

    it 'should give column values to "permission".';

        is_deeply [
            $user_role->user_id,
            $user_role->role_id,
        ], [
            @{$user_role->permission}{$user_role->permission->columns},
        ], spec;

    it 'should die on save.';

        dies_ok sub{ $user_role->save }, spec;
}

