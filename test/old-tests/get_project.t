#!/usr/bin/perl -w
use strict;
use lib "test/script-tests/";

use Data::Dumper;
use Test::More 'no_plan';
use JSON;

my $num_tests = 0;
my $json = new JSON;

$num_tests += test_project_query();
$num_tests += test_project_instance();


sub test_project_query {
    my $num_tests = 0;
    my $test_name = "get_project_query";

	my $cmd;

	#######################################################################
	# happy path tests
	# ----------------
	# 1. verbosity = minimal, order = id, limit = 10, offset = 0
	$cmd = "$test_name -verbosity='minimal' -order='id' -limit=10 -offset=0 ";
	$num_tests += &test_response($cmd);	

	# 2. Let order = "name"
	$cmd = "$test_name -verbosity='minimal' -order='name' -limit=10 -offset=0 ";
	$num_tests += &test_response($cmd);	

	# 3. Let verbosity = default
	$cmd = "$test_name  -order='id' -limit=10 -offset=0 ";
	$num_tests += &test_response($cmd);	

	# 4. Let order = default
	$cmd = "$test_name  -verbosity='minimal' -limit=10 -offset=0 ";
	$num_tests += &test_response($cmd);	

	# 5. Let limit be default
	$cmd = "$test_name  -verbosity='minimal' -order='id' -offset=0 ";
	$num_tests += &test_response($cmd);	

	# 6. Let offset be default
	$cmd = "$test_name  -verbosity='minimal' -order='id' -limit=10 ";
	$num_tests += &test_response($cmd);	

	# 7. Let offset be nonzero
	$cmd = "$test_name  -verbosity='minimal' -order='id' -limit=10 -offset=10 ";
	$num_tests += &test_response($cmd);	

	# 8.  with empty parameters returns a method description object 
	$cmd = "$test_name   ";
	$num_tests += &test_response($cmd);	

	# 9. Verbosity=full
	$cmd = "$test_name  -verbosity='full' -limit=10 -offset=0 ";
	$num_tests += &test_response($cmd);	

	# 11. Verbosity=verbose
	$cmd = "$test_name  -verbosity='verbose' -limit=10 -offset=0 ";
	$num_tests += &test_response($cmd);	

	#######################################################################
	# invalid parameter tests - should fail nicely
	# --------------------------------------------
	# 1. verbosity = blah
	$cmd = "$test_name  -verbosity='blah' -order='id' -limit=10 -offset=10 ";
	$num_tests += &bad_response($cmd);	

	# 2. order = blah
	$cmd = "$test_name  -verbosity='minimal' -order='blah' -limit=10 -offset=10 ";
	$num_tests += &bad_response($cmd);	

	# 3. limit = blah
	$cmd = "$test_name  -verbosity='minimal' -limit='blah' -offset=10 ";
	$num_tests += &bad_response($cmd);	

	# 4. offset = blah
	$cmd = "$test_name  -verbosity='minimal' -limit=10 -offset='blah' ";
	$num_tests += &bad_response($cmd);	

   return $num_tests;
}

sub test_project_instance {
    my $num_tests = 0;
    my $test_name = "get_project_instance";
	my $test_id = "mgp7";
	my @verbosities = ( 'minimal', 'verbose', 'full' );

	my $cmd;

	###########################################################################
	# Happy path tests
	# ----------------

	# with no parameters returns a method description object
	$cmd = "$test_name ";
	$num_tests += &test_response($cmd);	

	###########################################################################
	# Happy path tests
	# ----------------
	# loop through every verbosity with a single id and make sure they're good.
	foreach my $verbosity (@verbosities) {
		$cmd = "$test_name -verbosity=$verbosity -id=$test_id";
		$num_tests += &test_response($cmd);
	}

	###########################################################################
	# Invalid param tests
	# -------------------
	# 1. No id
	$cmd = "$test_name -verbosity='minimal'";
	$num_tests += &bad_response($cmd);	

	# 2. Invalid verbosity
	$cmd = "$test_name -id=$test_id -verbosity='blah'";
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
#	is(ref($decode),'HASH',"Was the return in JSON?");

	return (2);
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
