# MP3Sorter

## Introduction
mp3sorter sorts your MP3 files into directories based on the ID3 tags in the MP3 files.

There are two versions of MP3 sorter, one written in C and one written in Ruby.

The C version will only sort ID3v1 tags, however, the ruby version will sort both ID3v2 and ID3v1 tags.
ID3v2.2 and below is currently not supported.

## Usage

Both the C and Ruby version take the same arguments:
	mp3sorter input-directory|file output-directory
If there is more than one directory/file specified, the output directory MUST be specified.
If a single file/dir is specified and no output directory is specified, the current working directory will be used.