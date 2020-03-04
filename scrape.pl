#!/usr/bin/perl 

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use HTML::TreeBuilder;

# Get search term from cmd line
if (!@ARGV) {
	print("Usage: test.pl [SEARCH_TERM]");
}
my $search_term = $ARGV[0];

# Recursive function to find text to print from HTML
sub print_recursively {
	my $elem = $_[0];
	my @children = $elem->content_list;
	if (@children) {
		foreach my $e (@children) {
			# If is an HTML element
			if (ref($e) eq "HTML::Element") {
			
				# Only process DIV, SPAN, or A
				my $tag = $e->tag;
				if ($tag eq 'div' || $tag eq 'span') {
					print_recursively($e, $_[1]."-");
				}
				elsif ($tag eq 'a') {
					print_recursively($e, $_[1]."-");
					# Print link if relevant e.g. not an img, search link
					my @regex_res = $e->attr('href') =~ /^(?:\/url\?q=)?(https?:\/\/.+)$/;
					if (@regex_res) {
						print("[ ".$regex_res[0]." ]\n");
					}
				}
			}
			# Else assume is a text node and print
			else {
				print($e . "\n");
			}
		}
	}
	else {
		print($elem->as_text);
	}
	return;
}

# Initialize UserAgent as Mozilla/5.0
my $ua = LWP::UserAgent->new;
$ua->agent('Mozilla/5.0');

# Request google search
my $req = HTTP::Request->new('GET', 'http://www.google.com/search?q='.$search_term);
my $res = $ua->request($req);

# If request successful
if ($res->is_success()) {
	# Write response to out.html
	open(FH, '>', 'out.html');
	print(FH $res->content);
	
	# Parse HTML, get #main
	my $tree = HTML::TreeBuilder->new;
	$tree->parse_content($res->content);
	my $search_results = $tree->look_down('id', 'main');
	
	# Remove first two irrelevant elements
	my @elements = $search_results->content_list;
	@elements = @elements[2 .. $#elements];
	
	# For each element that is a div
	foreach my $e (@elements) {
		if ($e->tag eq 'div') {
			# print("div\n");
			print_recursively($e, "-");
			print("\n----------\n\n");
		}
	}
}
# If request not successful, print error
else {
	print($res->status_line);
}