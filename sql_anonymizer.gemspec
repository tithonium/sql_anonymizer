# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'sql_anonymizer'
  spec.version       = '2.0.0'
  spec.authors       = ["Martin Tithonium"]
  spec.email         = ["martian@midgard.org"]
  spec.description   = %q{A ruby script to read in sql and write out an anonymized version}
  spec.summary       = %q{A ruby script to read in sql and write out an anonymized version}
  spec.homepage      = ""
  spec.license       = ""

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'faker'
  spec.add_runtime_dependency 'pg'
end
