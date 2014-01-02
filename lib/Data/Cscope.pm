package Data::Cscope;

use strict;
use warnings;
use Carp;
use File::stat;
use Fcntl qw(SEEK_SET);
use autodie 'seek';

# from <url:cscope-15.8a/src/scanner.h#line=47>
use constant MARKER => {
	CLASSDEF	=> 'c', # class
	DEFINE		=> '#', # macro definition
	DEFINEEND	=> ')', # end of a definition
	ENUMDEF		=> 'e', # enum
	FCNCALL		=> '`', # function call
	FCNDEF		=> '$', # function definition
	FCNEND		=> '}', # end of function
	GLOBALDEF	=> 'g', # global variable
	INCLUDE		=> '~',
	MEMBERDEF	=> 'm',
	NEWFILE		=> '@', # file
	STRUCTDEF	=> 's', # struct
	TYPEDEF		=> 't',
	UNIONDEF	=> 'u',

	# not at that beginning of scanner.h
	INCLUDE         => '~',
 };

sub read {
	my ($class, $filename) = @_;
	-r $filename or croak "can not read $filename";
	bless { _filename => $filename }, $class;
}

use constant _HEADER_CSCOPE => 'cscope';
use constant _HEADER_CSCOPE_VERSION => '15';
use constant _HEADER => _HEADER_CSCOPE . ' ' . _HEADER_CSCOPE_VERSION;

sub _read_header {
	my ($self, $fh) = @_;
	my $header = <$fh>; # read in header line
	chomp $header;

	# check db format version
	my $version = substr $header, 0, length(_HEADER);
	die "header version mismatch: found $version" unless $version eq _HEADER;

	my $include_offset = 0 + (substr $header, -10);
	my $stat = stat($self->{_filename}) or die "file size could not be determined";
	die "corrupted file" unless $include_offset <= $stat->size;
	$self->{_include_offset} = $include_offset;
}

sub symbol_table {
	my ($self) = @_;
	return $self->{_symbol_table} if exists $self->{_symbol_table};
	open my $db_fh, '<', $self->{_filename} or die;
	$self->_read_header($db_fh);
	# TODO
	close $db_fh;
}

1;
# ABSTRACT: one line description TODO

=pod

=head1 SYNOPSIS

  use My::Package; # TODO

  print My::Package->new;

=head1 DESCRIPTION

TODO

=head1 CAVEATS

The cscope database format could change since, as stated in this L<blog
post|http://eli.thegreenplace.net/2010/09/28/pycscope-with-vim/>, "[the
database format of csope is] it’s not documented by design, to make sure all
tools go through cscope itself".

=head1 SEE ALSO

L<cscope|http://cscope.sourceforge.net/>

Tools that use the cscope database:
L<pycscope|https://github.com/portante/pycscope>,
L<CodeQuery|https://github.com/ruben2020/codequery>

=cut
