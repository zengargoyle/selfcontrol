package SelfControl;
my $ID = {
        date => q$Date$,
        headurl => q$HeadURL$,
        author => q$Author$,
        revision => q$Revision$,
};

use warnings;
use strict;
use YAML qw<Dump>;

use SelfControl::Config;

=head1 NAME

SelfControl - Block the internet for a period of time.

=head1 VERSION

Version 0.9

=cut

our $VERSION = '0.9';

=head1 SYNOPSIS

This application allows one to make a list of internet sites by
hostname or IP address, and then to block access to those sites
for a specifig amount of time.  For example: block access to
metafilter.com and slashdot.org for 45 minutes.

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
  if ($self->{config}{can_queue}) {
    $self->get_queue;
    $self->{config}{jobs} = $self->clean_expired_jobs;
    save_config($self->{config_file}, $self->{config});
    $self->{did_queue} = 1;
  }

  return $self;
}

sub clean_expired_jobs {
  my ($self) = @_;
  # clean out expired jobs
  my $nj = cc($self->{config}{jobs});
  for my $k (keys %{$nj}) {
    delete $nj->{$k} unless exists $self->{queue}->{$k};
  }
  return $nj
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

Please report any bugs or feature requests to C<zengargoyle at gmail.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SelfControl

You can also look for information at:

=over 4

=item * The SelfControl for Linux Homepage

L<http://svn.jklmnop.net/projects/SelfControl.html>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 zengargoyle.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

On Debian/Ubuntu systems these licenses can be found in:

    /usr/share/common-licenses/Artistic
    /usr/share/common-licenses/GPL

=cut

1; # End of SelfControl
