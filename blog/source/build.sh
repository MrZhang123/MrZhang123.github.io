#!/bin/sh

basedir=$(dirname $(pwd))

rm -rf $basedir/public

yarn build

mv public $basedir
