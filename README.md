# sql_anonymizer
A ruby script to read in sql and write out an anonymized version

# Requirements

* Written with ruby 2.4.1, but can probably tollerate any 2.x+
* Requires the `pg` and `faker` gems.
* .ruby-version and Gemfile provided, for those set up to make use of them.

# Usage

You need to create a configuration file. One is provided for dv3.

You need a plain-sql-format pg_dump for input, and it will output the same format.

You can read from a file or STDIN, and write to a file or STDOUT.

## Command line options

* `-c`/`--config` Specify the configuration file. Default is `anonymize-sql.yaml`
* `-i`/`--input` Specify the input file. If not provided, read from STDIN.
* `-o`/`--output` Specify the output file. If not provided, write to STDOUT.
* `-s`/`--schema` Specify the schema file. For when the input doesn't include schema data.
* `--consistent` Attempt to generate the same output given the same input. Slightly slower.

## Examples


`bundle exec ./anonymize-sql.rb --consistent -c dv3.anonymize-sql.yaml -s dv3.schema.sql -i dv3.data.sql -o dv3.anon-data.sql`

This will read dv3.out.sql, process it according to the config in dv3.anonymize-sql.yaml, and write to dv3.anon.sql

`pg_dump -Fp -d dv3_development | bundle exec ./anonymize-sql.rb --consistent -c dv3.anonymize-sql.yaml | psql dv3_anon`

Should be obvious.
