package SelfControl::Root;

use warnings;
use strict;

use Exporter qw<import>;
our @EXPORT = qw<check_chain add_chain add_hosts>;

use Sys::Syslog;
use SelfControl::Config;

=head1 NAME

SelfControl::Root - The great new SelfControl::Root!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use SelfControl::Root;

    my $foo = SelfControl::Root->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

#
# Manipulate firewall.
#

sub check_chain {
  my $out;
syslog('info',"check_chain");
  $out = `iptables -S SelfControl`;
  unless ($out =~ m/^-N SelfControl\s*$/m) {
    syslog('info','creating SelfControl chain');
    system("iptables -N SelfControl") and syslog('error','could not create SelfControl chain');
  }

  $out = `iptables -S OUTPUT`;
  unless ($out =~ m/^-A OUTPUT -j SelfControl\s*$/m) {
    syslog('info','adding SelfControl chain to OUTPUT chain');
    system("iptables -A OUTPUT -j SelfControl") and syslog('error','could not add SelfControl chain to OUTPUT chain');
  }
}
sub add_chain {
  my ($ConfigFile) = @_;
  unless (-f $ConfigFile) {
    die "No Config File found: '$ConfigFile'\n";
  }
  my ($Config) = load_config($ConfigFile);

  my $ts = "now + $Config->{timeout} minutes";
  open my $at, '|-', "at '$ts' 2>/dev/null" or die $!;
  for my $hr (@{$Config->{hosts}}) {
    my $h = $hr->[1];
    system("iptables -I SelfControl -d $h -j DROP");
    print $at "iptables -D SelfControl -d $h -j DROP\n";
  }
  close $at;
}
sub add_hosts {
  my ($ConfigFile) = @_;
  unless (-f $ConfigFile) {
    die "No Config File found: '$ConfigFile'\n";
  }
  my ($Config) = load_config($ConfigFile);
  my $ts = "now + $Config->{timeout} minutes";
  my @hn;
  for my $hr (@{$Config->{hosts}}) {
    my $h = $hr->[0];
    next if $h =~ /\.\d{1,3}$/;  # purge any IP only.
    push @hn, $h;
  }
  if (@hn) {
    open my $at, '|-', "at '$ts' 2>/dev/null" or die $!;
    open my $hf, '>>', '/etc/hosts' or die $!;
    print $at "ed /etc/hosts <<_EOF_ 2>/dev/null\n";
    for (@hn) {
      my $esc = $_;
      $esc =~ s/\./\\./g;
      print $hf "127.0.0.2 $_ # SelfControl - DO NOT EDIT!\n";
      print $at "/^127\\.0\\.0\\.2 $esc # SelfControl - DO NOT EDIT!\$/d\n";
    }
    close $hf;
    print $at "wq\n_EOF_\n";
    close $at;
  }
}

sub do_at {  # $cmd,$ts
  my ($cmd, $ts) = @_;
  my ($rc, $output) = spawn_simple($cmd,'at',$ts);
  return undef if $rc;
  my ($job, $when) = "@{$output}" =~ m/^\s*job\s+(\d+)\s+at\s+(.*?)\s*$/m;
  return ($job, $when);
}
sub spawn {
  pipe(my $fp, my $tc);
  pipe(my $fc, my $tp);
  my $pid = fork();
  if (!defined $pid) {
    close $fp; close $tc;
    close $fc; close $tp;
    warn "fork failed.\n";
    return;
  }
  elsif ($pid == 0) {
    # in the child
    close $tc; close $fc;
    open STDIN, "<&", $fp;
    open STDERR, ">&", $tp;
    open STDOUT, ">&", $tp;
    { exec @_ };
    print $tp "Failed to execute: ". join (" ", @_) ."\n";
    print $tp "Command '$_[0]' not accessible.\n"
        if $!{ENOENT} or $!{EPERM};
    close $tp;
    close $fp;
    exit -1;
  }
  else {
    close $fp; close $tp;
    return ($pid, $tc, $fc);
  }
}
sub spawn_simple {
  my ($input, @cmd) = @_;
  my ($status, @output);
  my ($pid, $tc, $fc) = spawn(@cmd);
  return unless defined $pid;
  print $tc $input if defined $input;
  close $tc;
  waitpid($pid, 0);
  $status = $? >> 8;
  $status = -1 if $status == 255;
  @output = <$fc>;
  close $fc;
  return ($status, \@output);
}

=head1 AUTHOR

zengargoyle, C<< <zengargoyle at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-selfcontrol at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SelfControl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SelfControl::Root


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

1; # End of SelfControl::Root
