#!/usr/bin/perl
# make a django project release
# e.g. ./make-django-release.sh cdp cspace_django_project "latest BMU, other small improvements"

use strict;

if (scalar @ARGV != 3)  {
  die "Need three arguments: tag-prefix directory \"comment (can be empty)\"\n";
}

my ($TENANT, $PROJECT, $MSG) = @ARGV;

chdir $PROJECT or die("could not change to $PROJECT directory");
    
my @tags = `git tag --list ${TENANT}_*`;
if ($#tags < 0) {
   print "can't find tags for ${TENANT}_*\n";
   exit(1);
}

my (@parts, $revision, $branch, $last_revision, $revision);

foreach my $tag (@tags) {
    @parts = split(/[\-_]/, $tag);
    $revision = pop(@parts);
    $branch = join('_', @parts);

    if ($revision > $last_revision) {
        $last_revision = $revision;
    }
}

$last_revision++;
my $version_number = "$branch-$last_revision";
my $tag_message = "Release tag for django project $version_number.";
$tag_message .= ' ' . $MSG if $MSG;

print "verifying code is current...\n";
system "git pull -v";
system "git checkout master";
print "updating CHANGELOG.txt...\n";
system "echo 'CHANGELOG for the cspace_django_webapps' > CHANGELOG.txt";
system "echo  >> CHANGELOG.txt";
system "echo 'OK, it is not a *real* change log, but a list of changes resulting from git log' >> CHANGELOG.txt";
system "echo 'with some human annotation after the fact.' >> CHANGELOG.txt";
system "echo  >> CHANGELOG.txt";
system "echo 'This is version $version_number' >> CHANGELOG.txt";
system "date >> CHANGELOG.txt ; echo >> CHANGELOG.txt";
system "git log --oneline --decorate >> CHANGELOG.txt";
system "git commit -a -m 'revise change log for version $version_number'";
system "git push -v" ;
print  "git tag -a $version_number -m '$tag_message'\n";
system "git tag -a $version_number -m '$tag_message'";
system "git push --tags";

