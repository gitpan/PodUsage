use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => "Pod::Usage",
    DISTNAME  => "PodUsage",
    VERSION   => "0.01",
    SKIP      => [qw(static dynamic)],
    linkext   => {LINKTYPE => ''},
    INSTALLDIRS => 'perl',
    PM        => { "Usage.pm" => '$(INST_LIB)/Pod/Usage.pm' },
);
