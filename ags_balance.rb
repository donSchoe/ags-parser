#!/usr/bin/env ruby
#
# Ruby parser for Angelshares in your BTC/PTS wallet.
# Usage: $ ruby ags_balances.rb
#
# Donations accepted:
# - BTC 1Bzc7PatbRzXz6EAmvSuBuoWED96qy3zgc
# - PTS PcDLYukq5RtKyRCeC1Gv5VhAJh88ykzfka
#
# Copyright (C) 2014 donSchoe <donschoe@qhor.net>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

require 'net/http'
require 'open-uri'
require 'timeout'
require 'time'
require 'date'

pts_url = 'http://q39.qhor.net/ags/pts.csv.txt'
btc_url = 'http://q39.qhor.net/ags/btc.csv.txt'
pts_data = open(pts_url).read
btc_data = open(btc_url).read
pts_donations = Hash.new
btc_donations = Hash.new
ags_balances = Hash.new
pts_ags_daily_rates = Hash.new
btc_ags_daily_rates = Hash.new
pts_sum = 0.0
btc_sum = 0.0
ags_rate = 0.0
day_break = 1388620800.0
day_count = 0
day_today = Time.new(Time.now.utc.year, Time.now.utc.month, Time.now.utc.day, 0, 0, 0, 0).utc

pts_data.lines.each do |line|
  line = line.gsub(/\"/,'').split(';')
  if not line[0].eql? 'BLOCK'
    time = Time.parse(line[1]).utc
    while (time.to_f > day_break.to_f) do
      pts_ags_daily_rates[day_count] = ags_rate
      day_count += 1
      pts_sum = 0.0
      day_break += 86400.0
    end
    amount = line[3].to_f
    pts_sum += amount
    ags_rate = 5000.0 / pts_sum
  end
end

puts '{'
puts '  "day_count":"' + day_count.to_s + '",'
puts '  "last_update":"' + day_today.to_s + '",'
puts '  "balances": {'

day_break = 1388620800.0
day_count = 0

btc_data.lines.each do |line|
  line = line.gsub(/\"/,'').split(';')
  if not line[0].eql? 'BLOCK'
    time = Time.parse(line[1]).utc
    while (time.to_f > day_break.to_f) do
      btc_ags_daily_rates[day_count] = ags_rate
      day_count += 1
      btc_sum = 0.0
      day_break += 86400.0
    end
    amount = line[3].to_f
    btc_sum += amount
    ags_rate = 5000.0 / btc_sum
  end
end

day_break = 1388620800.0
day_count = 0

pts_data.lines.each do |line|
  line = line.gsub(/\"/,'').split(';')
  if not line[0].eql? 'BLOCK'
    time = Time.parse(line[1]).utc
    if time.to_f < day_today.to_f
      while (time.to_f > day_break.to_f) do
        day_count += 1
        day_break += 86400.0
      end
      block = line[0].to_i
      sender = line[2].to_s
      amount = line[3].to_f
      pts_sum += amount
      if pts_donations[sender].nil?
        pts_donations[sender] = amount
        ags_balances[sender] = pts_ags_daily_rates[day_count].to_f * amount
      else
        pts_donations[sender] += amount
        ags_balances[sender] += pts_ags_daily_rates[day_count].to_f * amount
      end
    end
  end
end

day_break = 1388620800.0
day_count = 0

btc_data.lines.each do |line|
  line = line.gsub(/\"/,'').split(';')
  if not line[0].eql? 'BLOCK'
    time = Time.parse(line[1]).utc
    if time.to_f < day_today.to_f
      while (time.to_f > day_break.to_f) do
        day_count += 1
        day_break += 86400.0
      end
      block = line[0].to_i
      sender = line[2].to_s
      amount = line[3].to_f
      btc_sum += amount
      if btc_donations[sender].nil?
        btc_donations[sender] = amount
        ags_balances[sender] = btc_ags_daily_rates[day_count].to_f * amount
      else
        btc_donations[sender] += amount
        ags_balances[sender] += btc_ags_daily_rates[day_count].to_f * amount
      end
    end
  end
end

ags_balances = ags_balances.sort_by {|key, value| value}.reverse
ags_balances.each do |adr, ags|
  if adr.eql? ags_balances.last.first
    puts '    "' + adr.to_s + '":"' + ags.to_f.round(8).to_s + '"'
  else
    puts '    "' + adr.to_s + '":"' + ags.to_f.round(8).to_s + '",'
  end
end

puts '  }'
puts '}'

