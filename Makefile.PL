use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Sledge::Session::AnyDBM',
    'VERSION_FROM' => 'lib/Sledge/Session/AnyDBM.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
