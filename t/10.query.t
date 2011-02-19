use strict;
use warnings;
use Test::Base;
use DBIx::Hakobe::Query;

plan tests => 1 * blocks;

filters {
    'method' => [qw(chomp)],
    'args' => [qw(eval)],
    'decorates' => [qw(eval)],
    'stmt' => [qw(eval)],
    'binds' => [qw(eval)],
};

run {
    my($block) = @_;
    my $method = $block->method;
    my $args = $block->args;
    my $query = DBIx::Hakobe::Query->$method(@{$args});
    for ($query) {
        $block->decorates->($query);
    }
    my($stmt, @binds) = $query->statement;

    is_deeply
        [$block->stmt, @{$block->binds}],
        [$query->statement],
        $block->name;
};

__END__

=== select_from column x 1
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{}
--- stmt
'SELECT * FROM test'
--- binds
[]

=== select_from distinct column x 1
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->distinct;
}
--- stmt
'SELECT DISTINCT * FROM test'
--- binds
[]

=== select_from column x 3
--- method
select_from
--- args
[[qw(one two three)], 'test']
--- decorates
sub{}
--- stmt
'SELECT one, two, three FROM test'
--- binds
[]

=== select_from JOIN
--- method
select_from
--- args
[['*'], 'test1 JOIN test2']
--- decorates
sub{
    $_->filter('test1.a =', 5);
    $_->filter('test2.a <', 6);
}
--- stmt
'SELECT * FROM test1 JOIN test2 WHERE test1.a = ? AND test2.a < ?'
--- binds
[5, 6]

=== select_from filter x 1
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a =', 0);
}
--- stmt
'SELECT * FROM test WHERE a = ?'
--- binds
[0]

=== select_from filter x 2
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a =', 5);
    $_->filter('b =', 6);
}
--- stmt
'SELECT * FROM test WHERE a = ? AND b = ?'
--- binds
[5, 6]

=== select_from filter x 6
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a =', 5);
    $_->filter('b <>', 6);
    $_->filter('c <', 7);
    $_->filter('d <=', 8);
    $_->filter('e >', 9);
    $_->filter('f >=', 10);
}
--- stmt
'SELECT * FROM test WHERE a = ? AND b <> ? AND c < ? AND d <= ? AND e > ? AND f >= ?'
--- binds
[5, 6, 7, 8, 9, 10]

=== select_from filter x 6 manually
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a = ?', 5);
    $_->filter('b <> ?', 6);
    $_->filter('c < ?', 7);
    $_->filter('d <= ?', 8);
    $_->filter('e > ?', 9);
    $_->filter('f >= ?', 10);
}
--- stmt
'SELECT * FROM test WHERE a = ? AND b <> ? AND c < ? AND d <= ? AND e > ? AND f >= ?'
--- binds
[5, 6, 7, 8, 9, 10]

=== select_from filter x 6 - bind
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a = 5');
    $_->filter('b <> 6');
    $_->filter('c < 7');
    $_->filter('d <= 8');
    $_->filter('e > 9');
    $_->filter('f >= 10');
}
--- stmt
'SELECT * FROM test WHERE a = 5 AND b <> 6 AND c < 7 AND d <= 8 AND e > 9 AND f >= 10'
--- binds
[]

=== select_from filter ^ 2 (OR)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a = ? OR b = ?', 5, 6);
}
--- stmt
'SELECT * FROM test WHERE a = ? OR b = ?'
--- binds
[5, 6]

=== select_from filter ^ 2 (BETWEEN)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a BETWEEN ? AND ?', 5, 6);
}
--- stmt
'SELECT * FROM test WHERE a BETWEEN ? AND ?'
--- binds
[5, 6]

=== select_from filter ^ 2 (IN)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a IN (?, ?)', 5, 6);
}
--- stmt
'SELECT * FROM test WHERE a IN (?, ?)'
--- binds
[5, 6]

=== select_from filter ^ 4 (IN)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a IN (?, ?, ?, ?)', 5, 8, 13, 21);
}
--- stmt
'SELECT * FROM test WHERE a IN (?, ?, ?, ?)'
--- binds
[5, 8, 13, 21]

=== select_from filter ^ * (IN)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a IN (?*)', 5, 8, 13, 21);
}
--- stmt
'SELECT * FROM test WHERE a IN (?, ?, ?, ?)'
--- binds
[5, 8, 13, 21]

=== select_from filter x 1 (<>)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a <>', 'boom');
}
--- stmt
'SELECT * FROM test WHERE a <> ?'
--- binds
['boom']

=== select_from filter x 2 (IS NULL)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a IS NULL');
    $_->filter('b =', 'B');    
}
--- stmt
'SELECT * FROM test WHERE a IS NULL AND b = ?'
--- binds
['B']

=== select_from filter x 3 (IS NULL)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a IS NULL');
    $_->filter('b = ?', 'B');    
    $_->filter('c <>', 'D');    
}
--- stmt
'SELECT * FROM test WHERE a IS NULL AND b = ? AND c <> ?'
--- binds
['B', 'D']

=== select_from filter x 1 (date)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter(q{a = date(?, '-1 days')}, '2011-02-17');
}
--- stmt
q{SELECT * FROM test WHERE a = date(?, '-1 days')}
--- binds
['2011-02-17']

=== select_from filter x 1 (LIKE)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a LIKE ?', '2011-02%');
}
--- stmt
'SELECT * FROM test WHERE a LIKE ?'
--- binds
['2011-02%']

=== select_from filter x 2 (>, =)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a > 1 + 1');
    $_->filter('b =', 8);
}
--- stmt
'SELECT * FROM test WHERE a > 1 + 1 AND b = ?'
--- binds
[8]

=== select_from filter x 1 (function)
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('y = MAX(LENGTH(MIN(?)))', 'x');
}
--- stmt
'SELECT * FROM test WHERE y = MAX(LENGTH(MIN(?)))'
--- binds
['x']

=== select_from group
--- method
select_from
--- args
[['name', 'MAX(amount)'], 'test']
--- decorates
sub{
    $_->filter('country <>', 'japan');
    $_->group('name');
}
--- stmt
'SELECT name, MAX(amount) FROM test WHERE country <> ? GROUP BY name'
--- binds
['japan']

=== select_from group-
--- method
select_from
--- args
[['name', 'MAX(amount)'], 'test']
--- decorates
sub{
    $_->filter('country <>', 'japan');
    $_->group('-name');
}
--- stmt
'SELECT name, MAX(amount) FROM test WHERE country <> ? GROUP BY name DESC'
--- binds
['japan']

=== select_from group having
--- method
select_from
--- args
[['name', 'SUM(amount)'], 'test']
--- decorates
sub{
    $_->group('name')->having('SUM(amount) >=', 50);
}
--- stmt
'SELECT name, SUM(amount) FROM test GROUP BY name HAVING SUM(amount) >= ?'
--- binds
[50]

=== select_from order x 1
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->order('id');
}
--- stmt
'SELECT * FROM test ORDER BY id'
--- binds
[]

=== select_from order+ x 1
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->order('+id');
}
--- stmt
'SELECT * FROM test ORDER BY id ASC'
--- binds
[]

=== select_from order- x 1
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->order('-id');
}
--- stmt
'SELECT * FROM test ORDER BY id DESC'
--- binds
[]

=== select_from order x 3
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->filter('a =', 0);
    $_->order('boom');
    $_->order('-bada');
    $_->order('bing');
}
--- stmt
'SELECT * FROM test WHERE a = ? ORDER BY boom, bada DESC, bing'
--- binds
[0]

=== select_from limit
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->limit(-limit => 10);
}
--- stmt
'SELECT * FROM test LIMIT ?'
--- binds
[10]

=== select_from limit offset
--- method
select_from
--- args
[['*'], 'test']
--- decorates
sub{
    $_->limit(-limit => 10, -offset => 5);
}
--- stmt
'SELECT * FROM test LIMIT ? OFFSET ?'
--- binds
[10, 5]

=== insert
--- method
insert_into
--- args
['test']
--- decorates
sub{
    $_->set('a', 'a0');
}
--- stmt
'INSERT INTO test (a) VALUES(?)'
--- binds
['a0']

=== insert_into set x 1
--- method
insert_into
--- args
['test']
--- decorates
sub{
    $_->set('a', 1);
}
--- stmt
'INSERT INTO test (a) VALUES(?)'
--- binds
[1]

=== insert_into -replace set x 1
--- method
insert_into
--- args
['-replace', 'test']
--- decorates
sub{
    $_->set('a', 1);
}
--- stmt
'INSERT OR REPLACE INTO test (a) VALUES(?)'
--- binds
[1]

=== insert_into -abort set x 1
--- method
insert_into
--- args
['-abort', 'test']
--- decorates
sub{
    $_->set('a', 1);
}
--- stmt
'INSERT OR ABORT INTO test (a) VALUES(?)'
--- binds
[1]

=== insert_into -fail set x 1
--- method
insert_into
--- args
['-fail', 'test']
--- decorates
sub{
    $_->set('a', 1);
}
--- stmt
'INSERT OR FAIL INTO test (a) VALUES(?)'
--- binds
[1]

=== insert_into -rollback set x 1
--- method
insert_into
--- args
['-rollback', 'test']
--- decorates
sub{
    $_->set('a', 1);
}
--- stmt
'INSERT OR ROLLBACK INTO test (a) VALUES(?)'
--- binds
[1]

=== insert_into -ignore set x 1
--- method
insert_into
--- args
['-ignore', 'test']
--- decorates
sub{
    $_->set('a', 1);
}
--- stmt
'INSERT OR IGNORE INTO test (a) VALUES(?)'
--- binds
[1]

=== insert_into set x 5
--- method
insert_into
--- args
['test']
--- decorates
sub{
    $_->set('a', 1);
    $_->set('b', 2);
    $_->set('c', 3);
    $_->set('d', 4);
    $_->set('e', 5);
}
--- stmt
'INSERT INTO test (a, b, c, d, e) VALUES(?, ?, ?, ?, ?)'
--- binds
[1, 2, 3, 4, 5]

=== insert_into set x 5 - bind x 3
--- method
insert_into
--- args
['test']
--- decorates
sub{
    $_->set('a', [1]);
    $_->set('b', 2);
    $_->set('c', ['(SELECT COUNT(*) FROM foo)']);
    $_->set('d', [4]);
    $_->set('e', 5);
}
--- stmt
'INSERT INTO test (a, b, c, d, e) VALUES(1, ?, (SELECT COUNT(*) FROM foo), 4, ?)'
--- binds
[2, 5]

=== insert_into -replace set x 3 (named parameter)
--- method
insert_into
--- args
['-replace', 'bayes']
--- decorates
sub{
    $_->set('word', [':w', 'quick']);
    $_->set('category', [':c', 'good']);
    $_->set('count', [
        'ifnull((SELECT count FROM bayes WHERE word = :w AND category = :c),0)+1'
    ]);
}
--- stmt
'INSERT OR REPLACE INTO bayes (word, category, count) VALUES(:w, :c, ifnull((SELECT count FROM bayes WHERE word = :w AND category = :c),0)+1)'
--- binds
['quick', 'good']

=== insert_into set x 2 - bind x 1
--- method
insert_into
--- args
['test.table']
--- decorates
sub{
    $_->set('high_limit', ['MAX(all_limits)']);
    $_->set('low_limit', 4);
}
--- stmt
'INSERT INTO test.table (high_limit, low_limit) VALUES(MAX(all_limits), ?)'
--- binds
[4]

=== replace_into set x 5
--- method
replace_into
--- args
['test']
--- decorates
sub{
    $_->set('a', 1);
    $_->set('b', 2);
    $_->set('c', 3);
    $_->set('d', 4);
    $_->set('e', 5);
}
--- stmt
'REPLACE INTO test (a, b, c, d, e) VALUES(?, ?, ?, ?, ?)'
--- binds
[1, 2, 3, 4, 5]

=== replace_into set x 5 - bind x 3
--- method
replace_into
--- args
['test']
--- decorates
sub{
    $_->set('a', [1]);
    $_->set('b', 2);
    $_->set('c', ['(SELECT COUNT(*) FROM foo)']);
    $_->set('d', [4]);
    $_->set('e', 5);
}
--- stmt
'REPLACE INTO test (a, b, c, d, e) VALUES(1, ?, (SELECT COUNT(*) FROM foo), 4, ?)'
--- binds
[2, 5]

=== replace_into set x 3 (named parameter)
--- method
replace_into
--- args
['bayes']
--- decorates
sub{
    $_->set('word', [':w', 'quick']);
    $_->set('category', [':c', 'good']);
    $_->set('count', [
        'ifnull((SELECT count FROM bayes WHERE word = :w AND category = :c),0)+1'
    ]);
}
--- stmt
'REPLACE INTO bayes (word, category, count) VALUES(:w, :c, ifnull((SELECT count FROM bayes WHERE word = :w AND category = :c),0)+1)'
--- binds
['quick', 'good']

=== replace_into set x 2 - bind x 1
--- method
replace_into
--- args
['test.table']
--- decorates
sub{
    $_->set('high_limit', ['MAX(all_limits)']);
    $_->set('low_limit', 4);
}
--- stmt
'REPLACE INTO test.table (high_limit, low_limit) VALUES(MAX(all_limits), ?)'
--- binds
[4]

=== update set x 1
--- method
update
--- args
['test']
--- decorates
sub{
    $_->set('a =', 1);
}
--- stmt
'UPDATE test SET a = ?'
--- binds
[1]

=== update set x 1 (key => value)
--- method
update
--- args
['test']
--- decorates
sub{
    $_->set('a', 1);
}
--- stmt
'UPDATE test SET a = ?'
--- binds
[1]

=== update set x 1 (expr)
--- method
update
--- args
['test']
--- decorates
sub{
    $_->set('a = 1');
}
--- stmt
'UPDATE test SET a = 1'
--- binds
[]

=== update set ^ 3 (expr parameters)
--- method
update
--- args
['test']
--- decorates
sub{
    $_->set('a = func(?, ?, ?)', 1, 2, 3);
}
--- stmt
'UPDATE test SET a = func(?, ?, ?)'
--- binds
[1, 2, 3]

=== update set ^ * (expr parameters)
--- method
update
--- args
['test']
--- decorates
sub{
    $_->set('a = func(?*)', 1, 2, 3);
}
--- stmt
'UPDATE test SET a = func(?, ?, ?)'
--- binds
[1, 2, 3]

=== update set x 5
--- method
update
--- args
['test']
--- decorates
sub{
    $_->set('a', 1);
    $_->set('b', 2);
    $_->set('c', 3);
    $_->set('d', 4);
    $_->set('e', 5);
}
--- stmt
'UPDATE test SET a = ?, b = ?, c = ?, d = ?, e = ?'
--- binds
[1, 2, 3, 4, 5]

=== update set x 3 + filter x 2
--- method
update
--- args
['test']
--- decorates
sub{
    $_->set('a', 1);
    $_->set('b', 2);
    $_->set('c', 3);
    $_->filter('d =', 4);
    $_->filter('e =', 5);
}
--- stmt
'UPDATE test SET a = ?, b = ?, c = ? WHERE d = ? AND e = ?'
--- binds
[1, 2, 3, 4, 5]

=== delete_from
--- method
delete_from
--- args
['test']
--- decorates
sub{}
--- stmt
'DELETE FROM test'
--- binds
[]

=== delete_from filter
--- method
delete_from
--- args
['test']
--- decorates
sub{
    $_->filter('a =', 1)
}
--- stmt
'DELETE FROM test WHERE a = ?'
--- binds
[1]

=== delete_from filter(expr)
--- method
delete_from
--- args
['test']
--- decorates
sub{
    $_->filter('requester IS NULL')
}
--- stmt
'DELETE FROM test WHERE requester IS NULL'
--- binds
[]

