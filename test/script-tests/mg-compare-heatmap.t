#!/usr/bin/perl -w
use strict;
use warnings;
use lib "test/script-tests/";

use Data::Dumper;
use Test::More 'no_plan';
use JSON;

# script to test
my $script = "mg-compare-heatmap" ;

# assumption scripts are always in path
my $topDir 			= $ENV{KB_TOP} || "/";
my $service_repo 	= "communities_api" ;
my $script_path 	= $topDir . "" ;
my $num_tests   	= 0;
my $json        	= new JSON;
my $success     	= 1;
my $test_data_path 	= shift @ARGV || join "/" , $topDir , "dev_container/modules" , $service_repo , "test/data" ;
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




# list of all matrix files, output from mg-biom-merge
my @files ;

opendir(DATA, $test_data_path) || die "Error: no test data dirctory: $test_data_path!\n";

while(my $file = readdir DATA) {
	push @files , $file if ($file =~ /.+\.mg-biom-merge$/)
}

closedir DATA;


# loop throug list and create triples

foreach my $file (@files){
	
	# not used yet
	my $source = "Subsystems" ;
	
	# cluster function
	my @cf = ("ward", "single", "complete","mcquitty", "median", "centroid") ;
	# distance function
	my @df = ( "bray-curtis", "euclidean" , "maximum", "manhattan", "canberra", "minkowski", "difference" );
	
	# loop through existing profiles/parameters, retrieve profiles and merge them
	foreach my $cf (@cf) {
		foreach my $df (@df){
			#ok(get_data( $file ,$cf , $df) , "object for file $file and value $cf , $df") ;
			subtest get_data => sub { get_data( $file ,$cf , $df ) } ;
		}
	}
	
}





sub get_data{
	my ( $file ,$cf , $df ) 	= @_;
	my $success 		= undef ;
	
	# create test data
	#system("$script --input $file --format biom --cluster $cf --distance $df > $test_data_path/$file.$cf.$df.$script") if ($create_test_data); 
	
	
	
	
	#  mg-compare-heatmap [ --help, --input <input file or stdin>, --format <cv: 'text' or 'biom'>, --name <boolean>, --cluster <cv: ward, single, complete,
	#  mcquitty, median, centroid>, --distance <cv: bray-curtis, euclidean, maximum, manhattan, canberra, minkowski, difference>, --normalize <boolean> ]

	if ($debug){
            diag("$script --input $test_data_path/$file --format biom --cluster $cf --distance $df\n");
	}     
	
		
		if($create_test_data){
		    system("$script --input $test_data_path/$file --format biom --cluster $cf --distance $df > $test_data_path/$file.$cf.$df.$script") ; #unless (-f "$test_data_path/$file.$cf.$df.$script");
		}
		
	my $out = `$script --input $test_data_path/$file --format biom --cluster $cf --distance $df > $test_out_path/$file.$cf.$df.$script` ;

	ok(-f "$test_out_path/$file.$cf.$df.$script", "got data for file $file and value $cf , $df");

	if ($debug){
	    #print "$script --input $file --format biom --cluster $cf --distance $df";
	    print $out , "\n";
	}

	my $txt = '' ;
	open(FILE , "$test_out_path/$file.$cf.$df.$script") ;
	while (my $t = <FILE> ) {
	    $txt .= $t ;
	}
	close(FILE) ;

	# check if txt is json
	eval{
		my $o = $json->decode($txt) ;
		diag(Dumper $o) if ($debug) ;
		diag($txt) if ($debug);
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
	
	ok(!`diff $test_data_path/$file.$cf.$df.$script $test_out_path/$file.$cf.$df.$script` , 'Output identical to precomputed data');
	

}
