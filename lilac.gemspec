Gem::Specification.new do |s|
  s.name          = "lilac"
  s.version       = "0.0.0"
  s.summary       = "Compiler infrastructure"
  s.description   = "Lilac is a small compiler infrastructure."
  s.authors       = ["Matthew Daly"]
  s.email         = "hello@mattdaly.xyz"
  s.homepage      = "https://github.com/matthewd673/lilac"
  s.files         = Dir.glob("lib/**/*")
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.3.0"
end
