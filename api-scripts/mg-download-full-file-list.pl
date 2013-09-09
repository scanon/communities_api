use strict;
use warnings;

use Getopt::Long;

use LWP::UserAgent;
use JSON;

use Bio::KBase::IDServer::Client;

sub help {
  my $text = qq~
NAME
    mg-download-full-file-list.pl -- download a communities API pipeline result file

VERSION
    2

SYNOPSIS
    mg-download-full-file-list.pl [ --help, --user <user>, --pass <password>, --token <oAuth token>, --webkey <communities webkey>, --verbosity <verbosity level>--id <metagenome id>]

DESCRIPTION
    download the list of intermediate and resulting files produced by the communities API analysis pipeline for a specified metagenome

  Options
    help - display this message
    user - username to authenticate against the API, requires a password to be set as well
    pass - password to authenticate against the API, requires a username to be set as well
    token - Globus Online authentication token
    webkey - MG-RAST webkey to synch with the passed Globus Online authentication
    verbosity - verbosity of the result data, can be one of [ 'minimal', 'verbose', 'full' ]
    id - id of the metagenome

  Output
    JSON structure that contains the result data

EXAMPLES
    -

SEE ALSO
    -

AUTHORS
    Jared Bischof, Travis Harrison, Folker Meyer, Tobias Paczian, Andreas Wilke

~;
  print $text;
}

my $HOST      = 'http://kbase.us/services/communities/1/download/';
my $user      = '';
my $pass      = '';
my $token     = '';
my $verbosity = 'full';
my $help      = '';
my $webkey    = '';
my $offset    = '0';
my $limit     = '10';
my $id        = undef;
  

GetOptions ( 'user=s' => \$user,
             'pass=s' => \$pass,
             'token=s' => \$token,
             'verbosity=s' => \$verbosity,
             'help' => \$help,
             'webkey=s' => \$webkey,
             'limit=s' => \$limit,
             'offset' => \$offset,
	     'id=s' => \$id );

if ($help) {
  &help();
  exit 0;
}

if ($user || $pass) {
    if ($user && $pass) {
	my $agent = LWP::UserAgent->new;
	$agent->protocols_allowed( [ 'https' ] );
	my $request = HTTP::Request->new("POST", "https://nexus.api.globusonline.org/goauth/token?grant_type=client_credentials" );
	$request->authorization_basic($user, $pass);
	my $response = $agent->request($request)->content();
	my $ustruct = "";
	eval {
	    my $json = new JSON;
	    $ustruct = $json->decode($response);
	};
	if ($@) {
	    die "could not reach auth server";
	} else {
	    if ($ustruct->{access_token}) {
		$token = $ustruct->{access_token};
	    } else {
		die "authentication failed";
	    }
	}
    } else {
	die "you must supply both username and password";
    }
}

if ($id && $id =~/^kb\|/) {
  my $id_server_url = "http://www.kbase.us/services/idserver";
  my $idserver = Bio::KBase::IDServer::Client->new($id_server_url);
  my $return = $idserver->kbase_ids_to_external_ids( [ $id ]);
  $id = $return->{$id}->[1];
}

if ($id) {
  $HOST .= "$id/";
}

my $subresource = "";
my $additionals = ""; 

my $url = $HOST.$subresource."?verbosity=$verbosity&limit=$limit&offset=$offset".$additionals;
if ($webkey) {
  $url .= "&webkey=".$webkey;
}
my $ua = LWP::UserAgent->new;
if ($token) {
  $ua->default_header('user_auth' => $token);
}
print $ua->get($url)->content;
