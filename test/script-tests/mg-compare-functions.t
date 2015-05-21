#!/usr/bin/perl -w
use strict;
use warnings;
use lib "test/script-tests/";

use Data::Dumper;
use Test::More 'no_plan';
use JSON;

# script to test
my $script = "mg-compare-functions" ;

# assumption scripts are always in path
my $topDir 			= $ENV{KB_TOP} || "/";
my $service_repo 	= "communities_api" ;
my $script_path 	= $topDir . "" ;
my $num_tests   	= 0;
my $json        	= new JSON;
my $success     	= 1;
my $test_data_path 	= shift @ARGV || join "/" , $topDir , "../dev_container/modules" , $service_repo , "test/data" ;
my $test_out_path  	= shift @ARGV || "./" ;
my $create_test_data = 1;



print STDERR "Test data path: $test_data_path\n" ;


# test if script is in path
ok (`which $script` , "$script is deployed") ;
ok (`$script --help`, "$script executes with --help") ;

# test if script can retrieve data for ids from test list 
# mg-compare-functions --ids <IDs> --source Subsystems --format biom --evalue EVALUE
# changing parameters are:
# - ids: single id from wgs test data list
# - evalue: 5 , 10 , 15






open(IDs , "$test_data_path/ids.wgs.txt") or die "No test data file $test_data_path/ids.wgs.txt\n" ;

while (my $id = <IDs>){
	chomp $id ;
	
	foreach my $verbosity ("5","10", "15") {
		ok(get_data($id,$verbosity) , "object for id $id and value $verbosity") ;
		subtest get_data => sub { get_data($id,$verbosity) } ;
	}
	
}

close(IDs);



sub get_data{
	my ($id, $value) 	= @_;
	my $success 		= undef ;
	
	# create test data
	# system("$script --ids $id --source Subsystems --format biom --evalue $value > $test_data_path/$id.$value.$script") if ($create_test_data); 
	
	# mg-compare-functions --ids <IDs> --source Subsystems --format biom --evalue <EVALUE>
	my $txt = `$script --ids $id --source Subsystems --format biom --evalue $value` ;
	
	
	# check if txt is json
	eval{
		my $o = $json->decode($txt) ;
		# print Dumper $o ;
		
		# modify $o, remove timestamps
		$o->{date} = 'test date' ;
		
		# dump into file
		open(OUT , ">$test_out_path/$id.$value.$script") or die "Can't write to $test_out_path/$id.$value.$script" ;
		print OUT $json->encode($o) ;
		close(OUT) ;
		
		# create test data
		if ($create_test_data){
			open(OUT , ">$test_data_path/$id.$value.$script") or die "Can't write to $test_data_path/$id.$value.$script" ;
			print OUT $json->encode($o) ;
			close(OUT) ;
		}
		
	};
		
	ok(!$@ , 'Valid return structure') if ($txt);
	diag($@) if ($@);
	
	
	
	# Is output as expected
	# if (`diff $test_data_path/$id.$value.$script $test_out_path/$id.$value.$script`){
	#	$success = 0; 
	# }
	# else{
	# 	$success = 1;
	# };
	
	ok(!`diff $test_data_path/$id.$value.$script $test_out_path/$id.$value.$script` , 'Output identical to precomputed data');
	

	
}
