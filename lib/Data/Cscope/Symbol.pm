package Data::Cscope::Symbol;

use strict;
use warnings;

sub _new {
	my $class = shift;
	# TODO actually read in parameters
	bless { @_ }, $class;
}

1;
