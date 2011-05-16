source 'http://rubygems.org'

gem 'rails', '3.0.4'
gem 'unicorn'
gem 'pg', '0.9.0'
gem 'sequel', '3.16.0'
gem 'sequel-rails', '0.1.8'
gem 'bcrypt-ruby', :require => 'bcrypt'
gem 'rgl', :require => ['rgl/base', 'rgl/adjacency', 'rgl/topsort']
gem 'erector', :git => 'https://github.com/bigfix/erector.git', :tag => 'rails3'
gem 'pony', '1.1'
gem 'haml', '3.0.25'
gem 'resque', '1.15.0'
gem 'resque-status', '0.2.3', :require => ['resque/status', 'resque/job_with_status']
gem 'uuidtools', '2.1.2'

group :development, :test do
  gem 'thin'
  gem 'thor'
  gem 'haml', '3.0.25'
  gem 'rspec', '~> 2.5.0'
  gem 'rspec-rails', '~> 2.5.0'
  gem 'rr', '1.0.2'
  gem 'machinist', '1.0.6'
  gem 'faker', '0.9.5'
  gem 'spork', '~> 0.9.0.rc'
  gem 'parallel_tests', :git => 'git@github.com:nathansobo/parallel_tests.git', :ref => '1aacd508c932d360c015'
end

group :deploy do
  gem 'net-ssh', '2.1.0'
  gem 'net-ssh-telnet', :require => 'net/ssh/telnet'
  gem 'net-sftp', :require => 'net/sftp'
  gem 'uuidtools', '2.1.2'
end
