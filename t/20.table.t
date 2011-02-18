use strict;
use warnings;
use Test::Base;
use lib 't/lib';
use Test::Behaviour::Spec;
use DBIx::Hakobe;

@Foo::ISA = qw(DBIx::Hakobe);

plan tests => 40;

{
    describe 'Foo class';

    it 'should has a table class accessor.';
    
        ok(Foo->can('table'), spec);

    it 'should set its table name.';

        is 'tests', Foo->table('tests'), spec;

    it 'should get its table name.';

        is 'tests', Foo->table, spec;

    it 'should has a columns class accessor.';

        ok(Foo->can('columns'), spec);

    it 'should set its column names';

        is 'id', Foo->columns('id', 'name', 'content'), spec;

    it 'should get its column names';

        is_deeply ['id', 'name', 'content'], [Foo->columns], spec;

    it 'should create column accessor "id".';

        ok(Foo->can('id'), spec);

    it 'should create column accessor "name".';

        ok(Foo->can('name'), spec);

    it 'should create column accessor "content".';

        ok(Foo->can('content'), spec);

    it 'should has a primary_key class accessor.';

        ok(Foo->can('primary_key'), spec);

    it 'should set its primary_key name.';

        is 'id', Foo->primary_key('id'), spec;

    it 'should get its primary_key name.';

        is 'id', Foo->primary_key, spec;

    it 'should has a blobs class accessor.';

        ok(Foo->can('blobs'), spec);

    it 'should set its blobs hashref.';

        is_deeply {'content' => 1}, Foo->blobs({'content' => 1}), spec;

    it 'should get its blobs hashref.';

        is_deeply {'content' => 1}, Foo->blobs, spec;
    
    it 'should has new methods.';

        ok(Foo->can('new'), spec);

    it 'shoule make an instance with new.';

        my $foo = Foo->new;
        ok(ref $foo && $foo->isa('Foo'), spec);

    it 'shoule make an instance with injection.';

        $foo = Foo->new({id => 1, name => 'foo', content => 'Foo'});
        is_deeply {
            id => 1,
            name => 'foo',
            content => 'Foo',
        }, {
            id => $foo->id,
            name => $foo->name,
            content => $foo->content,
        }, spec;

    it 'should collect with new.';

        ok(Foo->can('collect_new'), spec);

    it 'should bless instances in a given list.';

        $foo = Foo->collect_new([
            {id => 1, name => 'foo', content => 'Foo'},
            {id => 2, name => 'bar', content => 'Bar'},
            {id => 3, name => 'baz', content => 'Baz'},
        ]);
        ok(    ref $foo eq 'ARRAY' && @{$foo} == 3
            && ref $foo->[0] && $foo->[0]->isa('Foo')
            && ref $foo->[1] && $foo->[1]->isa('Foo')
            && ref $foo->[2] && $foo->[2]->isa('Foo')
            && $foo->[0]->id == 1
            && $foo->[0]->name eq 'foo'
            && $foo->[0]->content eq 'Foo'
            && $foo->[1]->id == 2
            && $foo->[1]->name eq 'bar'
            && $foo->[1]->content eq 'Bar'
            && $foo->[2]->id == 3
            && $foo->[2]->name eq 'baz'
            && $foo->[2]->content eq 'Baz',

            spec,
        );
}

{
    describe 'Foo instance';

        my $foo1 = bless {}, 'Foo';
        my $foo2 = bless {}, 'Foo';

    it 'should get its table name.';

        is_deeply {
            foo1 => 'tests',
            foo2 => 'tests',
        }, {
            foo1 => $foo1->table,
            foo2 => $foo2->table,
        }, spec;

    it 'should get its column names';

        is_deeply {
            foo1 => ['id', 'name', 'content'],
            foo2 => ['id', 'name', 'content'],
        }, {
            foo1 => [$foo1->columns],
            foo2 => [$foo2->columns],
        }, spec;

    it 'should get its primary_key name';

        is_deeply {
            foo1 => 'id',
            foo2 => 'id',
        }, {
            foo1 => $foo1->primary_key,
            foo2 => $foo2->primary_key,
        }, spec;

    it 'should get its blobs hashref';

        is_deeply {
            foo1 => {'content' => 1},
            foo2 => {'content' => 1},
        }, {
            foo1 => $foo1->blobs,
            foo2 => $foo2->blobs,
        }, spec;

    it 'should has a column "id" on "foo1".';

        ok $foo1->can('id'), spec;

    it 'should has a column "id" on "foo2".';

        ok $foo2->can('id'), spec;

    it 'should set column "id" to "foo1".';

        is 47, $foo1->id(47), spec;

    it 'should set column "id" to "foo2".';

        is 23, $foo2->id(23), spec;

    it 'should get column "id" respectively.';

        is_deeply {
            foo1 => 47,
            foo2 => 23,
        }, {
            foo1 => $foo1->id,
            foo2 => $foo2->id,
        }, spec;

    it 'should has a column "name" on "foo1".';

        ok $foo1->can('name'), spec;

    it 'should has a column "name" on "foo2".';

        ok $foo2->can('name'), spec;

    it 'should set column "name" to "foo1".';

        is 'name1', $foo1->name('name1'), spec;

    it 'should set column "name" to "foo2".';

        is 'name2', $foo2->name('name2'), spec;

    it 'should get column "name" respectively.';

        is_deeply {
            foo1 => 'name1',
            foo2 => 'name2',
        }, {
            foo1 => $foo1->name,
            foo2 => $foo2->name,
        }, spec;

    it 'should has a column "content" on "foo1".';

        ok $foo1->can('content'), spec;

    it 'should has a column "content" on "foo2".';

        ok $foo2->can('content'), spec;

    it 'should set column "content" to "foo1".';

        is 'content1', $foo1->content('content1'), spec;

    it 'should set column "content" to "foo2".';

        is 'content2', $foo2->content('content2'), spec;

    it 'should get column "content" respectively.';

        is_deeply {
            foo1 => 'content1',
            foo2 => 'content2',
        }, {
            foo1 => $foo1->content,
            foo2 => $foo2->content,
        }, spec;

    it 'should set value for each columns.';

        is_deeply {
            foo1_id => 47,
            foo1_name => 'name1',
            foo1_content => 'content1',
            foo2_id => 23,
            foo2_name => 'name2',
            foo2_content => 'content2',
        }, {
            foo1_id => $foo1->id,
            foo1_name => $foo1->name,
            foo1_content => $foo1->content,
            foo2_id => $foo2->id,
            foo2_name => $foo2->name,
            foo2_content => $foo2->content,
        }, spec;
}

