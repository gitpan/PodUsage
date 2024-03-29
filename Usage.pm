#############################################################################
# Usage.pm -- print usage messages for the running script.
#
# Based on Tom Christiansen's Pod::Text::pod2text() function
# (with modifications).
#
# Copyright (C) 1996 Tom Christiansen. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#############################################################################

package Pod::Usage;

$VERSION = 0.01;   ## Current version of this package
require  5.002;    ## requires Perl version 5.002 or later

=head1 NAME

pod2usage

=head1 SYNOPSIS

    use Pod::Usage qw(pod2usage);
    pod2usage();
    pod2usage(2);
    pod2usage({EXIT => 2});
    pod2usage({EXIT => 2, VERBOSE => 0});
    pod2usage(EXIT => 1, VERBOSE => 2, OUTPUT=\*STDERR);
    pod2usage(VERBOSE => 2);

=head1 DESCRIPTION

B<pod2usage> will print a usage message for the invoking script (using
its embedded pod documentation) and then exit the script with the
specified exit value. It takes a single argument which is either a
numeric value corresponding to the desired exit status (which defaults
to 2), or a reference to a hash. If more than one argument is given then
the entire argument list is assumed to be a hash. If a hash is supplied
it should contain elements with one or more of the following keys:

=over 4

=item C<EXIT>

The desired exit status to pass to the B<exit()> function.

=item C<VERBOSE>

The desired level of "verboseness" to use when printing the usage
message. If the corresponding value is 0, then only the "SYNOPSIS"
section of the pod documentation is printed. If the corresponding value
is 1, then the "SYNOPSIS" section, along with any section entitled
"OPTIONS", "ARGUMENTS", or "OPTIONS AND ARGUMENTS" is printed.  If the
corresponding value is 2 or more then the entire manpage is printed.

=item C<OUTPUT>

A reference to a filehandle, or the pathname of a file to which the
usage message should be written. The default is C<\*STDERR> unless the
exit value is less than 2 (in which case the default is C<\*STDOUT>).

=item C<INPUT>

A reference to a filehandle, or the pathname of a file from which the
invoking scripts pod documentation from.  It defaults to the file
indicated by C<$0> (or C<$PROGRAM_NAME> if C<use English;> is in
effect).

=back

If neither the exit value nor the verbose level is specified, then the
default is to use an exit value of 2 with a verbose level of 0.

If an exit value is specified but the verbose level is not, then the
verbose level will default to 1 if the exit value is less than 2 and
will default to 0 otherwise.

If a verbose level is specified but an exit value is not, then the exit
value will default to 2 if the verbose level is 0 and will default to 1
otherwise.

=head1 EXAMPLE

Most scripts should print some type of usage message to STDERR when a
command line syntax error is detected. They should also provide an
option (usually C<-h> or C<-help>) to print a (possibly more verbose)
usage message to STDOUT. Some scripts may even wish to go so far as to
provide a means of printing their complete documentation to STDOUT
(perhaps by allowing a C<-man> option). The following example uses
B<pod2usage> in combination with B<Getopt::Long> to do all of these
things:

    use Pod::Usage;
    use Getopt::Long;

    GetOptions("help", "man")  ||  pod2usage(2);
    pod2usage(1)  if ($opt_help);
    pod2usage(VERBOSE => 2)  if ($opt_man);

=head1 AUTHOR

Brad Appleton E<lt>Brad_Appleton-GBDA001@email.mot.comE<gt>

Based on code for B<Pod::Text::pod2text()> written by
Tom Christiansen E<lt>tchrist@mox.perl.comE<gt>

=cut

#############################################################################

require Exporter;
use Pod::Filter;
use Pod::PlainText;

@ISA = qw(Exporter Pod::PlainText);
@EXPORT = qw(&pod2usage);

use strict;
use diagnostics;
use Carp;

##---------------------------------------------------------------------------

##---------------------------------
## Function definitions begin here
##---------------------------------

sub version {
    no strict;
    return  $VERSION;
}

sub pod2usage {
    local($_) = @_;
    my %options;
    ## Collect arguments
    if (@_ > 1) {
        ## Too many arguments - assume that this is a hash and
        ## the user forgot to pass a reference to it.
        %options = @_;
    }
    elsif (ref $_) {
        ## User passed a ref to a hash
        %options = %{$_}  if (ref($_) eq 'HASH');
    }
    else {
        ## User passed in the exit value to use
        $options{"EXIT"} =  $_;
    }

    ## Now determine default values to use
    if ((! defined $options{"EXIT"}) && (! defined $options{"VERBOSE"})) {
        $options{"EXIT"} = 2;
        $options{"VERBOSE"} = 0;
    }
    elsif (! defined $options{"EXIT"}) {
        $options{"EXIT"} = ($options{"VERBOSE"} > 0) ? 1 : 2;
    }
    elsif (! defined $options{"VERBOSE"}) {
        $options{"VERBOSE"} = ($options{"EXIT"} < 2);
    }
    $options{"INPUT"} = $0  unless (defined $options{"INPUT"});
    $options{"OUTPUT"} = ($options{"EXIT"} < 2) ? \*STDOUT : \*STDERR
            unless (defined $options{"OUTPUT"});

    ## Now create a pod reader and constrain it to the desired sections.
    my $filter = new Pod::Usage(VERBOSE => $options{"VERBOSE"});
    if ($options{"VERBOSE"} == 0) {
        $filter->select("SYNOPSIS");
    }
    elsif ($options{"VERBOSE"} == 1) {
        my $opt_re = '(?i)' .
                     '(?:OPTIONS|ARGUMENTS)' .
                     '(?:\s*(?:AND|\/)\s*(?:OPTIONS|ARGUMENTS))?';
        $filter->select( 'SYNOPSIS', $opt_re, "DESCRIPTION/$opt_re" );
    }

    ## Now translate the pod document and then exit with the desired status
    $filter->process_file($options{"INPUT"}, $options{"OUTPUT"});
    exit($options{"EXIT"});
}

##---------------------------------------------------------------------------

##-------------------------------
## Method definitions begin here
##-------------------------------

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %params = @_;
    my $self = {%params};
    bless $self, $class;
    $self->initialize();
    return $self;
}

sub preprocess {
    my $self = shift;
    local($_) = shift;
    ## See if this is a heading and we arent printing the entire manpage.
    if (($self->{VERBOSE} < 2) && /^=head/o) {
        ## Change the title of the SYNOPSIS section to USAGE
        s/^=head1\s+SYNOPSIS\s*$/=head1 USAGE/o;
        ## Try to do some lowercasing instead of all-caps in headings
        s{([A-Z])([A-Z]+)}{((length($2) > 2) ? $1 : lc($1)) . lc($2)}ge;
        ## Use a colon to end all headings
        s/\s*$/:/o  unless (/:\s*$/o);
    }
    return  $self->SUPER::preprocess($_);
}

