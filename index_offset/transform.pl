#!/usr/bin/perl -w

use strict;

use lib '../libs';

use Roman;
use XML::Twig;

use Getopt::Long;

my $top_roman = '';
my $offset = 0;

GetOptions(
    'top_roman=s' => \$top_roman,
    'offset=i'    => \$offset,
    help          => sub { HELP() },
) or HELP("Invalid Option");

my $file = shift @ARGV;

HELP("Please provide an input file") if (! $file);
HELP("Please provide an offset") if (! $offset);
HELP("Please provide a valid top roman") if ($offset && ! isroman($top_roman));

sub transform {
    my ($num) = @_;

    $num += $offset;

    if ($num < 1) {
        return (roman(arabic($top_roman) + $num), 1);
    } else {
        return ($num, 0);
    }
}

my $twig = XML::Twig->new(
    output_filter => 'safe',
    pretty_print => 'nsgmls',
);

$twig->parsefile($file);

my $root = $twig->root;

foreach my $elt ($root->find_by_tag_name('w:t')) {
    my $text = $elt->text;

    my $lead = '';

    if ($text =~ /([^,]*,)(.*)/) {
        $lead = $1;
        $text = $2;

        if ($lead =~ /^[\s\d&#;,]+$/) {
            $text = $elt->text;
            $lead = '';
        }
    }

    my $buf = $lead;

    while ($text) {
        $text =~ s/^(\D*)(\d*)//;

        if ($1) {
            $buf .= $1;
        }
        if ($2) {
            my ($out, $is_roman) = transform($2);

                if ($is_roman) {
                    $elt->set_text($buf);

                    my $r = $elt->parent->insert_new_elt("after", "w:r");
                    $r->insert_new_elt("first_child", "w:rPr")->insert_new_elt("first_child", "w:i")->insert_new_elt("after", "w:i-cs");
                    $elt = $r->insert_new_elt("last_child", "w:t");
                    $elt->set_text($out);
                    $buf = '';

                    $elt = $elt->parent->insert_new_elt("after", "w:r")->insert_new_elt("first_child", "w:t");
                } else {
                   $buf .= $out;
                }
        }
    }

    $elt->set_text($buf);
}

$root->print();

sub HELP {
    my ($msg) = @_;

    my $usage = <<USAGE ;
$0 - [OPTIONS] FILE > [OUTPUT]

Updates an index file (Word 2003 XML Document) to uniformly adjust all page
references up or down.

Caveats:
    * For negative offsets, adjusts negative page numbers into a roman numeral
      space (so page 0 converts to the provided --top_roman)
    * Roman numeral pages aren't affected
    * Roman numerals are italicized
    * Index entries are of the form: foo bar baz, 1, 2, 55-120
        * nothing before the first comma per entry is affected

FILE
    The file to parse

OPTIONS
    --offset     Offset for index entries.  May be negative
    --top_roman  The top roman numeral.  Required for negative offsets

    --help       This help information
USAGE

    if ($msg) {
        warn $msg;
        warn $usage;

        exit 1;
    } else {
        print $usage;

        exit 0;
    }
}
