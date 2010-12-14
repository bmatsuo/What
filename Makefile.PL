use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'What',
    VERSION_FROM      => 'lib/What.pm', # finds $VERSION
    PREREQ_PM         => {
        Getopt::Euclid => 0,
        Exception::Class => 0,
        Class::InsideOut => 0,
        Term::ReadLine => 0,
        Data::Dumper => 0,
        MP3::Tag => 0,
        LWP::UserAgent => 0,
        Moose => 0,
        Audio::FLAC::Header => 0,
        XML::Twig => 0,
        Perl6::Form => 0,
    }, # e.g., Module::Name => 1.1
    EXE_FILES   => [qw{
        scripts/snatch-inspect
        scripts/release-list
        scripts/release-import
        scripts/release-scaffold 
        scripts/release-art-convert
        scripts/release-delete
        scripts/release-flac-convert
        scripts/release-mktorrent
        scripts/release-add-to-library
        scripts/release-mkm3u
        scripts/release-embed-image
        scripts/release-link
        scripts/release-mkinfo
        scripts/release-rm-badchar
        scripts/release-stage-rip
        scripts/release-set-context
        scripts/release-forget-context
        scripts/release-ok
        scripts/release-organize
        scripts/mkrelease
    }],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       ABSTRACT_FROM  => 'lib/What.pm', # retrieve abstract from module
       AUTHOR         => 'dieselpowered') : ()),
);
