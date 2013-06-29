#!/usr/bin/env ruby -w

require 'yaml'

cc_ip     = ARGV[0]
cc_domain = ARGV[1]
nats_user = ARGV[2]
nats_pass = ARGV[3]

config_file = 'C:/IronFoundry/dea_ng/app/config/dea_mswin-clr.yml'

cfg = YAML.load_file(config_file)

cfg['local_route'] = cc_ip
cfg['domain'] = cc_domain

cfg['logging']['level'] = 'error'

if nats_user.nil? or nats_pass.nil?
  cfg['nats_uri'] = "nats://#{cc_ip}:4222/"
else
  cfg['nats_uri'] = "nats://#{nats_user}:#{nats_pass}@#{cc_ip}:4222/"
end

File.open(config_file, 'w') do |f|
  YAML.dump(cfg, f)
end

cmd = %w[netsh advfirewall firewall delete rule name=rubyw-193-in-allow]
system(*cmd)

cmd = %w[netsh advfirewall firewall delete rule name=rubyw-193-out-allow]
system(*cmd)

cmd = %w[netsh advfirewall firewall add rule name=rubyw-193-in-allow dir=in action=allow program=C:\\Ruby193\\bin\\rubyw.exe]
system(*cmd)

cmd = %w[netsh advfirewall firewall add rule name=rubyw-193-out-allow dir=out action=allow program=C:\Ruby193\bin\rubyw.exe]
system(*cmd)

exit(true)
