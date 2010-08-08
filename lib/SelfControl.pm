package SelfControl;

use warnings;
use strict;
use YAML qw<Dump>;

use SelfControl::Config;

=head1 NAME

SelfControl - The great new SelfControl!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SelfControl;

    my $foo = SelfControl->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

sub new {
  my ($class, $self) = @_;
  bless $self, $class;
  $self->init;
  return $self;
}

sub init {
  my ($self) = @_;

  $self->{config} = load_config($self->{config_file});

   # clean out expired jobs
   if ($self->{can_queue}) {
    $self->get_queue;
    my $nj = cc($self->{config}{jobs});
    for my $k (keys %{$nj}) {
      delete $nj->{$k} unless exists $self->{queue}->{$k};
    }
    $self->{config}{jobs} = $nj;
    save_config($self->{config_file}, $self->{config});
    $self->{did_queue} = 1;
  }
  return $self;
}

sub run {
  my ($self) = @_;
  $self->active_blocks;

  require SelfControl::UI;
  $self = SelfControl::UI->new($self);
  $self->run();

  #
  # if 'Start' was clicked, save changes and run self as root
  # to apply the blocks and schedule their removal.
  #
  if ($self->{started}) {
    save_config($self->{config_file}, $self->{config});
    if (scalar @{$self->{config}->{hosts}}) {
      system(@{$self->{sudo}}, $0);
    }
  }
  bless $self, __PACKAGE__;
  return $self;
}

# create a list suitable for SimpleList
# $self->{active_blocks} = [[jid, ts, hn, ip]];

sub active_blocks {
  my ($self) = @_;
  my $uj = cc($self->{config}{jobs});

  my @flat;
  for my $jid (keys %{$uj}) {
    my ($ts, $ha) = @{$uj->{$jid}};
    for my $he (@{$ha}) {
      my ($hn, $hi) = @{$he};
      push @flat, [$jid,$ts,$hn,$hi];
    }
  }

  my @sorted = sort {$a->[1] <=> $b->[1]} @flat;

  my (%last, %jtime);
  for my $x (@sorted) {
    $last{$x->[2]}{$x->[3]} = $x->[1]; $jtime{$x->[1]} = $x->[0];
  }

  my @list;
  for my $hn (sort keys %last) {
    for my $ip (keys %{$last{$hn}}) {
      my $ts = $last{$hn}{$ip};
      push @list, [$jtime{$ts}, $ts, $hn, $ip];
    }
  }

  $self->{active_blocks} = \@list;
}

# `atq` - requires sudoers line to really work:
# username ALL = NOPASSWD: /usr/bin/atq

sub get_queue {
  my ($self) = @_;
  my @lines = `sudo atq`;
  chomp @lines;

  my %data;
  for (@lines) {
    next unless m/
      ^
      (\d+)                                     # job id
      \t
      (... \s ... \s .. \s ..:..:.. \s ....)    # date
      \s
      (\w)                                      # queue name
      \s
      (\w+)                                     # job owner
      $
    /x;

    next unless $3 eq 'a';
    next unless $4 eq 'root';
    $data{$1} = $2;
  }
  return $self->{queue} = \%data;
}

# $x = cc($y) - serialized copy

sub cc {
  my ($x) = @_;
  YAML::Load(YAML::Dump($x));
}

=head1 AUTHOR

zengargoyle, C<< <zengargoyle at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-selfcontrol at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SelfControl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SelfControl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SelfControl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SelfControl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SelfControl>

=item * Search CPAN

L<http://search.cpan.org/dist/SelfControl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 zengargoyle.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SelfControl
