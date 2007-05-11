#!/usr/bin/perl

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;

use Business::OnlinePayment;

my $runinfo =
    "to test set environment variables:"
  . " (required) ELINK_ACH_ACCOUNT and ELINK_ACH_PASSWORD";

plan(
      ( $ENV{"ELINK_ACH_ACCOUNT"} && $ENV{"ELINK_ACH_PASSWORD"} )
    ? ( tests => 12 )
    : ( skip_all => $runinfo )
);

my %opts = (
    "debug"    => 0,
    "merchantcustservnum" => "8005551212",
);

my %content = (
    login          => $ENV{"ELINK_ACH_ACCOUNT"},
    password       => $ENV{"ELINK_ACH_PASSWORD"},
    action         => "Normal Authorization",
    type           => "CHECK",
    description    => "Business::OnlinePayment::TransFirsteLink test",
    routing_code   => "052000113",
    account_number => "000000000001",
    check_number   => "100",
    cvv2           => "123",
    expiration     => "12/" . strftime( "%y", localtime ),
    amount         => "0.01",
    invoice_number => "1999",
    account_name   => "Tofu Beast",
    customer_id    => "TB01",
    email          => 'transfirst@weasellips.com',
    address        => "123 Anystreet",
    city           => "Anywhere",
    state          => "GA",
    zip            => "30004",
    country        => "US",
    phone          => "4045551212",
);

{    # valid account test
    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content(%content);
    tx_check(
        $tx,
        desc          => "valid account",
        is_success    => 1,
        result_code   => "P00",
    );
}

SKIP: {    # invalid account test

    skip "invalid account tests broken", 4;

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, routing_code   => "052000113",
                            account_number => "000000000001",
                );

    tx_check(
        $tx,
        desc          => "invalid account",
        is_success    => 0,
        result_code   => 214,
    );
}

SKIP: {    # credit/refund test

    skip "credit/refund tests broken", 4;

    my $tx = new Business::OnlinePayment( "TransFirsteLink", %opts );
    $tx->content( %content, action => "Credit");

    tx_check(
        $tx,
        desc          => "credit/refund",
        is_success    => 0,
        result_code   => "P00",
    );
}

sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->test_transaction(1);
    $tx->submit;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    is( scalar(@{$tx->junk}), 0, "junk() / JUNK " );
    like( $tx->order_number, qr/^(\d{9}|)$/, "order_number() / PNREF" );
}

sub tx_info {
    my $tx = shift;

    no warnings 'uninitialized';

    return (
        join( "",
            "is_success(",     $tx->is_success,    ")",
            " order_number(",  $tx->order_number,  ")",
            " result_code(",   $tx->result_code,   ")",
            $tx->junk ? " junk(". join('|', @{$tx->junk}). ")" : '',
        )
    );
}
