#!perl

use Test::More;

BEGIN { use_ok( 'SelfControl' ); }

my $self = {};
bless $self, 'SelfControl';

$self->{config}{jobs} = {
  1 => [ 10, [
      [ qw/an ai/],
      [ qw/bn bi/],
      [ qw/cn ci/],
    ]],
  2 => [ 15, [
      [ qw/an ai/],
      [ qw/bn bi/],
      [ qw/cn ci/],
    ]],
  3 => [ 20, [
      [ qw/bn bi/],
    ]],
  4 => [ 12, [
      [ qw/bn bi/],
    ]],
};

$self->{queue} = {
  2 => 'not used',
  3 => 'not used',
};

my $nj = $self->clean_expired_jobs;

ok(!exists $nj->{1}, "expired jobs cleaned");
ok(exists $nj->{2}, "non-expired jobs present");

$self->{config}{jobs} = $nj;
$self->active_blocks;
#use YAML; print YAML::Dump($self->{active_blocks});

my $list = [
  [2, 15, qw/an ai/],
  [3, 20, qw/bn bi/],
  [2, 15, qw/cn ci/],
];
 
is_deeply($self->{active_blocks}, $list, "ordered active blocks");
done_testing();
