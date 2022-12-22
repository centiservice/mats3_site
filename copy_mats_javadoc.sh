#!/bin/sh

#
# Copying in all JavaDocs from mats-build to javadoc folder
# - Endre Stølsvik 2022-11-29
#

# Note the concept of "classic" vs. "modern". It refers to the IFrames that the original JavaDoc had, vs. the
# new crappy solution. The build must be done with jdk8 for "classic", and latest jdk for "modern".
# Only for "modern" will the API docs be copied.

matsversion='0.19'

copyJavaDoc() {
  variant=$1

  if [ "$variant" = "modern" ]; then
    echo "MODERN! Will also copy API docs alone (mats-api)"
  elif [ "$variant" = "classic" ]; then
    echo "CLASSIC! Not copying API docs mats-api."
  else
    echo "ERROR: Neither classic nor modern - stopping."
  fi

  # Assert that we're where we should be
  if [ -d '.git' -a -e 'EndreXY-README.txt' ]; then
    echo "Asserted location, good to go."
  else
    pwd=$(pwd)
    echo "Not in expected location, we're here: $pwd"
    exit 1
  fi

  if [ "$variant" = "modern" ]; then
    echo "Note: Variant 'modern', thus also copying API docs alone (mats-api)"
    mkdir -p javadoc/mats3/$matsversion/api
    echo "Deleting 'javadoc/mats3/$matsversion/api/*'"
    rm -rf javadoc/mats3/$matsversion/api/*
    echo "Copying in API docs from mats-api"
    cp -r ../mats3/mats-api/build-gradle/docs/javadoc/* javadoc/mats3/$matsversion/api/
  fi

  # Make correct folder if not present
  mkdir -p javadoc/mats3/$matsversion/$variant
  echo "Deleting 'javadoc/mats3/$matsversion/$variant/*'"
  rm -rf javadoc/mats3/$matsversion/$variant/*
  echo "Copying in alljavadocs from root of mats3"
  cp -r ../mats3/build-gradle/docs/javadoc/* javadoc/mats3/$matsversion/$variant/
}

## CLASSIC JAVADOC + JSDOC

echo "## CLASSIC JAVADOC"
echo "Setting Java to 8"
jdk8.sh
java -version

echo "cd to mats3"
cd ../mats3/ || exit 1

echo "building javadoc"
./gradlew clean javadoc

cd ../mats3_site/ || exit 1

echo "Copying JavaDoc"
copyJavaDoc "classic"

## MODERN JAVADOC + JSDOC

echo "## MODERN JAVADOC + JSDOC"
echo "Setting Java to 17"
jdk17.sh
java -version

echo "cd to mats3"
cd ../mats3/ || exit 1

echo "building javadoc"
./gradlew clean javadoc

cd ../mats3_site/ || exit 1

echo "Copying JavaDoc"
copyJavaDoc "modern"

echo "Setting Java back to 8"
jdk8.sh