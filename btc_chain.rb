#!/usr/bin/env ruby
#
# Ruby parser for Angelshares in the Bitcoin Blockchain.
# Usage: $ ruby btc_chain.rb [block=276970]
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

require 'json'

################################################################################

# Point this path to your PTS daemon!
@path = '/path/to/bitcoind'

# Enable/Disable debugging output.
@debug = false

################################################################################

if ARGV[0].nil?
  blockstrt = 276970
else
  blockstrt = ARGV[0].to_i
end

@sum = 0.0
@ags = 0
@day = 1388620800

puts "BLOCK;DATETIME;SENDER;DONATION[BTC];SUM[BTC];RATE[AGS/BTC];EXPECTED[AGS]"

def parse_tx(hi, time, tx)
  begin
    rawtx = `#{@path} getrawtransaction #{tx}`
    jsontx = `#{@path} decoderawtransaction #{rawtx}`
    jsontx = JSON.parse(jsontx)
    jsontx["vout"].each do |vout|
      address = vout["scriptPubKey"]["addresses"]
      value = vout["value"]
      if not address.nil?
        if address.include? '1ANGELwQwWxMmbdaSWhWLqBEtPTkWb8uDc'
          while (time.to_i > @day.to_i + 86400) do
            puts "+++++ Day Total: #{@sum} BTC (#{@ags} AGS/BTC) +++++"
            @sum = 0.0
            @day += 86400
            puts ""
            puts "+++++ New Day : #{Time.at(@day.to_i).utc} +++++"
            puts "BLOCK;DATETIME;SENDER;DONATION[BTC];SUM[BTC];RATE[AGS/BTC];EXPECTED[AGS]"
          end
          @sum += value
          stamp = Time.at(time.to_i).utc
          @ags = 5000.0 / @sum
          expected = value * @ags
          sendertx = jsontx['vin'].first['txid']
          sendernn = jsontx['vin'].first['vout']
          senderrawtx = `#{@path} getrawtransaction #{sendertx}`
          senderjsontx = `#{@path} decoderawtransaction #{senderrawtx}`
          senderjsontx = JSON.parse(senderjsontx)
          sender = 'unknown'
          senderjsontx["vout"].each do |sendervout|
            if sendervout['n'].eql? sendernn
              sender = sendervout['scriptPubKey']['addresses'].first
            end
          end
          puts hi.to_s + ';' + stamp.to_s + ';' + sender.to_s + ';' + value.to_s + ';' + @sum.to_s + ';' + @ags.to_s + ';' + expected.to_s
        end
      else
        if @debug
          puts "!!!WARNG ADDRESS EMPTY #{vout.to_s}"
        end
      end
    end
  rescue Errno::E2BIG
    if @debug
      puts "!!!ERROR TX TOO BIG TO PARSE #{tx}"
    end
  end
end

i=0
while true do
  if @debug
    puts "---DEBUG LOOP #{i}"
    puts "---DEBUG BLOCK #{blockstrt}"
  end
  blockhigh = `#{@path} getblockcount`
  (blockstrt.to_i..blockhigh.to_i).each do |hi|
    blockhash = `#{@path} getblockhash #{hi}`
    blockinfo = `#{@path} getblock #{blockhash}`
    transactions = JSON.parse(blockinfo)['tx']
    time = JSON.parse(blockinfo)['time']
    if not transactions.nil?
      if not transactions.size <= 1
        transactions.each do |tx|
          parse_tx(hi, time, tx)
        end
      else
        parse_tx(hi, time, transactions.first)
      end
    end
  end
  if @debug
    puts "---DEBUG SUM #{@sum}"
    puts "---DEBUG VALUE #{@ags}"
  end
  blockstrt = blockhigh.to_i + 1
  i += 1
  sleep(60)
end

#puts "+++++ Day Total: #{@sum} BTC (#{@ags} AGS/BTC) +++++"
