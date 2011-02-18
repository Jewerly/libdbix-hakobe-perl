package DBIx::Hakobe;
use strict;
use warnings;
use Carp;
use Encode qw(encode_utf8 decode_utf8);
use DBI;
use DBIx::Hakobe::Query;

our $VERSION = '0.001';
# $Id$

__PACKAGE__->make_class_accessor('table');
__PACKAGE__->make_class_accessor('columns');
__PACKAGE__->make_class_accessor('primary_key');
__PACKAGE__->make_class_accessor('blobs' => {});

my $dbh;
my $SQL_BUILDER = 'DBIx::Hakobe::Query';

sub sql { return $SQL_BUILDER }

sub new {
    my($class, @arg) = @_;
    my $self = bless {}, $class;
    $self->_initialize(@arg);
    return $self;
}

sub _initialize {
    my($self, $h) = @_;
    $h ||= {};
    %{$self} = %{$h};
    return;
}

sub dbh { return $dbh }

sub connect {                   ## no critic qw(ProhibitBuiltinHomonyms)
    my($class, $dsn, $user, $auth, $attr) = @_;
    $attr ||= {};
    $dbh = DBI->connect($dsn, $user, $auth, {
        RaiseError => 1,
        PrintError => 0,
        %{$attr},
    }) or croak $DBI::errstr;   ## no critic qw(ProhibitPackageVars)
    return $dbh;
}

sub connect_cached {
    my($class, $dsn, $user, $auth, $attr) = @_;
    $attr ||= {};
    $dbh = DBI->connect_cached($dsn, $user, $auth, {
        RaiseError => 1,
        PrintError => 0,
        %{$attr},
    }) or croak $DBI::errstr;   ## no critic qw(ProhibitPackageVars)
    return $dbh;
}

sub disconnect {
    my($class, @dsn) = @_;
    return if ! $dbh;
    my $rc = $dbh->disconnect;
    $dbh = undef;
    return $rc;
}

sub make_accessor { # based on Class-Accessor-Fast.
    my($pkg, $f) = @_;
    my $accessor = sub{
        my($self, @arg) = @_;
        if (@arg) {
            $self->{$f} = $arg[0];
        }
        return $self->{$f};
    };
    no strict 'refs';
    *{"${pkg}\::${f}"} = $accessor;
    return;
}

sub make_class_accessor { # based on Class-Data-Inheritable.
    my($pkg, $attr, @value) = @_;
    my $class_accessor = sub{
        my($self, @arg) = @_;
        my $class = ref($self) || $self;
        return $class->make_class_accessor($attr)->($class, @arg)
            if @arg && $pkg ne $class;
        if (@arg) {
            my $handler = "_preset_$attr";
            if (eval{ $class->can($handler)}) {
                $class->$handler(@arg);
            }
            @value = @arg;
        }
        return wantarray ? @value : $value[0];
    };
    no strict 'refs';
    *{"${pkg}\::${attr}"} = $class_accessor;
    return $class_accessor;
}

sub make_table {
    my($class, $table, $columns, %opt) = @_;
    my $pkg = $class->_package_name($table);
    if (! eval { $pkg->isa($class) }) {
        no strict 'refs';
        push @{"${pkg}::ISA"}, $class;
    }
    $pkg->table($table);
    $pkg->columns(@{$columns});
    if (my $primary_key = $opt{PRIMARY_KEY}) {
        $pkg->primary_key($primary_key);
    }
    return;
}

sub make_table_view {
    my($class, $view, @table_list) = @_;
    my $pkg = $class->_package_name($view);
    if (! eval { $pkg->isa($class) }) {
        no strict 'refs';
        push @{"${pkg}::ISA"}, $class;
    }
    for my $method (qw(insert save update reject)) {
        no strict 'refs';
        if (! defined &{"${pkg}::${method}"}) {
            *{"${pkg}::${method}"} = sub{ croak 'not available.' };
        }
    }
    my @columns;
    my %already;
    for (0 .. -1 + int @table_list / 2) {
        my $i = $_ * 2;
        my($table, $column_list) = @table_list[$i, $i + 1];
        for (0 .. -1 + int @{$column_list} / 2) {
            my $column = $column_list->[$_ * 2 + 1];
            if (! exists $already{$column}) {
                push @columns, $column;
                $already{$column} = 1;
            }
        }
        no strict 'refs';
        *{"${pkg}::${table}"} = $class->_make_table_obj($table, $column_list);
    }
    $pkg->table($view);
    $pkg->columns(@columns);
    return;
}

sub _make_table_obj {
    my($class, $table, $column_list) = @_;
    my $pkg = $class->_package_name($table);
    my %columns = @{$column_list};
    $class = $table = $column_list = undef;
    return sub{
        my($self, $opt) = @_;
        my $h;
        for my $k (keys %columns) {
            my $col = $columns{$k};
            $h->{$k} = $self->$col;
        }
        if ($opt) {
            %{$h} = (%{$h}, %{$opt});
        }
        return $pkg->new($h);
    };
}

sub _package_name {
    my($class, $table) = @_;
    my $pkg = ref $class ? ref $class : $class;
    $pkg = join q{::}, $pkg, join q{}, map { ucfirst lc } split /_/msx, $table;
    return $pkg;
}

sub collect_new {
    my($class, $row_list) = @_;
    $class = ref $class ? ref $class : $class;
    my @list;
    my $blob = $class->blobs;
    for my $row (@{$row_list}) {
        my $obj = $class->new;
        while (my($k, $v) = each %{$row}) {
            if (! $blob->{$k} && $v && ! utf8::is_utf8($v)) {
                $v = decode_utf8($v);
            }
            $obj->{$k} = $v;
        }
        push @list, $obj;
    }
    return \@list;
}

sub find {
    my($self, $arg, $query) = @_;
    $query ||= $self->sql->select_from(
        [$self->columns], $self->table,
    );
    $self->_compose_query($arg, $query);
    return $self->collect_new($self->execute($query->statement));
}

sub count {
    my($self, $arg, $query) = @_;
    $query ||= $self->sql->select_from(
        ['COUNT(*)'], $self->table,
    );
    $self->_compose_query($arg, $query);
    my($count) = $self->selectrow_array($query->statement);
    return $count;
}

sub _compose_query {
    my($self, $arg, $query) = @_;
    if (ref $arg eq 'CODE') {
        for ($query) {
            $arg->($query);
        }
    }
    elsif (ref $arg eq 'HASH' || ref $self) {
        $arg ||= ref $self ? $self : {};
        for my $col ($self->columns) {
            next if ! defined $arg->{$col};
            $query->filter("$col =", $arg->{$col});
        }
    }
    return $self;
}

sub save { return shift->insert('-replace') }

sub insert {
    my($self, @conflict) = @_;
    my $pk = $self->primary_key;
    my $table = $self->table;
    my @column = $self->columns;
    my $insert = $self->sql->insert_into(@conflict, $table);
    for my $col (@column) {
        # do not support 'NULL' insertion by undef.
        next if ! defined $self->$col;
        $insert->set($col, $self->$col);
    }
    $self->transaction(sub{
        $self->execute($insert->statement);
        if ($pk && ! defined $self->$pk) {
            $self->$pk(
                $self->dbh->last_insert_id(undef, undef, $table, $pk),
            );
        }
    });
    return $self;
}

sub update {
    my($class, $yield) = @_;
    return if ! $yield;
    my $update = $class->sql->update($class->table);
    for ($update) {
        $yield->($update);
    }
    $class->execute($update->statement);
    return;
}

sub reject {
    my($class, $arg, $reject) = @_;
    return if ! $arg && ! $reject;
    $reject ||= $class->sql->delete_from($class->table);
    $class->_compose_query($arg, $reject);
    $class->execute($reject->statement);
    return;
}

sub transaction {
    my($self, $yield, %after) = @_;
    my $begun_work =  $self->dbh->{BegunWork};
    $begun_work or $self->dbh->begin_work;
    my $value;
    my $success = eval {
        $value = $yield->();
        1;
    };
    if (! $success) {
        my $err = $@ || $self->dbh->errstr;
        if (exists $after{when_rollback}) {
            $after{when_rollback}->();
        }
        $begun_work or $self->dbh->rollback;
        croak $err;
    }
    if (exists $after{when_commit}) {
        $after{when_commit}->();
    }
    $begun_work or $self->dbh->commit;
    return $value;
}

sub execute {
    my($class, $sql, @bind) = @_;
    my $sth = ref $sql ? $sql : $class->dbh->prepare($sql);
    if (! defined wantarray) {
        $sth or return;
        # similar as $dbh->do($sql, undef, @bind);
        $sth->execute(@bind);
        return;
    }
    $sth or return [];
    # similar as $dbh->selectall_arrayref($sql, {Columns => {}}, @bind);
    $sth->execute(@bind);
    my $rows = $sth->fetchall_arrayref({});
    $sth->finish;
    return $rows;
}

sub selectrow_array {
    my($class, $sql, @bind) = @_;
    my $sth = ref $sql ? $sql : $class->dbh->prepare($sql);
    $sth or return;
    $sth->execute(@bind);
    my @row = $sth->fetchrow_array;
    $sth->finish;
    return @row;
}

sub _preset_columns {
    my($class, @column_names) = @_;
    for my $column (@column_names) {
        next if UNIVERSAL::can($class, $column);
        $class->make_accessor($column);
    }
    return;
}

1;

__END__

=head1 NAME

DBIx::Hakobe - DBI connector for DBIx::Hakobe::Query

=head1 VERSION

0.001

=head1 SYNOPSIS

    package MyTable;
    use parent qw(DBIx::Hakobe);
    
    __PACKAGE__->make_table(
        'users',
        [
            'user_id',
            'user_name',
        ],
        PRIMARY_KEY => 'user_id',
    );
    __PACKAGE__->make_table(
        'roles',
        [
            'role_id',
            'role_name',
        ],
        PRIMARY_KEY => 'role_id',
    );
    __PACKAGE__->make_table_view(
        'user_role',
        'users' => [
            'user_id' => 'user_id',
            'user_name' => 'user_name',
        ],
        'roles' => [
            'role_id' => 'role_id',
            'role_name' => 'role_name',
        ],
        'permissions' => [
            'permission_user_id' => 'user_id',
            'permission_role_id' => 'role_id',
        ],
    );
    
    package Example;
    use MyTable;
    
    -e 'example.db' and unlink 'example.db';
    MyTable->connect('dbi:SQLite:dbname=example.db', undef, undef);
    MyTable->execute(q{
        CREATE TABLE users (
             user_id INTEGER PRIMARY KEY
            ,user_name VARCHAR(64) NOT NULL UNIQUE
        );
    });
    MyTable->execute(q{
        CREATE TABLE roles (
             role_id INTEGER PRIMARY KEY
            ,role_name VARCHAR(64) NOT NULL UNIQUE
        );
    });
    MyTable->execute(q{
        CREATE TABLE permissions (
             permission_user_id INTEGER NOT NULL REFERENCES user(user_id)
            ,permission_role_id INTEGER NOT NULL REFERENCES role(role_id)
            ,UNIQUE (permission_user_id, permission_role_id)
            ,PRIMARY KEY (permission_user_id, permission_role_id)
        );
    });
    MyTable->execute(q{
        CREATE VIEW user_role AS
            SELECT user_id, user_name, role_id, role_name
              FROM user JOIN permissions JOIN role
              WHERE user_id = permission_user_id
                AND role_id = permission_role_id;
    });
    my $assignment = MyTable::UserRole->new({
        user_id => 1, user_name => 'Alice',
        role_id => 1, role_name => 'Explorer',
    });
    $assingment->transaction(sub{
        $assignment->users->save;
        $assignment->roles->save;
        $assignment->permissions->save;
    });
    
    my $user_role_list = MyTable::UserRole->find(sub{
        $_->filter('user_name =', 'Alice');
        $_->filter('role_id =', 1);
        $_->order('user_name');
        $_->order('-role_name');
        $_->limit(-limit => 10, -offset => 0);
    });
    for my $user_role (@{$user_role_list}) {
        print join q{ }, @{$user_role}{$user_role->columns};
        print "\n";
    }
    $assingment->roles->update(sub{
        $_->set('role_name =', 'Dreamer');
        $_->filter('role_id =', 1);
    });
    $assingment->permissions->reject;

=head1 DESCRIPTION

=head1 METHODS

=over

=item C<< $class->make_table($table, \@columns, [PRIMARY_KEY => $column]) >>

=item C<< $class->make_table_view($view, \@tables) >>

=item C<< $class->table >>

=item C<< $class->columns >>

=item C<< $class->primary_key >>

=item C<< $class->blobs >>

=item C<< $class->make_class_accessor($name, \@initvalue) >>

=item C<< $class->make_accessor($name) >>

=item C<< $class->connect($dsn, @dbi_parameters) >>

=item C<< $class->connect_cached($dsn, @dbi_parameters) >>

=item C<< $class->sql >>

=item C<< $class->dbh >>

=item C<< $class->disconnect >>

=item C<< $class->new(\%row) >>

=item C<< $class->collect_new(\@row_list) >>

=item C<< $class->find(sub{ $_->filter('foo =', 'bar') }) >>

=item C<< $class->count(sub{ $_->filter('foo =', 'bar') }) >>

=item C<< $self->save >>

=item C<< $self->insert >>

=item C<< $self->update >>

=item C<< $class->reject(sub{ $_->filter('foo =', 'bar') }) >>

=item C<< $class->transaction(\&block, %after_daemon) >>

=item C<< $class->execute($sql, @bind) >>

=item C<< $class->selectrow_array($sql, @bind) >>

=back

=head1 DEPENDENCIES

L<DBI>

=head1 SEE ALSO

L<DBIx::Hakobe::Query>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
