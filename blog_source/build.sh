#!/bin/sh

basedir=$(dirname $(pwd))
echo $basedir

hugo

cp -rf public/* $basedir/

rm -rf $basedir/blog_source/public


