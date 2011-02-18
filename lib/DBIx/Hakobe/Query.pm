package DBIx::Hakobe::Query;
use strict;
use warnings;
use Carp;

our $VERSION = '0.001';
# $Id$

sub select_from {
    my($class, $columns, $table) = @_;
    my $self = bless {
        statement => ['SELECT'],
        table => [$table],
        columns => $columns,
        filter => [],
        filter_value => [],
        group => [],
        having => [],
        having_value => [],
        order => [],
        limit => [],
    }, $class;
    return $self;
}

sub insert_into {
    my($class, @arg) = @_;
    my @stmt = ('INSERT');
    for my $k (qw(ROLLBACK ABORT REPLACE FAIL IGNORE)) {
        if (uc $arg[0] eq "-$k") {
            push @stmt, 'OR', $k;
            shift @arg;
            last;
        }
    }
    my $self = bless {
        statement => [@stmt],
        table => [@arg],
        column => [],
        column_expr => [],
        column_value => [],
    }, $class;
    return $self;
}

sub replace_into {
    my($class, $table) = @_;
    my $self = $class->insert_into($table);
    @{$self->{statement}} = ('REPLACE');
    return $self;    
}

sub update {
    my($class, @arg) = @_;
    my $self = $class->insert_into(@arg);
    $self->{statement}[0] = 'UPDATE';
    $self->{filter} = [];
    $self->{filter_value} = [];
    return $self;
}

sub delete_from {
    my($class, $table) = @_;
    my $self = bless {
        statement => ['DELETE'],
        table => [$table],
        filter => [],
        filter_value => [],
    }, $class;
    return $self;
}

sub distinct {
    my($self) = @_;
    push @{$self->{statement}}, 'DISTINCT';
    return $self;
}

sub filter {
    my($self, $expr, @value) = @_;
    if ($expr =~ /(?:\<[\>=]?|\>=?|=)\z/msx) {
        push @{$self->{filter}}, "$expr ?";
    }
    else {
        $expr =~ s{\?\*}{ join q{, }, (q{?}) x @value }emsx;
        push @{$self->{filter}}, $expr;
    }
    push @{$self->{filter_value}}, @value;
    return $self;
}

sub having {
    my($self, $expr, @value) = @_;
    if ($expr =~ /(?:\<[\>=]?|\>=?|=)\z/msx) {
        $self->{having}[0] = "$expr ?";
    }
    else {
        $expr =~ s{\?\*}{ join q{, }, (q{?}) x @value }emsx;
        $self->{having}[0] = $expr;
    }
    push @{$self->{having_value}}, @value;
    return $self;
}

sub group {
    my($self, $term) = @_;
    my($sign, $expr) = $term =~ /\A\s*([+-]?)(.*)\z/msx;
    my $direction = $sign eq q{-} ? 'DESC' : $sign eq q{+} ? 'ASC' : q{};
    push @{$self->{group}}, join q{ }, $expr, ($direction ? $direction : ());
    return $self;
}

sub set {       ## no critic qw(ProhibitAmbiguousNames)
    my($self, $column, @value) = @_;
    my $varb = $self->{statement}[0] || q{};
    if ($varb eq 'UPDATE') {
        if ($column =~ /\=\z/msx) {
            push @{$self->{column}}, "$column ?";
        }
        elsif ($column !~ /\=/msx) {
            push @{$self->{column}}, "$column = ?";
        }
        else {
            $column =~ s{\?\*}{ join q{, }, (q{?}) x @value }emsx;
            push @{$self->{column}}, $column;
        }
        push @{$self->{column_value}}, @value;
    }
    elsif ($varb eq 'INSERT' || $varb eq 'REPLACE') {
        push @{$self->{column}}, $column;
        if (@value && ref $value[0] eq 'ARRAY') {
            @value = @{$value[0]};
            push @{$self->{column_expr}}, shift @value;
        }
        else {
            push @{$self->{column_expr}}, (q{?}) x @value;
        }
        push @{$self->{column_value}}, @value;
    }
    return $self;
}

sub order {
    my($self, $term) = @_;
    my($sign, $expr) = $term =~ /\A\s*([+-]?)(.*)\z/msx;
    my $direction = $sign eq q{-} ? 'DESC' : $sign eq q{+} ? 'ASC' : q{};
    push @{$self->{order}}, join q{ }, $expr, ($direction ? $direction : ());
    return $self;
}

sub limit {
    my($self, %args) = @_;
    if (exists $args{-limit}) {
        $self->{limit}[0] = $args{-limit};
        if (exists $args{-offset}) {
            $self->{limit}[1] = $args{-offset};
        }
    }
    return $self;
}

sub statement {
    my($self) = @_;
    my @stmt = @{$self->{statement}};
    my @bind;
    my $varb = $stmt[0] || q{};
    if ($varb eq 'SELECT') {
        push @stmt, join q{, }, @{$self->{columns}};
    }
    if ($varb eq 'SELECT' || $varb eq 'DELETE') {
        push @stmt, 'FROM', @{$self->{table}};
    }
    if ($varb eq 'UPDATE') {
        push @stmt, @{$self->{table}}, 'SET';
        push @stmt, join q{, }, @{$self->{column}};
        push @bind, @{$self->{column_value}};
    }
    if ($varb eq 'SELECT' || $varb eq 'DELETE' || $varb eq 'UPDATE') {
        if (@{$self->{filter}}) {
            push @stmt, 'WHERE';
            my $i = -1;
            for my $expr (@{$self->{filter}}) {
                if (++$i > 0) {
                    push @stmt, 'AND';
                }
                push @stmt, $expr;
            }
            push @bind, @{$self->{filter_value}};
        }
    }
    if ($varb eq 'SELECT') {
        if (@{$self->{group}}) {
            push @stmt, 'GROUP BY';
            push @stmt, join q{, }, @{$self->{group}};
            if (@{$self->{having}}) {
                push @stmt, 'HAVING', @{$self->{having}};
                push @bind, @{$self->{having_value}};
            }
        }
        if (@{$self->{order}}) {
            push @stmt, 'ORDER BY';
            push @stmt, join q{, }, @{$self->{order}};
        }
        if (@{$self->{limit}}) {
            push @stmt, 'LIMIT', q{?};
            if (exists $self->{limit}[1]) {
                push @stmt, 'OFFSET', q{?};
            }
            push @bind, @{$self->{limit}};
        }
    }
    if ($varb eq 'INSERT' || $varb eq 'REPLACE') {
        push @stmt, 'INTO', @{$self->{table}};
        push @stmt, '(' . (join q{, }, @{$self->{column}}) . ')';
        push @stmt, 'VALUES(' . (join q{, }, @{$self->{column_expr}}) . ')';
        @bind = @{$self->{column_value}};
    }
    my $stmt = join q{ }, @stmt;
    if ($stmt !~ m{
        \A
        (?:\'[^\']*(?:\'\'[^\']*)*\'
        |  \"[\w\$.]*\"
        |  \`[\w\$.]*\`
        |  [^\'\"\`;]+
        )+
        \z
    }msx) {
        croak "Possible SQL injection attempt C<< $stmt >>.";
    }
    return ($stmt, @bind);
}

1;

__END__

=head1 NAME

DBIx::Hakobe::Query - SQL statement builder for DBIx::Hakobe.

=head1 VERSION

0.001

=head1 SYNOPSIS

    use DBIx::Hakobe::Query;
    
    $query = DBIx::Hakobe::Query->select_from(['*'], 'entry');
    $query->filter('entry_blog_id =', 1);
    $query->filter('entry_tag IN (?*)', 'lang', 'perl', 'script');
    $query->order('-posted');
    $query->limit(-limit => 5, -offset => 20);
    ($stmt, @bind) = $query->statement;
    
    $reject = DBIx::Hakobe::Query->delete_from('comment');
    $reject->filter('comment_is_spam =', 'yes');
    ($stmt, @bind) = $reject->statement;

    $update = DBIx::Hakobe::Query->update('session');
    $update->set('session_token', 'random generated base62');
    $update->set('session_token =', 'random generated base62');
    $update->set('session_token = ?', 'random generated base62');
    $update->set(q{session_expires = datetime('now', '+3 hours')});
    ($stmt, @bind) = $update->statement;

    $insert = DBIx::Hakobe::Query->insert_into('-replace', 'access_log');
    $insert->set('date', [q{datetime('now', 'localtime')}]);
    $insert->set('method', $q->request_method);
    $insert->set('remote', $q->remote_address);
    ($stmt, @bind) = $insert->statement;

=head1 DESCRIPTION

This module provides you to compose SQL statements
similar to Google App Engine Datastore Query.

=head1 METHODS

=over

=item C<< $class->select_from(\@column, $table) >>

    SELECT column FROM table ...

=item C<< $class->insert_into([$option], $table) >>

    INSERT INTO table (...) VALUES (...)
    INSERT OR ROLLBACK INTO table (...) VALUES (...)
    INSERT OR ABORT INTO table (...) VALUES (...)
    INSERT OR REPLACE INTO table (...) VALUES (...)
    INSERT OR FAIL INTO table (...) VALUES (...)
    INSERT OR IGNORE INTO table (...) VALUES (...)

=item C<< $class->replace_into($table) >>

    REPLACE INTO table (...) VALUES (...)

=item C<< $class->update([$option], $table) >>

    UPDATE table SET ... WHERE ...

option is same as insert_into.

=item C<< $class->delete_from($table) >>

    DELETE FROM table WHERE ...

=item C<< $self->distinct >>

Turns on distinct of SELECT.

    $query = $class->select_from(['*'], 'product')->distinct;

    SELECT DISTINCT column FROM table ...

=item C<< $self->filter($expr, @value) >>

WHERE part in SELECT, DELETE, and UPDATE statements.

    $query->filter('user_id = session_user_id');
    $query->filter('user_id =', 1);
    $query->filter('user_id = ?', 1);
    $query->filter('col >= func(?, ?)', 1, 2);
    $query->filter('word in (?, ?, ?, ?)', 'quick', 'brown', 'fox', 'jump');
    $query->filter('word in (?*)', 'quick', 'brown', 'fox', 'jump');
    $query->filter(q{session_expires <= datetime('now')});

=item C<< $self->group($term) >>

GROUP BY part in SELECT statements.

    $query = $class->select_from(['name', 'MAX(amount)'], 'product');
    $query->filter('country <>', 'japan');
    $query->group('-name');

    SELECT name, MAX(amount) FROM product
     WHERE country <> ?
     GROUP BY name DESC

=item C<< $self->having($expr, @value) >>

HAVING part in GROUP BY part.

    $query = $class->select_from(['name', 'SUM(amount)'], 'product');
    $query->group('name')->having('SUM(amount) >=', 50);

    SELECT name, SUM(amount) FROM product
     GROUP BY name
     HAVING SUM(amount) >= ?

=item C<< $self->order($term) >>

ORDER BY part in SELECT statements.

    $query = $class->select_from(['*'], 'entry');
    $query->filter('entry_blog_id =', 1);
    $query->order('-posted');
    $query->order('+entry_id');

    SELECT * FROM entry
     WHERE entry_blog_id = ?
     ORDER BY posted DESC, entry_id ASC

=item C<< $self->limit >>

LIMIT part in SELECT statements.

    $query = $class->select_from(['*'], 'entry');
    $query->filter('entry_blog_id =', 1);
    $query->order('-posted');
    $query->limit(-limit => 5, -offset => 20);

    SELECT * FROM entry
     WHERE entry_blog_id = ?
     ORDER BY posted DESC
     LIMIT ? OFFSET ?

=item C<< $self->set >>

SET section in UPDATE statements.

    $update = $class->update('session');
    $update->set('session_token', 'random generated base62');
    $update->set('session_token =', 'random generated base62');
    $update->set('session_token = ?', 'random generated base62');
    $update->set(q{session_expires = datetime('now', '+3 hours')});

    UPDATE session
       SET session_token = ?
          ,session_token = ?
          ,session_token = ?
          ,session_expires = datetime('now', '+3 hours')

VALUES section in INSERT or REPLACE statements.

    $insert = $class->insert_into('access_log');
    $insert->set('date', [q{datetime('now', 'localtime')}]);
    $insert->set('author', [':user', 'bob']);
    $insert->set('method', $q->request_method);
    $insert->set('remote', $q->remote_address);
    
    INSERT INTO access_log(date, method, remote)
         VALUES(datetime('now', 'localtime'), ?, ?)

=item C<< ($sql, @bind) = $self->statement >>

Composes SQL statement and its bind values.

=back

=head1 DEPENDENCIES

=head1 SEE ALSO

L<DBIx::Hakobe>
L<SQL::Abstract>
L<http://code.google.com/intl/en/appengine/docs/python/datastore/queryclass.html>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
