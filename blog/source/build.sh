#!/bin/sh

basedir=$(dirname $(pwd))

rm -rf $basedir/home

yarn build

mv public $basedir/home

