use inc::Module::Install;

all_from ('lib/MobiPerl.pm');
requires(Date::Format => 0,
Date::Parse => 0,
Mouse => 0.28,
Encode => 0,
GD => 0,
Getopt::Mixed => 0,
HTML::FormatText => 0,
HTML::TreeBuilder => 0,
Image::BMP => 0,
Image::Size => 0,
XML::Parser::Lite::Tree => 0,
);

auto_install_deps();

#MobiPerl::Config
#MobiPerl::EXTH
#MobiPerl::LinksInfo
#MobiPerl::MobiFile
#MobiPerl::MobiHeader
#MobiPerl::Opf
#MobiPerl::Util
#Palm::Doc
#Palm::PDB
#Palm::Raw
#
WriteAll();
