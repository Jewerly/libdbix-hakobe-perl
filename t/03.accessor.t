use strict;
use warnings;
use Test::Base;
use lib 't/lib';
use Test::Behaviour::Spec;
use DBIx::Hakobe;

@Foo::ISA = qw(DBIx::Hakobe);
@Bar::ISA = qw(Foo);

my @preset_watch;

sub Foo::_preset_bar {
    my($class, @names) = @_;
    @preset_watch = @names;
    return;
}

plan tests => 24;

{
    describe 'Foo class';

    it 'should make class accessors.';

        ok(Foo->can('make_class_accessor'), spec);

    it 'should make accessors.';

        ok(Foo->can('make_accessor'), spec);

    it 'should not has "foo" in the first time.';

        ok(! Foo->can('foo'), spec);

    it 'should make class_accessor "foo".';

        Foo->make_class_accessor('foo');
        ok(Foo->can('foo'), spec);

    it 'should set a value "hydrogen" to "foo".';

        is 'hydrogen', Foo->foo('hydrogen'), spec;

    it 'should keep the value "hydrogen" in "foo".';

        is 'hydrogen', Foo->foo, spec;

    it 'should set values ("H", "He", "Li", "Be") to "foo".';

        Foo->foo("H", "He", "Li", "Be");
        is_deeply ["H", "He", "Li", "Be"], [Foo->foo], spec;

    it 'should not has "fizz" in the first time.';

        ok(! Foo->can('fizz'), spec);

    it 'should make a class accessor "bar".';

        Foo->make_class_accessor('bar');
        ok(Foo->can('bar'), spec);

    it 'should invoke _preset_bar fook internally.';

        @preset_watch = ();
        Foo->bar('H', 'He', 'Li', 'Be');
        is_deeply ['H', 'He', 'Li', 'Be'], \@preset_watch, spec;

    it 'should make an instance accessor "fizz".';

        Foo->make_accessor('fizz');
        ok(Foo->can('fizz'), spec);
}

{
    describe 'Bar class';

    it 'should make class accessor.';

        ok(Bar->can('make_class_accessor'), spec);

    it 'should make accessors.';

        ok(Bar->can('make_accessor'), spec);

    it 'should inherit "foo" from Foo.';

        ok(Bar->can('foo'), spec);

    it 'should get a same value "hydrogen" set by Foo.';

        Foo->foo('hydrogen');
        is 'hydrogen', Bar->foo, spec;

    it 'should get a same value "helium" changed by Foo.';

        Foo->foo('helium');
        is 'helium', Bar->foo, spec;

    it 'should set an another value "litium" to "foo".';

        is 'litium', Bar->foo('litium'), spec;

    it 'should keep the value "litium" to "foo".';

        is 'litium', Bar->foo, spec;

    it 'should not change the value "helium" in "foo" of "Foo".';

        is 'helium', Foo->foo, spec;
}

{
    describe 'Foo instance';

        my $foo1 = bless {}, 'Foo';
        my $foo2 = bless {}, 'Foo';

    it 'should set the value "foo".';

        is 'belilium', $foo1->foo('belilium'), spec;

    it 'should get same value "foo".';

        is_deeply {
            Foo => 'belilium',
            foo1 => 'belilium',
            foo2 => 'belilium',
        }, {
            Foo => Foo->foo,
            foo1 => $foo1->foo,
            foo2 => $foo2->foo,
        }, spec;

    it 'should set the value "bolon" to "fizz" of foo1.';

        is 'bolon', $foo1->fizz("bolon"), spec;

    it 'should set the value "carbon" to "fizz" of foo2.';

        is 'carbon', $foo2->fizz("carbon"), spec;

    it 'should get the value from "fizz" respectively.';

        is_deeply {
            foo1 => 'bolon',
            foo2 => 'carbon',
        }, {
            foo1 => $foo1->fizz,
            foo2 => $foo2->fizz,
        }, spec;
}

