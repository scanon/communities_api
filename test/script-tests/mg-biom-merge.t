#!/usr/bin/perl -w
use strict;
use warnings;
use lib "test/script-tests/";

use Data::Dumper;
use Test::More 'no_plan';
use JSON;

# script to test
my $script = "mg-biom-merge" ;

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
my $debug            = 0;


# test if script is in path
ok (`which $script` , "$script is deployed") ;
ok (`$script --help`, "$script executes with --help") ;

# test if script can retrieve data for ids from test list 
# mg-compare-functions --ids <IDs> --source Subsystems --format biom --evalue EVALUE
# changing parameters are:
# - ids: single id from wgs test data list
# - evalue: 5 , 10 , 15




# list of all ids
my @list ;
open(IDs , "$test_data_path/ids.wgs.txt") or die "No test data file $test_data_path/ids.wgs.txt\n" ;

while (my $id = <IDs>){
	chomp $id ;
	push @list , $id ;
}

close(IDs);

# loop throug list and create triples

while ( @list >= 3){
	
	# create triple, slide through id list
	my @triple = (shift @list , $list[0] , $list[1]) ;
	
	# not used yet
	my $source = "Subsystems" ;
	
	# loop through existing profiles/parameters, retrieve profiles and merge them
	foreach my $evalue ("5","10") {
	    # ok(get_data(\@triple,$evalue,$source) , "object for id ". join(" " , @triple ) ." and value $evalue") ;
	    diag("Testing parameter id ". join(" " , @triple ) ." and value $evalue");
	    subtest get_data => sub { get_data(\@triple,$evalue) } ;
	}
	
}

close(IDs);



sub get_data{
	my ($ids, $value) 	= @_;
	my $success 		= undef ;
	
	# create test data
	# system("$script --ids $id --source Subsystems --format biom --evalue $value > $test_data_path/$id.$value.$script") if ($create_test_data); 
	
	
	
	
	#  mg-biom-merge [ --help --retain_dup_ids ] biom1 biom2 [ biom3 biom4 ... ]

	my @tmp ;
	foreach my $i (@$ids){
		
		if($create_test_data){
		    system("$script --ids $i --source Subsystems --format biom --evalue $value > $test_data_path/$i.$value.mg-compare-functions") unless (-f "$test_data_path/$i.$value.mg-compare-functions");
		}
		
		push @tmp , "$test_data_path/$i.$value.mg-compare-functions" if (-f "$test_data_path/$i.$value.mg-compare-functions");
	}
	my $list   = join " " , @tmp ;
	my $prefix = join "-" , @$ids ;
	
	
	#skip test if not enough data availbale for given parameter set
   	if (@tmp < 3){
		diag("Skipping test");
		diag("Files:" , @tmp);
		return 1;
	}
        
     
	
	my $txt = `$script $list` ;

	if ($debug){
	    print "$script $list";
	    print $txt , "\n";
	}

	# check if txt is json
	eval{
		my $o = $json->decode($txt) ;
		# print Dumper $o ;
		
		# modify $o, remove timestamps
		$o->{date} = 'test date' ;
		
		# dump into file
		open(OUT , ">$test_out_path/$prefix.$value.$script") or die "Can't write to $test_out_path/$prefix.$value.$script" ;
		print OUT $json->encode($o) ;
		close(OUT) ;
		
		# create test data
		if ($create_test_data){
			open(OUT , ">$test_data_path/$prefix.$value.$script") or die "Can't write to $test_data_path/$prefix.$value.$script" ;
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
	unless(`diff $test_data_path/$prefix.$value.$script $test_out_path/$prefix.$value.$script`){
	    ok(!`diff $test_data_path/$prefix.$value.$script $test_out_path/$prefix.$value.$script` , 'Output identical to precomputed data');
	};

}
