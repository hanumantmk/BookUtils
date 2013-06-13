#!/usr/bin/perl -w

use strict;

use Roman;
use XML::Twig;

sub transform {
    my ($num) = @_;

    $num -= 4;

    if ($num < 1) {
        return (roman(arabic("xiv") + $num), 1);
    } else {
        return ($num, 0);
    }
}

my $twig = XML::Twig->new(
    output_filter => 'safe',
    pretty_print => 'nsgmls',
);

$twig->parsefile('in.xml');

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
