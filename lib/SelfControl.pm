package SelfControl;

use warnings;
use strict;

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

=head2 function1

=cut

sub get_active {
use YAML qw<Dump>;
  my ($config) = @_;
  my $queue = get_queue();
  my $jobs = $config->{jobs};

  # delete completed jobs;
  for my $id (keys %{$jobs}) {
    delete $jobs->{$id} unless exists $queue->{$id}
  }

  # hash of host,ip = date; order of dates uniq
  # latest date wins
  my %last;
  my @order;
  for my $id (sort {$a <=> $b} keys %{$jobs}) {
    my $job = $jobs->{$id};
    my $date = shift @{$job};
    for my $entry (@{$job}) {
      $last{$entry->[1]}{$entry->[0]} = $date;
      push @order, $date unless grep {$date eq $_} @order;
    }
  }

  # build [date, [host, ip]] in date,host order
  my @sorted;
  for my $date (@order) {
    my @keep = ();
    for my $host (keys %last) {
      for my $ip (keys %{$last{$host}}) {
        push @keep, [$host, $ip] if $last{$host}{$ip} eq $date;
      }
    }
    push @sorted, [$date, [sort {$a->[0] cmp $b->[0]} @keep]] if @keep;
  }
  return \@sorted;
}
sub get_queue {
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
  return \%data;
}
sub function1 {
}

=head2 function2

=cut

sub function2 {
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
