#!/usr/bin/env bash

#Display useful information about the perlbrew installation.
#If a module is given the version and location of the module is displayed.
perlbrew info

<<COMMENT

Current perl:
  Name: perl-5.30.1
  Path: /Users/bruno/perl5/perlbrew/perls/perl-5.30.1/bin/perl
  Config: -de -Dprefix=/Users/bruno/perl5/perlbrew/perls/perl-5.30.1 -Aeval:scriptdir=/Users/bruno/perl5/perlbrew/perls/perl-5.30.1/bin
  Compiled at: Dec 16 2019 08:44:12

perlbrew:
  version: 0.87
  ENV:
    PERLBREW_ROOT: /Users/bruno/perl5/perlbrew
    PERLBREW_HOME: /Users/bruno/perl5/perlbrew
    PERLBREW_PATH: /Users/bruno/perl5/perlbrew/bin:/Users/bruno/perl5/perlbrew/perls/perl-5.30.1/bin
    PERLBREW_MANPATH: /Users/bruno/perl5/perlbrew/perls/perl-5.30.1/man
    
COMMENT

# List the recently available versions of perl on CPAN.
perlbrew available


# Removes all previously downloaded Perl tarballs and build directories.
perlbrew clean

# Show the version of perlbrew.
perlbrew version

<<COMMENT

# Build and install the given versions of perl.
perlbrew install [options] stable
perlbrew install [options] blead
perlbrew install [options] <version>
# https://github.com/perl11/cperl
perlbrew install [options] cperl-<version>

    Options for "install" command:

        -f --force     Force installation
        -j $n          Parallel building and testing. ex. C<perlbrew install -j 5 perl-5.14.2>
        -n --notest    Skip testing

           --switch    Automatically switch to this Perl once successfully
                       installed, as if with `perlbrew switch <version>`

           --as        Install the given version of perl by a name.
                       ex. C<perlbrew install perl-5.6.2 --as legacy-perl>

           --noman     Skip installation of manpages

           --thread    Build perl with usethreads enabled
           --multi     Build perl with usemultiplicity enabled
           --64int     Build perl with use64bitint enabled
           --64all     Build perl with use64bitall enabled
           --ld        Build perl with uselongdouble enabled
           --debug     Build perl with DEBUGGING enabled
           --clang     Build perl using the clang compiler
           --no-patchperl
                       Skip calling patchperl

        -D,-U,-A       Switches passed to perl Configure script.
                       ex. C<perlbrew install perl-5.10.1 -D usemymalloc -U versiononly>

        --destdir $path
                       Install perl as per 'make install DESTDIR=$path'

        --sitecustomize $filename
                       Specify a file to be installed as sitecustomize.pl
 
 # Uninstalls the given perl installation.                      
perlbrew uninstall <name>

COMMENT
