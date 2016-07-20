Gem::Specification.new do |s|
  s.name        = 'cp5200'
  s.version     = '0.0.1'
  s.date        = '2016-07-20'
  s.summary     = "cp5200"
  s.description = "C-Power cp5200 library"
  s.authors     = ["Alexander Kapustin"]
  s.email       = 'gonzalo.guerrero@yandex.ru'
  s.files       = ["lib/cp5200.rb"]
  s.homepage    = 'https://github.com/gonzaloguerrero/cp5200'
  s.license     = 'MIT'

  s.add_development_dependency 'bundler'
  s.add_runtime_dependency 'bindata'
end
