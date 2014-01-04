package Data::Cscope;

use strict;
use warnings;
use Carp;
use File::stat;
use Fcntl qw(SEEK_SET);
use IPC::Open2;
use autodie 'seek';
use Const::Fast;
use File::chdir;
use Path::Class;

const our $_CSCOPE_QUERY_MIN         => 0;
const our $CSCOPE_QUERY_SYMBOL       => 0; # Find this C symbol
const our $CSCOPE_QUERY_GLOBAL_DEF   => 1; # Find this global definition:
const our $CSCOPE_QUERY_FUNC_CALLED  => 2; # Find functions called by this function:
const our $CSCOPE_QUERY_FUNC_CALLING => 3; # Find functions calling this function:
const our $CSCOPE_QUERY_TEXT         => 4; # Find this text string:

# not supported
const our $_CSCOPE_QUERY_CHANGE_TEXT => 5; # Change this text string:

const our $CSCOPE_QUERY_EGREP        => 6; # Find this egrep pattern:
const our $CSCOPE_QUERY_FILE         => 7; # Find this file:
const our $CSCOPE_QUERY_INCLUDE      => 8; # Find files #including this file:
const our $CSCOPE_QUERY_ASSIGNMENT   => 9; # Find assignments to this symbol:
const our $_CSCOPE_QUERY_MAX         => 9;

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


=method read($options)

options:

=over 2

=item  file (required)

       a string with the path to the cross-ref file (e.g. C<cscope.out>)

=item  cscope_program (optional, default: C<cscope>)

     a string with the name of the cscope executable

=back

=cut
sub read {
	my ($class, %args) = @_;
	my $cscope_db = $args{cscope_db} or croak "cscope_db parameter is required";
	my $source = $args{source} or croak "source parameter is required";
	$cscope_db = file($cscope_db);
	my $cscope = $args{cscope_program} // 'cscope';

	#-r $filename or croak "can not read $cscope_db";

	my ($in, $out);
	my @dir = map { ('-s', $_) } @$source;
	my @args = ($cscope, '-R', '-l', '-f', $cscope_db, @dir);
	print "@args\n";
	my $pid;
	{
		local $CWD = $cscope_db->dir;
		$pid = open2($out, $in, @args);
	}

	bless {
		_cscope_db => $cscope_db,
		_source => $source,
		_pid => $pid,
		_in => $in,
		_out => $out,
	}, $class;
}

sub DESTROY {
	# TODO
	# quit cscope program
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
	my $stat = stat($self->{_cscope_db}) or die "file size could not be determined";
	die "corrupted file" unless $include_offset <= $stat->size;
	$self->{_include_offset} = $include_offset;
}

sub symbol_table {
	my ($self) = @_;
	return $self->{_symbol_table} if exists $self->{_symbol_table};
	open my $db_fh, '<', $self->{_cscope_db} or die;
	$self->_read_header($db_fh);
	# TODO
	close $db_fh;
	{};
}


# TODO map the queries to constants
sub query {
	my ($self, %args) = @_;
	my $query_type = $args{type};
	my $query = $args{query};
	my $ignore_case = $args{ignore_case}; # TODO keep case state
	die "invalid query" if $query_type < $_CSCOPE_QUERY_MIN || $query_type > $_CSCOPE_QUERY_MAX;
	die "change text query not supported" if $query_type == $_CSCOPE_QUERY_CHANGE_TEXT;

	my $h = $self->{_harness};
	my $in = $self->{_in};
	print $in "$query_type$query\n";
	my $out = $self->{_out};
	my $info  = <$out>;
	my $lines = ($info =~ /cscope: (\d+) lines/)[0];
	my $data;
	$data .= <$out> for 1..$lines;
	$data;
}

1;
# ABSTRACT: one line description TODO
__END__

=pod

=head1 SYNOPSIS

  use My::Package; # TODO

  print My::Package->new;

=head1 DESCRIPTION

TODO

=head1 CAVEATS

The cscope database format could change since, as stated in this L<blog
post|http://eli.thegreenplace.net/2010/09/28/pycscope-with-vim/>, "[the
database format of csope is] it's not documented by design, to make sure all
tools go through cscope itself".

=head1 SEE ALSO

L<cscope|http://cscope.sourceforge.net/>

Tools that use the cscope database:
L<pycscope|https://github.com/portante/pycscope>,
L<CodeQuery|https://github.com/ruben2020/codequery>

=cut
