require_relative 'lib/cp5200/version'

Gem::Specification.new do |s|
  s.name        = 'cp5200'
  s.version     = CPower::VERSION
  s.date        = '2016-07-20'
  s.summary     = "cp5200"
  s.description = "C-Power cp5200 library"
  s.authors     = ["Alexander Kapustin"]
  s.email       = 'gonzalo.guerrero@yandex.ru'
  s.homepage    = 'https://github.com/gonzaloguerrero/cp5200'
  s.license     = 'MIT'
  s.platform    = Gem::Platform::RUBY

  s.files        = Dir["{lib}/**/*.rb", "Gemfile", "*.md"]
  s.require_path = 'lib'

  s.add_runtime_dependency 'bindata', '~> 2.3', '>= 2.3.0'
end
