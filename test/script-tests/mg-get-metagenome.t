#!/usr/bin/perl -w
use strict;
use warnings;
use lib "test/script-tests/";

use Data::Dumper;
use Test::More 'no_plan';
use JSON;

# script to test
my $script = "mg-get-metagenome" ;

# assumption scripts are always in path
my $topDir 			= $ENV{KB_TOP} || "/";
my $service_repo 	= "communities_api" ;
my $script_path 	= $topDir . "" ;
my $num_tests   	= 0;
my $json        	= new JSON;
my $success     	= 1;
my $test_data_path 	= shift @ARGV || join "/" , $topDir , "../dev_container/modules" , $service_repo , "test/data" ;
my $test_out_path  	= shift @ARGV || "./" ;
my $create_test_data = 0;

#my $test_path = "/Users/Andi/Development/kbase/communities_api/scripts" ;

print STDERR "Test data path: $test_data_path\n" ;


# test if script is in path
ok (`which $script` , "$script is deployed") ;
ok (`$script --help`, "$script executes with --help") ;

# test if script can retrieve data for ids from test list 
# changing parameters are:
# - verbosity : ["minimal", "mixs",  "metadata",  "stats",  "full"]




open(IDs , "$test_data_path/ids.wgs.txt") or die "No test data file $test_data_path/ids.wgs.txt\n" ;

while (my $id = <IDs>){
	chomp $id ;
	
	foreach my $verbosity ("minimal", "mixs",  "metadata",  "stats",  "full") {
		ok(get_data($id,$verbosity) , "object for id $id and value $verbosity") ;
		subtest get_data => sub { get_data($id,$verbosity) } ;
	}
	
}

close(IDs);



sub get_data{
	my ($id, $value) 	= @_;
	my $success 		= undef ;
	
	# create test data
	system("$script --id $id --verbosity $value > $test_data_path/$id.$value.$script") if ($create_test_data); 
	
	system("$script --id $id --verbosity $value > $test_out_path/$id.$value.$script") ;
	
	open(FILE , "$test_out_path/$id.$value.$script") ;
	my $txt = <FILE> ;
	
	
	# check if txt is json
	eval{
		my $o = $json->decode($txt) ;
		# print Dumper $o ;
	};
	
	if ($@) {
		$success = 0;
		diag($@);
	}
	else{
		$success = 1;
	}
	
	ok(!$@ , 'Valid return structure') ;
	
	# Is output as expected
	if (`diff $test_data_path/$id.$value.$script $test_out_path/$id.$value.$script`){
		$success = 0; 
	}
	else{
		$success = 1;
	};
	
	ok(!`diff $test_data_path/$id.$value.$script $test_out_path/$id.$value.$script` , 'Output identical to precomputed data');
	
	close(FILE);
	
	return $success;
}
