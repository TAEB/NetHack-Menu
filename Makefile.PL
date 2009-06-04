# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'NetHack-Menu';
all_from       'lib/NetHack/Menu.pm';

requires       'Moose';

build_requires 'Test::MockObject';
build_requires 'Test::Exception';

githubmeta;
auto_install;
WriteAll;

