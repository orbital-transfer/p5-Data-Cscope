use Test::More;

use_ok('Data::Cscope');

# TODO generate file for tests
my $file = "$ENV{HOME}/sw_projects/doc-experiment/test/cscope.out";
my $source = ["$ENV{HOME}/sw_projects/p5-Image-Leptonica/leptonica-1.69/src"];

my $cs = Data::Cscope->read( cscope_db => $file, source => $source );

my $data = $cs->query(query => 'fmorph.*', type => $Data::Cscope::CSCOPE_QUERY_SYMBOL );
use DDP; p $data;
#$data1 = $cs->query(query => 'pix.*', type => $Data::Cscope::CSCOPE_QUERY_SYMBOL );
#use DDP; p $data1;

done_testing;
