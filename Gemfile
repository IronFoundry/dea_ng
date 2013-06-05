source "https://rubygems.org"

gem "eventmachine"
gem "em-http-request"

gem "em-warden-client", :git => "https://github.com/cloudfoundry/warden.git"
gem "warden-client", :git => "https://github.com/cloudfoundry/warden.git"
gem "warden-protocol", :git => "https://github.com/cloudfoundry/warden.git"

gem "nats", :require => "nats/client"
gem "rack", :require => %w[rack/utils rack/mime]
gem "rake"
gem "thin"
gem "yajl-ruby", :require => %w[yajl yajl/json_gem]
gem "grape", :git => "https://github.com/intridea/grape.git"

# gem "vcap_common", :git => "https://github.com/cloudfoundry/vcap-common.git"
gem "vcap_common", :git => "https://github.com/IronFoundry/vcap-common.git", :branch => "ironfoundry"

# gem "steno", :git => "https://github.com/IronFoundry/steno.git", :branch => "ironfoundry"
gem "steno", :path => "C:/proj/cf/steno", :branch => "ironfoundry"

gem 'uuidtools', '~> 2.1'
gem 'nokogiri', '>= 1.4.4'

gem "sys-filesystem"

group :test do
  gem "timecop"
  gem "patron"
  gem "foreman"
  gem "sinatra"
  gem "librarian"
  gem "rspec"
  gem "rack-test"
  gem "rcov", "0.9.11"
  gem "ci_reporter"
end
