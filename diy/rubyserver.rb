#!/usr/bin/env ruby

# WEBrick server middleware to return a list of altitudes ODN from NGRs.

# Copyright (C) 2015 Patrick B Warren unless stated otherwise.
# Email: patrickbwarren@gmail.com
# Paper mail: Dr Patrick B Warren, 11 Bryony Way, Birkenhead,
#   Merseyside, CH42 4LY, UK.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.

# This code modified from the DIY openshift cartridge released by RedHat.

require 'webrick'
include WEBrick

Dir.chdir(ARGV[1])

config = {}
config.update(:Port => 8080)
config.update(:BindAddress => ARGV[0])
config.update(:DocumentRoot => ARGV[1])

server = HTTPServer.new(config)

['INT', 'TERM'].each {|signal|
  trap(signal) {server.shutdown}
}

server.mount_proc '/exec' do |req, res|
  File.open('ngr.txt', 'w') do |f|
    f.puts(req.query["ngr"])
  end
  res['Content-Type'] = "text/plain"
  res.body = `cd #{ARGV[1]}; /usr/bin/perl process.pl ngr.txt`
end

server.start
