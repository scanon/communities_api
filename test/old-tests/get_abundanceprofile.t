#!/usr/bin/perl -w
use strict;
use lib "test/script-tests/";

use Data::Dumper;
use Test::More 'no_plan';
use JSON;

my $num_tests = 0;
my @test_ids = ();
my $json = new JSON;

@test_ids = test_metagenome_query();
$num_tests += test_abundanceprofile_instance(@test_ids);

isnt($num_tests,0,"Number of tests is greater than zero");

sub test_metagenome_query {
    my $num_tests = 0;
    my $test_name = "get_metagenome_query";

	my $cmd;
	my $return = '';
	my $decode = '';
	my @test_ids = ();

	#######################################################################
	# happy path tests
	# ----------------
	# 1. verbosity = minimal, order = id, limit = 10, offset = 0
	$cmd = "$test_name -verbosity='minimal' -limit=5 ";

	note ("Get a set of metagenome IDs to test");	
	eval { $return = `$cmd`; };
	is($@, '', "Calling \"$cmd\" ");

	eval { $decode = $json->decode($return); };
	is($@, '', "JSON return \"$cmd\" ");
	is(ref($decode),'HASH',"Was the return in JSON?");

	my $data = %$decode->{'data'};
	foreach my $key (@$data)
	{
		push(@test_ids, %$key->{'id'} );
	}	
	print "TESTIDs=@test_ids \n";
   return @test_ids;
}

sub test_abundanceprofile_instance {
	my @test_ids = @_;
    my $num_tests = 0;
    my $test_name = "get_abundanceprofile_instance";
	my @verbosities = ( 'minimal', 'verbose', 'full' );
	my $cmd;

	###########################################################################
	# Happy path tests
	# ----------------
	# loop through every verbosity with a single id and make sure they're good.
	foreach my $verbosity (@verbosities) {
		foreach my $test_id (@test_ids)
		{
			$cmd = "$test_name -verbosity=$verbosity -id=$test_id";
			$num_tests += &test_response($cmd);
		}	
	}

	###########################################################################
	# Invalid param tests
	# -------------------
	# 1. No id
	$cmd = "$test_name -verbosity='minimal'";
	$num_tests += &bad_response($cmd);	

	# 2. Invalid verbosity
	$cmd = "$test_name -id=$test_ids[0] -verbosity='blah'";
	$num_tests += &bad_response($cmd);	

    return $num_tests;
}

#--------------------------------------------------------------------------
#  Check that the command line returns without error
#  Did the response parse into JSON?

sub test_response
{
	my ($cmd) = @_;

	my $return = '';
	my $decode = '';
	eval { $return = `$cmd`; };
	is($@, '', "Calling \"$cmd\" ");

	eval { $decode = $json->decode($return); };
	is($@, '', "JSON return \"$cmd\" ");

	if ($@)
	{
		print Dumper($decode);
	}
	is(ref($decode),'HASH',"Was the return in JSON?");

	return (3);
}


#--------------------------------------------------------------------------
#  Check that the command line returns with an error
#  1. The return code empty
#  2. The return is in JSON
#  3. The return contains the word error 

sub bad_response
{
	my ($cmd) = @_;

	my $return = '';
	my $error  = '';
	my $decode = '';

	eval { $return = `$cmd`; };
	is($@, '', "Bad Parameters \"$cmd\" ");

	eval { $decode = $json->decode($return); };
	is($@, '', "JSON return \"$cmd\" ");

	$error = $return if ($return =~ /error/i);
	isnt($error, '', "Return had the word error ");
#	print "DEBUG: RETURN=$return\n" if (length($return) < 5000);

	return (3);
}
