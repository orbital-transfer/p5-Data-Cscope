use Test::More;

use_ok('Data::Cscope');

# TODO generate file for tests
my $file = "$ENV{HOME}/sw_projects/doc-experiment/test/cscope.out";
my $cs = Data::Cscope->read($file);

use DDP; p $cs->symbol_table;

done_testing;
