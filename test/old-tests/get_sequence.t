#!/usr/bin/perl -w
use strict;
use lib "test/script-tests/";

use Data::Dumper;
use Test::More 'no_plan';
use JSON;

my $num_tests = 0;
my $json = new JSON;

$num_tests += test_sample_query();
$num_tests += test_sample_instance();


sub test_sample_query {
    my $num_tests = 0;
    my $test_name = "get_sequenceset_instance";
    my $test_id = "mgm4440286.3";
    my $invalid_id = "4440286.3mgm";


	my $cmd;

	#######################################################################
	# happy path tests
	# ----------------
	# 1. order = id, limit = 10, offset = 0
	$cmd = "$test_name -id=$test_id ";
	$num_tests += &test_response($cmd);	


#    # happy test (really only one - one parameter, right?)
#    eval{ $result = $client->$test_name($params); };
#	is($@, '', "Calling '$test_name' with id='$test_id' passed successfully.");
#	$num_tests++;
#	if ($result) {
#		$num_tests += test_result($result, \%attributes, $params);
#	}

	# unhappy test (no id)
	$cmd = "$test_name  ";
	$num_tests += &bad_response($cmd);	
#   eval{ $result = $client->$test_name({}); };
#  $error = $@;
#	ok(!$error, "Calling '$test_name' with no id returns something valid.");
#	$num_tests++;
#	if (!$error) {
#		note "Checking if calling '$test_name' with no parameters returns a method description object";
#		$num_tests += test_method_description($result);
#	} else {
#		note "Found an error instead!";
#		test_error_value($error, "Bio::KBase::Exceptions::JSONRPC", 400, qr/invalid/i);
#	}


	# unhappy test (invalid id)
	$cmd = "$test_name -id=$invalid_id ";
	$num_tests += &bad_response($cmd);	
 #   eval{ $result = $client->$test_name({ id => 'invalid_id' }); };
#	ok($error, "Calling '$test_name' with an invalid id failed properly.");
#	$num_tests++;
#	if ($error) {
#		$num_tests += test_error_value($error, "Bio::KBase::Exceptions::JSONRPC");
#	}

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
