#!/usr/bin/perl
# make a django project release
# ./make-django-release.pl <tag-prefix> <django-project-directory> "commit comment"
# e.g. ./make-django-release.pl cdp cspace_django_project "a few fixes and enhancements"

use strict;

if (scalar @ARGV != 3)  {
  die "Need three arguments: tag-prefix directory \"comment (can be empty)\"\n";
}

my ($TAGPREFIX, $DIRECTORY, $MSG) = @ARGV;

chdir $DIRECTORY or die("could not change to $DIRECTORY directory");
    
my @tags = `git tag --list ${TAGPREFIX}_*`;
if ($#tags == 0) {
   print "can't find any tags for ${TAGPREFIX}_*\n";
   exit(1);
}

my (@parts, $revision, $version_number, $last_revision, $last_version_number, $revision);

foreach my $tag (@tags) {
    @parts = split(/[\-_]/, $tag);
    $revision = pop(@parts);
    $version_number = join('_', @parts);

    if ($revision > $last_revision) {
        $last_revision = $revision;
        $last_version_number = $version_number;
    }
}

$last_revision++;
my $version_number = "$last_version_number-$last_revision";
my $tag_message = "Release tag for django project $version_number.";
$tag_message .= ' ' . $MSG if $MSG;

print "verifying code is current and using master branch...\n";
system "git pull -v";
system "git checkout master";
print "updating CHANGELOG.txt...\n";
system "echo 'CHANGELOG for the cspace_django_webapps' > CHANGELOG.txt";
system "echo  >> CHANGELOG.txt";
system "echo 'OK, it is not a *real* change log, but a list of changes resulting from git log' >> CHANGELOG.txt";
system "echo 'with some human annotation after the fact.' >> CHANGELOG.txt";
system "echo  >> CHANGELOG.txt";
system "echo 'This is version $version_number' >> CHANGELOG.txt";
system "echo '$version_number' > VERSION";
system "date >> CHANGELOG.txt ; echo >> CHANGELOG.txt";
system "git log --oneline --decorate >> CHANGELOG.txt";
print  "git tag -a $version_number -m '$tag_message'\n";
system "git tag -a $version_number -m '$tag_message'";
system "git commit -a -m 'revise change log and VERSION file for version $version_number'";
system "git push -v" ;
system "git push --tags";

